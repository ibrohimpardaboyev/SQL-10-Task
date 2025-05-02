CREATE TABLE users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    ip_address VARCHAR(20),
    last_login DATETIME
);

INSERT INTO users (user_id,full_name,email,ip_address,last_login) VALUES
(1, 'Ali Valiyev', 'ali@example.com', '192.168.1.10', '2025-05-01 10:00:00'),
(2, 'Laylo Karimova', 'laylo@example.com', '192.168.1.11', '2025-05-01 10:01:00'),
(3, 'John Doe', 'john@example.com', '203.0.113.5', '2025-05-01 10:03:00');


CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    user_id INT,
    country VARCHAR(50),
    account_type VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO accounts VALUES
(101, 1, 'Uzbekistan', 'savings'),
(102, 1, 'Uzbekistan', 'checking'),
(103, 2, 'Uzbekistan', 'savings'),
(104, 3, 'USA', 'checking');

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    amount DECIMAL(10,2),
    transaction_type VARCHAR(10),  
    destination_country VARCHAR(50),
    transaction_time DATETIME,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

INSERT INTO transactions VALUES
(1, 101, 6000, 'withdrawal', 'Uzbekistan', '2025-05-01 09:00:00'),
(2, 101, 6100, 'withdrawal', 'Uzbekistan', '2025-05-01 09:05:00'),
(3, 101, 7000, 'withdrawal', 'Uzbekistan', '2025-05-01 09:10:00'), 
(4, 102, 200, 'deposit', 'Uzbekistan', '2025-05-01 10:00:00'),
(5, 102, 150, 'withdrawal', 'Russia', '2025-05-01 11:00:00'),
(6, 103, 100, 'deposit', 'Uzbekistan', '2025-05-01 08:00:00'),
(7, 103, 100, 'withdrawal', 'Germany', '2025-05-01 08:30:00'),
(8, 103, 100, 'withdrawal', 'Germany', '2025-05-01 09:30:00'),
(9, 103, 100, 'withdrawal', 'Germany', '2025-05-01 10:30:00'),
(10, 103, 100, 'withdrawal', 'Germany', '2025-05-01 11:30:00'),
(11, 103, 100, 'withdrawal', 'Germany', '2025-05-01 12:30:00'),
(12, 104, 800, 'withdrawal', 'France', '2025-05-01 13:00:00');

CREATE TABLE fraud_flags (
    flag_id INT PRIMARY KEY,
    transaction_id INT,
    account_id INT,
    flag_type VARCHAR(50),
    flag_time datetime,
    resolved int DEFAULT 0,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

INSERT INTO fraud_flags VALUES
(1, 3, 101, 'high_value_withdrawal_sequence', '2025-05-01 09:11:00', 0),
(2, 12, 104, 'foreign_transfer', '2025-05-01 13:01:00', 0);

CREATE TABLE login_logs (
    log_id INT PRIMARY KEY,
    user_id INT,
    login_time Datetime,
    ip_address VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

INSERT INTO login_logs VALUES
(1, 1, '2025-05-01 08:00:00', '192.168.1.10'),
(2, 1, '2025-05-01 08:00:00', '192.168.1.20'),
(3, 2, '2025-05-01 09:00:00', '192.168.1.11');

CREATE TABLE fraud_cases (
    case_id INT PRIMARY KEY,
    country VARCHAR(50),
    fraud_type VARCHAR(50),
    amount_usd DECIMAL(12, 2),
    report_date DATE
);


INSERT INTO fraud_cases VALUES
(1, 'USA', 'Credit Card Fraud', 12000.00, '2024-01-10'),
(2, 'India', 'Identity Theft', 8500.50, '2024-01-15'),
(3, 'Brazil', 'Insurance Fraud', 5400.00, '2024-01-20'),
(4, 'Germany', 'Tax Evasion', 23000.00, '2024-01-25'),
(5, 'China', 'Bank Fraud', 15500.75, '2024-02-01'),
(6, 'Russia', 'Online Scam', 9800.00, '2024-02-03'),
(7, 'UK', 'Ponzi Scheme', 30000.00, '2024-02-10'),
(8, 'Australia', 'Credit Card Fraud', 7200.20, '2024-02-14'),
(9, 'Canada', 'Phishing', 6600.00, '2024-02-18'),
(10, 'Japan', 'Corporate Fraud', 41000.00, '2024-02-20'),
(11, 'France', 'Bank Fraud', 13400.00, '2024-03-01'),
(12, 'Mexico', 'Money Laundering', 27000.00, '2024-03-04'),
(13, 'Nigeria', 'Online Scam', 8900.00, '2024-03-06'),
(14, 'South Korea', 'Embezzlement', 24500.00, '2024-03-10'),
(15, 'Italy', 'Tax Evasion', 21000.00, '2024-03-15'),
(16, 'South Africa', 'Insurance Fraud', 5600.00, '2024-03-20'),
(17, 'Spain', 'Identity Theft', 7800.00, '2024-03-25'),
(18, 'Turkey', 'Phishing', 9200.00, '2024-03-30'),
(19, 'Argentina', 'Corporate Fraud', 31000.00, '2024-04-02'),
(20, 'Uzbekistan', 'Bank Fraud', 8800.00, '2024-04-05');

-- 5 times consecutive transactions

with diffs as (
	select account_id, datediff(hour,lag(transaction_time,5) over (partition by account_id order by transaction_time asc,amount asc),transaction_time) as trans_fiveth from transactions
)
select distinct account_id from diffs where trans_fiveth <= 24 

-- possibly fraud detection

with flag as (
	select 
		account_id,
		amount,
		transaction_time,
		case
			when datediff(hour,lag(transaction_time,3) over (partition by account_id order by transaction_time),transaction_time) <= 24 and lag(amount,3) over (partition by account_id order by transaction_time)>=5000 then 'possibly fraud'
			else 'no fraud detection'		
		end as flag
	from 
		transactions 
)
select distinct account_id from [flag] where flag = 'possibly fraud'

-- 2 or more logins on same time alert 
CREATE TABLE alerts (
    alert_id INT IDENTITY PRIMARY KEY,
    user_id INT,
    alert_time DATETIME,
    message VARCHAR(255)
);

create trigger tg_same_time_login 
on login_logs
after insert
as begin 
	insert into alerts (user_id,alert_time,message)
	select 
		user_id,
		login_time,
		CONCAT(count(*), ' number of logins on the same time')
	from inserted
	group by user_id,login_time
	having count(*)>=2;
end
select * from login_logs
insert into login_logs values 
(4,3,'2025-05-02 15:14:40','192.168.1.25'),
(5,3,'2025-05-02 15:14:40','192.168.1.27')
select * from alerts

-- transaction to foreign country

select * from fraud_flags


--select * from transactions
create trigger transaction_to_foreign_country 
on transactions 
after insert 
as begin
	insert into fraud_flags (flag_id,transaction_id,account_id,flag_type,flag_time)
	select 
		(select count(*) from fraud_flags)+1,
		transaction_id,
		account_id,
		'transaction to the other foreign country',
		transaction_time
	from inserted
	where destination_country != 'Uzbekistan'
end


create view fraud_visualizer as 
select country, count(*) as total_case, sum(amount_usd) as total_money_stolen from fraud_cases group by country

-- ip change capture procedure

create table log_ip (
	user_id int,
	ip_adrees_change_rate float
)

create procedure ip_cdc
as 
begin
	truncate table log_ip;
	insert into log_ip (user_id, ip_adrees_change_rate)
	select 
		user_id,
		count(distinct ip_address)
	from login_logs
	group by user_id
end


exec ip_cdc

select * from log_ip