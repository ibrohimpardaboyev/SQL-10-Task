CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    username VARCHAR(100),
    followers INT,
    engagement_rate DECIMAL(5, 2)
);

CREATE TABLE Posts (
    post_id INT PRIMARY KEY,
    user_id INT,
    post_date DATE,
    likes INT,
    comments INT,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Followers (
    follower_id INT PRIMARY KEY,
    user_id INT, 
    follower_user_id INT, 
    follow_date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Post_Likes (
    like_id INT PRIMARY KEY,
    post_id INT,
    user_id INT, 
    like_date DATE,
    FOREIGN KEY (post_id) REFERENCES Posts(post_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

INSERT INTO Users VALUES
(1, 'user_ali', 15000, 0),
(2, 'user_vali', 8500, 0),
(3, 'user_dilshod', 12000, 0),
(4, 'user_malika', 3500, 0),
(5, 'user_shohruh', 20000, 0);

INSERT INTO Posts VALUES
(1, 1, '2025-04-01', 250, 30),
(2, 1, '2025-04-03', 200, 40),
(3, 2, '2025-04-02', 100, 15),
(4, 3, '2025-04-05', 400, 50),
(5, 4, '2025-04-06', 60, 10),
(6, 5, '2025-04-01', 500, 100);

INSERT INTO Followers VALUES
(1, 1, 2, '2025-01-01'),
(2, 1, 3, '2025-01-02'),
(3, 1, 5, '2025-01-03'),
(4, 2, 3, '2025-02-01'),
(5, 2, 4, '2025-02-02'),
(6, 3, 1, '2025-03-01'),
(7, 3, 4, '2025-03-02'),
(8, 4, 5, '2025-04-01');


INSERT INTO Post_Likes VALUES
(1, 1, 1, '2025-04-01'),
(2, 1, 2, '2025-04-02'),
(3, 2, 3, '2025-04-02'),
(4, 3, 1, '2025-04-06'),
(5, 4, 5, '2025-04-06'),
(6, 6, 1, '2025-04-01'),
(7, 5, 2, '2025-04-01');

-- engagement rate 	
create view whole_users as
select 
	us.user_id,
	username,
	followers,
	case when engagement is null then 0 else engagement end as engagement
from 
users us left join 
(select 
	user_id, 
	round(cast(count(*) as float)/(select count(*) from Posts),2)*100 as engagement 
from Post_Likes 
group by user_id) u on u.user_id = us.user_id

-- influencer 

select 
	* 
from whole_users where engagement>=5 and followers>10000

-- users who posted the most 

select user_id, count(*) as total_number_of_postes from Posts group by user_id order by total_number_of_postes desc
select user_id,sum(likes) as total_likes from posts group by user_id order by total_likes desc

-- average daily likes and comments count
select 
	post_id,
	user_id,
	post_date, 
	round(cast(likes as float) / datediff(day, post_date, GETDATE()),2) as avg_daily_likes_count,
	round(cast(comments as float) / datediff(day, post_date, GETDATE()) ,2) as avg_daily_comments_count
from Posts

-- most liked postes

select post_id,user_id,likes,comments from Posts order by likes desc
-- ghost followers 
select * from whole_users where engagement = 0
select * from [dbo].[Posts]

select post_id, datediff(, post_date,CAST(GETDATE() AS DATE)) from Posts