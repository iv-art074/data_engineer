
Таблицы измерений (dimension tables) содержат описательную информацию, которая помогает контекстуализировать данные фактов.   
Это таблицы dim_branch, dim_city, dim_customer, dim_product_line, dim_payment, dim_date, dim_time.  
Таблицы фактов (fact tables) содержат измеримые, количественные данные о бизнес-процессах.
В данном случае это таблица fact_sales, которая хранит данные о продажах.  
  
dim_branch: филиалы  
branch_id: уникальный идентификатор филиала.  
branch_name: название филиала.  
  
dim_city: Города  
city_id: уникальный идентификатор города.  
city_name: название города.  
  
dim_customer: покупатели  
customer_id: уникальный идентификатор клиента.  
customer_type: тип клиента (например, 'VIP', 'Regular').  
  
gender: пол клиента.  
  
dim_product_line: Помогает анализировать продажи по различным продуктовым линейкам.  
product_line_id: уникальный идентификатор продуктовой линейки.  
product_line_name: название продуктовой линейки.  
  
dim_payment: способы оплаты.  
payment_id: уникальный идентификатор способа оплаты.  
payment_type: тип оплаты (например, 'Credit Card', 'Cash').  
  
dim_date: Используется для анализа данных по временным интервалам, позволяе проводить анализ по разным временным интервалам дат  
date_id: уникальный идентификатор даты.
date: дата.
year: год.
quarter: квартал.
month: месяц.
day: день.
day_of_week: день недели.  
  
dim_time: Обеспечивает анализ данных по времени суток.  
time_id: уникальный идентификатор времени.  
time: время.  
hour: час.  
minute: минута.  
second: секунда.  

fact_sales:  
sale_id: уникальный идентификатор продажи.  
invoice_id: уникальный идентификатор счета-фактуры.  
branch_id, city_id, customer_id, product_line_id, date_id, time_id, payment_id: ссылки на соответствующие таблицы измерений.  
unit_price, quantity, tax_5_percent, total, cost_of_goods_sold, gross_margin_percentage, gross_income, rating: количественные показатели продаж.  

[Назад](https://github.com/iv-art074/data_engineer/edit/main/diplom/Readme.md)   
