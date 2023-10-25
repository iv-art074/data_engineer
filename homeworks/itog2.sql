
1. Используя сервис https://supabase.com/ нужно поднять облачную базу данных PostgreSQL.

2. Для доступа к данным в базе данных должен быть создан пользователь 
логин: netocourier
пароль: NetoSQL2022
права: полный доступ на схему public, к information_schema и pg_catalog права только на чтение, предусмотреть доступ к иным схемам, если они нужны. 


--права

CREATE ROLE netocourier WITH LOGIN PASSWORD 'NetoSQL2022'

revoke all on all tables in schema public from netocourier

select * from account a 

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public to netocourier

GRANT USAGE ON SCHEMA public TO netocourier;

GRANT USAGE ON SCHEMA information_schema TO netocourier;
GRANT USAGE ON SCHEMA pg_catalog TO netocourier;

grant select on all tables in schema information_schema to netocourier

grant select on all tables in schema pg_catalog to netocourier  


-- таблицы
drop table contact

drop table "user"

drop table account 

drop table courier 


account: --список контрагентов
id uuid PK
name varchar --название контрагента

CREATE TABLE account (
	id uuid PRIMARY key default uuid_generate_v4(), 
	name varchar (50) not null);


contact: --список контактов контрагентов
id uuid PK
last_name varchar --фамилия контакта
first_name varchar --имя контакта
account_id uuid FK --id контрагента



CREATE TABLE contact (
	id uuid PRIMARY key default uuid_generate_v4(),
	last_name varchar (50) not null,
	first_name varchar (50) not null,
	--account_id uuid not null references account (id));
    account_id uuid not null,
    foreign key (account_id) references account (id));
	
--user: --сотрудники
id uuid PK
last_name varchar --фамилия сотрудника
first_name varchar --имя сотрудника
dismissed boolean --уволен или нет, значение по умолчанию "нет"


   
CREATE TABLE "user" (
	id uuid PRIMARY key default uuid_generate_v4(),
	last_name varchar(50) NOT NULL,
	first_name varchar(50) NOT NULL,
	dismissed boolean default false not null);


create  type statuses as enum ('В очереди', 'Выполняется', 'Выполнено', 'Отменен');

courier: --данные по заявкам на курьера
id uuid PK
from_place varchar --откуда
where_place varchar --куда
name varchar --название документа
account_id uuid FK --id контрагента
contact_id uuid FK --id контакта 
description text --описание
user_id uuid FK --id сотрудника отправителя
status enum -- статусы 'В очереди', 'Выполняется', 'Выполнено', 'Отменен'. По умолчанию 'В очереди'
created_date date --дата создания заявки, значение по умолчанию now()


create table courier (
  id uuid primary key default uuid_generate_v4(),
  from_place varchar (100) not null,
  where_place varchar (100) not null,
  name varchar (40) not null,
  account_id uuid not null ,
  contact_id uuid not null ,
  description text,
  user_id uuid not null ,
  status statuses not null default 'В очереди',
  created_date date not null default now(),
  foreign key (account_id) references account (id),
  foreign key (contact_id) references contact (id),
  foreign key (user_id) references "user" (id));
	
##################################

SELECT repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*32+1)::integer),(random()*5+1)::integer);

select repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,(ceiling((random()*33))::int2)), ceiling((random()*10))::integer);


select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1, ((random()*32)+1)::int2),
	           ((random()*10)+1)::int2), 1, 50);

select ceiling((random()*33)) --::int2

select (random()*32+1)::int2

select (/*now() - interval '1 day' * */round(random() * 1000))  --::date

SELECT floor(random()*(33))+1;


-- от 1 до 33
select (random()*32+1)::int2

select length(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1, ((random()*32)+1)::int2),
	           (random()+1)::int2))

################ insert_test_data() #################

6. Для возможности тестирования приложения необходимо реализовать процедуру insert_test_data(value), которая принимает на вход целочисленное значение.
Данная процедура должна внести:
value * 1 строк случайных данных в отношение account.
value * 2 строк случайных данных в отношение contact.
value * 1 строк случайных данных в отношение user.
value * 5 строк случайных данных в отношение courier.
- Генерация id должна быть через uuid-ossp
- Генерация символьных полей через конструкцию SELECT repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя',1,(random()*33)::integer),(random()*10)::integer);
Соблюдайте длину типа varchar. Первый random получает случайный набор символов из строки, второй random дублирует количество символов полученных в substring.
- Генерация булева типа происходит через 0 и 1 с использованием оператора random.
- Генерацию даты и времени можно сформировать через select now() - interval '1 day' * round(random() * 1000) as timestamp;
- Генерацию статусов можно реализовать через enum_range()


create or replace procedure insert_test_data (int4) as $$
declare i int2;
     id_account uuid;
     id_contact uuid;
     id_us uuid;
     status1 statuses;
   begin 
--таблица account	
	i = 0;
	for i in 1..$1 
	loop
		insert into account (name)
		select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1, ((random()*32)+1)::int2),
	           (random()+1)::int2), 1, 50);    --подстрока 33*2 обрезаем до 50 
	end loop;
--таблица contact	
	i = 0;
    for  i in 1..2*$1 
    loop 
	 insert into contact (last_name, first_name, account_id)
	    select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
	                    ((random()*32)+1)::int2), (random()+1)::int2), 1, 50),			--33*2
		       substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		                ((random()*32)+1)::int2), (random()+1)::int2), 1, 50),			--33*2
		       id from account order by random() limit 1;
	end loop;
--таблица user	
    i = 0;
	for i in 1..$1 
	loop
	   insert into "user" (last_name, first_name, dismissed)
	   select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
	                   ((random()*32)+1)::int2), (random()+1)::int2), 1, 50) ,			--33*2
		      substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		               ((random()*32)+1)::int2), (random()+1)::int2), 1, 50) ,          --33*2
		      random()::int4::boolean;
	end loop;
--таблица courier	
    i = 0;
	for i in 1..5*$1 
	loop
	    id_account = (select id from account order by random() limit 1);
    	id_contact = (select id from contact order by random() limit 1 );
    	id_us = ( select id from "user" order by random() limit 1 );
    	status1 = (select status from unnest(enum_range(null::statuses)) as status order by random() limit 1);
	    insert into courier (from_place, where_place, name, account_id,contact_id, description, user_id, status, created_date)
	    select substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		                ((random()*32)+1)::int2), ((random()*2)+1)::int2), 1, 100) ,   --33*3
		       substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		                ((random()*32)+1)::int2), ((random()*2)+1)::int2), 1,100) ,		--33*3
		       substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		                ((random()*32)+1)::int2), (random()+1)::int2), 1, 40),         --33*2
		       id_account,id_contact,
		       substring(repeat(substring('абвгдеёжзийклмнопрстуфхцчшщьыъэюя', 1,
		                ((random()*32)+1)::int2), ((random()*2)+1)::int2), 1, 100),		--33*3
		       id_us,status1,
		       (now() - interval '1 day' * round(random() * 30))::date;
	end loop;
  end;
	
$$ language plpgsql


7. Необходимо реализовать процедуру erase_test_data(), которая будет удалять тестовые данные из отношений.

################## erase_test_data() ###############


create or replace procedure erase_test_data() as $$
begin 
	truncate account, contact, "user",courier;
--	delete from account ;
--    delete from contact ;
--	delete from courier ;
--	delete from "user";
end;

$$ language plpgsql

################################

call insert_test_data(1)

call erase_test_data() 

select * from account 

select * from contact 

select * from "user"

select * from courier


8. На бэкенде реализована функция по добавлению новой записи о заявке на курьера:
function add($params) --добавление новой заявки
    {
        $pdo = Di::pdo();
        $from = $params["from"]; 
        $where = $params["where"]; 
        $name = $params["name"]; 
        $account_id = $params["account_id"]; 
        $contact_id = $params["contact_id"]; 
        $description = $params["description"]; 
        $user_id = $params["user_id"]; 
        $stmt = $pdo->prepare('CALL add_courier (?, ?, ?, ?, ?, ?, ?)');
        $stmt->bindParam(1, $from); --from_place
        $stmt->bindParam(2, $where); --where_place
        $stmt->bindParam(3, $name); --name
        $stmt->bindParam(4, $account_id); --account_id
        $stmt->bindParam(5, $contact_id); --contact_id
        $stmt->bindParam(6, $description); --description
        $stmt->bindParam(7, $user_id); --user_id
        $stmt->execute();
    }
Нужно реализовать процедуру add_courier(from_place, where_place, name, account_id, contact_id, description, user_id), 
которая принимает на вход вышеуказанные аргументы и вносит данные в таблицу courier
Важно! Последовательность значений должна быть строго соблюдена, иначе приложение работать не будет.

################ add_courier() ################

 create or replace procedure  add_courier(varchar(100), varchar(100), varchar(40),uuid, uuid, text, uuid) as $$
begin 
	insert into  courier (from_place, where_place, name, account_id, contact_id, description, user_id)
		values ($1, $2, $3, $4, $5, $6, $7);
end;

$$ language plpgsql


9. На бэкенде реализована функция по получению записей о заявках на курьера: 
static function get() --получение списка заявок
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_courier()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        return $data;
    }
Нужно реализовать функцию get_courier(), которая возвращает таблицу согласно следующей структуры:
id --идентификатор заявки
from_place --откуда
where_place --куда
name --название документа
account_id --идентификатор контрагента
account --название контрагента
contact_id --идентификатор контакта
contact --фамилия и имя контакта через пробел
description --описание
user_id --идентификатор сотрудника
user --фамилия и имя сотрудника через пробел
status --статус заявки
created_date --дата создания заявки
Сортировка результата должна быть сперва по статусу, затем по дате от большего к меньшему.


################  get_courier()  ################

 create or replace function get_courier() returns table ( id uuid, from_place varchar(100),
 where_place varchar(100), name varchar(40), account_id uuid, account varchar(150), 
 contact_id uuid, contact varchar(120), description text, user_id uuid, "user" varchar(120), 
 status statuses, created_date date) as $$
 begin 
 	return query 
 	select c.id , c.from_place ,c.where_place, c.name , c.account_id , a.name , c.contact_id ,
  (co.last_name ||' '|| co.first_name):: varchar(120) as contact , c.description , c.user_id,
 	(u.last_name ||' '|| u.first_name):: varchar(120)  as user, c.status, c.created_date  
 	from courier c
 	join account a on a.id = c.account_id   
 	join contact co on co.id = c.contact_id 
 	join "user" u on u.id = c.user_id 
 	order by c.status, c.created_date desc;
 end;
  
 $$ language plpgsql
 
 select * from get_courier()
 
 
 
 10. На бэкенде реализована функция по изменению статуса заявки.
function change_status($params) --изменение статуса заявки
    {
        $pdo = Di::pdo();
        $status = $params["new_status"];
        $id = $params["id"];
        $stmt = $pdo->prepare('CALL change_status(?, ?)');
        $stmt->bindParam(1, $status); --новый статус
        $stmt->bindParam(2, $id); --идентификатор заявки
        $stmt->execute();
    }
Нужно реализовать процедуру change_status(status, id), которая будет изменять статус заявки. На вход процедура принимает новое значение статуса и значение идентификатора заявки.



 ############## change_status() ###########################
 
 create or replace procedure change_status( statuses,  uuid ) as $$ 
 begin 
 	update courier set status = $1 where id= $2;
 end;
 $$ language plpgsql
 
 call change_status('Отменен','7d31af40-fe16-463c-b00d-8c6b556d5fef')
 
 
 11. На бэкенде реализована функция получения списка сотрудников компании.
static function get_users() --получение списка пользователей
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_users()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['user'];
        }
        return $result;
    }
Нужно реализовать функцию get_users(), которая возвращает таблицу согласно следующей структуры:
user --фамилия и имя сотрудника через пробел 
Сотрудник должен быть действующим! Сортировка должна быть по фамилии сотрудника.

 
 ###############  get_users() #######################
 
 create or replace function get_users() returns table (users varchar(101)) as $$
 begin
 	  return query
 	  select (last_name||' '||first_name)::varchar as users from "user" where dismissed is not null order by 1;
 end;
 $$ language PLPGSQL
 
 
 12. На бэкенде реализована функция получения списка контрагентов.
static function get_accounts() --получение списка контрагентов
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM get_accounts()');
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['account'];
        }
        return $result;
    }
Нужно реализовать функцию get_accounts(), которая возвращает таблицу согласно следующей структуры:
account --название контрагента 
Сортировка должна быть по названию контрагента.


 
 ##################### get_accounts() ###################
 
     create or replace function get_accounts() returns table ( acc_name varchar (50)) as $$ 
begin 
	return query 
	select name as acc_name from account order by name;
end;
$$ language PLPGSQL


13. На бэкенде реализована функция получения списка контактов.
function get_contacts($params) --получение списка контактов
    {
        $pdo = Di::pdo();
        $account_id = $params["account_id"]; 
        $stmt = $pdo->prepare('SELECT * FROM get_contacts(?)');
        $stmt->bindParam(1, $account_id); --идентификатор контрагента
        $stmt->execute();
        $data = $stmt->fetchAll();
        $result = [];
        foreach ($data as $v) {
            $result[] = $v['contact'];
        }
        return $result;
    }
Нужно реализовать функцию get_contacts(account_id), которая принимает на вход идентификатор контрагента и возвращает таблицу с контактами переданного контрагента согласно следующей структуры:
contact --фамилия и имя контакта через пробел 
Сортировка должна быть по фамилии контакта. Если в функцию вместо идентификатора контрагента передан null, нужно вернуть строку 'Выберите контрагента'.


#################### get_contacts() ###################

create or replace function get_contacts(uuid default null) returns table (contacts varchar(101)) as $$ 
begin 
	if $1 is not null 
	then 
		return query 
			select (c.last_name ||' '|| c.first_name) :: varchar (101) as contacts from contact c
			where account_id = $1 order by c.last_name;
	else
		return query
 		select 'Выберите контрагента'::varchar; 
	end if;
end;
$$ language PLPGSQL


14. На бэкенде реализована функция по получению статистики о заявках на курьера: 
static function get_stat() --получение статистики
    {
        $pdo = Di::pdo();
        $stmt = $pdo->prepare('SELECT * FROM courier_statistic');
        $stmt->execute();
        $data = $stmt->fetchAll();
        return $data;
    }
Нужно реализовать представление courier_statistic, со следующей структурой:
account_id --идентификатор контрагента
account --название контрагента
count_courier --количество заказов на курьера для каждого контрагента
count_complete --количество завершенных заказов для каждого контрагента
count_canceled --количество отмененных заказов для каждого контрагента
percent_relative_prev_month -- процентное изменение количества заказов текущего месяца к предыдущему месяцу для каждого контрагента, если получаете деление на 0, то в результат вывести 0.
count_where_place --количество мест доставки для каждого контрагента
count_contact --количество контактов по контрагенту, которым доставляются документы
cansel_user_array --массив с идентификаторами сотрудников, по которым были заказы со статусом "Отменен" для каждого контрагента


################# courier_statistic #################

create or replace view courier_statistic as 
with cte as (select * from courier c) 
select a.id, a."name", coalesce(count_courier,0) as count_courier,
  		coalesce(count_complete,0) as count_complete,
  		coalesce(count_canceled,0) as count_canceled,
  case 
  	when coalesce(previous_month,0) = 0
  		then 0
  	else (coalesce(current_month, 0)-previous_month)/current_month*100
    end percent_relative_prev_month,
    	coalesce(count_where_place,0) as count_where_place,
    	coalesce(count_contact,0) as count_contact, canсel_user_array
    from account a 
 left join (select account_id, count(id) as count_courier 
            from cte
            group by 1) t on a.id = t.account_id
 left join (select account_id, count(id) as count_complete 
            from cte 
            where status = 'Выполнено' group by 1) t2 on a.id = t2.account_id
 left join (select account_id, count(id) as count_canceled
            from cte
            where status = 'Отменен'
            group by account_id ) t3 on a.id = t3.account_id
 left join (select account_id , count( distinct where_place) as count_where_place
            from cte
            group by 1) t4 on a.id = t4.account_id
 left join (select account_id, count(id) as count_contact
            from cte
            group by 1) t5 on a.id = t5.account_id
 left join (select account_id , count(id) as current_month
			from cte 
			where date_trunc('Month', created_date ) = date_trunc('Month', current_date)
			group by account_id) t6 on a.id = t6.account_id
 left join (select account_id ,  count(id) as previous_month
			from cte 
			where date_trunc('Month', created_date-interval '1 month') = 
			date_trunc('Month', current_date-interval '1 month') 
			group by 1 ) t7 on a.id = t7.account_id
 left join (select account_id, array_agg(user_id) as canсel_user_array 
            from cte
            where status = 'Отменен'
            group by account_id) t8 on a.id = t8.account_id

drop view courier_statistic

--вариант 2
/*create or replace view courier_statistic as 
  select a.id , a."name" , coalesce(count_courier, 0) as count_courier,
  coalesce(count_complete, 0) as count_complete,
  coalesce(count_canceled, 0) as count_canceled,
  case 
  	when coalesce( previous_month, 0) = 0
  	then 0
  	else (coalesce( current_month, 0) -  previous_month) / current_month * 100
    end percent_relative_prev_month,
    coalesce(count_where_place, 0) as count_where_place,
    coalesce(count_contact, 0) as count_contact,
    cansel_user_array
    from account a 
   left join (select c.account_id, count(c.id) as count_courier 
              from courier c group by 1) t on a.id = t.account_id
  left join (select c2.account_id, count(c2.id) as count_complete 
              from courier c2 
              where c2. status = 'Выполнено' group by 1) t2 on a.id = t2.account_id
  left join (select c.account_id, count(c.id) as count_canceled
              from courier c
              where c. status = 'Отменен'
              group by c.account_id ) t3 on a.id = t3.account_id
  left join (select c3.account_id , count( distinct  c3.where_place) as count_where_place
            from courier c3
            group by 1) t4 on a.id = t4.account_id
  left join (select c4.account_id, count(c4.id) as count_contact
            from contact c4
            group by 1) t5 on a.id = t5.account_id
  left join (select account_id , count(c.id) as current_month
from courier c 
where date_trunc('Month', created_date ) = date_trunc('Month', current_date  )
group by account_id) t6 on a.id = t6.account_id
  left join (select account_id ,  count(c.id) as previous_month
from courier c 
where date_trunc('Month', created_date - interval '1 month' ) = 
date_trunc('Month', current_date  - interval '1 month') 
group by 1 ) t7 on a.id = t7.account_id
  left join (select c.account_id, array_agg(c.user_id) as cansel_user_array 
              from courier c
              where c. status = 'Отменен'
              group by c.account_id  ) t8 on a.id = t8.account_id*/
  
explain analyze  --53/288-511
select * from courier_statistic
				--113/284-356



  