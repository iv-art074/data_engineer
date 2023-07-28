## Домашнее задание по теме "Введение в SQL. Установка ПО"   Артемьев Игорь  

### Основная часть  

### Задание 1.
Создайте новое соединение в DBeaver и подключите облачную базу данных с учебной базой данных dvd-rental согласно инструкции. Сделайте скриншот результата.  
![Screenshot 2023-07-28 181850](https://github.com/iv-art074/data_engineer/assets/87374285/806aa616-3646-4a73-9514-fc13353a6130)  
### Задание 2.
Откройте ER-диаграмму таблиц учебной базы данных dvd-rental. Сделайте скриншот результата.  
![Screenshot 2023-07-28 182538](https://github.com/iv-art074/data_engineer/assets/87374285/ee945d4f-94a2-4d88-afba-6d9417fbf320)  
### Задание 3.
Перечислите все таблицы учебной базы данных dvd-rental и столбцы, которые имеют ограничения первичных ключей для этих таблиц.  
|Название таблицы    |Ключ                  |
|:--------------------|:----------------------:|
actor               |actor _id
|address             |address_id            |
|category            |category_id           |  
|city                |city_id               |  
|country             |country_id            |  
|customer            |customer_id           |  
|film                |film_id               |  
|film_actor          |film_actor_id         |  
|film_category       |film_category_id      |  
|inventory           |inventory_id          |  
|language            |language_id           |  
|payment             |payment_id            |  
|rental              |rental_id             |  
|staff               |staff_id              |  
|store               |store_id              |  

### Задание 4.  
Выполните SQL-запрос к учебной базе данных dvd-rental “SELECT * FROM country;”. Сделайте скриншот результата.  
![Screenshot 2023-07-28 185152](https://github.com/iv-art074/data_engineer/assets/87374285/c20f7e3d-8102-4dab-b024-15c3b18c7436)  

### Дополнительная часть

### Задание 2.  
С помощью SQL-запроса выведите в результат таблицу, содержащую названия таблиц и названия ограничений первичных ключей в этих таблицах.  
Для написания запроса используйте представление information_schema.table_constraints.  
![Screenshot 2023-07-28 191744](https://github.com/iv-art074/data_engineer/assets/87374285/f1bd7d8a-2f92-421c-bec1-b9a531a25bba)  

ссылка на скрипт:  
https://github.com/iv-art074/data_engineer/blob/main/homeworks/constrains.sql  
