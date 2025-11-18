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
    -- definem se as variáveis responsáveis pelo código da query, nome da query e etapa (antes ou depois)
)
-- o objetivo é inserir os resultados do benchmark na tabela benchmark_results, daí o RETURNS VOID
RETURNS VOID AS $$
-- variáveis para armazenar os resultados do EXPLAIN ANALYZE
DECLARE
plano JSON;
plan_time DOUBLE PRECISION;
exec_time DOUBLE PRECISION;
total_time DOUBLE PRECISION;
total_cost DOUBLE PRECISION;
rows_ret INT;
buf_hit INT;
buf_read INT;

-- corpo da função responsável por executar o EXPLAIN ANALYZE e deixar no formato json para se
-- extrairem os dados necessários mais facilmente
BEGIN 
EXECUTE 'EXPLAIN( ANALYZE, BUFFERS, FORMAT JSON) '|| query_code
    INTO plano;

-- extrai os dados do plano

plan_time := (plano -> 0 ->> 'Planning Time')::DOUBLE PRECISION;
exec_time := (plano -> 0 ->> 'Execution Time')::DOUBLE PRECISION;
total_time := (plan_time + exec_time)::DOUBLE PRECISION;
total_cost := (plano -> 0 -> 'Plan' ->> 'Total Cost')::DOUBLE PRECISION;
rows_ret := (plano -> 0 -> 'Plan' ->>  'Actual Rows')::INT;
buf_hit := (plano -> 0 -> 'Plan' ->> 'Shared Hit Blocks')::INT;
buf_read := (plano -> 0 -> 'Plan' ->> 'Shared Read Blocks')::INT;

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
   buffers_read
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

-- ====================================================================================================================================================
-- ====================================================================================================================================================

-- Daqui para a frente no documento vamos invocar a funnção para documentar os dados relevantes sobre as queries




SELECT run_benchmark(
        'SELECT
            f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
            s.salario_bruto AS salario_bruto
        FROM bd054_schema.funcionarios f
        LEFT JOIN bd054_schema.salario s ON f.id_fun = s.id_fun
        WHERE s.salario_bruto > (SELECT AVG(salario_bruto) FROM bd054_schema.salario)
        AND s.data_inicio = (
            SELECT MAX(s2.data_inicio)
            FROM bd054_schema.salario s2
            WHERE s2.id_fun = f.id_fun
        )
        ORDER BY salario_bruto DESC;',
    'Q03',
    'antes'
);
