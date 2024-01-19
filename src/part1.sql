CREATE TYPE check_state AS ENUM('0', '1', '2');
CREATE TYPE in_or_out_state AS ENUM('1', '2');

SET datestyle = 'dmy';

CREATE TABLE peers (
	nickname VARCHAR(255) PRIMARY KEY,
	birthday DATE
);

CREATE TABLE tasks (
	title VARCHAR(255) PRIMARY KEY,
	parenttask VARCHAR(255),
	maxXP BIGINT
);

CREATE TABLE checks (
	id BIGINT PRIMARY KEY,
	peer VARCHAR(255) REFERENCES peers(nickname),
	task VARCHAR(255) REFERENCES tasks(title),
	date DATE
);

CREATE TABLE P2P (
	id BIGINT PRIMARY KEY,
	check_ BIGINT REFERENCES checks(id),
	checkingpeer VARCHAR(255) REFERENCES peers(nickname),
	state check_state,
	time TIME
);

CREATE TABLE verter (
	id BIGINT PRIMARY KEY,
	check_ BIGINT REFERENCES checks(id),
	state check_state,
	time TIME
);

CREATE TABLE transferredpoints (
	id BIGINT PRIMARY KEY,
	checkingpeer VARCHAR(255) REFERENCES peers(nickname),
	checkedpeer VARCHAR(255) REFERENCES peers(nickname),
	pointsAmount INTEGER
);

CREATE TABLE friends (
	id BIGINT PRIMARY KEY,
	peer1 VARCHAR(255) REFERENCES peers(nickname),
	peer2 VARCHAR(255) REFERENCES peers(nickname)
);

CREATE TABLE recommendations (
	id BIGINT PRIMARY KEY,
	peer VARCHAR(255) REFERENCES peers(nickname),
	recommendedPeer VARCHAR(255) REFERENCES peers(nickname)
);

CREATE TABLE XP (
	id BIGINT PRIMARY KEY,
	check_ BIGINT REFERENCES checks(id),
	XPAmount INTEGER
);

CREATE TABLE timetracking (
	id BIGINT PRIMARY KEY,
	peer VARCHAR(255) REFERENCES peers(nickname),
	date DATE,
	time TIME,
	state in_or_out_state 
);

CREATE OR REPLACE PROCEDURE from_csv(table_name_ VARCHAR(30), csv_separator VARCHAR(1) DEFAULT ';')
LANGUAGE PLPGSQL
AS $$
DECLARE
	csv_path VARCHAR = 'D:\SQL2_Info21_v1.0-2\src\CSV\' || table_name_ || '.csv';
BEGIN
	EXECUTE 'copy ' || table_name_ || ' from ''' || csv_path || ''' delimiter ''' || csv_separator || ''' csv header';
END;
$$;

CREATE OR REPLACE PROCEDURE to_csv(table_name_ VARCHAR(30), csv_separator VARCHAR(1) DEFAULT ';')
LANGUAGE PLPGSQL
AS $$
DECLARE
	csv_path VARCHAR = 'D:\SQL2_Info21_v1.0-2\src\CSV\' || table_name_ || '.csv';
BEGIN
	EXECUTE 'copy ' || table_name_ || ' to ''' || csv_path || ''' delimiter ''' || csv_separator || ''' csv header';
END;
$$;

CALL from_csv('peers');
CALL from_csv('tasks');
CALL from_csv('checks');
CALL from_csv('friends');
CALL from_csv('p2p');
CALL from_csv('recommendations');
CALL from_csv('timetracking');
CALL from_csv('transferredpoints');
CALL from_csv('verter');
CALL from_csv('xp');

-- CALL to_csv('xp');