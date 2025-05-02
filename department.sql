CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    department VARCHAR(50),
    position_id INT,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE positions (
    position_id INT PRIMARY KEY,
    title VARCHAR(50),
    level VARCHAR(20)
);

CREATE TABLE salaries (
    salary_id INT PRIMARY KEY,
    employee_id INT,
    salary_amount DECIMAL(10,2),
    effective_date DATE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY,
    employee_id INT,
    attendance_date DATE,
    status VARCHAR(20) -- 'Present', 'Absent', 'Late'
);

CREATE TABLE leaves (
    leave_id INT PRIMARY KEY,
    employee_id INT,
    leave_start DATE,
    leave_end DATE,
    leave_type VARCHAR(20) -- 'Annual', 'Sick', etc.
);

CREATE TABLE audit_log (
    log_id INT PRIMARY KEY IDENTITY,
    employee_id INT,
    changed_field VARCHAR(50),
    old_value VARCHAR(100),
    new_value VARCHAR(100),
    change_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE interviews (
    interview_id INT PRIMARY KEY,
    employee_id INT,
    interview_date DATE,
    result VARCHAR(10) 
);

INSERT INTO positions VALUES
(1, 'Software Engineer', 'Mid'),
(2, 'HR Specialist', 'Junior'),
(3, 'Accountant', 'Senior');

INSERT INTO employees (employee_id, full_name, department, position_id, hire_date, status) VALUES
(1, 'Ali Valiyev', 'IT', 1, '2021-01-10', 'active'),
(2, 'Laylo Karimova', 'HR', 2, '2022-05-15', 'active'),
(3, 'John Doe', 'Finance', 3, '2023-03-20', 'active'),
(4, 'Sara Smith', 'IT', 1, '2024-02-10', 'active');

INSERT INTO salaries VALUES
(1, 1, 5000.00, '2024-11-01'),
(2, 1, 5300.00, '2025-01-01'),
(3, 1, 5500.00, '2025-04-01'),
(4, 2, 4000.00, '2025-01-01'),
(5, 3, 4500.00, '2025-02-01'),
(6, 3, 4700.00, '2025-03-01'),
(7, 4, 3000.00, '2025-03-01');

INSERT INTO attendance VALUES
(1, 1, '2025-04-01', 'Late'),
(2, 1, '2025-04-02', 'Late'),
(3, 1, '2025-04-03', 'Late'),
(4, 2, '2025-04-01', 'Present'),
(5, 2, '2025-04-02', 'Late'),
(6, 2, '2025-04-03', 'Present'),
(7, 3, '2025-04-01', 'Late'),
(8, 3, '2025-04-02', 'Late'),
(9, 3, '2025-04-03', 'Late'),
(10, 3, '2025-04-04', 'Late'),
(11, 4, '2025-04-01', 'Present');

INSERT INTO leaves VALUES
(1, 1, '2024-12-20', '2024-12-25', 'Annual'),
(2, 2, '2025-02-10', '2025-02-11', 'Sick'),
(3, 3, '2025-01-15', '2025-01-16', 'Annual'),
(4, 4, '2025-01-05', '2025-01-07', 'Annual');

INSERT INTO interviews VALUES
(1, 1, '2020-12-25', 'Passed'),
(2, 2, '2022-04-01', 'Passed'),
(3, 3, '2023-02-25', 'Passed'),
(4, 4, '2024-01-20', 'Passed');

-- last 6 month salary change
with numbered as (
	select 
		ROW_NUMBER() over (partition by employee_id order by effective_date desc) as row_num, * 
	from salaries
	where datediff(month,effective_date,getdate()) <= 6
)
select 
	employee_id,
	min(salary_amount) as salary_min,
	max(salary_amount) as salary_max,
	max(salary_amount) - min(salary_amount) as change
from salaries group by employee_id

--each department info

create view current_salary as
select s.employee_id,s.salary_amount from salaries s join
(select 
	employee_id,
	max(effective_date) as effective_date
from salaries
group by employee_id) s1 on s1.employee_id = s.employee_id and s.effective_date = s1.effective_date


select department,count(*) as employee_count from employees group by department order by employee_count desc
select department,sum(cs.salary_amount) * 12 as yearly_salary from employees e join current_salary cs on e.employee_id = cs.employee_id group by department
select department,avg(cs.salary_amount) as average_salary from employees e join current_salary cs on e.employee_id = cs.employee_id group by department

-- the most delay day for every employee
with delayed as (
	select employee_id,DATENAME(DAY,attendance_date) as day_num,count(*) over (partition by employee_id,DATENAME(DAY,attendance_date)) as cnt from attendance
), delayed_max_count as (
	select employee_id, max(cnt) as cnt from delayed group by employee_id
) 

select d.employee_id,day_num,d.cnt from delayed d join delayed_max_count dmc on d.employee_id = dmc.employee_id and d.cnt = dmc.cnt

-- warn employees who is late to work on 3 or more days 
create view warning_alert as 
select 
	employee_id,
	sum(case when status='Late' then 1 else 0 end) as late_count,
	case
		when sum(case when status='Late' then 1 else 0 end) >= 3 then 'warnig' else 'no warning'
	end as status 
from attendance 
group by employee_id


select * from warning_alert

-- employees who leaves the least 

select employee_id,sum(DATEDIFF(DAY,leave_start,leave_end)) as total_leave_days from leaves group by employee_id

--	l;oyalty calculation

select 
	employee_id,
	DATEDIFF(YEAR,hire_date,GETDATE()) as loayalty_in_years
from employees

-- audit log

CREATE TRIGGER trg_log_employee_updates
ON employees
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit_log (employee_id, changed_field, old_value, new_value)
    SELECT
        i.employee_id,
        'full_name',
        d.full_name,
        i.full_name
    FROM inserted i
    JOIN deleted d ON i.employee_id = d.employee_id
    WHERE ISNULL(i.full_name, '') <> ISNULL(d.full_name, '');

    INSERT INTO audit_log (employee_id, changed_field, old_value, new_value)
    SELECT
        i.employee_id,
        'department',
        d.department,
        i.department
    FROM inserted i
    JOIN deleted d ON i.employee_id = d.employee_id
    WHERE ISNULL(i.department, '') <> ISNULL(d.department, '');

    INSERT INTO audit_log (employee_id, changed_field, old_value, new_value)
    SELECT
        i.employee_id,
        'position_id',
        CAST(d.position_id AS VARCHAR),
        CAST(i.position_id AS VARCHAR)
    FROM inserted i
    JOIN deleted d ON i.employee_id = d.employee_id
    WHERE ISNULL(i.position_id, -1) <> ISNULL(d.position_id, -1);
END;

-- average hiring days by each department

select [department],avg(DATEDIFF(DAY,interview_date,hire_date)) as avg_hiring_days from interviews i join employees e on i.employee_id = e.employee_id group by department