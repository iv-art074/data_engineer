/*  1.1. Создайте новую базу данных с любым названием
C:\Program Files\PostgreSQL\14\bin>createdb -h localhost -p 5432 -U postgres new_db

1.2. Восстановите бэкап учебной базы данных в новую базу данных с помощью psql
C:\Program Files\PostgreSQL\14\bin>psql -h localhost -p 5432 -U postgres -d new_db < "c:\temp\hr.sql"
*/


-- 2.1. Создайте нового пользователя MyUser, которому разрешен вход, но не задан пароль и права доступа.
create role MyUser LOGIN;

-- 2.2. Задайте пользователю MyUser любой пароль сроком действия до последнего дня текущего месяца.

alter role myuser WITH password '123' valid until '31.10.2023';

-- 2.3. Дайте пользователю MyUser права на чтение данных из двух любых таблиц восстановленной базы данных.

grant select on table hr.city,hr.hours to myuser; 

-- 2.4. Заберите право на чтение данных ранее выданных таблиц

revoke all on all tables in schema hr from myuser;

-- 2.5. Удалите пользователя MyUser.

drop role myuser;

-- 3.1. Начните транзакцию

begin;

-- 3.2. Добавьте в таблицу projects новую запись

insert into projects (project_id,name,amount) values (129,'trial',100);

-- 3.3. Создайте точку сохранения
savepoint sp1;

-- 3.4. Удалите строку, добавленную в п.3.2
delete from projects where project_id = 129;

-- 3.5. Откатитесь к точке сохранения
rollback to sp1;

-- 3.6. Завершите транзакцию.
commit;


select * from pg_catalog.pg_roles 



