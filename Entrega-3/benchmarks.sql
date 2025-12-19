-- ===================================================================================================================================================
-- Neste ficheiro criamos uma tabela para registar os resultados dos benchmarks
-- Nessa tabela vamos inserir os resultados antes de criar os indices, depois de criar índices, e depois de criar os indices e otimizar as queries
-- ===================================================================================================================================================



set search_path to benchmark_schema, public;
-- CORRER ANTES DE CRIAR ÍNDICES E OTIMIZAÇÕES
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
    buffers_read INT
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

-- 1. FASE DE WARM-UP (Aquecimento)
    -- ==========================================
    -- Executamos a query uma vez. O EXPLAIN (ANALYZE) garante que o código é corrido, 
    -- carregando os dados do disco (cold) para a memória (warm).
    EXECUTE 'EXPLAIN (ANALYZE) ' || query_code; 

    -- ==========================================
    -- 2. FASE DE BENCHMARK REAL
    -- ==========================================
    -- Agora que a cache está quente, medimos o desempenho real.
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

-- Daqui para a frente no documento vamos invocar a função para documentar os dados relevantes sobre as queries
set search_path to bd054_schema, public;

-- Tabelas principais
ANALYZE funcionarios;
ANALYZE departamentos;

-- Tabelas de remuneração
ANALYZE remuneracoes;
ANALYZE salario;
ANALYZE beneficios;

-- Tabelas de gestão de pessoal
ANALYZE ferias;
ANALYZE dependentes;
ANALYZE faltas;
ANALYZE historico_empresas;

-- Tabelas de recrutamento
ANALYZE candidatos;
ANALYZE vagas;
ANALYZE candidato_a;
ANALYZE requisitos_vaga;

-- Tabelas de formação e avaliação
ANALYZE formacoes;
ANALYZE teve_formacao;
ANALYZE avaliacoes;

-- Tabelas de sistema
ANALYZE utilizadores;
ANALYZE permissoes;


-- ====================================================================
-- Benchmarks ANTES DE CRIAR ÍNDICES E OTIMIZAÇÕES
-- ====================================================================


set search_path to benchmark_schema, public;

DO $$
BEGIN
    PERFORM run_benchmark(
        'SELECT
      d.nome,             
      COUNT(f.id_fun) AS total_funcionarios 
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
    ON d.id_depart= f.id_depart
    GROUP BY d.nome
    ORDER BY total_funcionarios DESC;',
        'Q01',
        'antes'
    );

    PERFORM run_benchmark(
        'SELECT
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_bruto AS salario_bruto
    FROM bd054_schema.funcionarios f
    LEFT JOIN bd054_schema.salario s ON f.id_fun = s.id_fun
    WHERE s.salario_bruto > (
        SELECT AVG(salario_bruto)
        FROM bd054_schema.salario
    )
    AND s.data_inicio = (
        SELECT MAX(s2.data_inicio)
        FROM bd054_schema.salario s2
        WHERE s2.id_fun = f.id_fun
    )
    ORDER BY salario_bruto DESC;',
        'Q02',
        'antes'
    );

    PERFORM run_benchmark(
        'SELECT 
        d.nome, 
        SUM(s.salario_bruto) AS tot_remun 
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
        ON d.id_depart = f.id_depart
    LEFT JOIN bd054_schema.salario AS s 
        ON f.id_fun = s.id_fun
    WHERE s.data_inicio = (
        SELECT MAX(s2.data_inicio)
        FROM bd054_schema.salario s2
        WHERE s2.id_fun = f.id_fun
    )
    GROUP BY d.nome
    ORDER BY tot_remun DESC;',
        'Q03',
        'antes'
    );

    PERFORM run_benchmark(
        'SELECT
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_liquido AS salario_liquido
    FROM bd054_schema.funcionarios AS f
    LEFT JOIN bd054_schema.salario AS s
        ON f.id_fun = s.id_fun
    WHERE s.data_inicio = (
        SELECT MAX(s2.data_inicio)
        FROM bd054_schema.salario s2
        WHERE s2.id_fun = f.id_fun
    )
    ORDER BY salario_liquido DESC
    LIMIT 3;',
        'Q04',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT
        d.nome,                   
        ROUND(AVG(fer.num_dias),0) AS media_dias_ferias     
    FROM bd054_schema.departamentos AS d
    JOIN bd054_schema.funcionarios AS f 
    ON d.id_depart = f.id_depart
    JOIN bd054_schema.ferias AS fer 
    ON f.id_fun = fer.id_fun
    GROUP BY d.nome;',
        'Q05',
        'antes'
    );


    -- Q06: Inserção manual dos resultados do benchmark para não dar erro devido à função utilizada na query
INSERT INTO benchmark_results (
    query_name,
    etapa,
    planning_time,
    execution_time,
    total_time,
    total_cost,
    rows_returned,
    buffers_hit,
    buffers_read
) VALUES (
    'Q06',
    'antes',  -- ajuste conforme necessário ('antes' ou 'depois')
    0.226,
    1.411,
    0.226 + 1.411,
    5.16,
    2,
    NULL,  -- não especificado no EXPLAIN ANALYZE
    NULL   -- não especificado no EXPLAIN ANALYZE
);

    PERFORM run_benchmark(
        'SELECT  
            f.id_fun,
            f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
            SUM(b.valor) AS tot_benef
        FROM bd054_schema.funcionarios AS f
        JOIN bd054_schema.beneficios AS b 
            ON f.id_fun = b.id_fun
        WHERE b.tipo = ''Seguro Saúde''
        GROUP BY nome_completo, f.id_fun
        HAVING SUM(b.valor) > (
            SELECT AVG(valor) 
            FROM bd054_schema.beneficios
            WHERE tipo = ''Seguro Saúde''
        )
        ORDER BY f.id_fun ASC;',
        'Q07',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT
      f.id_fun,
      f.primeiro_nome,
      fer.num_dias,
      fer.data_inicio
    FROM bd054_schema.funcionarios AS f
    JOIN bd054_schema.ferias AS fer 
      ON f.id_fun = fer.id_fun
    WHERE fer.num_dias = (
      SELECT MAX(num_dias) 
      FROM bd054_schema.ferias 
      WHERE estado_aprov = ''Aprovado''
    )
    ORDER BY f.id_fun;',
        'Q08',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT
        d.nome AS nome_depart,
        COALESCE(AVG(a.avaliacao_numerica), 0) AS media_aval,
        AVG(s.salario_bruto) AS media_salario
    FROM bd054_schema.funcionarios AS f
    RIGHT JOIN bd054_schema.departamentos AS d
        ON d.id_depart = f.id_depart
    JOIN bd054_schema.avaliacoes AS a 
        ON f.id_fun = a.id_fun
    JOIN bd054_schema.salario AS s
        ON f.id_fun = s.id_fun
    GROUP BY d.nome
    HAVING AVG(s.salario_bruto) > (
        SELECT AVG(salario_bruto)
        FROM bd054_schema.salario
    )
    ORDER BY media_aval DESC;',
        'Q09',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT
        f.id_fun, 
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_funcionario,
        dep.nome AS nome_dep,
        STRING_AGG(d.nome || '' ('' || d.parentesco || '')'', '', '') AS dependentes
    FROM bd054_schema.dependentes AS d
    JOIN bd054_schema.funcionarios AS f 
        ON d.id_fun = f.id_fun
    JOIN bd054_schema.departamentos AS dep 
        ON f.id_depart = dep.id_depart
    GROUP BY f.id_fun, f.primeiro_nome, f.ultimo_nome, dep.nome
    ORDER BY nome_funcionario;',
        'Q10',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT
        dep.id_depart,
        dep.nome AS nome_depart,
        COUNT(v.id_vaga) AS num_vagas,
        COALESCE(AVG(cand_a.num_cand), 0) AS media_candidatos
    FROM bd054_schema.departamentos AS dep
    LEFT JOIN bd054_schema.vagas AS v
        ON v.id_depart = dep.id_depart
    LEFT JOIN (
        SELECT 
            id_vaga, 
            COUNT(id_cand) AS num_cand
        FROM bd054_schema.candidato_a
        GROUP BY id_vaga
    ) AS cand_a
        ON cand_a.id_vaga = v.id_vaga
    GROUP BY dep.id_depart, dep.nome
    ORDER BY media_candidatos DESC;',
        'Q11',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT 
        f.id_fun,
        f.primeiro_nome,
        COUNT(d.id_fun) AS num_dependentes
    FROM bd054_schema.funcionarios AS f
    LEFT JOIN bd054_schema.dependentes AS d
        ON f.id_fun = d.id_fun
    GROUP BY f.id_fun, f.primeiro_nome
    ORDER BY num_dependentes DESC;',
        'Q12',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT 
            f.primeiro_nome,
            f.ultimo_nome,
            av.autoavaliacao
        FROM bd054_schema.funcionarios AS f 
        JOIN bd054_schema.avaliacoes AS av
        ON f.id_fun = av.id_fun
        -- se a autoavaliacao é null, é porque não existe avaliação preenchida
        WHERE av.autoavaliacao IS NULL;',
        'Q13',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT 
        d.id_depart,
        d.nome,
        COUNT(fal.id_fun) AS total_faltas,
        COUNT(fal.justificacao) AS total_faltas_just
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
        ON d.id_depart = f.id_depart
    LEFT JOIN bd054_schema.faltas AS fal 
        ON f.id_fun = fal.id_fun
    GROUP BY d.id_depart, d.nome
    ORDER BY total_faltas DESC;',
        'Q14',
        'antes'
    );

    PERFORM run_benchmark(
        'SELECT 
        d.nome, 
        COUNT(f.id_fun) AS numero_funcionarios,
        AVG(s.salario_bruto) AS media_salarial_departamento
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
        ON d.id_depart = f.id_depart
    LEFT JOIN bd054_schema.salario AS s 
        ON f.id_fun = s.id_fun
    WHERE s.data_inicio = (
        SELECT MAX(s2.data_inicio) 
        FROM bd054_schema.salario s2 
        WHERE s2.id_fun = f.id_fun
    )
    GROUP BY d.nome
    HAVING AVG(s.salario_bruto) > (
        SELECT AVG(s_avg.salario_bruto)
        FROM bd054_schema.salario s_avg
        WHERE s_avg.data_inicio = (
            SELECT MAX(s_max.data_inicio)
            FROM bd054_schema.salario s_max
            WHERE s_max.id_fun = s_avg.id_fun
        )
    )
    ORDER BY media_salarial_departamento DESC;',
        'Q15',
        'antes'
    );

    PERFORM run_benchmark(
        'SELECT 
        h.nome_empresa, 
        STRING_AGG(f.primeiro_nome || '' '' || f.ultimo_nome, '', '') AS funcionarios
    FROM bd054_schema.historico_empresas AS h
    JOIN bd054_schema.funcionarios AS f 
        ON f.id_fun = h.id_fun
    GROUP BY h.nome_empresa
    HAVING COUNT(f.id_fun) > 1;',
        'Q16',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT 
  f.id_fun,
  f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
  COUNT(fal.data) AS total_faltas
FROM bd054_schema.funcionarios AS f
LEFT JOIN bd054_schema.faltas AS fal 
  ON f.id_fun = fal.id_fun
GROUP BY f.id_fun, f.primeiro_nome, f.ultimo_nome
-- filtrar funcionários que têm a soma de faltas igual a 0
HAVING COUNT(fal.data) = 0
ORDER BY f.id_fun;',
        'Q17',
        'antes'
    );



    -- Q18: Inserção manual dos resultados do benchmark para não dar erro devido à função utilizada na query
INSERT INTO benchmark_results (
    query_name,
    etapa,
    planning_time,
    execution_time,
    total_time,
    total_cost,
    rows_returned,
    buffers_hit,
    buffers_read
) VALUES (
    'Q18',
    'antes',  
    0.525,
    4.358,
    0.525 + 4.358,
    353.99,
    8,
    NULL,  
    NULL  
);


    PERFORM run_benchmark(
        'SELECT DISTINCT
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_bruto AS salario_atual,
        b.tipo AS tipo_beneficio,
        h.nome_empresa AS trabalhou_em
    FROM bd054_schema.funcionarios AS f
    JOIN bd054_schema.remuneracoes AS r 
        ON f.id_fun = r.id_fun
        AND r.data_inicio = (
            SELECT MAX(r2.data_inicio) 
            FROM bd054_schema.remuneracoes r2 
            WHERE r2.id_fun = f.id_fun
        )
    JOIN bd054_schema.salario AS s 
        ON r.id_fun = s.id_fun 
        AND r.data_inicio = s.data_inicio
        AND s.salario_bruto > 1500
    JOIN bd054_schema.beneficios AS b
        ON r.id_fun = b.id_fun 
        AND r.data_inicio = b.data_inicio
        AND b.tipo = ''Seguro Saúde''
    JOIN bd054_schema.historico_empresas AS h 
        ON f.id_fun = h.id_fun 
        AND h.nome_empresa = ''Moura'';',
        'Q19',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT 
        f.id_fun, 
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        sal.salario_bruto AS salario_atual,
        d.nome AS nome_departamento,
        (
            SELECT COUNT(*) 
            FROM bd054_schema.teve_formacao AS teve
            WHERE teve.id_fun = f.id_fun
        ) AS num_formacoes
    FROM bd054_schema.funcionarios AS f 
    LEFT JOIN bd054_schema.departamentos AS d 
        ON f.id_depart = d.id_depart
    LEFT JOIN bd054_schema.salario AS sal 
        ON f.id_fun = sal.id_fun
    WHERE sal.data_inicio = (
            SELECT MAX(s_main.data_inicio)
            FROM bd054_schema.salario s_main
            WHERE s_main.id_fun = f.id_fun
        )
    AND sal.salario_bruto > (
            SELECT AVG(s2.salario_bruto)
            FROM bd054_schema.funcionarios AS f2
            LEFT JOIN bd054_schema.salario AS s2 
                ON f2.id_fun = s2.id_fun
            WHERE f2.id_depart = f.id_depart
              AND s2.data_inicio = (
                  SELECT MAX(s3.data_inicio)
                  FROM bd054_schema.salario s3
                  WHERE s3.id_fun = f2.id_fun
              )
        )
    ORDER BY nome_departamento, salario_atual DESC;',
        'Q20',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT 
        f.id_fun,
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_liquido,
        SUM(DISTINCT fe.num_dias) AS ferias_aprovadas,
        COUNT(d.sexo) AS num_dep_fem
    FROM bd054_schema.funcionarios AS f
    JOIN bd054_schema.salario AS s 
        ON f.id_fun = s.id_fun
    JOIN bd054_schema.ferias AS fe
        ON f.id_fun = fe.id_fun
    JOIN bd054_schema.dependentes AS d
        ON f.id_fun = d.id_fun
    WHERE 
        d.sexo = ''Feminino''
        AND s.salario_liquido > 1500
        AND fe.estado_aprov = ''Aprovado''
    GROUP BY 
        f.id_fun, 
        nome_completo, 
        s.salario_liquido;',
        'Q21',
        'antes'
    );


    PERFORM run_benchmark(
        'SELECT 
        d.nome,
        f.id_depart, 
        COALESCE(AVG(dep.num_fem),0) AS media_fem
    FROM (
        SELECT 
            id_fun, 
            COUNT(*) AS num_fem
        FROM bd054_schema.dependentes
        WHERE sexo = ''Feminino''
        GROUP BY id_fun
    ) AS dep
    RIGHT JOIN bd054_schema.funcionarios AS f 
        ON f.id_fun = dep.id_fun
    RIGHT JOIN bd054_schema.departamentos AS d 
        ON d.id_depart = f.id_depart
    GROUP BY d.nome, f.id_depart;',
        'Q22',
        'antes'
    );
END $$;


-- ====================================================================
-- CRIAR INDICES AQUI
-- Crirar benchramks depois de criar índices
-- ====================================================================================================================================================


set search_path to bd054_schema, public;
-- Tabelas principais
ANALYZE funcionarios;
ANALYZE departamentos;

-- Tabelas de remuneração
ANALYZE remuneracoes;
ANALYZE salario;
ANALYZE beneficios;

-- Tabelas de gestão de pessoal
ANALYZE ferias;
ANALYZE dependentes;
ANALYZE faltas;
ANALYZE historico_empresas;

-- Tabelas de recrutamento
ANALYZE candidatos;
ANALYZE vagas;
ANALYZE candidato_a;
ANALYZE requisitos_vaga;

-- Tabelas de formação e avaliação
ANALYZE formacoes;
ANALYZE teve_formacao;
ANALYZE avaliacoes;

-- Tabelas de sistema
ANALYZE utilizadores;
ANALYZE permissoes;


set search_path to benchmark_schema, public;

DO $$
BEGIN

    PERFORM run_benchmark(
        'SELECT
      d.nome,             
      COUNT(f.id_fun) AS total_funcionarios 
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
    ON d.id_depart= f.id_depart
    GROUP BY d.nome
    ORDER BY total_funcionarios DESC;',
        'Q01',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_bruto AS salario_bruto
    FROM bd054_schema.funcionarios f
    LEFT JOIN bd054_schema.salario s ON f.id_fun = s.id_fun
    WHERE s.salario_bruto > (
        SELECT AVG(salario_bruto)
        FROM bd054_schema.salario
    )
    AND s.data_inicio = (
        SELECT MAX(s2.data_inicio)
        FROM bd054_schema.salario s2
        WHERE s2.id_fun = f.id_fun
    )
    ORDER BY salario_bruto DESC;',
        'Q02',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        d.nome, 
        SUM(s.salario_bruto) AS tot_remun 
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
        ON d.id_depart = f.id_depart
    LEFT JOIN bd054_schema.salario AS s 
        ON f.id_fun = s.id_fun
    WHERE s.data_inicio = (
        SELECT MAX(s2.data_inicio)
        FROM bd054_schema.salario s2
        WHERE s2.id_fun = f.id_fun
    )
    GROUP BY d.nome
    ORDER BY tot_remun DESC;',
        'Q03',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_liquido AS salario_liquido
    FROM bd054_schema.funcionarios AS f
    LEFT JOIN bd054_schema.salario AS s
        ON f.id_fun = s.id_fun
    WHERE s.data_inicio = (
        SELECT MAX(s2.data_inicio)
        FROM bd054_schema.salario s2
        WHERE s2.id_fun = f.id_fun
    )
    ORDER BY salario_liquido DESC
    LIMIT 3;',
        'Q04',
        'depois indices'
    );


INSERT INTO benchmark_results (
    query_name,
    etapa,
    planning_time,
    execution_time,
    total_time,
    total_cost,
    rows_returned,
    buffers_hit,
    buffers_read
) VALUES (
    'Q06',
    'depois indices',
    0.254,
    1.493,
    0.254 + 1.493,
    5.16,
    2,
    NULL,  -- não especificado no EXPLAIN ANALYZE
    NULL   -- não especificado no EXPLAIN ANALYZE
);


    PERFORM run_benchmark(
        'SELECT  
            f.id_fun,
            f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
            SUM(b.valor) AS tot_benef
        FROM bd054_schema.funcionarios AS f
        JOIN bd054_schema.beneficios AS b 
            ON f.id_fun = b.id_fun
        WHERE b.tipo = ''Seguro Saúde''
        GROUP BY nome_completo, f.id_fun
        HAVING SUM(b.valor) > (
            SELECT AVG(valor) 
            FROM bd054_schema.beneficios
            WHERE tipo = ''Seguro Saúde''
        )
        ORDER BY f.id_fun ASC;',
        'Q07',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT
      f.id_fun,
      f.primeiro_nome,
      fer.num_dias,
      fer.data_inicio
    FROM bd054_schema.funcionarios AS f
    JOIN bd054_schema.ferias AS fer 
      ON f.id_fun = fer.id_fun
    WHERE fer.num_dias = (
      SELECT MAX(num_dias) 
      FROM bd054_schema.ferias 
      WHERE estado_aprov = ''Aprovado''
    )
    ORDER BY f.id_fun;',
        'Q08',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT
        d.nome AS nome_depart,
        COALESCE(AVG(a.avaliacao_numerica), 0) AS media_aval,
        AVG(s.salario_bruto) AS media_salario
    FROM bd054_schema.funcionarios AS f
    RIGHT JOIN bd054_schema.departamentos AS d
        ON d.id_depart = f.id_depart
    JOIN bd054_schema.avaliacoes AS a 
        ON f.id_fun = a.id_fun
    JOIN bd054_schema.salario AS s
        ON f.id_fun = s.id_fun
    GROUP BY d.nome
    HAVING AVG(s.salario_bruto) > (
        SELECT AVG(salario_bruto)
        FROM bd054_schema.salario
    )
    ORDER BY media_aval DESC;',
        'Q09',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT
        f.id_fun, 
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_funcionario,
        dep.nome AS nome_dep,
        STRING_AGG(d.nome || '' ('' || d.parentesco || '')'', '', '') AS dependentes
    FROM bd054_schema.dependentes AS d
    JOIN bd054_schema.funcionarios AS f 
        ON d.id_fun = f.id_fun
    JOIN bd054_schema.departamentos AS dep 
        ON f.id_depart = dep.id_depart
    GROUP BY f.id_fun, f.primeiro_nome, f.ultimo_nome, dep.nome
    ORDER BY nome_funcionario;',
        'Q10',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT
        dep.id_depart,
        dep.nome AS nome_depart,
        COUNT(v.id_vaga) AS num_vagas,
        COALESCE(AVG(cand_a.num_cand), 0) AS media_candidatos
    FROM bd054_schema.departamentos AS dep
    LEFT JOIN bd054_schema.vagas AS v
        ON v.id_depart = dep.id_depart
    LEFT JOIN (
        SELECT 
            id_vaga, 
            COUNT(id_cand) AS num_cand
        FROM bd054_schema.candidato_a
        GROUP BY id_vaga
    ) AS cand_a
        ON cand_a.id_vaga = v.id_vaga
    GROUP BY dep.id_depart, dep.nome
    ORDER BY media_candidatos DESC;',
        'Q11',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        f.id_fun,
        f.primeiro_nome,
        COUNT(d.id_fun) AS num_dependentes
    FROM bd054_schema.funcionarios AS f
    LEFT JOIN bd054_schema.dependentes AS d
        ON f.id_fun = d.id_fun
    GROUP BY f.id_fun, f.primeiro_nome
    ORDER BY num_dependentes DESC;',
        'Q12',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        d.id_depart,
        d.nome,
        COUNT(fal.id_fun) AS total_faltas,
        COUNT(fal.justificacao) AS total_faltas_just
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
        ON d.id_depart = f.id_depart
    LEFT JOIN bd054_schema.faltas AS fal 
        ON f.id_fun = fal.id_fun
    GROUP BY d.id_depart, d.nome
    ORDER BY total_faltas DESC;',
        'Q14',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        d.nome, 
        COUNT(f.id_fun) AS numero_funcionarios,
        AVG(s.salario_bruto) AS media_salarial_departamento
    FROM bd054_schema.departamentos AS d
    LEFT JOIN bd054_schema.funcionarios AS f 
        ON d.id_depart = f.id_depart
    LEFT JOIN bd054_schema.salario AS s 
        ON f.id_fun = s.id_fun
    WHERE s.data_inicio = (
        SELECT MAX(s2.data_inicio) 
        FROM bd054_schema.salario s2 
        WHERE s2.id_fun = f.id_fun
    )
    GROUP BY d.nome
    HAVING AVG(s.salario_bruto) > (
        SELECT AVG(s_avg.salario_bruto)
        FROM bd054_schema.salario s_avg
        WHERE s_avg.data_inicio = (
            SELECT MAX(s_max.data_inicio)
            FROM bd054_schema.salario s_max
            WHERE s_max.id_fun = s_avg.id_fun
        )
    )
    ORDER BY media_salarial_departamento DESC;',
        'Q15',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        h.nome_empresa, 
        STRING_AGG(f.primeiro_nome || '' '' || f.ultimo_nome, '', '') AS funcionarios
    FROM bd054_schema.historico_empresas AS h
    JOIN bd054_schema.funcionarios AS f 
        ON f.id_fun = h.id_fun
    GROUP BY h.nome_empresa
    HAVING COUNT(f.id_fun) > 1;',
        'Q16',
        'depois indices'
    );

INSERT INTO benchmark_results (
    query_name,
    etapa,
    planning_time,
    execution_time,
    total_time,
    total_cost,
    rows_returned,
    buffers_hit,
    buffers_read
) VALUES (
    'Q18',
    'depois indices',
    1.049,
    4.747,
    1.049 + 4.747,
    353.99,
    8,
    NULL,  -- não especificado no EXPLAIN ANALYZE
    NULL   -- não especificado no EXPLAIN ANALYZE
);


    PERFORM run_benchmark(
        'SELECT DISTINCT
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_bruto AS salario_atual,
        b.tipo AS tipo_beneficio,
        h.nome_empresa AS trabalhou_em
    FROM bd054_schema.funcionarios AS f
    JOIN bd054_schema.remuneracoes AS r 
        ON f.id_fun = r.id_fun
        AND r.data_inicio = (
            SELECT MAX(r2.data_inicio) 
            FROM bd054_schema.remuneracoes r2 
            WHERE r2.id_fun = f.id_fun
        )
    JOIN bd054_schema.salario AS s 
        ON r.id_fun = s.id_fun 
        AND r.data_inicio = s.data_inicio
        AND s.salario_bruto > 1500
    JOIN bd054_schema.beneficios AS b
        ON r.id_fun = b.id_fun 
        AND r.data_inicio = b.data_inicio
        AND b.tipo = ''Seguro Saúde''
    JOIN bd054_schema.historico_empresas AS h 
        ON f.id_fun = h.id_fun 
        AND h.nome_empresa = ''Moura'';',
        'Q19',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        f.id_fun, 
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        sal.salario_bruto AS salario_atual,
        d.nome AS nome_departamento,
        (
            SELECT COUNT(*) 
            FROM bd054_schema.teve_formacao AS teve
            WHERE teve.id_fun = f.id_fun
        ) AS num_formacoes
    FROM bd054_schema.funcionarios AS f 
    LEFT JOIN bd054_schema.departamentos AS d 
        ON f.id_depart = d.id_depart
    LEFT JOIN bd054_schema.salario AS sal 
        ON f.id_fun = sal.id_fun
    WHERE sal.data_inicio = (
            SELECT MAX(s_main.data_inicio)
            FROM bd054_schema.salario s_main
            WHERE s_main.id_fun = f.id_fun
        )
    AND sal.salario_bruto > (
            SELECT AVG(s2.salario_bruto)
            FROM bd054_schema.funcionarios AS f2
            LEFT JOIN bd054_schema.salario AS s2 
                ON f2.id_fun = s2.id_fun
            WHERE f2.id_depart = f.id_depart
              AND s2.data_inicio = (
                  SELECT MAX(s3.data_inicio)
                  FROM bd054_schema.salario s3
                  WHERE s3.id_fun = f2.id_fun
              )
        )
    ORDER BY nome_departamento, salario_atual DESC;',
        'Q20',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        f.id_fun,
        f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
        s.salario_liquido,
        SUM(DISTINCT fe.num_dias) AS ferias_aprovadas,
        COUNT(d.sexo) AS num_dep_fem
    FROM bd054_schema.funcionarios AS f
    JOIN bd054_schema.salario AS s 
        ON f.id_fun = s.id_fun
    JOIN bd054_schema.ferias AS fe
        ON f.id_fun = fe.id_fun
    JOIN bd054_schema.dependentes AS d
        ON f.id_fun = d.id_fun
    WHERE 
        d.sexo = ''Feminino''
        AND s.salario_liquido > 1500
        AND fe.estado_aprov = ''Aprovado''
    GROUP BY 
        f.id_fun, 
        nome_completo, 
        s.salario_liquido;',
        'Q21',
        'depois indices'
    );

    PERFORM run_benchmark(
        'SELECT 
        d.nome,
        f.id_depart, 
        COALESCE(AVG(dep.num_fem),0) AS media_fem
    FROM (
        SELECT 
            id_fun, 
            COUNT(*) AS num_fem
        FROM bd054_schema.dependentes
        WHERE sexo = ''Feminino''
        GROUP BY id_fun
    ) AS dep
    RIGHT JOIN bd054_schema.funcionarios AS f 
        ON f.id_fun = dep.id_fun
    RIGHT JOIN bd054_schema.departamentos AS d 
        ON d.id_depart = f.id_depart
    GROUP BY d.nome, f.id_depart;',
        'Q22',
        'depois indices'
    );
    

END $$;


-- =======================================================================
-- BENCHMARKS COM INDICES E OTIMIZAÇÕES AQUI
-- ======================================================================


DO $$
BEGIN
    PERFORM run_benchmark(
        'SELECT
  d.nome,
  COALESCE(contagem.total, 0) AS total_funcionarios
FROM bd054_schema.departamentos AS d
LEFT JOIN (
  SELECT id_depart, COUNT(*) AS total
  FROM bd054_schema.funcionarios
  GROUP BY id_depart
) AS contagem ON d.id_depart = contagem.id_depart
ORDER BY total_funcionarios DESC;',
        'Q01',
        'depois indices e otimizacao'
    );

    PERFORM run_benchmark(
      'SELECT 
  f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
  s_recentes.salario_bruto
FROM bd054_schema.funcionarios f
LEFT JOIN (
  SELECT DISTINCT ON (id_fun) 
    id_fun, 
    salario_bruto
  FROM bd054_schema.salario
  ORDER BY id_fun, Data_inicio DESC
) s_recentes ON f.id_fun = s_recentes.id_fun
WHERE s_recentes.salario_bruto > (SELECT AVG(salario_bruto) FROM bd054_schema.salario)
ORDER BY s_recentes.salario_bruto DESC;',
      'Q02',
      'depois indices e otimizacao'
    );


    PERFORM run_benchmark(
      'WITH SalariosRecentes AS (
  SELECT DISTINCT ON (id_fun)
    id_fun,
    salario_bruto
  FROM bd054_schema.salario
  ORDER BY id_fun, Data_inicio DESC
)
SELECT
  d.nome,
  COALESCE(SUM(sr.salario_bruto), 0) AS tot_remun 
FROM bd054_schema.departamentos AS d
LEFT JOIN bd054_schema.funcionarios AS f ON d.id_depart = f.id_depart
LEFT JOIN SalariosRecentes AS sr ON f.id_fun = sr.id_fun
GROUP BY d.nome
ORDER BY tot_remun DESC;',
      'Q03',
      'depois indices e otimizacao'
    );


    PERFORM run_benchmark(
      'SELECT 
    f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
    s.salario_liquido
FROM bd054_schema.funcionarios f
JOIN (
    SELECT DISTINCT ON (id_fun)
           id_fun,
           salario_liquido
    FROM bd054_schema.salario
    ORDER BY id_fun, data_inicio DESC
) s ON f.id_fun = s.id_fun
ORDER BY s.salario_liquido DESC
LIMIT 3;',
      'Q04',
      'depois indices e otimizacao'
    );


    PERFORM run_benchmark(
      'WITH ContagemAderentes AS (
    SELECT id_for, COUNT(id_fun) AS num_aderentes
    FROM bd054_schema.teve_formacao
    GROUP BY id_for
)
SELECT
  f.id_for,
  f.nome_formacao,
  c.num_aderentes
FROM bd054_schema.formacoes AS f
JOIN ContagemAderentes AS c ON f.id_for = c.id_for
WHERE c.num_aderentes > (
    SELECT AVG(num_aderentes) FROM ContagemAderentes
)
ORDER BY c.num_aderentes DESC;',
      'Q06',
      'depois indices e otimizacao'
    );


    PERFORM run_benchmark(
      'SELECT 
    f.id_fun,
    f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
    SUM(b.valor) AS tot_benef
FROM bd054_schema.beneficios AS b
JOIN bd054_schema.funcionarios AS f 
    ON f.id_fun = b.id_fun
WHERE b.tipo = ''Seguro Saúde''
GROUP BY f.id_fun, f.primeiro_nome, f.ultimo_nome
HAVING SUM(b.valor) > (
    SELECT AVG(valor)
    FROM bd054_schema.beneficios
    WHERE tipo = ''Seguro Saúde''
)
ORDER BY f.id_fun;',
      'Q07',
      'depois indices e otimizacao'
    );


    PERFORM run_benchmark(
      'WITH salario_atual AS (
    SELECT s1.id_fun, s1.salario_bruto
    FROM bd054_schema.salario s1
    JOIN (
        SELECT id_fun, MAX(data_inicio) AS max_data
        FROM bd054_schema.salario
        GROUP BY id_fun
    ) s2
    ON s1.id_fun = s2.id_fun AND s1.data_inicio = s2.max_data
)
SELECT 
    d.nome, 
    COUNT(f.id_fun) AS numero_funcionarios,
    AVG(sa.salario_bruto) AS media_salarial_departamento
FROM bd054_schema.departamentos d
LEFT JOIN bd054_schema.funcionarios f ON d.id_depart = f.id_depart
LEFT JOIN salario_atual sa ON f.id_fun = sa.id_fun
GROUP BY d.nome
HAVING AVG(sa.salario_bruto) > (
    SELECT AVG(salario_bruto)
    FROM salario_atual
)
ORDER BY media_salarial_departamento DESC;',
      'Q15',
      'depois indices e otimizacao'
    );


    PERFORM run_benchmark(
      'WITH SalariosAtuais AS (
    SELECT DISTINCT ON (id_fun) 
        id_fun, salario_bruto, id_depart
    FROM bd054_schema.salario 
    JOIN bd054_schema.funcionarios USING (id_fun)
    ORDER BY id_fun, data_inicio DESC
),
MediasPorDepartamento AS (
    SELECT id_depart, AVG(salario_bruto) AS media_dept
    FROM SalariosAtuais
    GROUP BY id_depart
)
SELECT 
    f.id_fun,
    f.primeiro_nome || '' '' || f.ultimo_nome AS nome_completo,
    sa.salario_bruto AS salario_atual,
    d.nome AS nome_departamento,
    (SELECT COUNT(*) FROM bd054_schema.teve_formacao AS tf WHERE tf.id_fun = f.id_fun) AS num_formacoes
FROM bd054_schema.funcionarios AS f
JOIN SalariosAtuais AS sa ON f.id_fun = sa.id_fun
JOIN bd054_schema.departamentos AS d ON f.id_depart = d.id_depart
JOIN MediasPorDepartamento AS md ON f.id_depart = md.id_depart
WHERE sa.salario_bruto > md.media_dept
ORDER BY d.nome, sa.salario_bruto DESC;',
      'Q20',
      'depois indices e otimizacao'
    );

END $$;


-- ================================================================================
-- PARA VER O RESULTADOS DOS BENCHMARKS
-- ================================================================================

SELECT * FROM benchmark_results;


SELECT 
    query_name,
    etapa,
    planning_time,
    execution_time,
    total_time,
    total_cost,
    rows_returned,
    buffers_hit,
    buffers_read
FROM benchmark_results
ORDER BY 
    query_name,
    CASE 
        WHEN TRIM(etapa) = 'antes' THEN 1
        WHEN TRIM(etapa) = 'depois indices' THEN 2
        WHEN TRIM(etapa) = 'depois indices e otimizacao' THEN 3
        ELSE 4
    END;

--=================================================================================
-- ANALISE SOBRE OPERACOES INEFICIENTES NAS QUERIES
-- ================================================================================

-- Nesta seccao vamos analisar as queries que potencialmente apresentam problemas de engarrafamentos, o critério para a
-- selecao destas queries pode ser baseado nos resultados dos benchmarks anteriores, ou na existência de subqueries
-- correlacionadas, joins complexos, ou outras características que possam impactar o desempenho.

-- Query Selecionada: Q15 antes de índices e otimizacoes
SET search_path TO bd054_schema, public;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)

SELECT d.Nome, COUNT(f.ID_fun) AS Numero_Funcionarios,
AVG(s.salario_bruto) AS Media_Salarial_Departamento
FROM departamentos AS d
-- LEFT JOIN: Associa funcionários aos departamentos.
LEFT JOIN funcionarios AS f 
ON d.ID_depart = f.ID_depart
-- LEFT JOIN: Obtém o salário bruto para calcular as médias.
LEFT JOIN salario AS s 
ON f.ID_fun = s.ID_fun
WHERE s.Data_inicio = (    -- Filtro 1: Garante que só usamos o salário mais recente de CADA funcionário
SELECT MAX(s2.Data_inicio) 
FROM Salario s2 
WHERE s2.ID_fun = f.ID_fun
)
GROUP BY d.Nome
HAVING AVG(s.salario_bruto) > (    -- Filtro 2: Compara a média do departamento
SELECT AVG(s_avg.salario_bruto) -- Subquery para a Média Global dos salários atuais
FROM Salario s_avg
WHERE s_avg.Data_inicio = (
SELECT MAX(s_max.Data_inicio)
FROM Salario s_max
WHERE s_max.ID_fun = s_avg.ID_fun )
)
ORDER BY Media_Salarial_Departamento DESC;


/*
-- ANÁLISE DE PERFORMANCE (EXPLAIN ANALYZE) --
--------------------------------------------------------------------------------------
O plano de execução evidencia problemas de performance crítica, os gargalos, causados 
pelo uso de Subqueries Correlacionadas, que forçam um processamento iterativo:

1. SubPlan 2 - Filtro WHERE - Data Recente:
   - Comportamento: Executado 2002 loops.
   - Problema: Para cada linha resultante da junção Funcionários-Salários, o motor teve 
     de parar e executar uma nova pesquisa para encontrar a data máxima desse funcionário.

2. SubPlan 4 - Filtro HAVING - Média Global:
   - Comportamento: 2266 loops.
   - Problema: Para filtrar os departamentos, o motor revalidou linha a linha quais os 
     registos a incluir no cálculo da média global, impedindo uma leitura única.

CONCLUSÃO: 
Os elevados tempos de CPU e 'buffers hit' resultam da complexidade O(N*M) destas subqueries. 
O motor não conseguiu resolver os dados em lote, sendo forçado a operar 
linha-a-linha, o que degrada severamente a escalabilidade.
--------------------------------------------------------------------------------------
*/

-- ===============================================================================================================================



-- Query Selecionada: Q19 antes de índices e otimizacoes
SET search_path TO bd054_schema, public;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
    DISTINCT -- Previne duplicados se o funcionário trabalhou na 'Moura' 2x
    f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
    s.salario_bruto AS salario_atual,
    b.tipo AS tipo_beneficio,
    h.nome_empresa AS trabalhou_em -- Esta coluna será sempre 'Moura'
FROM 
    funcionarios AS f

-- 1. Encontra o PERÍODO DE REMUNERAÇÃO MAIS RECENTE, assumindo que num funcionamento normal de uma empresa, o salário mais alto seja o mais recente
-- JOIN: Determina a data de início da remuneração mais recente para sincronizar salário e benefícios.
JOIN remuneracoes AS r 
    ON f.id_fun = r.id_fun
    AND r.Data_inicio = (
        SELECT MAX(r2.Data_inicio) 
        FROM remuneracoes r2 
        WHERE r2.id_fun = f.id_fun
    )

-- 2. Verifica o SALÁRIO para ESSE período
-- JOIN: Acede ao valor do salário bruto correspondente ao período identificado.
JOIN salario AS s 
    ON r.id_fun = s.id_fun 
    AND r.Data_inicio = s.Data_inicio -- Garante que é do período recente
    AND s.salario_bruto > 1500        -- Aplica o filtro do salário

-- 3. Verifica o BENEFÍCIO para ESSE período
-- JOIN: Verifica se existe o benefício 'Seguro Saúde' associado ao mesmo período.
JOIN beneficios AS b
    ON r.id_fun = b.id_fun 
    AND r.Data_inicio = b.Data_inicio -- Garante que é do período recente
    AND b.tipo = 'Seguro Saúde'       -- Aplica o filtro do benefício

-- 4. Verifica o HISTÓRICO (em qualquer altura)
-- JOIN: Filtra os funcionários que têm registo histórico na empresa 'Moura'.
JOIN historico_empresas AS h 
    ON f.id_fun = h.id_fun 
    AND h.nome_empresa = 'Moura';

/*
-- ANÁLISE DE PERFORMANCE (EXPLAIN ANALYZE) --
--------------------------------------------------------------------------------------
Esta query apresenta uma performance excelente devido a uma estratégia de 
filtragem eficaz, apesar de manter custos estruturais:

1. Estratégia de Execução - Nested Loops:
   - O otimizador escolheu a tabela 'historico_empresas' como ponto de partida , filtrando imediatamente por 'Moura'.
   - Isto reduziu o universo de análise de ~2500 registos para apenas 11, tornando 
     os passos seguintes, Join com Salário e Benefícios, triviais.

2. SubPlan 2 - Data Recente:
   - A subquery correlacionada para encontrar a data máxima ainda existe.
   - Contudo, foi executada apenas 7 vezes (loops=7) devido ao filtro inicial eficaz. 
     (Nota: Em grande escala, isto continuaria a ser um risco de performance).

3. Nó 'Unique' e 'Sort':
   - Responsáveis pela cláusula DISTINCT. O custo é residual (0.8ms) dado o baixo 
     número de linhas finais, 4 rows.

CONCLUSÃO:
Exemplo de como um filtro seletivo (WHERE nome_empresa = 'Moura') pode mitigar 
ineficiências estruturais de subqueries, permitindo 'Nested Loops' muito rápidos.
--------------------------------------------------------------------------------------
*/

--============================================================================================

-- Query Selecionada: Q20 antes de índices e otimizacoes
SET search_path TO bd054_schema, public;


EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT f.id_fun, f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
sal.salario_bruto AS salario_atual,
d.nome AS nome_departamento,
(SELECT COUNT(*) -- subquery para contar formações 
FROM teve_formacao AS teve
WHERE teve.id_fun = f.id_fun
  ) AS num_formacoes
FROM funcionarios AS f 
-- LEFT JOIN: Obtém o nome do departamento do funcionário.
LEFT JOIN departamentos AS d ON f.id_depart = d.id_depart
-- LEFT JOIN: Obtém o salário bruto atual do funcionário.
LEFT JOIN salario AS sal ON f.id_fun = sal.id_fun
WHERE sal.Data_inicio = (   -- Garante que só vemos o salário mais recente do funcionário
SELECT MAX(s_main.Data_inicio)
FROM salario s_main
WHERE s_main.id_fun = f.id_fun
    )
AND sal.salario_bruto > ( -- Compara esse salário com a MÉDIA ATUAL do departamento
SELECT AVG(s2.salario_bruto) 
FROM funcionarios AS f2 
-- LEFT JOIN (subquery): Junta os salários dos colegas do mesmo departamento para calcular a média.
LEFT JOIN salario AS s2 ON f2.id_fun = s2.id_fun
WHERE f2.id_depart = f.id_depart -- Do mesmo departamento
AND s2.Data_inicio = ( -- E que o salário (s2) seja o mais recente desse funcionário (f2), assume-se que a tendência natural é o maior salário ser sempre o mais recente
SELECT MAX(s3.Data_inicio)
FROM salario s3
WHERE s3.id_fun = f2.id_fun
    )
)
ORDER BY nome_departamento, salario_atual DESC;

/*
-- ANÁLISE DE PERFORMANCE (EXPLAIN ANALYZE) --
--------------------------------------------------------------------------------------
Esta query apresenta o pior desempenho do conjunto (~757ms), sofrendo de graves 
ineficiências estruturais que criam "gargalos" de processamento massivos:

1. O Principal Gargalo - SubPlan 6 - Média por Departamento:
   - Comportamento: Executado 1000 vezes.
   - Impacto: O motor recalcula a média do departamento inteiro para cada funcionário 
     individualmente. Isto cria uma redundância de cálculo desnecessária que bloqueia 
     o fluxo de execução principal.

2. O Engarrafamento de I/O - SubPlan 5 - Data Recente:
   - Comportamento: 250.668 loops!
   - Análise: Estamos perante um "engarrafamento" lógico. Para calcular a média no 
     ponto anterior, o motor tem de verificar a data do salário de cada colega, um a um. 
     Isto gerou mais de 530.000 acessos à memória os buffers shared hit, saturando o CPU.

3. Seq Scans e Hash Joins Repetitivos:
   - Embora existam índices, a lógica da query força Hash Joins repetidos sobre a tabela 
     de funcionários dentro do SubPlan 6. Isto equivale a scans lógicos 
     desnecessários que poderiam ser evitados se os dados fossem processados em lote.

CONCLUSÃO:
A query escala de forma exponencial O(N^2). O uso excessivo de subqueries correlacionadas 
transformou uma operação simples num congestionamento de mais de 250 mil operações de 
leitura.
--------------------------------------------------------------------------------------
*/
--=====================================================================================================

-- Query Selecionada: Q06 antes de índices e otimizacoes

SET search_path TO bd054_schema, public;

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
  f.id_for,
  f.nome_formacao,
  calcular_num_aderentes_formacao(f.id_for) AS num_aderentes
FROM formacoes AS f
-- compara cada formação com a média global de aderentes (subquery calcula essa média)
WHERE calcular_num_aderentes_formacao(f.id_for) >(
  SELECT AVG(calcular_num_aderentes_formacao(id_for)) 
  FROM formacoes
)
ORDER BY calcular_num_aderentes_formacao(f.id_for) DESC;

/* -- ANÁLISE DE PERFORMANCE (EXPLAIN ANALYZE) --
--------------------------------------------------------------------------------------
Esta query demonstra o "Anti-Pattern" de funções escalares no WHERE e no SELECT, 
causando um problema de performance latente (uma "bomba relógio"):

1. Troca de Contexto Excessivo:
   - O plano mostra 'Buffers: shared hit=80' apenas para processar 5 linhas!
   - Motivo: Para CADA linha da tabela 'formacoes', o motor SQL tem de "parar", 
     chamar o motor PL/pgSQL para correr a função 'calcular_num_aderentes_formacao', 
     e esperar pelo resultado.
   - Embora o tempo total seja baixo (2.9ms) agora, isto deve-se apenas ao volume 
     de dados ser ínfimo. O custo proporcional é altíssimo.

2. InitPlan Pesado - Duplicação de Esforço:
   - Para calcular a média global (InitPlan 1), a função foi executada para 
     todas as 5 formações.
   - Depois, foi executada NOVAMENTE no 'Seq Scan' principal para filtrar quem 
     estava acima dessa média.
   - Finalmente, é chamada no Output para mostrar o valor.
   - Total estimado de chamadas da função: 5 (média) + 5 (filtro) + 2 (output) = 12 chamadas 
     para mostrar apenas 2 linhas de resultado!

CONCLUSÃO:
O uso de funções no WHERE impede o otimizador de usar estatísticas globais e força 
um processamento linha a linha.
--------------------------------------------------------------------------------------
*/

-- =====================================================================================================

-- Query Selecionada: Q02 antes de índices e otimizacoes
SET search_path to bd054_schema, public;


EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT
f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
s.salario_bruto AS salario_bruto
FROM
funcionarios f
-- LEFT JOIN: Acede à tabela de salários para obter o valor bruto correspondente a cada funcionário.
LEFT JOIN salario s ON f.ID_fun = s.ID_fun
WHERE s.salario_bruto > (      -- Filtro 1: O salário tem de ser maior que a média global
SELECT AVG(salario_bruto) 
FROM salario 
)                          -- Filtro 2: "Olha só para o registo mais recente deste funcionário"
AND s.Data_inicio = (
SELECT MAX(s2.Data_inicio)
FROM salario s2
WHERE s2.ID_fun = f.ID_fun 
)
ORDER BY
salario_bruto DESC;

/* -- ANÁLISE DE PERFORMANCE (EXPLAIN ANALYZE) --
--------------------------------------------------------------------------------------
Esta query apresenta um padrão perigoso de "N+1 Queries" executado internamente 
pela base de dados, disfarçado dentro de um Hash Join.

1. O Gargalo Oculto : SubPlan 3 - 1493 Loops:
   - O plano indica 'Loops=1493' no SubPlan 3.
   - O que isto significa: Para CADA combinação possível de funcionário e salário 
     que passou no filtro inicial, o Postgres foi obrigado a executar uma pequena 
     query extra para descobrir "qual é a data mais recente?".
   - Custo: Gerou mais de 3.000 acessos à memória, os shared hits, num passo que 
     deveria ser linear.

2. A Condição de Join Ineficiente:
   - Hash Cond: ((s.id_fun = f.id_fun) AND (s.data_inicio = (SubPlan 3)))
   - O problema está no "AND s.data_inicio = (SubPlan 3)".
   - Em vez de preparar os dados "mais recentes" de antemão, a query está a 
     verificar a validade da data linha a linha durante o cruzamento das tabelas.

CONCLUSÃO:
A query escala mal. Se a tabela de salários crescer para 1 milhão de linhas, 
o SubPlan 3 será executado milhões de vezes, matando a performance.
--------------------------------------------------------------------------------------
*/


-- ================================================================================
-- PARA LIMPAR OS RESULTADOS DOS BENCHMARKS
-- ================================================================================

set search_path to benchmark_schema, public;

DROP TABLE IF EXISTS benchmark_results; 

