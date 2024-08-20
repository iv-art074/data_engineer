Необходимо сделать dockerfile для получения рабочего контейнера.  

В качестве основы, берём образ continuumio/miniconda3:latest  
Добавляем и делаем рабочей папкой /app  
Создаём простой sh файл с названием 1.sh, который должен выдавать надпись “Hello Netology”.  
Надо скопировать этот файл внутрь контейнера и выдать ему права на исполнение.  
Запустить установку пакетов python mlflow boto3 pymysql.  
В конце запустить на вывод файл 1.sh.  
После чего собрать через docker build контейнер с тегом netology-ml:netology-ml  

мой dockerfile  

![изображение](https://github.com/user-attachments/assets/f915bb49-5a69-4b26-8ced-624ca2675c3b)  

результат  
![изображение](https://github.com/user-attachments/assets/772c24db-8fde-46e6-9764-8a762236f84c)  




