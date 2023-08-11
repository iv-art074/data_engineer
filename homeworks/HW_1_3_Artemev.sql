--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

SELECT cu.customer_id,(cu.first_name::text || ' '::text) || cu.last_name::text as "name",
    a.address,city,country
FROM customer cu
     JOIN address a ON cu.address_id = a.address_id
     JOIN city ON a.city_id = city.city_id
     JOIN country ON city.country_id = country.country_id;

--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.
select store_id,count(*)
from store s 
join customer using (store_id)
group by store_id;


--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.
select store_id,count(*)
from store s 
join customer using (store_id)
group by store_id
having count(*)>300


-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select s.store_id,city,st.last_name,st.first_name,count(*)
from store s 
join customer using (store_id)
join address a on s.address_id = a.address_id
join city using (city_id)
join staff st on s.manager_staff_id = st.staff_id
group by s.store_id,city,st.last_name,st.first_name
having count(*)>300



--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов
select last_name||' '||first_name as "Фамилия имя покупателя", count (*) as "количество фильмов"
from rental r 
join customer c using (customer_id)
group by r.customer_id,last_name,first_name
order by count(*) desc limit 5




--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма

select r.customer_id,last_name||' '||first_name as "Фамилия имя покупателя", count (r.rental_id) as "Количество фильмов",round(sum(amount))"Общая стоимость платежей",min(amount) "Минимальный платеж",max(amount) "Максимальный платеж"
from rental r 
join customer c on r.customer_id=c.customer_id
join payment p on r.rental_id=p.rental_id
group by r.customer_id,last_name,first_name




--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
select c.city "Город 1",c1.city "Город 2"
from city c , city c1
where c.city>c1.city
order by 1




--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.

select c.customer_id,round(AVG(return_date::date - rental_date::date),2) as "Среднее кол-во дней на возврат"
from rental r 
join customer c on r.customer_id=c.customer_id
group by c.customer_id--,return_date,rental_date 
order by 1 



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select title "Название фильма",rating "Рейтинг",cat.name "Жанр",release_year "Год выпуска",l.name "Язык",count (rental_id) "Количество аренд",sum(amount) "Общая стоимость аренды"
from film f 
join inventory i using (film_id)
join rental r  using (inventory_id)
join film_category fc using (film_id)
join category cat using (category_id)
join "language" l using (language_id)
join payment p using (rental_id)
group by film_id,cat.name,l.name
order by 1





--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.

select f.title "Название фильма",rating "Рейтинг",cat.name "Жанр",release_year "Год выпуска",l.name "Язык",count (rental_id) "Количество аренд",sum(amount) "Общая стоимость аренды"
from film f 
full join inventory i using (film_id)
left join rental r  using (inventory_id)
join film_category fc using (film_id)
join category cat using (category_id)
join "language" l using (language_id)
left join payment p using (rental_id)
group by f.title,f.rating,f.release_year,cat.name,l.name
having count(rental_id)=0
order by 1



--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select staff_id,count(*) "Количество продаж",
case
		when count(*) > 7300 then 'Да'
		when count(*) <=7300 then 'Нет'
end as "Премия"
from staff s 
join payment p using (staff_id)
group by staff_id





