CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(50),
    region VARCHAR(50),
    salary INT
);

INSERT INTO Customers VALUES
(1, 'Ali Karimov', 'Toshkent', 5000),
(2, 'Dilshod Umarov', 'Andijon', 3000),
(3, 'Nodira Yuldasheva', 'Fargona', 4000),
(4, 'Azizbek Roziyev', 'Samarqand', 4500),
(5, 'Malika Qosimova', 'Buxoro', 3500),
(6, 'Shavkat Ergashev', 'Toshkent', 3800),
(7, 'Gulnora Nazarova', 'Andijon', 4200),
(8, 'Javohir Olimov', 'Fargona', 4700),
(9, 'Ozoda Tolaganova', 'Samarqand', 3900),
(10, 'Farruh Xolmatov', 'Buxoro', 3200);

CREATE TABLE Credits (
    credit_id INT PRIMARY KEY,
    customer_id INT,
    amount INT,
    interest_rate FLOAT,
    credit_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

INSERT INTO Credits VALUES
(1, 1, 10000, 14.5, '2024-01-10', 'active'),
(2, 2, 5000, 15.0, '2024-02-15', 'active'),
(3, 3, 8000, 13.0, '2024-03-01', 'frozen'),
(4, 4, 12000, 16.5, '2024-01-25', 'active'),
(5, 5, 7000, 12.0, '2024-02-10', 'active'),
(6, 6, 6500, 15.5, '2024-03-10', 'frozen'),
(7, 7, 4000, 11.0, '2024-02-01', 'active'),
(8, 8, 9000, 17.0, '2024-01-20', 'active'),
(9, 9, 11000, 13.5, '2024-03-05', 'active'),
(10, 10, 6000, 10.0, '2024-02-20', 'active');

CREATE TABLE Payments (
    payment_id INT PRIMARY KEY,
    credit_id INT,
    payment_date DATE,
    amount INT,
    delay_days INT,
    FOREIGN KEY (credit_id) REFERENCES Credits(credit_id)
);

INSERT INTO Payments VALUES
(1, 1, '2024-02-10', 2000, 0),
(2, 1, '2024-03-10', 2000, 5),
(3, 1, '2024-04-10', 2000, 3),
(4, 2, '2024-03-15', 1000, 0),
(5, 2, '2024-04-15', 1000, 7),
(6, 3, '2024-04-01', 1600, 10),
(7, 3, '2024-05-01', 1600, 8),
(8, 4, '2024-02-25', 2400, 0),
(9, 5, '2024-03-10', 1400, 0),
(10, 6, '2024-04-10', 1300, 15);

CREATE TABLE Expenses (
    expense_id INT PRIMARY KEY,
    customer_id INT,
    expense_date DATE,
    amount INT,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

INSERT INTO Expenses VALUES
(1, 1, '2023-10-10', 1200),
(2, 1, '2024-02-10', 1500),
(3, 2, '2023-11-01', 800),
(4, 2, '2024-03-01', 1000),
(5, 3, '2023-12-15', 2000),
(6, 3, '2024-03-20', 1800),
(7, 4, '2023-10-30', 1000),
(8, 5, '2023-11-25', 900),
(9, 6, '2024-02-10', 1100),
(10, 7, '2023-12-20', 1300);

CREATE TABLE RiskLevels (
    customer_id INT PRIMARY KEY,
    risk_level VARCHAR(10),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

INSERT INTO RiskLevels VALUES
(1, 'High'),
(2, 'Medium'),
(3, 'High'),
(4, 'Low'),
(5, 'Medium'),
(6, 'High'),
(7, 'Low'),
(8, 'Medium'),
(9, 'Low'),
(10, 'Medium');

-- delayed paymeny 

select top 1 * from Credits
select top 1 * from Customers
select top 1 * from Expenses
select top 1 * from Payments
select top 1 * from RiskLevels
-- delayed days
with delayed_days as (
	select 
		credit_id,
		SUM(amount) as total_amount_paid,
		avg(delay_days) as average_delay_days, 
		count(*) as number_of_delayed_days 
	from Payments 
	where delay_days > 0 group by credit_id
)

select 
	dd.credit_id,
	total_amount_paid,
	number_of_delayed_days,
	average_delay_days,
	amount,interest_rate,
	cast(amount as float) + cast(amount as float)/100 * interest_rate - cast(total_amount_paid as float) as amount_need_to_pay,
	status
from delayed_days dd left join Credits c on dd.credit_id = c.credit_id
select * from [dbo].[Credits]

--expenses after and before credit
--after credit
with after_cre as (
	select
		e.customer_id,
		sum(case when expense_date >= credit_date and DATEDIFF(month,credit_date,expense_date) <= 3 then e.amount else 0 end) as total_spendature_after_credit
	from Credits c 
	right join Expenses e on e.customer_id = c.customer_id 
	group by e.customer_id
)
select bc.customer_id, total_spendature_after_credit, salary from after_cre bc left join Customers c on c.customer_id = bc.customer_id
--before credit
go
with before_cre as (
	select
		e.customer_id,
		sum(case when expense_date < credit_date and DATEDIFF(month,expense_date,credit_date) <= 3 then e.amount else 0 end) as total_spendature_before_credit
	from Credits c 
	right join Expenses e on e.customer_id = c.customer_id 
	group by e.customer_id
)
select bc.customer_id, total_spendature_before_credit, salary from before_cre bc left join Customers c on c.customer_id = bc.customer_id


-- overall after landing credit almost all of the users expenses have reduced

select region, sum(amount) as total_credit_amount,avg(interest_rate) as avg_interest_rate, count(*) as credit_count  from Credits cr left join Customers c on c.customer_id = cr.customer_id group by region

-- credit amount for all user group

select 
	r.risk_level,
	sum(amount) as total_amount
from RiskLevels r 
left join Credits c on c.customer_id = r.customer_id
group by risk_level
order by total_amount desc

-- trigger 
create trigger trg_frozen
on Payments
after insert
as
begin
    update c
    set c.status = 'frozen'
    from Credits c
    where c.credit_id IN (    
		select p.credit_id
        from Payments p
        join inserted i on p.credit_id = i.credit_id
        where p.delay_days > 0
        group by p.credit_id
        having count(*) > 3
    )
    and c.status != 'frozen'; 
end;