Установил образ и запустил контейнеры добавив к указанной в DockerHub команде проброс порта 9000  
docker run -d -p 9000:9000 --name some-clickhouse-server --ulimit nofile=262144:262144 yandex/clickhouse-server  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/f183cce0-986b-4c67-9aa6-5a9e900ebdf1)  

Создал базу и таблицу  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/80b7d1f8-70f9-45af-90de-68ae0a2f91f8)  

заполнил данными  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/1a092bb4-fe51-469c-ac84-d5a491910fa9)  

составил запрос  
![image](https://github.com/iv-art074/data_engineer/assets/87374285/3b8033cd-b62b-4574-b624-2bf8b96d3ef3)

Очевидно пользователь с UserID 1313448155240738815 сделал больше всего просмотров страниц (если я правильно понимаю структуру базы)  :)  





