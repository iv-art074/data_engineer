import os
import shutil
from pathlib import Path
import pandas as pd
import logging
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.utils.dates import days_ago
from datetime import datetime, timedelta

# Пути к файлам
source_path = "/home/airflow" #/opt/airflow/config" #~/mnt/c/Users/iv_art/Documents/diplom"   #/home/iv_art/airflow/"
target_path = "/home/airflow"

# Аргументы для DAG
default_args = {
    'owner': 'airflow',
    'start_date': days_ago(1),
    'retries': 2,
    'retry_delay': timedelta(minutes=1),
}

# Объявляем DAG
dag = DAG(
    'get_data_dag',
    default_args=default_args,
    description='Get data from CSV and load to SQL',
    schedule_interval='0 1 * * *',  # Запуск каждый день в 1:00 ночи
    )

# Подключение
def connect_to_db(conn_id='nds_airflow'):
#    logging.info(f"Connecting to the database with conn_id: {conn_id}")
    pg_hook = PostgresHook(postgres_conn_id=conn_id)
    connect = pg_hook.get_conn()
    logging.info(f"Connection with: {conn_id} established.")
    return connect

# Лог статуса загрузок
def log_load_status(connect, load_id, status, message=None):
    try:
        cur = connect.cursor()
      #  logging.info(f"Inserting load status for load_id: {load_id}, status: {status}, message: {message}")
        cur.execute("""
            INSERT INTO load_status (load_id, status_time, status, message)
            VALUES (%s, %s, %s, %s)
            """, (load_id, datetime.now(), status, message))
        connect.commit()
        cur.close()
        logging.info(f"Load status: {status} inserted successfully.")
    except Exception as ex:
        logging.error(f"Error: {str(ex)}")
        raise

# Начинем загрузку в history
def start_load(dag_id, task_id):
    try:
        connect = connect_to_db('dds_airflow')
        cur = connect.cursor()
#        logging.info(f"Inserting load history for DAG: {dag_id}, task: {task_id}")
        cur.execute("""
            INSERT INTO load_history (dag_id, task_id, start_time)
            VALUES (%s, %s, %s) RETURNING load_id
            """, (dag_id, task_id, datetime.now()))
        load_id = cur.fetchone()[0]
        connect.commit()
        cur.close()
        connect.close()
        logging.info(f"Load history DAG: {dag_id}, task: {task_id} started with load_id: {load_id}")
        return load_id
    except Exception as ex:
        logging.error(f"Error: {str(ex)}")
        raise

# Окончание загрузки history
def end_load(load_id, row_count=None, error_message="Ok"):
    try:
        connect = connect_to_db('dds_airflow')
        cur = connect.cursor()
#        logging.info(f"Updating load history for load_id: {load_id}, status: {status}, row_count: {row_count}, error_message: {error_message}")
        cur.execute("""
            UPDATE load_history
            SET end_time = %s, rows_ = %s, error_ = %s
            WHERE load_id = %s
            """, (datetime.now(), row_count, error_message, load_id))
        connect.commit()
        cur.close()
        connect.close()
        logging.info(f"Load history for load_id: {load_id} updated successfully.")
    except Exception as ex:
        logging.error(f"Error: {str(ex)}")
        raise


# Перенос в базу данных
def load_data_to_db(df):
    connect = connect_to_db()
    cur = connect.cursor()

    logging.info(f"Loading data to the database. Data shape: {df.shape}")
    
    # Очистка от дубликатов
    branch_unique = df[['branch']].drop_duplicates()
    city_unique = df[['city']].drop_duplicates()
    customer_unique = df[['customer_type', 'gender']].drop_duplicates()
    product_line_unique = df[['product']].drop_duplicates()
    payment_unique = df[['payment']].drop_duplicates()

    # Заполнение уникальными значениями таблиц
    for branch in branch_unique['branch']:
        cur.execute("""
            INSERT INTO Branches (branch_name) VALUES (%s) 
            ON CONFLICT (branch_name) DO NOTHING
        """, (branch,))
    for city in city_unique['city']:
        cur.execute("""
            INSERT INTO City (city_name) VALUES (%s) 
            ON CONFLICT (city_name) DO NOTHING
        """, (city,))
    for _, row in customer_unique.iterrows():
        cur.execute("""
            INSERT INTO Customer (customer_type, gender) VALUES (%s, %s) 
            ON CONFLICT DO NOTHING
        """, (row['customer_type'], row['gender']))
    for product_line in product_line_unique['product']:
        cur.execute("""
            INSERT INTO ProductLine (product_line_name) VALUES (%s) 
            ON CONFLICT (product_line_name) DO NOTHING
        """, (product_line,))
    for payment in payment_unique['payment']:
        cur.execute("""
            INSERT INTO Payment (payment_type) VALUES (%s) 
            ON CONFLICT (payment_type) DO NOTHING
        """, (payment,))

    connect.commit()
    logging.info("Inserted unique data into Branches, City, Customer, Product, Payment tables.")
    
    # Заполнение Sales
    for _, row in df.iterrows():
        cur.execute("""
            INSERT INTO Sales (
                invoice_id, branch_id, city_id, customer_id, product_id, cost, quantity, 
                tax, total, date_, time_, payment_id, cogs, gross_margin_percentage, gross_income, rating, flashed)
            VALUES (
                %s,
                (SELECT branch_id FROM Branches WHERE branch_name = %s LIMIT 1),
                (SELECT city_id FROM City WHERE city_name = %s LIMIT 1),
                (SELECT customer_id FROM Customer WHERE customer_type = %s AND gender = %s LIMIT 1),
                (SELECT product_id FROM ProductLine WHERE product_line_name = %s LIMIT 1),
                %s, %s, %s, %s, %s, %s, 
                (SELECT payment_id FROM Payment WHERE payment_type = %s LIMIT 1),
                %s, %s, %s, %s, FALSE
            )
            ON CONFLICT (invoice_id) DO NOTHING
        """, (
            row['invoice_id'], row['branch'], row['city'], row['customer_type'], row['gender'], row['product'],
            row['cost'], row['quantity'], row['tax'], row['total'], row['date'], row['time'],
            row['payment'], row['cogs'], row['gross_margin_percentage'], row['gross_income'], row['rating']
        ))

    connect.commit()
    cur.close()
    connect.close()
    logging.info("Data committed to Sales table.")

# Формируем датафрейм из CSV файла
def process_data(file_path):
    logging.info(f"Loading file: {file_path}")
    df = pd.read_csv(file_path)
    logging.info(f"Initial dataframe shape: {df.shape}")
    
    # Удаление пустых и дублированных строк
    df.dropna(inplace=True)
    df.drop_duplicates(inplace=True)
    logging.info(f"Cleaned dataframe shape: {df.shape}")
    
    # Удаление ошибочных символов и переименование столбцов
    df.columns = df.columns.str.replace('ï»¿', '')  
    df.rename(columns={
        'Invoice ID': 'invoice_id',
        'Branch': 'branch',
        'City': 'city',
        'Customer type': 'customer_type',
        'Gender': 'gender',
        'Product line': 'product',
        'Unit price': 'cost',
        'Quantity': 'quantity',
        'Tax 5%': 'tax',
        'Total': 'total',
        'Date': 'date',
        'Time': 'time',
        'Payment': 'payment',
        'cogs': 'cogs',
        'gross margin percentage': 'gross_margin_percentage',
        'gross income': 'gross_income',
        'Rating': 'rating'
    }, inplace=True)
    df['date'] = pd.to_datetime(df['date'])
    df['time'] = pd.to_datetime(df['time']).dt.time

    logging.info(f"Processed dataframe columns: {df.columns}")
    return df

# Основная функция выполнения процесса
def main(**kwargs):
    dag_id = kwargs['dag'].dag_id
    task_id = kwargs['task'].task_id
    load_id = start_load(dag_id, task_id)
    kwargs['load_id'] = load_id
    logging.info(f"Запускаем DAG {dag_id}, task {task_id}, id загрузки {load_id}")
    connect = connect_to_db('dds_airflow')

    try:
        log_load_status(connect, load_id, 'processing', 'Starting main function')
        logging.info("Starting main function")
        input_files = [f for f in os.listdir(source_path) if f.endswith('.csv') ]
        logging.info(f"Input files: {input_files}")
        row_count = 0
        for file in input_files:
            full_file_path = os.path.join(source_path, file)
            df = process_data(full_file_path)
            load_data_to_db(df)
            row_count += len(df)
            
            now = datetime.now()
            base_name = os.path.basename(full_file_path)
            new_name = f"{os.path.splitext(base_name)[0]}"+now.strftime("_%d_%m_%Y_%H:%M:%S")+".ext"   #f"{os.path.splitext(base_name)[0]}.ext"
            logging.info(f"Movin` file from: {full_file_path} to: {os.path.join(target_path, new_name)}")
            shutil.move(full_file_path, os.path.join(target_path, new_name)) #os.rename(full_file_path, os.path.join(target_path, new_name))
            #logging.info(f"Moved file from: {full_file_path} to: {os.path.join(target_path, new_name)}")
            
        log_load_status(connect, load_id, 'completed', 'Main function completed successfully')
        end_load(load_id,row_count)
    except Exception as ex:
        log_load_status(connect, load_id, 'failed', str(ex))
        end_load(load_id, error_message=str(ex))
        raise
    finally:
        connect.close()

# Определение задачи для обработки данных
get_data_task = PythonOperator(
    task_id='process_data',
    python_callable=main,
    provide_context=True,
    dag=dag,
)

get_data_task
