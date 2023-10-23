--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

--вариант полный
select f.title,f.description,f.release_year,l.name,a.first_name||' '||a.last_name as actors,rental_duration,rental_rate,f.length,rating,special_features,fulltext
from film f
join film_actor fa using (film_id)
join language l using (language_id)
join actor a on fa.actor_id = a.actor_id
where f.special_features && array['Behind the Scenes']

--вариант простой 
select film_id,title,special_features
from film 
where special_features && array['Behind the Scenes']

--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

select film_id,title,special_features
from film 
where 'Behind the Scenes' = some(special_features)

select film_id,title,special_features
from film 
where special_features @> array['Behind the Scenes']


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.
with cte as (
        select film_id,title,special_features
        from film 
        where special_features @> array['Behind the Scenes'])
select customer_id,count(rental_id)
from cte
join inventory using (film_id) 
join rental using (inventory_id)
group by customer_id
order by customer_id


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

select customer_id,count(rental_id)
from (select film_id,title,special_features
        from film 
        where special_features @> array['Behind the Scenes']) t
join inventory using (film_id) 
join rental using (inventory_id)
group by customer_id
order by customer_id




--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view v1 as
	select customer_id,count(rental_id)
	from (select film_id,title,special_features
        from film 
        where special_features @> array['Behind the Scenes']) t
	join inventory using (film_id) 
	join rental using (inventory_id)
	group by customer_id
	order by customer_id
--with no data

select * from v1

refresh materialized view v1


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;

explain analyze  --67.5/0.768
select film_id,title,special_features
from film 
where special_features && array['Behind the Scenes']


explain analyze --77.5/0.635
select film_id,title,special_features
from film 
where 'Behind the Scenes' = some(special_features)

explain analyze  --67.5/0.753
select film_id,title,special_features
from film 
where special_features @> array['Behind the Scenes']

--Быстрее отрабатывают операторы && и @> (имеют практически одинаковое время). Функция some требует
-- больше ресурсов из-за бОльших затрат на последовательное сканирование


--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.

explain analyze   --675/20.709
with cte as (
        select film_id,title,special_features
        from film 
        where special_features @> array['Behind the Scenes'])
select customer_id,count(rental_id)
from cte
join inventory using (film_id) 
join rental using (inventory_id)
group by customer_id
order by customer_id


explain analyze   --675/22.883
select customer_id,count(rental_id)
from (select film_id,title,special_features
        from film 
        where special_features @> array['Behind the Scenes']) t
join inventory using (film_id) 
join rental using (inventory_id)
group by customer_id
order by customer_id


--  Быстрее выполняется скрипт с CTE, поскольку это уже просчитанный временный результат выполнения SQL-выражения, который можно использовать



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

--Сделайте explain analyze этого запроса.
--Основываясь на описании запроса, найдите узкие места и опишите их.

explain analyze
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

--1)значительное время тратится на этапе ProjectSet который отражает работу ф-ции unnest
--2)имеются ненужные переопределения алиасов

--мой запрос
explain analyze   --675/22.9
select customer_id,count(rental_id)
from (select film_id,title,special_features
        from film 
        where special_features @> array['Behind the Scenes']) t
join inventory using (film_id) 
join rental using (inventory_id)
group by customer_id
order by customer_id

--мой запрос выполняется быстрее, поиск в массиве производится через оператор @>, алиасов минимум. вывод ФИО не производится
--можно еще оптимизировать по образцу из лекции, совместив join c поиском в подзапросе и использовав right join
explain analyze --652.73 / 7.5
select c.first_name  || ' ' || c.last_name as name, count(i.film_id)
from rental r 
right join inventory i on i.inventory_id = r.inventory_id and 
	i.film_id in (
		select film_id
		from film 
		where special_features && array['Behind the Scenes'])
join customer c on c.customer_id = r.customer_id
group by c.customer_id
order by 2 desc

-- построчное описание explain analyze находится в приложенном xls-файле


--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

select p.staff_id, f.film_id, f.title, p.amount, p.payment_date, c.last_name, c.first_name
from (
	select *, first_value(payment_date) over (partition by staff_id order by payment_date)
	from payment) p 
join customer c using (customer_id)
join rental r using (rental_id)
join inventory i using(inventory_id)
join film f using (film_id)
where payment_date = first_value


--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день

select x.store_id, x.rental_date, x.count, y.payment_date, y.sum
from (
	select i.store_id, r.rental_date::date, count(*), max(count(*)) over (partition by i.store_id)
	from rental r 
	join inventory i using (inventory_id)
	group by i.store_id, r.rental_date::date) x
join (
	select i.store_id, p.payment_date::date, sum(p.amount), min(sum(p.amount)) over (partition by i.store_id)
	from payment p 
	join rental r using (rental_id)
	join inventory i using (inventory_id)
	group by i.store_id, p.payment_date::date) y on x.store_id = y.store_id
where x.max = x.count and y.sum = y.min


