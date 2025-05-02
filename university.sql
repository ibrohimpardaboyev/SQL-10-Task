CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    name VARCHAR(50),
    enrollment_date DATE
);

INSERT INTO Students VALUES
(1, 'Ali Karimov', '2022-09-01'),
(2, 'Dilnoza Abdullaeva', '2022-09-01'),
(3, 'Javohir Qosimov', '2023-01-15'),
(4, 'Malika Toirova', '2023-01-15'),
(5, 'Bekzod Ergashev', '2022-09-01');

CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(100),
    teacher_id INT,
    semester VARCHAR(10),
    deadline DATE
);

INSERT INTO Courses VALUES
(1, 'Database Systems', 1, '2024S', '2024-06-15'),
(2, 'Data Structures', 2, '2024S', '2024-06-10'),
(3, 'Algorithms', 1, '2024S', '2024-06-20'),
(4, 'Statistics', 3, '2024S', '2024-06-12'),
(5, 'AI Basics', 2, '2024S', '2024-06-25');

CREATE TABLE Teachers (
    teacher_id INT PRIMARY KEY,
    name VARCHAR(50),
    department VARCHAR(50)
);

INSERT INTO Teachers VALUES
(1, 'Dr. Ahmadov', 'Computer Science'),
(2, 'Ms. Usmonova', 'Software Engineering'),
(3, 'Mr. Tursunov', 'Mathematics'),
(4, 'Mrs. Yun', 'AI'),
(5, 'Dr. Lee', 'Data Science');

CREATE TABLE Enrollments (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    enroll_date DATE,
    completion_date DATE
);

INSERT INTO Enrollments VALUES
(1, 1, 1, '2024-02-01', '2024-06-14'),
(2, 2, 1, '2024-02-01', '2024-06-16'),
(3, 3, 2, '2024-02-01', '2024-06-09'),
(4, 4, 3, '2024-02-01', '2024-06-22'),
(5, 5, 4, '2024-02-01', '2024-06-10');

CREATE TABLE Grades (
    grade_id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    grade DECIMAL(4,2)
);

INSERT INTO Grades VALUES
(1, 1, 1, 4.0),
(2, 2, 1, 3.2),
(3, 3, 2, 2.8),
(4, 4, 3, 1.9),
(5, 5, 4, 3.5);

-- average gpa and top 10 high graded students
create view students_avg_gpa as
select 
	g.student_id,
	avg(grade) as avg_gpa
from grades g left join Students s on g.student_id = s.student_id
group by g.student_id
order by avg_gpa desc 
offset 0 rows 
fetch next 10 rows only;

-- compleated on time

select 
	e.course_id, 
	enroll_date,
	completion_date,
	deadline,
	case 
		when deadline>=completion_date then 'Yes'
		else 'No'
	end as compleated_on_time
from Enrollments e 
join Courses c on e.course_id = c.course_id
select * from [dbo].[Teachers]

create table pass_fail_scores
(
	teacher_id int,
	status varchar(50),
	low_grade float,
	high_grade float
)
insert into pass_fail_scores values
(5,'fail',0,3.5),
(5,'pass',3.6,5)

-- avg grade
select 
	course_id,
	avg(grade) as average_grade 
from Grades 
group by course_id 

-- success rate 

select 
	g.course_id,
	sum(case when status = 'pass' then 1 else 0 end)*100/count(*) as success_rate
from grades g join Courses c on g.course_id = c.course_id 
left join pass_fail_scores p on c.teacher_id = p.teacher_id where low_grade<=g.grade and g.grade<=high_grade group by g.course_id

-- fail rate 

select 
	g.course_id,
	avg(g.grade),
	sum(case when status = 'fail' then 1 else 0 end)*100/count(*) as fail_rate
from grades g join Courses c on g.course_id = c.course_id 
left join pass_fail_scores p on c.teacher_id = p.teacher_id where low_grade<=g.grade and g.grade<=high_grade group by g.course_id 

-- teacher's courses fail and success rate

select 
	c.teacher_id,
	count(*) as courses,
	sum(case when status = 'pass' then 1 else 0 end)*100/count(*) as pass_rate,
	100-sum(case when status = 'pass' then 1 else 0 end)*100/count(*) as fail_rate
from grades g join Courses c on g.course_id = c.course_id 
left join pass_fail_scores p on c.teacher_id = p.teacher_id where low_grade<=g.grade and g.grade<=high_grade group by c.teacher_id

-- procedure 

create procedure enroll_student
(
	@enrollment_id int,
	@student_id int,
	@course_id int,
	@enroll_date date,
	@compeltion_date date,
	@semester varchar(20),
	@teacher_id int,
	@course_name varchar(10),
	@deadline date
)
as 
begin 
	insert into Enrollments values (@enrollment_id,@student_id,@course_id,@enroll_date,@compeltion_date);
	insert into Courses values (@course_id, @course_name, @teacher_id, @semester, @deadline);
end