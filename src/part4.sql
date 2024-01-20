-- 1)  Create a stored procedure that, without destroying the database, destroys all those tables
-- in the current database whose names begin with the phrase 'TableName'.

CREATE TABLE IF NOT EXISTS TableName0();

CREATE OR REPLACE PROCEDURE drop_table_name() LANGUAGE PLPGSQL AS $$
DECLARE current_table TEXT;
BEGIN
	FOR current_table IN SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'TableName%'
	LOOP EXECUTE 'DROP TABLE IF EXISTS ' || current_table || ';';
	END LOOP;
END;
$$;
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
-- DO $$
-- DECLARE 
--     function_number INT;
-- BEGIN
--     function_number := 0;
--     CALL get_function_names_parameters(function_number);
-- 	RAISE NOTICE 'function_number: %', function_number;
-- END $$;

-----------------------------------------------------------------------------------------

