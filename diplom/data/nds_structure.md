Таблица Branch: Имеет поля: branch_id (первичный ключ), branch_name.  
Таблица City: Имеет поля: city_id (первичный ключ), city_name.  
Таблица Customer:  
Имеет поля: customer_id (первичный ключ), customer_type, gender.  
Таблица ProductLine: Имеет поля: product_line_id (первичный ключ), product_line_name.  
Таблица Payment: Имеет поля: payment_id (первичный ключ), ``payment_type`.  
Все вышеуказанные таблицы соответствуют 3НФ т.к. поля зависят только от первичного ключа.  
Таблица Sales: Имеет поля: sale_id (первичный ключ), invoice_id, branch_id, city_id, customer_id, product_line_id, unit_price, quantity, tax_5_percent, total, date, time, payment_id, cost_of_goods_sold, gross_margin_percentage, gross_income, rating.  
branch_id, city_id, customer_id, product_line_id, payment_id — являтся ссылками на соответствующие таблицы.  
  
Поле gender неэффективно выделять в отдельную таблицу, т.к. это усложнит схему и увеличит количество соединений при запросах, что может негативно сказаться на производительности.  
Поле rating Рейтинг (оценка) относится к конкретной транзакции и имеет смысл только в контексте этой продажи. 
Вынесение этого поля в отдельную таблицу не улучшит структуру данных и не принесет существенных преимуществ. Также создание отдельной таблицы приведет к усложнению запросов и потенциальным потерям в производительности.  

[Назад](https://github.com/iv-art074/data_engineer/edit/main/diplom/Readme.md)  
