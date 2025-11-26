set search_path to benchmark_schema, public;

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