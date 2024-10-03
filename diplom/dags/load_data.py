import os
import pandas as pd
from airflow import DAG
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from datetime import datetime, timedelta
import logging

# Аргументы по умолчанию для DAG
default_args = {
    'owner': 'airflow',
    'start_date': days_ago(1),
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

# Определение DAG
dag = DAG(
    'load_data_dag',
    default_args=default_args,
    description='Load data to DDS',
    schedule_interval='0 17 * * *',  # Запуск каждый день в 2:00 ночи
)

# Функция для подключения к базе данных
def connect_to_db(conn_id):
    logging.info(f"Connecting to the database with conn_id: {conn_id}")
    pg_hook = PostgresHook(postgres_conn_id=conn_id)
    connect = pg_hook.get_conn()
    logging.info("Connection established.")
    return connect

# Функция для логирования статуса загрузки
def log_load_status(connect, load_id, status, message=None):
    try:
        cur = connect.cursor()
       # logging.info(f"Inserting load status for load_id: {load_id}, status: {status}, message: {message}")
        cur.execute("""
            INSERT INTO load_status (load_id, status_time, status, message)
            VALUES (%s, %s, %s, %s)
        """, (load_id, datetime.now(), status, message))
        connect.commit()
        cur.close()
        logging.info(f"Load status inserted for load_id: {load_id}, status: {status} successfully.")
    except Exception as ex:
        logging.error(f"Error: {str(ex)}")
        raise

# Функция для начала загрузки
def start_load(dag_id, task_id):
    try:
        connect = connect_to_db('dds_airflow')
        cur = connect.cursor()
        #logging.info(f"Inserting load history for DAG: {dag_id}, task: {task_id}")
        cur.execute("""
            INSERT INTO load_history (dag_id, task_id, start_time)
            VALUES (%s, %s, %s) RETURNING load_id
        """, (dag_id, task_id, datetime.now()))
        load_id = cur.fetchone()[0]
        connect.commit()
        cur.close()
        connect.close()
        logging.info(f"Load history started for DAG: {dag_id}, task: {task_id}, load_id: {load_id}")
        return load_id
    except Exception as ex:
        logging.error(f"Error: {str(ex)}")
        raise

# Функция для завершения загрузки
def end_load(load_id, row_=None, error_="Ok"):
    try:
        connect = connect_to_db('dds_airflow')
        cur = connect.cursor()
#  logging.info(f"Updating load history for load_id: {load_id}, status: {status}, row_count: {row_count}, error_message: {error_message}")
        cur.execute("""
            UPDATE load_history
            SET end_time = %s, rows_ = %s, error_ = %s
            WHERE load_id = %s
        """, (datetime.now(), row_, error_, load_id))
        connect.commit()
        cur.close()
        connect.close()
        logging.info(f"Load history for load_id: {load_id}, rows: {row_} updated successfully.")
    except Exception as ex:
        logging.error(f"Error: {str(ex)}")
        raise

# Функция для получения новых данных из базы данных NDS
def extract_data():
    connect = connect_to_db('nds_airflow')
    sql_q = """
        SELECT s.*, 
               b.branch_name, 
               c.city_name, 
               cu.customer_type, cu.gender, 
               pl.product_line_name, 
               p.payment_type
        FROM Sales s
        JOIN Branches b ON s.branch_id = b.branch_id
        JOIN City c ON s.city_id = c.city_id
        JOIN Customer cu ON s.customer_id = cu.customer_id
        JOIN ProductLine pl ON s.product_id = pl.product_id
        JOIN Payment p ON s.payment_id = p.payment_id
        WHERE s.flashed = FALSE;
    """
    df = pd.read_sql(sql_q, connect)
    connect.close()
    logging.info(f"Extracted {len(df)} rows from NDS.")
    return df

# Функция для вставки данных в базу данных DDS
def load_data_to_dds(df, load_id):
    connect = connect_to_db('dds_airflow')
    cur = connect.cursor()
#    logging.info(f"Loading data to DDS. Data shape: {df.shape}")

    # Вставка уникальных значений в таблицы измерений
    for _, row in df.iterrows():
        cur.execute("""
            INSERT INTO dim_branches (b_name) VALUES (%s)
            ON CONFLICT (b_name) DO NOTHING;
        """, (row['branch_name'],))
        cur.execute("""
            INSERT INTO dim_city (city_name) VALUES (%s)
            ON CONFLICT (city_name) DO NOTHING;
        """, (row['city_name'],))
        cur.execute("""
            INSERT INTO dim_customer (customer_type, gender) VALUES (%s, %s)
            ON CONFLICT (customer_type, gender) DO NOTHING;
        """, (row['customer_type'], row['gender']))
        cur.execute("""
            INSERT INTO dim_product_line (product_name) VALUES (%s)
            ON CONFLICT (product_name) DO NOTHING;
        """, (row['product_line_name'],))
        cur.execute("""
            INSERT INTO dim_payment (payment_type) VALUES (%s)
            ON CONFLICT (payment_type) DO NOTHING;
        """, (row['payment_type'],))
        cur.execute("""
            INSERT INTO dim_date (date, year, quarter, month, day, day_of_week)
            VALUES (%s, EXTRACT(YEAR FROM %s), EXTRACT(QUARTER FROM %s), EXTRACT(MONTH FROM %s), EXTRACT(DAY FROM %s), TO_CHAR(%s, 'Day'))
            ON CONFLICT (date) DO NOTHING;
        """, (row['date_'], row['date_'], row['date_'], row['date_'], row['date_'], row['date_']))
        cur.execute("""
            INSERT INTO dim_time (time, hour, minute, second)
            VALUES (%s, EXTRACT(HOUR FROM %s), EXTRACT(MINUTE FROM %s), EXTRACT(SECOND FROM %s))
            ON CONFLICT (time) DO NOTHING;
        """, (row['time_'], row['time_'], row['time_'], row['time_']))

    # Вставка данных в таблицу фактов
    for _, row in df.iterrows():
        cur.execute("""
            INSERT INTO fact_sales (
                invoice_id, b_id, city_id, customer_id, product_id, cost, quantity, 
                tax, total, date_id, time_id, payment_id, cogs, 
                gross_margin_percentage, gross_income, rating
            )
            VALUES (
                %s,
                (SELECT b_id FROM dim_branches WHERE b_name = %s),
                (SELECT city_id FROM dim_city WHERE city_name = %s),
                (SELECT customer_id FROM dim_customer WHERE customer_type = %s AND gender = %s),
                (SELECT product_id FROM dim_product_line WHERE product_name = %s),
                %s, %s, %s, %s,
                (SELECT date_id FROM dim_date WHERE date = %s),
                (SELECT time_id FROM dim_time WHERE time = %s),
                (SELECT payment_id FROM dim_payment WHERE payment_type = %s),
                %s, %s, %s, %s
            )
            ON CONFLICT (invoice_id) DO NOTHING;
        """, (
            row['invoice_id'], row['branch_name'], row['city_name'], row['customer_type'], row['gender'], row['product_line_name'],
            row['cost'], row['quantity'], row['tax'], row['total'],
            row['date_'], row['time_'], row['payment_type'], row['cogs'], row['gross_margin_percentage'], row['gross_income'], row['rating']
        ))

    connect.commit()
    cur.close()
    connect.close()
    logging.info("Data loaded to DDS successfully.")

    # Обновление поля переноса в NDS
    connect_nds = connect_to_db('nds_airflow')
    cur_nds = connect_nds.cursor()
    invoice_ids = tuple(df['invoice_id'].tolist())
    cur_nds.execute("""
        UPDATE Sales
        SET flashed = TRUE
        WHERE invoice_id IN %s;
    """, (invoice_ids,))
    connect_nds.commit()
    cur_nds.close()
    connect_nds.close()
    logging.info("NDS Sales table updated successfully.")

# Основная функция выполнения процесса
def main(**kwargs):
    dag_id = kwargs['dag'].dag_id
    task_id = kwargs['task'].task_id
    load_id = start_load(dag_id, task_id)
    connect = connect_to_db('dds_airflow')

    try:
        log_load_status(connect, load_id, 'loading', 'Started task')
        logging.info("Starting...")
        df = extract_data()
        if not df.empty:
            load_data_to_dds(df, load_id)
            row_count = len(df)
        else:
            logging.info("Nothing to load")
            row_count = 0

        log_load_status(connect, load_id, 'loaded', 'Main function completed successfully')
        end_load(load_id, row_count)
    except Exception as ex:
        log_load_status(connect, load_id, 'failed', str(ex))
        end_load(load_id, error_message=str(ex))
        raise
    finally:
        connect.close()

# Определение задачи для обработки данных
load_dim_data_task = PythonOperator(
    task_id='load_data',
    python_callable=main,
    provide_context=True,
    dag=dag,
)

load_dim_data_task