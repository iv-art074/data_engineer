/*1.Выведите названия самолётов, которые имеют менее 50 посадочных мест.*/
--explain analyze    с подзапросом быстрее
select model 
    from (select aircraft_code,count(seat_no)
		from seats
		group by aircraft_code
		having count(seat_no) < 50) t
	join aircrafts using (aircraft_code)
	
	
/*2.Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.*/

select date_trunc('month', book_date) as "месяц",
	lag(sum(total_amount)) over (order by date_trunc('month', book_date)) as "пред месяц",
	sum(total_amount) as "сумма тек месяца",
	round((sum(total_amount)/lag(sum(total_amount)) over (order by date_trunc('month', book_date)))*100-100,2) as "изменение на %%"
from bookings 
group by 1
	
/*3.Выведите названия самолётов без бизнес-класса. Используйте в решении функцию array_agg*/

select model
from (
   	select aircraft_code, array_agg(fare_conditions)  
	from seats 
	group by aircraft_code) t
join aircrafts a on a.aircraft_code = t.aircraft_code and array_position(t.array_agg,'Business') is null

  
 
/*4.Выведите накопительный итог количества мест в самолётах по каждому аэропорту на каждый день.
 * Учтите только те самолеты, которые летали пустыми и только те дни, когда из одного аэропорта вылетело более одного такого самолёта.

Выведите в результат код аэропорта, дату вылета, количество пустых мест и накопительный итог.*/

--не смог обойтись без маленького подзапроса
 
select actual_departure::date "факт дата вылета", departure_airport "аэропорт вылета", count(f.flight_id)*t.seats_q "пустых мест за сутки", 
	   sum(count(f.flight_id)*seats_q) over (partition by actual_departure::date order by departure_airport) "накопительный итог"
from boarding_passes bp
    right join flights f on bp.flight_id=f.flight_id 
    join (select aircraft_code,count(seat_no) as seats_q from seats group by aircraft_code) t using (aircraft_code)  -- присоединяем кол-во мест
    where ticket_no is null and actual_departure is not null 							--отбираем по пустым билетам и факту вылета
    group by cast (actual_departure as date), departure_airport, seats_q
    having  count(f.flight_id) > 1                      							--больше 1 в сутки
order by cast (actual_departure as date), departure_airport 


/*вариант с группировкой по аэропорту за все дни

select departure_airport "аэропорт вылета", actual_departure::date "факт дата вылета", count(f.flight_id)*t.seats_q "пустых мест за сутки", 
	   sum(count(f.flight_id)*seats_q) over (partition by departure_airport order by actual_departure::date) "накопительный итог"
from boarding_passes bp
    right join flights f on bp.flight_id=f.flight_id 
    join (select aircraft_code,count(seat_no) as seats_q from seats group by aircraft_code) t using (aircraft_code)  -- присоединяем кол-во мест
    where ticket_no is null and actual_departure is not null 							--отбираем по пустым билетам и факту вылета
    group by departure_airport,cast (actual_departure as date),seats_q
    having  count(f.flight_id) > 1                      							--больше 1 в сутки
order by departure_airport,cast (actual_departure as date)
*/


/* 5.Найдите процентное соотношение перелётов по маршрутам от общего количества перелётов. 
 * 
 Выведите в результат названия аэропортов и процентное отношение.*/

select a.airport_name "аэропорт вылета", a1.airport_name "аэропорт прилета",
       count(flight_no) *100/ sum(count(flight_id)) over () "% отношение"
from flights f 
join airports a on f.departure_airport = a.airport_code
join airports a1 on f.arrival_airport = a1.airport_code
group by a.airport_name,a1.airport_name
order by 3 desc 



/* 6.Выведите количество пассажиров по каждому коду сотового оператора. Код оператора – это три символа после +7 */

select substring(contact_data->>'phone' from 3 for 3) as "код оператора",count(contact_data)as "кол-во пассажиров"
from tickets
group by 1

/* 7.Классифицируйте финансовые обороты (сумму стоимости билетов) по маршрутам:
до 50 млн – low
от 50 млн включительно до 150 млн – middle
от 150 млн включительно – high
Выведите в результат количество маршрутов в каждом полученном классе.*/


--непонятно что делать с маршрутами без билетов, не стал учитывать, для учета просто нужно убрать комментарии

select class_id "класс",count(fn) "кол-во маршрутов"
from (
     select flight_no as fn,  
			case 
   	            when sum(amount)<50000000 /*or sum(amount) is NULL*/ then 'low'
   	            when sum(amount)>=150000000 then 'high'
   	            else 'middle'
            end as class_id 
     from flights f 
     /*left*/ join ticket_flights tf using(flight_id)
     group by flight_no) t
group by class_id


/*8.Вычислите медиану стоимости билетов, медиану стоимости бронирования и отношение медианы бронирования
 * 
  к медиане стоимости билетов, результат округлите до сотых. */

select percentile_cont(0.5) WITHIN GROUP (ORDER BY t.total_amount) as "стоимость бронирования",
       percentile_cont(0.5) WITHIN GROUP (ORDER BY t.amount) as "стоимость билетов",
       round(percentile_cont(0.5) WITHIN GROUP (ORDER BY t.total_amount)::numeric/percentile_cont(0.5) WITHIN GROUP (ORDER BY t.amount)::numeric,2) as "отношение /"
from (select total_amount,NULL as amount from bookings 
      union all 
      select NULL as total_amount, amount from ticket_flights order by total_amount,amount) t

      
/* 9. Найдите значение минимальной стоимости одного километра полёта для пассажира.
 Для этого определите расстояние между аэропортами и учтите стоимость билетов.*/

--explain analyze --832974/23.237
with cte as (
select airport_code,latitude,longitude
from airports a)
	select min(amount/earth_distance(ll_to_earth(c.latitude,c.longitude),ll_to_earth(c1.latitude,c1.longitude))*1000)  
	from flights f
	join cte c on f.departure_airport =c.airport_code
	join cte c1 on f.arrival_airport =c1.airport_code
	join ticket_flights using (flight_id)

	
/*explain analyze   --973701/24.613
with cte as (
select airport_code,latitude,longitude
from airports a)
select min(t.amount/t.kilo)
from (
	select distinct earth_distance(ll_to_earth(c.latitude,c.longitude),ll_to_earth(c1.latitude,c1.longitude))/1000 AS kilo, amount 
	from flights f
	join cte c on f.departure_airport =c.airport_code
	join cte c1 on f.arrival_airport =c1.airport_code
	join ticket_flights using (flight_id)) t*/


