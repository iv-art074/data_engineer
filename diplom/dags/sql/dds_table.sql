-- Измерения
-- справочник филиалов
CREATE TABLE IF NOT EXISTS dim_branches (
    b_id SERIAL PRIMARY KEY,
    b_name VARCHAR(10) UNIQUE NOT NULL
);

-- справочник городов
CREATE TABLE IF NOT EXISTS dim_city (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(50) UNIQUE NOT NULL
);

-- справочник клиентов
CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id SERIAL PRIMARY KEY,
    customer_type VARCHAR(10) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    UNIQUE (customer_type, gender)
);

-- справочник продуктов
CREATE TABLE IF NOT EXISTS dim_product_line (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(50) UNIQUE NOT NULL
);

-- справочник способов оплаты
CREATE TABLE IF NOT EXISTS dim_payment (
    payment_id SERIAL PRIMARY KEY,
    payment_type VARCHAR(20) UNIQUE NOT NULL
);

-- таблица дат
CREATE TABLE IF NOT EXISTS dim_date (
    date_id SERIAL PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    day INT NOT NULL,
    day_of_week VARCHAR(10) NOT NULL
);

-- таблица времени
CREATE TABLE IF NOT EXISTS dim_time (
    time_id SERIAL PRIMARY KEY,
    time TIME UNIQUE NOT NULL,
    hour INT NOT NULL,
    minute INT NOT NULL,
    second INT NOT NULL
);

-- Факты
-- продажи 
CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id SERIAL PRIMARY KEY,
    invoice_id VARCHAR(20) UNIQUE NOT NULL,
    b_id INT REFERENCES dim_branches(b_id),
    city_id INT REFERENCES dim_city(city_id),
    customer_id INT REFERENCES dim_customer(customer_id),
    product_id INT REFERENCES dim_product_line(product_id),
    cost NUMERIC(10, 2) NOT NULL,
    quantity INT NOT NULL,
    tax NUMERIC(10, 2) NOT NULL,
    total NUMERIC(10, 2) NOT NULL,
    date_id INT REFERENCES dim_date(date_id),
    time_id INT REFERENCES dim_time(time_id),
    payment_id INT REFERENCES dim_payment(payment_id),
    cogs NUMERIC(10, 2) NOT NULL,
    gross_margin_percentage NUMERIC(5, 2) NOT NULL,
    gross_income NUMERIC(10, 2) NOT NULL,
    rating NUMERIC(3, 1) NOT NULL
);
-- Таблица кол-ва прогрузок
CREATE TABLE IF NOT EXISTS load_history (
    load_id SERIAL PRIMARY KEY,  
    dag_id VARCHAR(255) NOT NULL,  
    task_id VARCHAR(255) NOT NULL,  
    start_time TIMESTAMP NOT NULL,  
    end_time TIMESTAMP,  
--    status VARCHAR(50) NOT NULL,  -- Статус загрузки (например, 'success', 'failed')
    rows_ INT,  -- Количество загруженных строк
    error_ TEXT  -- текст ошибки
);

-- Таблица статусов загрузок
CREATE TABLE IF NOT EXISTS load_status (
    load_status_id SERIAL PRIMARY KEY,  -- Уникальный идентификатор статуса загрузки
    load_id INT REFERENCES load_history(load_id),  -- Ссылка на историю загрузки
    status_time TIMESTAMP NOT NULL,  -- Время обновления статуса
    status VARCHAR(50) NOT NULL,  -- Статус (например, 'started', 'in_progress', 'completed', 'failed')
    message TEXT  -- Дополнительная информация о статусе
);

-- Индексы для оптимизации запросов к таблицам метаданных
CREATE INDEX IF NOT EXISTS idx_load_history_dag_task ON load_history(dag_id, task_id);
CREATE INDEX IF NOT EXISTS idx_load_status_load_id ON load_status(load_id);
