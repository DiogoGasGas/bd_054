set search_path to benchmark_schema, public;

-- primeiro de tudo, cria se uma tabela para armazenar os resultados do benchmark
 


CREATE TABLE benchmark_results (
    id SERIAL PRIMARY KEY,
    query_name TEXT,
    etapa TEXT,                   -- 'antes' ou 'depois'
    planning_time DOUBLE PRECISION,
    execution_time DOUBLE PRECISION,
    total_time DOUBLE PRECISION,
    total_cost DOUBLE PRECISION,
    rows_returned INT,
    buffers_hit INT,
    buffers_read INT,
    execution_date TIMESTAMP DEFAULT NOW()
); 


-- Função para executar o benchmark de uma query específica

CREATE OR REPLACE FUNCTION run_benchmark(
    query_code TEXT,
    query_name TEXT,
    etapa TEXT
)
RETURNS VOID AS $$
DECLARE
plano JSON;
plan_time DOUBLE PRECISION;
exec_time DOUBLE PRECISION;
total_time DOUBLE PRECISION;
total_cost DOUBLE PRECISION;
rows_ret INT;
buf_hit INT;
buf_read INT;


BEGIN 
EXECUTE 'EXPLAIN( ANALYZE, BUFFERS, FORMAT JSON) '|| query_code
    INTO plano;

-- extrai os dados do plano

plan_time := (plano -> 0 -> 'Planning Time');
exec_time := (plano -> 0 -> 'Execution Time');
total_time := (plan_time + exec_time);
total_cost := (plano -> 0 -> 'Plan' ->> 'Total Cost');
rows_ret := (plano -> 0 -> 'Plan' ->>  'Actual Rows');
buf_hit := (plano -> 0 -> 'Plan' ->> 'Shared Hit Blocks');
buf_read := (plano -> 0 -> 'Plan' ->> 'Shared Read Blocks');

-- inserir rsultados na tabela benchmark_results

INSERT INTO benchmark_results(
   query_name,
   etapa,
   planning_time,
   execution_time,
   total_time,
   total_cost,
   rows_returned,
   buffers_hit,
   buffers_read,
   execution_date
)
VALUES( 
    query_name,
    etapa,
    plan_time,
    exec_time,
    total_time,
    total_cost,
    rows_ret,
    buf_hit,
    buf_read
);
END;
$$ LANGUAGE plpgsql;
