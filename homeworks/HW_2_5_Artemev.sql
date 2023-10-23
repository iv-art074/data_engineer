--Задание 1. Создайте подключение к удаленному облачному серверу базы HR (база данных postgres, схема hr),
--используя модуль postgres_fdw.
--Напишите SQL-запрос на выборку любых данных используя 2 сторонних таблицы, соединенных с помощью JOIN.


--новая схема для облачного подключения

CREATE SCHEMA ext_hw;

set search_path to ext_hw;

--select * from pg_catalog.pg_available_extensions where installed_version is not null

create extension postgres_fdw

--создаем сервер
create server netology_cloud
foreign data wrapper postgres_fdw
options(host '51.250.106.132', port '19001', dbname 'postgres');

--маппинг
create user mapping for postgres 
server netology_cloud options (user 'netology', password 'NetoSQL2019');

--таблица1 для работы с облаком
create foreign table employee_l (
emp_id int4,
emp_type_id int4,
person_id int4,
pos_id int4,
rate numeric(12,2),
hire_date date)
SERVER netology_cloud
OPTIONS (schema_name 'hr', table_name 'employee');

select * from employee_l

--таблица2 для работы с облаком
create foreign table employee_salary_l (
order_id int4,
emp_id int4,
salary numeric(12,2),
effective_from date)
SERVER netology_cloud
OPTIONS (schema_name 'hr', table_name 'employee_salary');

--запрос из объединенных таблиц
select * from employee_l join employee_salary_l using(emp_id) where emp_id = 2



--Задание 2. С помощью модуля tablefunc получите из таблицы projects базы HR таблицу с данными,
--колонками которой будут: год, месяцы с января по декабрь,
--общий итог по стоимости всех проектов за год.

set search_path to hr;
 
create extension tablefunc;

select * from crosstab ($$ 
select p_year::text, coalesce(p_m::text, 'Итого'), p_sum 
from(
	select coalesce(t1.p_y, p_year) as p_year, t1.p_m, coalesce(t.sum,0) as p_sum
	from(
		select date_part('years', created_at) as p_year ,date_part('month', created_at) as p_month,	sum(amount) as sum
		from projects
		group by cube(1,2)
		order by 1,3)t   					--основной запрос
	full join
	(select p_y , p_m  from generate_series(2018,2020,1) p_y, generate_series(1,12,1) p_m order by 1,2) t1 
	on t.p_year=t1.p_y and  t.p_month::int =t1.p_m
	where coalesce(t1.p_y, p_year) is not null   --дополняем месяцами
order by 1,2)gen_pm
$$,
$$
(select p_month::text from (
	select distinct (date_part('month',date_trunc('month', created_at))) as p_month 
	from projects order by 1)m_list									--структура столбцов     
 union all
 select 'Итого')
$$) as cst("Год" text,"Январь" numeric,"Февраль" numeric,"Март" numeric,"Апрель" numeric,"Май" numeric,"Июнь" numeric,
"Июль" numeric,"Август" numeric,"Сентябрь" numeric,"Октябрь" numeric,"Ноябрь" numeric,"Декабрь" numeric,"Итого" numeric);

--
create extension pg_stat_statements

select * from pg_stat_statements