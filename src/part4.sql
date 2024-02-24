-- 1)  Create a stored procedure that, without destroying the database, destroys all those tables
-- in the current database whose names begin with the phrase 'TableName'.
-- создание тестовой таблицы для проверки:
-- CREATE TABLE IF NOT EXISTS TableName0();

CREATE OR REPLACE PROCEDURE drop_table_name() LANGUAGE PLPGSQL AS $$
DECLARE current_table TEXT;
BEGIN
	FOR current_table IN SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'TableName%'
	LOOP EXECUTE 'DROP TABLE IF EXISTS ' || current_table || ';';
	END LOOP;
END;
$$;
-- для вызова:
-- CALL drop_table_name();

-----------------------------------------------------------------------------------------

-- 2) Create a stored procedure with an output parameter that outputs a list of names and parameters
-- of all scalar user's SQL functions in the current database.
-- Do not output function names without parameters.
-- The names and the list of parameters must be in one string.
-- The output parameter returns the number of functions found.

CREATE OR REPLACE PROCEDURE get_function_names_parameters(OUT function_number INT) LANGUAGE plpgsql AS $$
DECLARE
	current_function RECORD;
BEGIN
	function_number := 0;
	FOR current_function IN SELECT routine_name || ' (' || ARRAY_TO_STRING(ARRAY_AGG(DISTINCT parameter_name), ', ') || ')' AS fnc
		FROM information_schema.routines
		JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
		WHERE information_schema.routines.specific_schema = 'public'
		GROUP BY routine_name
	LOOP
		function_number := function_number + 1;
		RAISE NOTICE '%', current_function;
	END LOOP;
END;
$$;
-- для вызова:
-- DO $$
-- DECLARE 
--     function_number INT;
-- BEGIN
--     function_number := 0;
--     CALL get_function_names_parameters(function_number);
-- 	RAISE NOTICE 'function_number: %', function_number;
-- END $$;

-----------------------------------------------------------------------------------------

-- 3) Create a stored procedure with output parameter, which destroys all SQL DML triggers
-- in the current database. The output parameter returns the number of destroyed triggers.

-- создание тестового триггера для проверки:
-- CREATE OR REPLACE FUNCTION test_trigger_fun() RETURNS trigger AS $$ BEGIN RAISE NOTICE 'begin again'; END; $$ LANGUAGE plpgsql;
-- CREATE OR REPLACE TRIGGER test_trigger BEFORE UPDATE ON peers FOR EACH ROW EXECUTE PROCEDURE test_trigger_fun();

CREATE OR REPLACE PROCEDURE destroy_triggers(OUT trigger_number INT) LANGUAGE plpgsql AS $$
DECLARE
	current_trigger RECORD;
BEGIN
	trigger_number := 0;
	FOR current_trigger IN SELECT *
		FROM information_schema.triggers
	LOOP
		EXECUTE 'DROP TRIGGER IF EXISTS ' || current_trigger.trigger_name || ' ON ' || current_trigger.event_object_table;
		trigger_number := trigger_number + 1;
	END LOOP;
END;
$$;
-- для вызова:
-- DO $$
-- DECLARE 
--     trigger_number INT;
-- BEGIN
--     trigger_number := 0;
--     CALL destroy_triggers(trigger_number);
-- 	RAISE NOTICE 'trigger_number: %', trigger_number;
-- END $$;

-----------------------------------------------------------------------------------------

-- 4) Create a stored procedure with an input parameter that outputs names and descriptions
-- of object types (only stored procedures and scalar functions) that have a string
-- specified by the procedure parameter.

CREATE OR REPLACE PROCEDURE get_object_names_descriptions(IN string TEXT) LANGUAGE plpgsql AS $$
DECLARE
	current_function RECORD;
BEGIN
	FOR current_function IN SELECT *
		FROM information_schema.routines
		WHERE routine_type IN ('PROCEDURE', 'FUNCTION')
		AND information_schema.routines.specific_schema = 'public'
		AND information_schema.routines.routine_name LIKE '%' || string || '%'
	LOOP
		RAISE NOTICE '%', current_function.routine_name;
	END LOOP;
END;
$$;
-- для вызова:
-- CALL get_object_names_descriptions('destroy');