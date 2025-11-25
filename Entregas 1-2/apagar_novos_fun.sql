set search_path to bd054_schema, public;

EXPLAIN ANALYZE
DELETE FROM Funcionarios
WHERE ID_fun BETWEEN 1001 AND 2000;