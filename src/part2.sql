
CREATE OR REPLACE PROCEDURE p2p_checked(
  IN checked VARCHAR,
  IN checking VARCHAR,
  IN taskName VARCHAR,
  IN p2p_state check_state,
  IN P2Ptime TIME
) LANGUAGE plpgsql AS 
$$ DECLARE last_p2p_check_state check_state = (
        SELECT state
        FROM p2p
        JOIN checks ON p2p.check_ = checks.id
        WHERE checkingpeer = checking AND
              peer = checked AND
              task = taskName
        ORDER BY p2p.id DESC LIMIT 1
    );
BEGIN
    IF p2p_state = '0' THEN
        IF last_p2p_check_state IS NULL OR last_p2p_check_state != '0' THEN
            INSERT INTO checks(id, peer, task, date)
            VALUES ((SELECT MAX(id) FROM checks) + 1, checked, taskName, CURRENT_DATE);

            INSERT INTO p2p(id, check_, checkingpeer, state, time)
            VALUES (
				(SELECT MAX(id) FROM p2p) + 1,
                (SELECT MAX(id) FROM checks),
                checking,
                p2p_state,
                P2Ptime
            );
        ELSE
            RAISE EXCEPTION 'Проверка уже началась.';
        END IF;
    ELSIF p2p_state IN ('1', '2') THEN
        IF last_p2p_check_state = '0' AND last_p2p_check_state IS NOT NULL THEN
            INSERT INTO p2p(id, check_, checkingpeer, state, time)
            VALUES (
				(SELECT MAX(id) FROM p2p) + 1,
                (SELECT MAX(check_)
                 FROM p2p
                 JOIN checks ON p2p.check_ = checks.id
                 WHERE checkingpeer = checking AND
                       peer = checked AND
                       task = taskName
                 ),
                checking,
                p2p_state,
                P2Ptime
            );
        ELSE
            RAISE EXCEPTION 'Ошибка добавления проверки.';
        END IF;
    END IF;
END;
$$

CREATE OR REPLACE PROCEDURE verter_check(
    checked_peer VARCHAR,
    taskName VARCHAR,
    verter_state check_state,
    verter_time TIME
) LANGUAGE plpgsql AS $$
DECLARE
    last_check int = (
        SELECT checks.id
        FROM checks
        JOIN p2p ON checks.id = p2p.check_
        WHERE peer = checked_peer AND
              task = taskName
        ORDER BY p2p.id DESC LIMIT 1
    );
BEGIN
    IF last_check IS NULL OR
       NOT exists(SELECT state FROM p2p WHERE check_ = last_check AND state = '1') THEN
        RAISE EXCEPTION 'Такой проверки нет.';
    END IF;
    IF verter_state = '0' AND
       exists(SELECT * FROM verter WHERE verter.check_ = last_check AND state = '0') THEN
        RAISE EXCEPTION 'Уже проверено.';
    END IF;
    IF verter_state IN ('1', '2') AND
       (exists(SELECT * FROM verter WHERE verter.check_ = last_check AND state IN ('1', '2')) OR
        NOT exists(SELECT * FROM verter WHERE verter.check_ = last_check AND state = '0')) THEN
        RAISE EXCEPTION 'Сначала начните проверку.';
    END IF;
    INSERT INTO verter(id, check_, state, time)
    VALUES (
		(SELECT MAX(id) FROM verter) + 1,
        last_check,
        verter_state,
        verter_time
   );
END;
$$

CREATE OR REPLACE FUNCTION fnc_update_transferredpoints()
    RETURNS trigger LANGUAGE 'plpgsql' AS
$$
DECLARE
    checked VARCHAR = (SELECT peer FROM checks WHERE id = NEW.check_ LIMIT 1);
BEGIN
    IF NEW.state = '0'
    THEN
        IF EXISTS(
            SELECT * FROM transferredpoints
            WHERE
                checkingpeer = NEW.checkingpeer AND
                checkedpeer = checked
        ) THEN
            UPDATE transferredpoints
            SET pointsAmount = pointsAmount + 1
            WHERE
                checkingpeer = NEW.checkingpeer AND
                checkedpeer = checked;
        ELSE
            INSERT INTO transferredpoints(id, checkingpeer, checkedpeer, pointsamount)
            VALUES ((SELECT MAX(id) FROM TransferredPoints) + 1, NEW.checkingpeer, checked, 1);
        END IF;
    END IF;
    RETURN NEW;
END;
$$

CREATE OR REPLACE TRIGGER trigger_update_transferredpoints
BEFORE INSERT ON P2P
FOR EACH ROW
EXECUTE PROCEDURE p2p_tranferred_points_change_trigger_fnc();


CREATE OR REPLACE FUNCTION fnc_update_xp()
    RETURNS trigger  LANGUAGE 'plpgsql' AS
$$
DECLARE
    max_xp INTEGER = (
        SELECT maxXP
        FROM tasks
        WHERE title = (SELECT task FROM checks WHERE checks.id = NEW.check_)
    );
    p2p_state check_state = (
        SELECT state
        FROM P2P
        WHERE P2P.check_ = NEW.check_
        ORDER BY P2P.id DESC LIMIT 1
    );
    verter_state check_state = (
        SELECT state
        FROM verter
        WHERE verter.check_ = NEW.check_
        ORDER BY verter.id DESC LIMIT 1
    );
    is_success_check bool = (
        SELECT p2p_state = '1' AND (verter_state IS NULL OR verter_state = '1')
    );
BEGIN
    IF NOT is_success_check THEN
        RAISE EXCEPTION 'Проверка провалена';
    ELSIF NEW.XPAmount > max_xp THEN
        RAISE EXCEPTION 'Неверное количество опыта';
    END IF;
    RETURN NEW;
END;
$$

CREATE OR REPLACE TRIGGER trigger_update_xp
BEFORE INSERT ON XP
FOR EACH ROW
EXECUTE PROCEDURE fnc_update_xp();

-- Вызовы для проверок
-- 1)
CALL p2p_checked('gdlzzcthpd', 'iosfiypdje', 'AP4', '1', '23:30:22');
CALL p2p_checked('gdlzzcthpd', 'iosfiypdje', 'AP4', '0', '23:30:22');
CALL p2p_checked('gdlzzcthpd', 'iosfiypdje', 'AP4', '2', '23:30:22');

-- результат
SELECT
*
FROM
    p2p p
INNER JOIN checks c ON c.id = p.check_
WHERE
    p.checkingpeer = 'iosfiypdje'
    AND peer = 'gdlzzcthpd'
ORDER BY
    c.id DESC
LIMIT 10

-- 2)
CALL verter_insert('gdlzzcthpd', 'AP4', '0', '00:30:22');

-- результат
SELECT
*
FROM
    transferredpoints p
WHERE
    p.checkingpeer = 'gdlzzcthpd'
ORDER BY
    c.id DESC

-- 3)
-- вызовы из пункта 1
-- результат
SELECT
*
FROM
    verter p
WHERE
    p.checkingpeer = 'gdlzzcthpd'
ORDER BY
    c.id DESC
-- 4)
INSERT INTO xp(id, check_, xpamount)
            VALUES ((SELECT MAX(id) FROM xp) + 1, 3, 800);

INSERT INTO xp(id, check_, xpamount)
            VALUES ((SELECT MAX(id) FROM xp) + 1, 14, 800);