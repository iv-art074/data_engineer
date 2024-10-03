from airflow import DAG
from airflow.operators.dagrun_operator import TriggerDagRunOperator
from airflow.sensors.external_task_sensor import ExternalTaskSensor
from airflow.operators.email_operator import EmailOperator
from airflow.utils.dates import days_ago
from datetime import timedelta, datetime
from airflow.notifications.basenotifier import BaseNotifier
from airflow.utils.state import State

#class MyNotifier(BaseNotifier):
#    """
#    Basic notifier, prints the task_id, state and a message.
#    """
#
#    template_fields = ("message",)
#
#    def __init__(self, message):
#        self.message = message
#
#    def notify(self, context):
#        t_id = context["ti"].task_id
#        t_state = context["ti"].state
#        print(f"Извещение! {t_id} закончен: {t_state} со статусом {self.message}")





default_args = {
    'owner': 'airflow',
    'start_date': days_ago(1),
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'dags_dag',
    default_args=default_args,
    description='Trigger for other DAGs',
    schedule_interval='0 2 * * *',  # Запуск каждый день в 1:00 
    catchup=False,
    #on_success_callback=MyNotifier(message="Success!"),
    #on_failure_callback=MyNotifier(message="Failure!"),
)

# Запуск create_dag
#trigger_create_tables_dag = TriggerDagRunOperator(
#    task_id='trigger_create_tables_dag',
#    trigger_dag_id='create_tables_dag',
#    dag=dag,
#    #on_success_callback=MyNotifier(message="Task Succeeded!"),
#    #on_failure_callback=MyNotifier(message="Failure!")

#)

# Ожидание завершения create_dag
#wait_for_create_tables_dag = ExternalTaskSensor(
#    task_id='wait_for_create_tables_dag',
#    external_dag_id='create_tables_dag',
#    external_task_id=None,
#    mode='reschedule',
    #timeout=60*60,  # ждем до 1 часа
#    dag=dag,
#)

# Запуск process_data_dag
trigger_get_data_dag = TriggerDagRunOperator(
    task_id='trigger_get_data_dag',
    trigger_dag_id='get_data_dag',
    dag=dag,
#    on_success_callback=MyNotifier(message="Task Succeeded!"),
#    on_failure_callback=MyNotifier(message="Failure!")
)

# Ожидание завершения process_data_dag
wait_for_get_data_dag = ExternalTaskSensor(
    task_id='wait_for_get_data_dag',
    external_dag_id='get_data_dag',
    external_task_id=None,
    allowed_states=[State.SUCCESS],
    execution_delta=timedelta(minutes=30),
#    mode='reschedule',
#    timeout=60*60,  # ждем до 1 часа
    dag=dag,
)

# Запуск load_data_dag
trigger_load_data_dag = TriggerDagRunOperator(
    task_id='trigger_load_data_dag',
    trigger_dag_id='load_data_dag',
    dag=dag,
#    on_success_callback=MyNotifier(message="Task Succeeded!"),
#    on_failure_callback=MyNotifier(message="Failure!")
)

# Ожидание завершения transfer_data_dag
wait_for_load_data_dag = ExternalTaskSensor(
    task_id='wait_for_load_data_dag',
    external_dag_id='load_data_dag',
    external_task_id=None,
    mode='reschedule',
    timeout=60*60,  # ждем до 1 часа
    dag=dag,
)

# Уведомление об ошибке
#error_notification = EmailOperator(
#    task_id='error_notification',
#    to='petr0vskjy.aleksander@gmail.com',
#    subject='ETL DAG Failed',
#    html_content='One of the DAGs in the ETL process failed after 3 attempts.',
#    trigger_rule='one_failed',  # Выполняется, если хотя бы одна из предыдущих задач завершилась с ошибкой
#    dag=dag,
#)



# Определение порядка выполнения задач
#trigger_create_tables_dag >> wait_for_create_tables_dag >> 
trigger_get_data_dag >> wait_for_get_data_dag >> trigger_load_data_dag >> wait_for_load_data_dag

# Добавляем уведомление об ошибке ко всем сенсорам
#wait_for_create_tables_dag >> notify(context="создание таблиц") #error_notification
#wait_for_get_data_dag >> notify(context="загрузка данных") #error_notification
#wait_for_load_data_dag >> notify(context="перенос в DDS") #error_notification
