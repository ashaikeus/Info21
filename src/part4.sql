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


-- CREATE OR REPLACE FUNCTION get_function_names_parametres() RETURNS TABLE(function_number INT) LANGUAGE sql AS $$
-- 	SELECT routine_name || ' (' || ARRAY_TO_STRING(ARRAY_AGG(DISTINCT parameter_name), ', ') || ')' AS functions
-- 	FROM information_schema.routines
-- 	JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
-- 	WHERE information_schema.routines.specific_schema = 'public'
-- 	GROUP BY routine_name;
-- 	SELECT COUNT(DISTINCT routine_name)
-- 	FROM information_schema.routines
-- 	JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
-- 	WHERE information_schema.routines.specific_schema = 'public';
-- $$;
-- SELECT get_function_names_parametres();


CREATE OR REPLACE FUNCTION get_function_names_parametres(OUT function_number INT) LANGUAGE plpgsql AS $$
DECLARE current_function TEXT;
BEGIN
	FOR current_function IN SELECT routine_name || ' (' || ARRAY_TO_STRING(ARRAY_AGG(DISTINCT parameter_name), ', ') || ')' AS fnc
		FROM information_schema.routines
		JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
		WHERE information_schema.routines.specific_schema = 'public'
		GROUP BY routine_name
	LOOP RAISE NOTICE '%', fnc;
	END LOOP;
	SELECT COUNT(DISTINCT routine_name)
	FROM information_schema.routines
	JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
	WHERE information_schema.routines.specific_schema = 'public';
END;
$$;

SELECT get_function_names_parametres();