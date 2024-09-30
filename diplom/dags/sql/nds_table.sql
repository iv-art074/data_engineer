
-- Filial`s table
CREATE TABLE IF NOT EXISTS Branches (
    branch_id SERIAL PRIMARY KEY,  -- идентификатор филиала
    branch_name VARCHAR(10) UNIQUE NOT NULL  -- филиал
);

-- Superbase cities
CREATE TABLE IF NOT EXISTS City (
    city_id SERIAL PRIMARY KEY,  -- идентификатор города
    city_name VARCHAR(50) UNIQUE NOT NULL  -- город
);


-- client`s table
CREATE TABLE IF NOT EXISTS Customer (
    customer_id SERIAL PRIMARY KEY,  -- Уникальный id клиента
    customer_type VARCHAR(10) NOT NULL,  -- Тип клиента
    gender VARCHAR(10) NOT NULL  -- Пол 
);

-- Product lines
CREATE TABLE IF NOT EXISTS ProductLine (
    product_id SERIAL PRIMARY KEY,  -- id продуктовой линейки
    product_line_name VARCHAR(50) UNIQUE NOT NULL  -- Название продукта
);

-- Payment types
CREATE TABLE IF NOT EXISTS Payment (
    payment_id SERIAL PRIMARY KEY,  -- id платежа
    payment_type VARCHAR(20) UNIQUE NOT NULL  -- Тип платежа
);

-- Sales table
CREATE TABLE IF NOT EXISTS Sales (
    sale_id SERIAL PRIMARY KEY,  -- id продажи
    invoice_id VARCHAR(20) UNIQUE NOT NULL,  -- id счета
    branch_id INT REFERENCES Branches(branch_id),  -- id филиал
    city_id INT REFERENCES City(city_id),  -- Ссылка на город
    customer_id INT REFERENCES Customer(customer_id),  -- клиент
    product_id INT REFERENCES ProductLine(product_id),  -- продуктовая линейка
    cost NUMERIC(10, 2) NOT NULL,  -- Цена за единицу товара
    quantity INT NOT NULL,  -- Количество товара
    tax NUMERIC(10, 2) NOT NULL,  -- Налог 5%
    total NUMERIC(10, 2) NOT NULL,  -- Общая стоимость
    date_ DATE NOT NULL,  -- Дата транзакции
    time_ TIME NOT NULL,  -- Время транзакции
    payment_id INT REFERENCES Payment(payment_id),  -- тип платежа
    cogs NUMERIC(10, 2) NOT NULL,  -- Себестоимость 
    gross_margin_percentage NUMERIC(5, 2) NOT NULL,  -- Процент прибыли
    gross_income NUMERIC(10, 2) NOT NULL,  -- Полученный доход
    rating NUMERIC(3, 1) NOT NULL,  -- Рейтинг
    flashed BOOLEAN DEFAULT FALSE  -- Флаг обработки
);
