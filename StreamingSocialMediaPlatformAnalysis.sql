CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(50),
    signup_date DATE
);

INSERT INTO users VALUES
(1, 'Ali Karimov', '2024-01-10'),
(2, 'Dilnoza Abdullaeva', '2024-02-15'),
(3, 'Javohir Qosimov', '2024-03-05'),
(4, 'Malika Toirova', '2024-03-28'),
(5, 'Bekzod Ergashev', '2024-04-01');

CREATE TABLE videos (
    video_id INT PRIMARY KEY,
    user_id INT,
    title VARCHAR(100),
    category VARCHAR(50),
    upload_date DATE,
    status VARCHAR(20)
);

INSERT INTO videos VALUES
(1, 1, 'SQL Tutorial', 'Education', '2024-03-01', 'approved'),
(2, 2, 'Funny Cats', 'Entertainment', '2024-03-10', 'approved'),
(3, 1, 'Python Tips', 'Education', '2024-04-02', 'pending approval'),
(4, 3, 'Football Highlights', 'Sports', '2024-04-10', 'approved'),
(5, 4, 'Movie Review', 'Entertainment', '2024-04-11', 'approved');


CREATE TABLE views (
    view_id INT PRIMARY KEY,
    user_id INT,
    video_id INT,
    watch_duration INT, -- in minutes
    view_date DATE
);

INSERT INTO views VALUES
(1, 1, 2, 5, '2024-04-01'),
(2, 2, 1, 15, '2024-04-01'),
(3, 3, 1, 10, '2024-04-02'),
(4, 4, 3, 8, '2024-04-05'),
(5, 5, 4, 12, '2024-04-06');

CREATE TABLE subscriptions (
    subscription_id INT PRIMARY KEY,
    user_id INT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(20),
    cancel_reason VARCHAR(100)
);

INSERT INTO subscriptions VALUES
(1, 1, '2024-01-15', NULL, 'active', NULL),
(2, 2, '2024-02-20', '2024-04-10', 'cancelled', 'Too expensive'),
(3, 3, '2024-03-07', NULL, 'active', NULL),
(4, 4, '2024-04-01', NULL, 'active', NULL),
(5, 5, '2024-04-03', '2024-04-15', 'cancelled', 'Not useful');

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    user_id INT,
    amount DECIMAL(6,2),
    payment_date DATE
);

INSERT INTO payments VALUES
(1, 1, 9.99, '2024-01-15'),
(2, 2, 9.99, '2024-02-20'),
(3, 3, 9.99, '2024-03-07'),
(4, 4, 9.99, '2024-04-01'),
(5, 5, 9.99, '2024-04-03');

CREATE TABLE likes (
    like_id INT PRIMARY KEY,
    video_id INT,
    user_id INT
);

INSERT INTO likes VALUES
(1, 1, 2),
(2, 1, 3),
(3, 2, 1),
(4, 4, 5),
(5, 5, 4);

CREATE TABLE comments (
    comment_id INT PRIMARY KEY,
    video_id INT,
    user_id INT,
    comment_text TEXT,
    comment_date DATE
);

INSERT INTO comments VALUES
(1, 1, 3, 'Great video!', '2024-04-01'),
(2, 2, 1, 'Very funny!', '2024-04-02'),
(3, 4, 5, 'Nice match!', '2024-04-06'),
(4, 1, 2, 'Helpful tutorial', '2024-04-03'),
(5, 5, 4, 'Interesting review.', '2024-04-05');



-- view duration 

select * from views

select user_id, sum(watch_duration) as total_watch_duration from views group by user_id

-- engagement 
with likes_count as (
	select 
		video_id,
		count(*) as likes_count
	from likes group by video_id
), comments_count as (
	select 
		video_id,
		count(*) as commens_count
	from comments group by video_id
), viwes_count as (
	select 
		video_id,
		count(*) as viwes_count 
	from views group by video_id
)
select 
	v.video_id,
	coalesce(likes_count,0) as likes,
	coalesce(commens_count,0) as comments,
	coalesce(viwes_count,0) as views_cnt
from videos v 
left join  likes_count lc on lc.video_id = v.video_id
left join comments_count cc on cc.video_id = v.video_id
left join viwes_count vc on vc.video_id = v.video_id;

-- top on viewed content owners 

with viwes_count as (
	select 
		video_id,
		count(*) as viwes_count 
	from views group by video_id
)
select 
	v.user_id,
	sum(coalesce(vc.viwes_count,0)) as views_cnt
from videos v 
left join viwes_count vc on vc.video_id = v.video_id group by v.user_id order by views_cnt desc offset 0 rows fetch next 10 rows only 

-- percantage of users subscribed in last 30 days 
select (select count(*) from users)/100*count(*) as proportion from users where DATEDIFF(day,signup_date,getdate())<=30

-- subscription revenue 
with montly_revenue as (
	select YEAR(payment_date) as year,MONTH(payment_date) as month,sum(amount) as total_revenue from [dbo].[payments] group by MONTH(payment_date),YEAR(payment_date)
), users_number as (
	select count(*) as user_number from users
)
select * from users_number


-- pending approval trigger
create trigger tg_approval
on videos
instead of insert 
as begin 
	INSERT INTO videos (video_id, user_id, title, category, upload_date, status)
    SELECT 
        video_id, 
        user_id, 
        title, 
        category, 
        upload_date, 
        'pending approval' 
    FROM inserted
end

INSERT INTO videos (video_id, user_id, title, category, upload_date, status)
VALUES (6, 2, 'New Comedy Clip', 'Entertainment', '2024-05-02', 'approved');

-- cancellation reason
select subscription_id,user_id,end_date,status,cancel_reason from subscriptions where status='cancelled' and DATEDIFF(MONTH,end_date,GETDATE()) <= 3

-- total_income 

select 
	vw.video_id,
	v.duration/avg(vw.watch_duration) 
from views vw 
left join videos v on v.video_id = vw.video_id 
group by vw.video_id