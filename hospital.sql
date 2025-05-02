CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    birth_date DATE,
    gender CHAR(1)
);

INSERT INTO patients VALUES
(1, 'Ali Karimov', '1955-06-01', 'M'),
(2, 'Gulbahor Toirova', '1978-12-12', 'F'),
(3, 'Jasur Ergashev', '2001-09-05', 'M'),
(4, 'Dilnoza Qodirova', '1960-03-22', 'F');

CREATE TABLE doctors (
    doctor_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    specialty VARCHAR(50)
);

INSERT INTO doctors VALUES
(1, 'Dr. Tohir Hasanov', 'Cardiology'),
(2, 'Dr. Dilshod Raximov', 'Neurology'),
(3, 'Dr. Malika Erkinova', 'General');

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    appointment_date DATE,
    status VARCHAR(20)  -- 'attended', 'no-show'
);

INSERT INTO appointments VALUES
(1, 1, 1, '2024-01-10', 'attended'),
(2, 1, 1, '2024-02-15', 'attended'),
(3, 2, 2, '2024-02-20', 'no-show'),
(4, 2, 2, '2024-03-01', 'attended'),
(5, 3, 3, '2024-04-01', 'attended'),
(6, 4, 1, '2024-04-10', 'attended');

CREATE TABLE prescriptions (
    prescription_id INT PRIMARY KEY,
    patient_id INT,
    doctor_id INT,
    drug_name VARCHAR(100),
    price DECIMAL(10, 2),
    quantity INT
);

INSERT INTO prescriptions VALUES
(1, 1, 1, 'Aspirin', 2.50, 10),
(2, 2, 2, 'Paracetamol', 1.00, 20),
(3, 3, 3, 'Ibuprofen', 3.00, 5),
(4, 4, 1, 'Amoxicillin', 5.00, 6);

CREATE TABLE lab_results (
    result_id INT PRIMARY KEY,
    patient_id INT,
    test_date DATE,
    test_name VARCHAR(100),
    result_value VARCHAR(100),
    normal_range VARCHAR(100),
    diagnosis VARCHAR(100)
);

INSERT INTO lab_results VALUES
(1, 1, '2024-01-11', 'Blood Pressure', '160/100', '120/80', 'Hypertension'),
(2, 1, '2024-02-16', 'Cholesterol', '250', 'Below 200', 'High Cholesterol'),
(3, 2, '2024-03-01', 'Glucose', '180', '70-99', 'Diabetes'),
(4, 3, '2024-04-02', 'CBC', 'Normal', 'Normal', 'Normal'),
(5, 4, '2024-04-11', 'Blood Pressure', '140/90', '120/80', 'Prehypertension');


select 
	doctor_id,
	count(patient_id) as patients_count
from appointments
group by doctor_id

-- latest lab results 

--select * from lab_results

select 
	patient_id,diagnosis 
from 
	(select patient_id, ROW_NUMBER() over (partition by patient_id order by test_date desc) as row_num, diagnosis from lab_results) as tab 
where row_num=1

-- revenue from bills

select drug_name,price,sum(quantity) as total_quantity_sold, sum(price*quantity) as total_revenue from prescriptions group by drug_name,price

-- the most frequent illnesses on people greater than 65 based on lab results

select 
	l.diagnosis,
	count(*) as diagnosed_count
from lab_results l 
left join patients p on p.patient_id = l.patient_id
where datediff(year,p.birth_date,test_date)>=65
group by diagnosis
order by diagnosed_count desc

-- alert table 
CREATE TABLE alerts (
    alert_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT,
    test_name VARCHAR(100),
    result_value VARCHAR(100),
    alert_time DATETIME DEFAULT GETDATE()
);

create trigger tg_lab_result 
on lab_results
after insert 
as begin
	insert into alerts (patient_id, test_name, result_value)
	select 
		patient_id,
		test_date,
		result_value
	from lab_results
	where result_value != normal_range
end 

-- doctors free day



-- no show percentage

select 100 * count(*)/cast((select count(*) from appointments) as numeric) from appointments where status = 'no-show'
