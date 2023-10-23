--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа

SELECT *,
ROW_NUMBER() OVER (order by payment_date)
FROM payment p

--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа

SELECT *,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date)
FROM payment 

--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей

select customer_id, payment_date, amount, sum(amount) over (partition by customer_id order by payment_date,amount)
from payment

--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

SELECT *,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY amount DESC)
FROM payment 


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.

select customer_id,payment_date,  
	lag(amount,1,0.0) over (partition by customer_id order by payment_date),
	amount
from payment

--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
select customer_id, payment_date, rental_id,
	amount as "текущий",
	lead(amount) over (partition by customer_id order by payment_date) as "следующий",
	lead(amount) over (partition by customer_id order by payment_date)-amount as "разница"
from payment 

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

--old version
/*select p.customer_id,p.payment_id,p.payment_date,amount  
from (select *, first_value(rental_id) over (partition by customer_id order by rental_date desc)
	from rental) t 
join payment p using(rental_id)
where rental_id = first_value
order by t.customer_id, t.rental_date*/

select customer_id,payment_id,payment_date,amount  
from (select *, first_value(payment_id) over (partition by customer_id order by payment_date desc)
	from payment) t 
where payment_id = first_value



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.


SELECT staff_id,payment_date::date,sum(amount) as sum_amount,
sum(sum(amount)) OVER (PARTITION BY staff_id ORDER BY payment_date::date)
FROM payment p
where date_trunc('month',payment_date) = '2005-08-01'
group by p.staff_id,p.payment_date::date


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

select customer_id,first_name, last_name,payment_date,row_number
from (select customer_id,payment_date,row_number () over (order by payment_date)
from payment p
where payment_date::date = '2005-08-20') t
join customer c using (customer_id)
where mod(row_number,100) = 0



--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

select distinct cn.country, 
	first_value(concat(c.last_name, ' ', c.first_name)) over (partition by cn.country_id order by count(i.film_id) desc) as "покупатель, арендовавший наибольшее количество фильмов", 
	first_value(concat(c.last_name, ' ', c.first_name)) over (partition by cn.country_id order by sum(p.amount) desc)as "покупатель, арендовавший фильмов на самую большую сумму", 
	first_value(concat(c.last_name, ' ', c.first_name)) over (partition by cn.country_id order by max(r.rental_date) desc) as "покупатель, который последним арендовал фильм"
from country cn
left join city c2 using(country_id) 
left join address a using(city_id)
left join customer c using(address_id)	
left join rental r using(customer_id)
left join inventory i using(inventory_id)
left join payment p using(rental_id)
group by cn.country_id, c.customer_id




