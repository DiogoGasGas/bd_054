set search_path to benchmark_schema, public;

-- =========================================================================
-- BLOCO 1: FASE FORÇADA (c/ índices E S/ SeqScan)
-- O PostgreSQL é forçado a usar os índices.
-- =========================================================================

-- FICHEIRO: benchmarks_depois_indices_forcados.sql

-- NOTA: Assume-se que a função run_benchmark (com Warm-up) já foi definida 
-- e que os índices já foram criados no schema bd054_schema.

DO $$
BEGIN
    -- ATIVA O MODO FORÇADO: Desliga o Sequential Scan, 
    -- forçando o PostgreSQL a usar índices ou index scans, mesmo que o planner 
    -- original o considerasse mais lento. Este SET LOCAL é revertido no fim do bloco.
    SET LOCAL enable_seqscan = off;

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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
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
        'depois_s_seqscan'
    );
    
-- O comando SET LOCAL é automaticamente revertido aqui.

END $$;


-- =========================================================================
-- BLOCO 2: FASE REAL (c/ índices E C/ SeqScan)
-- O PostgreSQL usa o seu planeador normal para decidir.
-- =========================================================================

DO $$
BEGIN
    -- FICHEIRO: benchmarks_depois_indices_c_seqscan.sql

set search_path to benchmark_schema, public;

-- NOTA: Assume-se que a função run_benchmark (com Warm-up) já foi definida 
-- e que os índices já foram criados no schema bd054_schema.
-- O Sequential Scan (SeqScan) está ativo por defeito. Não é necessário usar SET.

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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
    );
END $$;-- Não é necessário nenhum SET. O enable_seqscan está no seu valor padrão (on).

 -- FICHEIRO: benchmarks_depois_indices_c_seqscan.sql


-- NOTA: Assume-se que a função run_benchmark (com Warm-up) já foi definida 
-- e que os índices já foram criados no schema bd054_schema.

DO $$
BEGIN
    -- O Sequential Scan (SeqScan) está ativo por defeito. Não é necessário usar SET.

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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
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
        'depois_c_seqscan'
    );
<<<<<<< HEAD
END $$;
=======
END $$;
>>>>>>> 509e753d862ac4f56b6ed5c73e476d01775922ca
