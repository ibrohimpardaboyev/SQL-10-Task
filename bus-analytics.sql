CREATE TABLE Cities (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100)
);

CREATE TABLE Companies (
    company_id INT PRIMARY KEY,
    company_name VARCHAR(100)
);

CREATE TABLE Buses (
    bus_id INT PRIMARY KEY,
    company_id INT,
    capacity INT,
    FOREIGN KEY (company_id) REFERENCES Companies(company_id)
);

CREATE TABLE Routes (
    route_id INT PRIMARY KEY,
    from_city_id INT,
    to_city_id INT,
    price DECIMAL(10,2),
    FOREIGN KEY (from_city_id) REFERENCES Cities(city_id),
    FOREIGN KEY (to_city_id) REFERENCES Cities(city_id)
);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100)
);

CREATE TABLE Tickets (
    ticket_id INT PRIMARY KEY,
    customer_id INT,
    route_id INT,
    bus_id INT,
    purchase_date DATE,
    travel_date DATE,
    status VARCHAR(20), -- 'paid', 'unpaid', 'cancelled'
    seat_number INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (route_id) REFERENCES Routes(route_id),
    FOREIGN KEY (bus_id) REFERENCES Buses(bus_id)
);

INSERT INTO Cities VALUES
(1, 'Toshkent'),
(2, 'Samarqand'),
(3, 'Buxoro'),
(4, 'Fargʻona');

INSERT INTO Companies VALUES
(1, 'UzTrans'),
(2, 'OrientBus');

INSERT INTO Buses VALUES
(1, 1, 50),
(2, 1, 40),
(3, 2, 45),
(4, 2, 50);

INSERT INTO Routes VALUES
(1, 1, 2, 50000.00),
(2, 1, 3, 80000.00),
(3, 2, 3, 60000.00),
(4, 3, 4, 70000.00);


INSERT INTO Customers VALUES
(1, 'Ali'),
(2, 'Vali'),
(3, 'Dilshod'),
(4, 'Malika'),
(5, 'Shohruh');

INSERT INTO Tickets VALUES
(1, 1, 1, 1, '2025-04-25', '2025-04-30', 'paid', 1),
(2, 1, 2, 2, '2025-04-20', '2025-04-28', 'paid', 3),
(3, 2, 1, 1, '2025-04-27', '2025-04-30', 'unpaid', 5),
(4, 2, 1, 1, '2025-04-20', '2025-04-25', 'paid', 6),
(5, 3, 3, 3, '2025-04-18', '2025-04-22', 'cancelled', 7),
(6, 3, 2, 2, '2025-04-15', '2025-04-20', 'paid', 8),
(7, 4, 1, 1, '2025-04-10', '2025-04-17', 'paid', 9),
(8, 5, 4, 4, '2025-04-28', '2025-04-29', 'unpaid', 10),
(9, 5, 4, 4, '2025-04-25', '2025-04-26', 'paid', 11),
(10, 2, 3, 3, '2025-04-15', '2025-04-21', 'paid', 12),
(11, 3, 3, 3, '2025-04-17', '2025-04-23', 'paid', 13),
(12, 4, 2, 2, '2025-04-10', '2025-04-16', 'paid', 14),
(13, 4, 2, 2, '2025-04-11', '2025-04-18', 'unpaid', 15),
(14, 5, 1, 1, '2025-04-12', '2025-04-18', 'cancelled', 16),
(15, 1, 1, 1, '2025-04-29', '2025-04-30', 'paid', 17),
(16, 1, 2, 2, '2025-04-24', '2025-04-27', 'unpaid', 18),
(17, 2, 2, 2, '2025-04-26', '2025-04-30', 'paid', 19),
(18, 3, 1, 1, '2025-04-23', '2025-04-29', 'paid', 20),
(19, 5, 4, 4, '2025-04-21', '2025-04-28', 'paid', 21),
(20, 1, 1, 1, '2025-04-20', '2025-04-24', 'unpaid', 22);

create view whole_data as 
select 
	t.ticket_id,
	b.company_id,
	t.customer_id,
	r.route_id,
	r.from_city_id,
	r.to_city_id,
	price,
	purchase_date,
	status,
	seat_number,
	company_name
from Tickets t 
left join Customers c on c.customer_id = t.customer_id
left join [Routes] r on r.route_id = t.route_id
left join Buses b on b.bus_id = t.bus_id
left join Companies cp on cp.company_id = b.company_id

select * from whole_data

-- 

select 
	to_city_id, 
	count(*) as total_records, 
	sum(case when status='paid' then 1 else 0 end) as sold_tickets,
	sum(case when status='cancelled' then 1 else 0 end) as cancelled_tickets,
	sum(case when status='paid' then price else 0 end) as Tickets_number 
from whole_data 
group by to_city_id

-- o‘rtacha chiptaning narxini, foyda, safar

select 
	company_name,
	sum(case when status='paid' then price else 0 end) as total_profit , 
	avg(price) as average_ticket_price,
	count(distinct (purchase_date)) as total_travels 
from whole_data 
group by company_name;

-- qayta sotib olish

select 
	customer_id, 
	count(*) as paids,
	sum(case when status='paid' then 1 else 0 end) as paid,
	sum(case when status='cancelled' then 1 else 0 end) as cancelled,
	sum(case when status='unpaid' then 1 else 0 end) as unpaid
from whole_data 
group by customer_id

-- procedure 
select * from whole_data

create procedure unpaid_selector
as 
begin 
	select 
		* 
	from 
		whole_data 
	where 
		status = 'unpaid' and datediff(day,purchase_date,getdate()) >= 1
end 

drop procedure unpaid_selector

exec unpaid_selector
