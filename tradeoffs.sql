-- ====================================================================
-- BENCHMARK SIMPLIFICADO: Trade-off de Escrita
-- ====================================================================

SET search_path TO bd054_schema, public;

-- 1. Limpeza inicial (caso tenhas corrido antes)
DROP TABLE IF EXISTS beneficios_bench;
DROP TABLE IF EXISTS resultados_benchmark;

-- 2. Preparar as tabelas
-- Tabela 'bench' é uma cópia vazia da tabela beneficios
CREATE TABLE beneficios_bench AS SELECT * FROM beneficios WHERE 1=0;

-- Tabela para guardar os tempos (para te mostrar no fim)
CREATE TEMPORARY TABLE resultados_benchmark (
    cenario VARCHAR(50),
    tempo_execucao INTERVAL
);

-- ====================================================================
-- TESTE A: Inserção SEM Índices
-- ====================================================================
DO $$
DECLARE
    inicio TIMESTAMP;
    fim TIMESTAMP;
BEGIN
    inicio := clock_timestamp();

    -- Inserir 50.000 linhas
    INSERT INTO beneficios_bench (id_fun, data_inicio, tipo, valor)
    SELECT 
        (random() * 1000)::int, 
        CURRENT_DATE + (i || ' days')::interval, 
        CASE WHEN (i % 2) = 0 THEN 'Seguro Saúde' ELSE 'Subsídio Transporte' END,
        (random() * 200)::numeric(10,2)
    FROM generate_series(1, 50000) AS i;

    fim := clock_timestamp();
    
    -- Guardar o tempo na tabela de resultados
    INSERT INTO resultados_benchmark VALUES ('1. Sem Índices', fim - inicio);
END $$;

-- Limpar os dados para o próximo teste
TRUNCATE beneficios_bench;

-- ====================================================================
-- TESTE B: Inserção COM Índices
-- ====================================================================

-- Recriar a estrutura pesada de índices que tens no projeto
CREATE INDEX bench_ind_tipo ON beneficios_bench(tipo);           -- B-Tree
CREATE INDEX bench_hash_tipo ON beneficios_bench USING HASH(tipo); -- Hash (Redundante)
CREATE INDEX bench_ind_valor ON beneficios_bench(valor);         -- B-Tree

DO $$
DECLARE
    inicio TIMESTAMP;
    fim TIMESTAMP;
BEGIN
    inicio := clock_timestamp();

    -- Inserir as mesmas 50.000 linhas
    INSERT INTO beneficios_bench (id_fun, data_inicio, tipo, valor)
    SELECT 
        (random() * 1000)::int, 
        CURRENT_DATE + (i || ' days')::interval, 
        CASE WHEN (i % 2) = 0 THEN 'Seguro Saúde' ELSE 'Subsídio Transporte' END,
        (random() * 200)::numeric(10,2)
    FROM generate_series(1, 50000) AS i;

    fim := clock_timestamp();
    
    -- Guardar o tempo
    INSERT INTO resultados_benchmark VALUES ('2. Com Índices', fim - inicio);
END $$;

-- ====================================================================
-- RESULTADO FINAL
-- ====================================================================
SELECT * FROM resultados_benchmark ORDER BY cenario;

-- Limpeza final (opcional, se quiseres manter a tabela para ver, comenta estas linhas)
DROP TABLE beneficios_bench;
DROP TABLE resultados_benchmark;


-- ====================================================================
--TESTE 2
-- ====================================================================

-- ====================================================================
-- BENCHMARK ADICIONAL: Tabela Funcionários
-- Comparação: Sem Índices vs Com Índices (Depart + Nome Completo)
-- ====================================================================

SET search_path TO bd054_schema, public;

-- 1. Limpeza inicial
DROP TABLE IF EXISTS funcionarios_bench;
DROP TABLE IF EXISTS resultados_benchmark_fun;

-- 2. Preparar tabela de teste e tabela de resultados
-- Cria uma cópia da estrutura da tabela funcionarios (sem chaves/constraints para isolar o teste dos índices)
CREATE TABLE funcionarios_bench AS SELECT * FROM funcionarios WHERE 1=0;

CREATE TEMPORARY TABLE resultados_benchmark_fun (
    cenario VARCHAR(50),
    tempo_execucao INTERVAL
);

-- ====================================================================
-- TESTE A: Inserção SEM Índices
-- ====================================================================
DO $$
DECLARE
    inicio TIMESTAMP;
    fim TIMESTAMP;
BEGIN
    inicio := clock_timestamp();

    -- Inserir 100.000 funcionários fictícios
    INSERT INTO funcionarios_bench (id_fun, nif, primeiro_nome, ultimo_nome, id_depart, email, data_nascimento)
    SELECT 
        i, 
        (100000000 + i)::varchar, -- NIF único fictício
        'Funcionario' || i, 
        'Teste' || (i % 100), 
        (random() * 7 + 1)::int, -- Departamentos 1 a 8
        'func' || i || '@empresa_teste.pt',
        '1990-01-01'::date + (i % 3650)::int -- Data nasc aleatória
    FROM generate_series(1, 100000) AS i;

    fim := clock_timestamp();
    
    INSERT INTO resultados_benchmark_fun VALUES ('1. Sem Índices', fim - inicio);
END $$;

-- Limpar tabela para o próximo teste
TRUNCATE funcionarios_bench;

-- ====================================================================
-- TESTE B: Inserção COM Índices
-- ====================================================================

-- 1. Criar o índice pedido pelo utilizador
CREATE INDEX bench_ind_fun_depart ON funcionarios_bench(id_depart);

-- 2. Criar também o índice funcional (do indexes.sql) para tornar o teste mais "pesado" e realista


DO $$
DECLARE
    inicio TIMESTAMP;
    fim TIMESTAMP;
BEGIN
    inicio := clock_timestamp();

    -- Inserir os mesmos 100.000 funcionários
    INSERT INTO funcionarios_bench (id_fun, nif, primeiro_nome, ultimo_nome, id_depart, email, data_nascimento)
    SELECT 
        i, 
        (100000000 + i)::varchar,
        'Funcionario' || i, 
        'Teste' || (i % 100), 
        (random() * 7 + 1)::int,
        'func' || i || '@empresa_teste.pt',
        '1990-01-01'::date + (i % 3650)::int
    FROM generate_series(1, 100000) AS i;

    fim := clock_timestamp();
    
    INSERT INTO resultados_benchmark_fun VALUES ('2. Com Índices', fim - inicio);
END $$;

-- ====================================================================
-- RESULTADO FINAL
-- ====================================================================
SELECT * FROM resultados_benchmark_fun ORDER BY cenario;

-- Limpeza final
DROP TABLE funcionarios_bench;
DROP TABLE resultados_benchmark_fun;




-- ====================================================================
-- TESTE 3: Benchmark Update
-- ====================================================================

SET search_path TO bd054_schema, public;

-- 1. Limpeza inicial
DROP TABLE IF EXISTS funcionarios_update_bench;
DROP TABLE IF EXISTS resultados_update_bench;

-- Tabela para guardar os tempos
CREATE TEMPORARY TABLE resultados_update_bench (
    cenario VARCHAR(50),
    tempo_execucao INTERVAL
);

-- ====================================================================
-- PREPARAÇÃO (Criação da Tabela Base)
-- ====================================================================
-- Criar estrutura simples
CREATE TABLE funcionarios_update_bench (
    id_fun INT,
    primeiro_nome VARCHAR(50),
    ultimo_nome VARCHAR(50)
);

-- ====================================================================
-- TESTE A: Update SEM Índices
-- ====================================================================
DO $$
DECLARE
    inicio TIMESTAMP;
    fim TIMESTAMP;
BEGIN
    -- 1. Popular a tabela com 100.000 registos
    TRUNCATE funcionarios_update_bench;
    INSERT INTO funcionarios_update_bench (id_fun, primeiro_nome, ultimo_nome)
    SELECT 
        i, 
        'Joao' || i, 
        'Silva' || i
    FROM generate_series(1, 100000) AS i;

    -- 2. Medir o UPDATE
    -- Vamos mudar o primeiro nome de TODA a gente.
    -- Sem índices, isto deve ser apenas escrita sequencial na tabela (rápido).
    inicio := clock_timestamp();

    UPDATE funcionarios_update_bench 
    SET primeiro_nome = 'Maria' || id_fun;

    fim := clock_timestamp();
    
    INSERT INTO resultados_update_bench VALUES ('1. Update Sem Índice', fim - inicio);
END $$;

-- ====================================================================
-- TESTE B: Update COM Índice Funcional
-- ====================================================================
DO $$
DECLARE
    inicio TIMESTAMP;
    fim TIMESTAMP;
BEGIN
    -- 1. Reset aos dados (Apagar e inserir de novo para ter condições iguais)
    TRUNCATE funcionarios_update_bench;
    INSERT INTO funcionarios_update_bench (id_fun, primeiro_nome, ultimo_nome)
    SELECT 
        i, 
        'Joao' || i, 
        'Silva' || i
    FROM generate_series(1, 100000) AS i;

    -- 2. Criar o Índice Funcional (o "alvo" do nosso teste)
    -- O Postgres terá de recalcular (primeiro || ' ' || ultimo) sempre que mudarmos um nome.
    CREATE INDEX bench_ind_nome_completo ON funcionarios_update_bench ((primeiro_nome || ' ' || ultimo_nome));

    -- 3. Medir o UPDATE (Exatamente a mesma operação)
    inicio := clock_timestamp();

    UPDATE funcionarios_update_bench 
    SET primeiro_nome = 'Maria' || id_fun;

    fim := clock_timestamp();
    
    INSERT INTO resultados_update_bench VALUES ('2. Update Com Índice Funcional', fim - inicio);
END $$;

-- ====================================================================
-- RESULTADO FINAL
-- ====================================================================
SELECT * FROM resultados_update_bench ORDER BY cenario;

-- Limpeza final
DROP TABLE funcionarios_update_bench;
DROP TABLE resultados_update_bench;