import airflow
import datetime
from datetime import timedelta
from airflow import DAG
from airflow.operators.postgres_operator import PostgresOperator
from airflow.utils.dates import days_ago

# create_tables
# instantiating the Postgres Operator

with DAG(
    dag_id="create_tables_dag",
    start_date=datetime.datetime(2020, 2, 2),
    schedule_interval="@once",
    catchup=False,
) as dag:
    create_nds_table = PostgresOperator(
    task_id="create_nds_table",
    postgres_conn_id="nds_airflow",
    sql="sql/nds_table.sql",
    )
    create_dds_table = PostgresOperator(
    task_id="create_dds_table",
    postgres_conn_id="dds_airflow",
    sql="sql/dds_table.sql",
    )

create_nds_table >> create_dds_table

