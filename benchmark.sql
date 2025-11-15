

-- começa se por criar uma tabela para armazenar os dados obtidos no benchmarking

CREATE TABLE benchmark_results (
    id SERIAL PRIMARY KEY,
    query_name TEXT,
    etapa TEXT,                   -- 'antes' ou 'depois'
    planning_time DOUBLE PRECISION,
    execution_time DOUBLE PRECISION,
    total_time DOUBLE PRECISION,
    rows_returned INT,
    buffers_hit INT,
    buffers_read INT,
    execution_date TIMESTAMP DEFAULT NOW()
);

-- após criar a tabela, cria-se uma função que retira automaticamente os valores obtidos no explain analyse e insere na tabela
