CREATE TABLE countries (
    country_id INT PRIMARY KEY,
    country_name VARCHAR(50)
);

INSERT INTO countries VALUES
(1, 'USA'),
(2, 'China'),
(3, 'Germany'),
(4, 'Uzbekistan'),
(5, 'Russia');

CREATE TABLE ports (
    port_id INT PRIMARY KEY,
    port_name VARCHAR(50),
    country_id INT FOREIGN KEY REFERENCES countries(country_id)
);

INSERT INTO ports VALUES
(1, 'Port A', 1),
(2, 'Port B', 2),
(3, 'Port C', 3);

CREATE TABLE goods (
    goods_id INT PRIMARY KEY,
    description VARCHAR(100)
);

INSERT INTO goods VALUES
(1, 'Electronics'),
(2, 'Textiles'),
(3, 'Machinery'),
(4, 'Food'),
(5, 'Vehicles');

CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY,
    goods_id INT FOREIGN KEY REFERENCES goods(goods_id),
    origin_country INT FOREIGN KEY REFERENCES countries(country_id),
    destination_country INT FOREIGN KEY REFERENCES countries(country_id),
    port_id INT FOREIGN KEY REFERENCES ports(port_id),
    arrival_date DATE,
    release_date DATE,
    status VARCHAR(20)
);

INSERT INTO shipments VALUES
(1, 1, 2, 1, 1, '2025-03-01', '2025-03-05', 'released'),
(2, 3, 3, 2, 2, '2025-03-10', '2025-03-25', 'released'),
(3, 4, 5, 3, 3, '2025-03-15', NULL, 'pending'),
(4, 2, 1, 4, 2, '2025-03-20', '2025-03-23', 'released'),
(5, 5, 2, 3, 1, '2025-03-22', NULL, 'pending');

CREATE TABLE customs (
    customs_id INT PRIMARY KEY,
    shipment_id INT FOREIGN KEY REFERENCES shipments(shipment_id),
    inspection_status VARCHAR(20),
    cleared_date DATE
);

INSERT INTO customs VALUES
(1, 1, 'passed', '2025-03-05'),
(2, 2, 'passed', '2025-03-25'),
(3, 3, 'quarantine', NULL),
(4, 4, 'passed', '2025-03-23'),
(5, 5, 'pending', NULL);

CREATE TABLE invoices (
    invoice_id INT PRIMARY KEY,
    shipment_id INT FOREIGN KEY REFERENCES shipments(shipment_id),
    amount_usd DECIMAL(10,2)
);

INSERT INTO invoices VALUES
(1, 1, 5500.00),
(2, 2, 8700.00),
(3, 3, -1200.00), 
(4, 4, 0.00),     
(5, 5, 7300.00);

CREATE TRIGGER trg_quarantine_new_shipment
ON shipments
AFTER INSERT
AS
BEGIN
    INSERT INTO customs (customs_id, shipment_id, inspection_status, cleared_date)
    SELECT 
        (SELECT ISNULL(MAX(customs_id), 0) + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM customs),
        i.shipment_id,
        'quarantine',
        NULL
    FROM inserted i;
END;
-- imported and exported goods count
select c.country_name,count(*) as exported_goods from shipments sh join countries c on sh.origin_country = c.country_id group by c.country_name
select c.country_name,count(*) as imported_goods from shipments sh join countries c on sh.destination_country = c.country_id group by c.country_name

-- average days at bojhona
select goods_id, avg(DATEDIFF(DAY,arrival_date,release_date)) as average_days_at_bojxona from shipments where status!='pending' group by goods_id

-- total goods revenue passed by each port  

select sh.port_id,sum(amount_usd) as total_sold from shipments sh join invoices i on i.shipment_id = sh.shipment_id where amount_usd>0 group by port_id 

-- goods not relased or on bojhona

select goods_id from shipments where arrival_date is not null and status = 'pending'

-- Bir oy ichida eng ko‘p miqdordagi tranzitlar bo‘lgan yo‘nalishlar

select 
	c.country_name,
	sum(i.amount_usd) as total_goods_sales,
	count(*) as number_of_shipments
from shipments sh 
join invoices i on sh.shipment_id = i.shipment_id 
join countries c on sh.destination_country = c.country_id 
where DATEDIFF(DAY,arrival_date,GETDATE())<=70 and amount_usd>0
group by c.country_name
order by number_of_shipments desc

-- invoice incorrect amounts 

select * from invoices where amount_usd<=0

-- realease trigger 

create trigger quarantine 
on invoices 
after insert
as begin
	insert into customs (customs_id,shipment_id,inspection_status,cleared_date)
	select 
		(select count(*) from customs)+1,
		shipment_id,
		'quarantine',
		Null
	from inserted
end

-- alert for clearance date is greater than 10

select *, 'clearance day have came' as alert from customs where DATEDIFF(day,cleared_date,GETDATE())>=10