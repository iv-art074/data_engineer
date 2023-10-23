--Задание 1. Напишите функцию, которая принимает на вход название должности (например, стажер),
--а также даты периода поиска, и возвращает количество вакансий, опубликованных по этой должности в заданный период.

	
create or replace function foo1 (start_date date, end_date date, prof text) returns numeric as $$
declare 
	res numeric;
begin
	if start_date is null or end_date is null
		then raise exception 'Одна из дат отсутствует';
	elseif start_date > end_date
		then raise exception 'Дата начала больше чем дата окончания';
	else			
	    select count (*) into res
		from vacancy 
		where create_date>=start_date and closure_date<end_date and vac_title like prof;	
	return res; 
	end if; 	
end;
$$ language plpgsql

--select foo1('01.01.2020', '01.06.2020','ведущий инженер')  -- 10

--Задание 2. Напишите триггер, срабатывающий тогда, когда в таблицу position добавляется значение grade, которого нет в таблице-справочнике grade_salary. 
--Триггер должен возвращать предупреждение пользователю о несуществующем значении grade.

--drop function tg_test() cascade;

create trigger tg_test
before insert or update on hr."position" 
for each row execute procedure tg_test()

create or replace function tg_test () returns trigger as $$
begin
    if (SELECT COUNT(*) FROM grade_salary gs where gs.grade = new.grade)=0
    	then 
    	raise exception 'Нет такого значения grade %',new.grade;
	else return new;
	end if;
end;
$$ language plpgsql
	
insert into position (pos_id,pos_title,pos_category,unit_id,grade,address_id,manager_pos_id)
values (5005,'специалист по персоналу','Административный',214,3,3,10)	

--Задание 3. Создайте таблицу employee_salary_history с полями:
--
--emp_id - id сотрудника
--salary_old - последнее значение salary (если не найдено, то 0)
--salary_new - новое значение salary
--difference - разница между новым и старым значением salary
--last_update - текущая дата и время

create table employee_salary_history (
	emp_id int4,
	salary_old numeric(12,2) default 0,
	salary_new numeric(12,2),
	difference numeric generated always as (salary_new-salary_old)stored,
	last_update timestamp);

--drop table employee_salary_history

--Напишите триггерную функцию, которая срабатывает при добавлении новой записи о сотруднике 
--или при обновлении значения salary в таблице employee_salary,
--и заполняет таблицу employee_salary_history данными.
	
create trigger tg_test2
after insert or update of salary on employee_salary 
for each row execute procedure tg_test2();

--drop trigger tg_test2 on employee_salary


--select salary from employee_salary where emp_id=3000 order by order_id  desc limit 1 offset 1

create or replace function tg_test2() returns trigger as $$
--берем предыдущее значение оклада (ввел смещение)      --убрал поиск по дате
declare salary_prev numeric(12,2)=(select salary from employee_salary where emp_id=new.emp_id /*and effective_from <> now()::date*/ order by order_id  desc limit 1 offset 1);
begin
	if salary_prev is null     --новый сотрудник
    	then insert into employee_salary_history (emp_id, salary_old, salary_new, last_update) values (new.emp_id,0,new.salary,now());
        return new;
	elseif tg_op = 'INSERT'  --действующий сотрудник новый оклад
			then insert into employee_salary_history (emp_id, salary_old, salary_new, last_update)values (new.emp_id,salary_prev,new.salary,now());
    		return new;
    else -- действующий сотрудник исправление значения оклада. разница с пред. действующим
    	insert into employee_salary_history (emp_id, salary_old, salary_new, last_update)values (new.emp_id,old.salary,new.salary,now());
	    return new;
	end if;
end;
$$ language plpgsql

--insert into employee_salary values (30007,2375,148000.00,current_date)

--select * from employee_salary where emp_id=2375

--select * from employee_salary_history



--Задание 4. Напишите процедуру, которая содержит в себе транзакцию на вставку данных в таблицу employee_salary. 
--Входными параметрами являются поля таблицы employee_salary.

create or replace procedure proc(order_p int, emp int, salary_p numeric, ef_from_p timestamp) as $$
	begin
		insert into employee_salary(order_id, emp_id, salary, effective_from)
		values (order_p, emp, salary_p, ef_from_p);
	   	commit;
	end;
$$ language plpgsql;

--call proc(30007,3000,147000.00,'2023-10-10')