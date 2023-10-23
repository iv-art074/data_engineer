set search_path to public

--Задание 1. 
--Выполните горизонтальное партиционирование для таблицы inventory учебной базы dvd-rental:
--	- создайте 2 партиции по значению store_id
--	- создайте индексы для каждой партиции
--	- заполните партиции данными из родительской таблицы
--	- для каждой партиции создайте правила на внесение, обновление, удаление данных. 
--Напишите команды SQL для проверки работы правил.


--таблицы
create table inventory_1 (check (store_id =1))inherits (inventory);

create table inventory_2 (check (store_id =2))inherits (inventory);

--индексы

create index inventory_1_idx ON inventory_1 (CAST(store_id as int4));

create index inventory_2_idx ON inventory_2 (CAST(store_id as int4));


--alter table rental drop constraint rental_inventory_id_fkey;

--правила insert

CREATE RULE inventory_insert_1 AS ON INSERT TO inventory WHERE (store_id = 1)DO INSTEAD INSERT INTO inventory_1 VALUES (new.*);
CREATE RULE inventory_insert_2 AS ON INSERT TO inventory WHERE (store_id = 2)DO INSTEAD INSERT INTO inventory_2 VALUES (new.*);

--переносим данные

WITH cte AS ( 
	DELETE FROM ONLY inventory 
	WHERE store_id=1 RETURNING *)
INSERT INTO inventory_1 
SELECT * FROM cte;

WITH cte AS ( 
	DELETE FROM ONLY inventory 
	WHERE store_id=2 RETURNING *)
INSERT INTO inventory_2 
SELECT * FROM cte;



--правила update 

CREATE RULE inventory_update_1 AS ON UPDATE TO inventory 
WHERE (old.store_id = 1 AND new.store_id != 1)
DO INSTEAD (INSERT INTO inventory VALUES (new.*); DELETE FROM inventory_1 WHERE inventory_id = new.inventory_id);

CREATE RULE inventory_update_2 AS ON UPDATE TO inventory 
WHERE (old.store_id = 2 AND new.store_id != 2)
DO INSTEAD (INSERT INTO inventory VALUES (new.*); DELETE FROM inventory_2 WHERE inventory_id = new.inventory_id);

-- проверки

insert into inventory(film_id,store_id,last_update)values(87, 1, now());
 
insert into inventory(film_id,store_id,last_update)values(88, 2, now());

update inventory set store_id = 1 where inventory_id = 1000;

select * from inventory_2 i

select * from inventory i

select * from inventory where inventory_id = 1000; 

select * from inventory_2 where film_id = 88


/*Задание 2. Создайте новую базу данных и в ней 2 таблицы для хранения данных по инвентаризации каждого магазина,
 *  которые будут наследоваться из таблицы inventory базы dvd-rental.
 *  Используя шардирование и модуль postgres_fdw создайте подключение к новой базе данных и необходимые
 *  внешние таблицы в родительской базе данных для наследования. Распределите данные по внешним таблицам.
 *  Напишите SQL-запросы для проверки работы внешних таблиц.*/

--база
create database db_lesson6 owner ='postgres';

--оболочка
create extension postgres_fdw;

/*  таблицы в новой базе
CREATE TABLE public.inventory1 (
	inventory_id serial4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT null check (store_id = 1),
	last_update timestamp NOT NULL DEFAULT now());
	
CREATE TABLE public.inventory2 (
	inventory_id serial4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT null check (store_id = 2),
	last_update timestamp NOT NULL DEFAULT now());
 */ 

--сервер

create server server_inventory
foreign data wrapper postgres_fdw
options(host 'localhost', port '5432', dbname 'db_lesson6');

--юзер
create user mapping for postgres 
server server_inventory options (user 'postgres', password 'suckers1');


--таблицы внешние
create foreign table inventory1_in (
	inventory_id serial4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT null check (store_id = 1),
	last_update timestamp NOT NULL DEFAULT now())
	inherits (inventory)
server server_inventory
options (schema_name 'public', table_name 'inventory1');
	
create foreign table inventory2_in (
	inventory_id serial4 NOT NULL,
	film_id int2 NOT NULL,
	store_id int2 NOT null check (store_id = 2),
	last_update timestamp NOT NULL DEFAULT now())
	inherits (inventory)
server server_inventory
options (schema_name 'public', table_name 'inventory2');

 

--триггер вставки

create or replace function inventory_insert() returns trigger as $$
begin
	if  new.store_id = 1 then    
		insert into in_inventory1_in values (new.*);
	elsif new.store_id = 2 then  
		insert into in_inventory2_in values (new.*);
	else raise exception 'шард отсутствует';
	end if;
	return null;
end; $$ language plpgsql;

create trigger inventory_insert    
before insert on inventory
for each row execute function inventory_insert();

-- удаляем ограничения внешнего ключа rental_inventory_id_fkey из rental
alter table rental drop constraint rental_inventory_id_fkey;

--переносим данные 
with cte as (  
    delete from only inventory      
    where store_id =1  returning *)
insert into inventory1_in   
    select * from cte;

with cte as (  
    delete from only inventory      
    where store_id =2  returning *)
insert into inventory2_in   
    select * from cte;   
   
   
select * from inventory1_in;
select * from only inventory;
select * from inventory2_in;
