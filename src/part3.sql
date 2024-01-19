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
	SELECT Peer1 AS "Peer", SUM(PointsAmount) AS "PointsChange"
	FROM sorted
	GROUP BY 1
	ORDER BY 2 DESC;
	
	
---ex05

SELECT "Peer1" AS "Peer", SUM("PointsAmount") AS "PointsChange"
FROM transferred_points_hr()
GROUP BY 1
ORDER BY 2 DESC;


---ex06

WITH daily_task_counts AS (
  SELECT date , task, COUNT(id) AS TaskCount,
  	 ROW_NUMBER() OVER (PARTITION BY date ORDER BY COUNT(id) DESC) AS RowNum
  FROM checks
  GROUP BY 1,2
)
SELECT date AS "Day",  task AS "Task"
FROM daily_task_counts
WHERE RowNum = 1;


---ex07


CREATE OR REPLACE FUNCTION peers_finished_blocks(blockname VARCHAR)
RETURNS TABLE("Peer" VARCHAR, "Day" DATE) AS $$
BEGIN
	RETURN QUERY
	SELECT c.peer, c.date
	FROM checks c
	JOIN verter v ON v.check_ = c.id
	WHERE v.state = '1' AND task LIKE  blockname || '%';
END;
$$ LANGUAGE plpgsql;


select * from peers_finished_blocks('SQL');



