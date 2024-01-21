SET datestyle = 'dmy'
---ex01

CREATE OR REPLACE FUNCTION transferred_points_hr()
RETURNS TABLE("Peer1" VARCHAR, "Peer2" VARCHAR, "PointsAmount" BIGINT) AS $$
BEGIN
	RETURN QUERY
	WITH sorted AS (
		SELECT
			CASE WHEN CheckingPeer < CheckedPeer 
		           THEN CheckedPeer 
		           ELSE CheckingPeer END AS Peer1,
			CASE WHEN CheckingPeer < CheckedPeer 
		           THEN CheckingPeer 
		           ELSE CheckedPeer END AS Peer2,
			CASE WHEN CheckingPeer < CheckedPeer 
		           THEN -PointsAmount 
		           ELSE PointsAmount END
		FROM TransferredPoints
	)
	SELECT Peer1, Peer2, SUM(PointsAmount) 
	FROM sorted
	GROUP BY 1, 2;
END;
$$ LANGUAGE plpgsql;

select * from transferred_points_hr();

---ex02

CREATE OR REPLACE FUNCTION finished_tasks()
RETURNS TABLE("Peer" VARCHAR, "Task" VARCHAR, "XP" INT) AS $$
BEGIN
	RETURN QUERY
	SELECT c.peer, task, xpamount
	FROM checks c
	JOIN xp ON xp.check_ = c.id
	JOIN verter v ON v.check_ = c.id
	WHERE v.state = '1';
END;
$$ LANGUAGE plpgsql;

select * from finished_tasks();

---ex03

CREATE OR REPLACE FUNCTION no_left_campus_peers(check_date DATE)
RETURNS TABLE("Peer" VARCHAR) AS $$
BEGIN
	RETURN QUERY
	WITH tracking_in AS (
		select peer, count(state) AS in_count
		from timetracking
		where check_date = "date" and state = '1'
		group by 1
	), tracking_exit AS (
		select peer, count(state) AS out_count
		from timetracking
		where check_date = "date" and state = '2'
		group by 1
	)
	select ti.peer
	from tracking_in ti
	join tracking_exit te on ti.peer = te.peer
	where ti.in_count > te.out_count;

END;
$$ LANGUAGE plpgsql;

select * from no_left_campus_peers('13.05.2022');

-----ex04

CREATE OR REPLACE FUNCTION calculatePeerPointsChange()
RETURNS TABLE("Peer" VARCHAR, "PointsChange" BIGINT) AS $$
BEGIN
	RETURN QUERY
	WITH sorted AS (
			SELECT
				CASE WHEN CheckingPeer < CheckedPeer 
					   THEN CheckedPeer 
					   ELSE CheckingPeer END AS Peer1,
				CASE WHEN CheckingPeer < CheckedPeer 
					   THEN CheckingPeer 
					   ELSE CheckedPeer END AS Peer2,
				CASE WHEN CheckingPeer < CheckedPeer 
					   THEN -PointsAmount 
					   ELSE PointsAmount END
			FROM TransferredPoints
		)
		SELECT Peer1, SUM(PointsAmount)
		FROM sorted
		GROUP BY 1
		ORDER BY 2 DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM calculatePeerPointsChange();
	
	
---ex05

CREATE OR REPLACE FUNCTION peer_point_change()
RETURNS TABLE("Peer" VARCHAR, "PointsChange" BIGINT) AS $$
BEGIN
	RETURN QUERY
	SELECT "Peer1", SUM("PointsAmount")::BIGINT
	FROM transferred_points_hr()
	GROUP BY 1
	ORDER BY 2 DESC;
END;
$$ LANGUAGE plpgsql;

SELECT  * FROM peer_point_change();

---ex06
CREATE OR REPLACE FUNCTION most_checked_tasks()
RETURNS TABLE("Day" DATE, "Task" VARCHAR) AS $$
BEGIN
	RETURN QUERY
	WITH daily_task_counts AS (
	  SELECT date , task, COUNT(id) AS TaskCount,
		 ROW_NUMBER() OVER (PARTITION BY date ORDER BY COUNT(id) DESC) AS RowNum
	  FROM checks
	  GROUP BY 1,2
	)
	SELECT date,  task
	FROM daily_task_counts
	WHERE RowNum = 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM most_checked_tasks();

---ex07


CREATE OR REPLACE FUNCTION peers_finished_blocks(blockname VARCHAR)
RETURNS TABLE("Peer" VARCHAR, "Day" DATE) AS $$
BEGIN
	RETURN QUERY
	SELECT c.peer, c.date
	FROM checks c
	JOIN xp ON xp.check_ = c.id
	WHERE task IN ( select max(title) from tasks
					where title like blockname || '%');
END;
$$ LANGUAGE plpgsql;


select * from peers_finished_blocks('SQL');


---ex08

INSERT INTO peers (nickname,  birthday)
VALUES ('Gayespel', '22.02.2001'),
('Gaylordr', '11.09.2000'),
('Leygoods', '19.11.1999'),
('Rightspo', '09.05.2004'),
('Gigachad', '01.01.2001'),
('Pablous', '24.03.1997');

INSERT INTO friends (id, peer1, peer2)
VALUES ((SELECT MAX(id) + 1 from friends),'Gayespel', 'Leygoods'),
((SELECT MAX(id) + 2 from friends),'Gayespel', 'Gaylordr'),
((SELECT MAX(id) + 3 from friends),'Gayespel', 'Rightspo'),
((SELECT MAX(id) + 4 from friends),'Gigachad', 'Leygoods'),
((SELECT MAX(id) + 5 from friends),'Gigachad', 'Gayespel'),
((SELECT MAX(id) + 6 from friends),'Gigachad', 'Gaylordr'),
((SELECT MAX(id) + 7 from friends),'Gigachad', 'Pablous'),
((SELECT MAX(id) + 8 from friends),'Gaylordr', 'Rightspo');


INSERT INTO recommendations (id, peer, recommendedpeer)
VALUES ((SELECT MAX(id) + 1 from recommendations),'Gayespel', 'Leygoods'),
((SELECT MAX(id) + 2 from recommendations),'Leygoods', 'Gayespel'),
((SELECT MAX(id) + 3 from recommendations),'Gayespel', 'Rightspo'),
((SELECT MAX(id) + 4 from recommendations),'Gigachad', 'Leygoods'),
((SELECT MAX(id) + 5 from recommendations),'Leygoods', 'Gigachad'),
((SELECT MAX(id) + 6 from recommendations),'Gaylordr', 'Gigachad'),
((SELECT MAX(id) + 7 from recommendations),'Pablous', 'Gigachad'),
((SELECT MAX(id) + 8 from recommendations),'Gaylordr', 'Rightspo'),
((SELECT MAX(id) + 9 from recommendations),'Leygoods', 'Rightspo');


CREATE OR REPLACE FUNCTION best_peer_to_check()
RETURNS TABLE("Peer" VARCHAR, "RecommendedPeer" VARCHAR) AS $$
BEGIN
	RETURN QUERY
	WITH all_friends AS (
		SELECT peer1 as peer, peer2  as friend FROM friends
		UNION ALL
		SELECT peer2 as peer, peer1 as friend FROM friends),
	count_rec AS (
		SELECT p.nickname, recommendedpeer, COUNT(recommendedpeer)
		FROM peers p
		JOIN all_friends af ON p.nickname = af.peer
		JOIN recommendations r ON r.peer = af.friend
		WHERE p.nickname != r.recommendedpeer
		GROUP BY 1,2),
	max_rec AS (
		SELECT nickname, recommendedpeer, 
		ROW_NUMBER() OVER (PARTITION BY nickname ORDER BY count DESC) AS rn
		FROM count_rec)
	SELECT nickname, recommendedpeer FROM max_rec
	WHERE rn = 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM best_peer_to_check();

--ex09

CREATE OR REPLACE FUNCTION peers_started_blocks(block1 VARCHAR, block2 VARCHAR)
RETURNS TABLE("StartedBlock1" BIGINT, "StartedBlock2" BIGINT, "StartedBothBlock" BIGINT, "DidntStartAnyBlock" BIGINT) AS $$
BEGIN
	RETURN QUERY
	with sb_one AS (
		SELECT DISTINCT peer
		From checks c
		WHERE task LIKE block1 || '%'
	),
	sb_two AS (
		SELECT DISTINCT peer
		From checks c
		WHERE task LIKE block2 || '%'
	),
	both_bl AS (
		select *
		from sb_one
		INTERSECT
		select *
		from sb_two
	),
	no_blocks AS (
		select distinct peer
		from checks
		except
		(select * from sb_one
		union
		select * from sb_two)),
	all_checks AS (
		select
			(select count(*) from sb_one)+
	  		(select count(*) from sb_two)+
	  		(select count(*) from both_bl)+
	  		(select count(*) from no_blocks))
	select
	  100 * (select count(*) from sb_one) / (select * from all_checks),
	  100 * (select count(*) from sb_two) / (select * from all_checks),
	  100 * (select count(*) from both_bl) / (select * from all_checks),
	  100 - (100 * (select count(*) from sb_one) / (select * from all_checks))-
	  (100 * (select count(*) from sb_two) / (select * from all_checks))-
	  (100 * (select count(*) from both_bl) / (select * from all_checks));
	
END;
$$ LANGUAGE plpgsql;

select *
from peers_started_blocks('SQL','A');


--ex10

CREATE OR REPLACE FUNCTION birthday_checks()
RETURNS TABLE("SuccessfulChecks" BIGINT, "UnsuccessfulChecks" BIGINT) AS $$
BEGIN
	RETURN QUERY
	with success_ch AS
		(select distinct  c.peer
		from checks c
		join xp on xp.check_ = c.id
		join peers p on p.nickname = c.peer
		WHERE extract(day from p.birthday) = extract(day from c.date)
		and extract(month from p.birthday) = extract(month from c.date)
		),
	all_checks as
	(select distinct c.peer
		from checks c
		join peers p on p.nickname = c.peer
		WHERE extract(day from p.birthday) = extract(day from c.date)
		and extract(month from p.birthday) = extract(month from c.date))
	select 100 *(select count(*) from success_ch)/(select count(*) from all_checks),
		   100 - 100 * (select count(*) from success_ch)/(select count(*) from all_checks);
	
	
END;
$$ LANGUAGE plpgsql;

select * from birthday_checks();

--ex11

CREATE OR REPLACE FUNCTION peers_completed_tasks(blockname varchar)
RETURNS TABLE ("Peer" varchar) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT c.peer
    FROM checks c
    WHERE c.task = blockname || '1' AND c.peer NOT IN (
        SELECT DISTINCT c.peer
        FROM checks c
        WHERE task = blockname || '3'
    )
    INTERSECT
    SELECT DISTINCT c.peer
    FROM checks c
    WHERE c.task = blockname || '2' AND c.peer NOT IN (
        SELECT DISTINCT peer
        FROM checks
        WHERE task = blockname || '3'
    );
END;
$$ LANGUAGE plpgsql;

select * from peers_completed_tasks('CPP');


--ex12


CREATE OR REPLACE FUNCTION previous_tasks()
RETURNS TABLE("Task" VARCHAR, "PrevCount" int) AS $$
BEGIN
	RETURN QUERY
	WITH RECURSIVE prev_tasks AS (
		SELECT title, 0 AS Level
		FROM Tasks
		WHERE ParentTask = 'None'

		UNION ALL

		SELECT t.title, pv.Level + 1 AS Level
		FROM Tasks t
		JOIN prev_tasks pv ON t.ParentTask = pv.title
	)
	SELECT title, level
	FROM prev_tasks;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM previous_tasks();

---- ex13
-- Найти «удачные» для проверок дни. День считается «удачным», если в нем есть хотя бы N идущих подряд успешных проверки
-- Параметры процедуры: количество идущих подряд успешных проверок N. 
-- Временем проверки считать время начала P2P этапа. 
-- Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных. 
-- При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального. 
-- Формат вывода: список дней.


CREATE OR REPLACE FUNCTION lucky_days(checks_amount bigint)
RETURNS TABLE("LuckyDays" Date) AS $$
BEGIN
	RETURN QUERY
	WITH eighty_percent AS  (
		SELECT * FROM xp
		JOIN checks c ON c.id = xp.check_
		JOIN tasks t ON t.title = c.task
		WHERE xpamount * 100 / maxxp >= 80
		),
	is_passed AS  (
	SELECT 	c.date, time, CASE WHEN ep.xpamount IS NULL THEN 0 ELSE 1 END AS status
		FROM checks c
		JOIN p2p ON p2p.check_ = c.id
		FULL OUTER JOIN eighty_percent ep ON ep.check_ = c.id
		ORDER BY c.date, p2p.time),
	lucky_day AS(
	SELECT date, time, status, CASE WHEN status = 1 THEN status + LAG(status) OVER (PARTITION BY date ORDER BY date, time) ELSE 0 END AS lucky_count
	FROM is_passed)
	SELECT DISTINCT date
	FROM lucky_day
	WHERE lucky_count >= checks_amount;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM lucky_days(1);


--ex14

CREATE OR REPLACE FUNCTION max_xp_peer()
RETURNS TABLE("Peer" VARCHAR, "Xp" bigint) AS $$
BEGIN
	RETURN QUERY
	select peer, sum(xpamount) as xp 
	from xp
	join checks c on c.id = xp.check_
	group by 1
	order by 2 desc
	limit 1;
END;
$$ LANGUAGE plpgsql;

select *  from max_xp_peer();

-- ex15
-- Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
-- Параметры процедуры: время, количество раз N. 
-- Формат вывода: список пиров.


CREATE OR REPLACE FUNCTION peers_who_enter(entertime time, enter_amount bigint)
RETURNS TABLE("Peer" VARCHAR) AS $$
BEGIN
	RETURN QUERY
	WITH entriers AS
		(select peer, count(id)
		from timetracking t
		where state = '1' and entertime > t.time
		GROUP BY 1
		)
	SELECT peer FROM entriers
	WHERE count >= enter_amount;
END;
$$ LANGUAGE plpgsql;

select * from peers_who_enter('15:00', 5);

----ex16
-- Определить пиров, выходивших за последние N дней из кампуса больше M раз
-- Параметры процедуры: количество дней N, количество раз M. 
-- Формат вывода: список пиров.

CREATE OR REPLACE FUNCTION peers_who_exit(last_days bigint, exit_amount bigint)
RETURNS TABLE("Peer" VARCHAR) AS $$
BEGIN
	RETURN QUERY
	
	WITH entriers AS
		(select peer, count(id)
		from timetracking t
		where state = '2' and 
		 date <= (select max(date) from timetracking) 
		  and date >= (select max(date) - last_days::int from timetracking)
		GROUP BY 1
		)
	SELECT peer FROM entriers
	WHERE count > exit_amount;
END;
$$ LANGUAGE plpgsql;

select * from peers_who_exit(14,1);

--ex17

CREATE OR REPLACE FUNCTION early_entiers_percentage()
RETURNS TABLE("Month" VARCHAR, "EarlyEntiers" bigint) AS $$
BEGIN
	RETURN QUERY
	WITH all_entriers AS
		(select id, time, TO_CHAR(date, 'Month') as month
		from timetracking t
		join peers p ON p.nickname = t.peer
		where state = '1' and extract(month from date) = extract(month from birthday))
	,entriers_am AS (
		SELECT COUNT(id), month
		FROM all_entriers
		WHERE  time < '12:0:0'
		GROUP BY month
		),
	all_ent_count AS (SELECT COUNT(id), month FROM all_entriers
					  GROUP BY month)
	SELECT aec.month::varchar, 100 * eam.count / aec.count
	FROM entriers_am eam
	JOIN all_ent_count aec ON aec.month = eam.month;
END;
$$ LANGUAGE plpgsql;

select *  from early_entiers_percentage();