CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    registration_date DATE
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock INT,
    status VARCHAR(10) DEFAULT 'active'
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_type VARCHAR(20), -- e.g., 'card', 'cash', 'paypal'
    payment_date DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Customers
INSERT INTO customers VALUES
(1, 'Ali Karimov', 'ali@example.com', '2024-01-15'),
(2, 'Malika Yuldasheva', 'malika@example.com', '2024-03-20'),
(3, 'Sardor Bek', 'sardor@example.com', '2024-02-10');

-- Products
INSERT INTO products VALUES
(101, 'Smartphone X', 'Electronics', 500.00, 10, 'active'),
(102, 'Headphones Pro', 'Electronics', 150.00, 0, 'active'),
(103, 'Running Shoes', 'Sportswear', 100.00, 5, 'active'),
(104, 'Backpack Travel', 'Accessories', 80.00, 2, 'active'),
(105, 'Office Chair', 'Furniture', 200.00, 0, 'active');

-- Orders
INSERT INTO orders VALUES
(1001, 1, '2024-11-01 10:30:00'),
(1002, 2, '2025-01-15 14:20:00'),
(1003, 1, '2025-02-10 09:15:00'),
(1004, 3, '2025-03-28 16:45:00'),
(1005, 2, '2025-04-12 12:00:00');

-- Order Items
INSERT INTO order_items VALUES
(1, 1001, 101, 1, 500.00),
(2, 1001, 102, 2, 150.00),
(3, 1002, 103, 1, 100.00),
(4, 1003, 104, 1, 80.00),
(5, 1004, 101, 1, 500.00),
(6, 1005, 105, 1, 200.00);

-- Payments
INSERT INTO payments VALUES
(501, 1001, 'card', '2024-11-01 11:00:00'),
(502, 1002, 'cash', '2025-01-16 10:00:00'),
(503, 1003, 'paypal', '2025-02-11 08:00:00'),
(504, 1004, 'card', '2025-03-29 17:00:00'),
(505, 1005, 'paypal', '2025-04-13 14:00:00');


CREATE TRIGGER trg_update_product_status
ON products
AFTER UPDATE
AS
BEGIN
    UPDATE p
    SET p.status = 'inactive'
    FROM products p
    WHERE p.stock = 0;
END;
drop trigger trg_update_product_status

select * from products

--trigger 
--changes active to incative if number of remained products is 0
CREATE TRIGGER trg_update_product_status
ON products
AFTER UPDATE
AS
BEGIN
    UPDATE p
    SET p.status = 'inactive'
    FROM products p
    INNER JOIN inserted i ON p.product_id = i.product_id
    WHERE p.stock = 0;
END;
drop trigger trg_update_product_status

INSERT INTO products VALUES
(326, 'redmi 9a', 'Electronics', 150.00, 2, 'active')

select * from customers
select * from order_items
select * from orders
select * from payments
select * from products

with sales as ( 
	select 
		order_item_id,
		customer_id,
		oi.order_id,
		product_id,
		quantity * price as total_revenue,
		order_date
	from orders o right join order_items oi on o.order_id = oi.order_id
)

select 
	product_id,
	sum(total_revenue) as total_income 
from 
	sales 
where 
	DATEDIFF(MONTH,order_date,GETDATE())<=6 
group by product_id 
order by total_income desc

--Recency
select 
	customer_id,
	CONCAT(
		'last payment made ',
		datediff(year,max(order_date),getdate()),
		' years ',
		datediff(MONTH,max(order_date),getdate()),
		' months ',
		datediff(day,max(order_date),getdate()),
		' days ago '
	)
from 
payments p left join orders o on o.order_id = p.order_id 
group by customer_id;

-- frequency 

with prev_dates as (
	select
	    customer_id,
		p.order_id,
		payment_date,
		lag(payment_date,1) over (partition by customer_id order by payment_date asc) as prev_date
	from 
	payments p left join orders o on o.order_id = p.order_id 
)
select 
	customer_id,
	concat('frequency is ',avg(DATEDIFF(YEAR,prev_date,payment_date)*365.25*24 + DATEDIFF(MONTH,prev_date,payment_date)*30*24 + DATEDIFF(HOUR,prev_date,payment_date)),' hours')
from 
prev_dates where prev_date is not null group by customer_id

-- Monetary

select customer_id,sum(quantity*price) as total_monetary from order_items oi left join orders o on o.order_id = oi.order_id group by customer_id

-- number of products sold by each product category
select 
	category,
	SUM(quantity) as total_orders
from 
	order_items oi 
left join orders o on oi.order_id = o.order_id 
left join products p on oi.product_id = p.product_id  
group by category
order by total_orders desc

-- total revenue earned by each product category
select 
	category,
	SUM(quantity * oi.price) as total_revenue_earned
from 
	order_items oi 
left join orders o on oi.order_id = o.order_id 
left join products p on oi.product_id = p.product_id  
group by category
order by total_revenue_earned desc

-- avg delayes for each payment method in minutes 

select 
	payment_type,
	avg(datediff(day,order_date,payment_date)*24*60+datediff(hour,order_date,payment_date)*60+datediff(minute,order_date,payment_date)) as avg_diff_in_minutes
from payments p 
right join orders o on o.order_id = p.order_id 
group by payment_type