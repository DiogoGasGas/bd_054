set search_path to bd054_schema, public;

ANALYZE funcionarios;
ANALYZE departamentos;
ANALYZE avaliacoes;
ANALYZE beneficios;
ANALYZE candidato_a;
ANALYZE candidatos;
ANALYZE dependentes;
ANALYZE ferias;
ANALYZE formacoes;
ANALYZE faltas;
ANALYZE historico_empresas;
ANALYZE salario;
ANALYZE remuneracoes;
ANALYZE teve_formacao;
ANALYZE vagas;
ANALYZE permissoes;
ANALYZE utilizadores;





-- Querie 1 original
ANALYZE departamentos;
ANALYZE funcionarios;

set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
  d.nome,              -- nome do departamento
  COUNT(f.id_fun) AS total_funcionarios -- número total de funcionários no departamento
FROM departamentos AS d
-- LEFT JOIN permite listar também departamentos sem funcionários
LEFT JOIN funcionarios AS f 
ON d.id_depart= f.id_depart
-- agrupa os resultados por departamento para fazer a contagem corretamente
GROUP BY d.nome
ORDER BY total_funcionarios DESC;


-- Otimização 1: Pré-agragação (A mais impactante)
ANALYZE departamentos;
ANALYZE funcionarios;


set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
  d.nome,
  COALESCE(contagem.total, 0) AS total_funcionarios
FROM departamentos AS d
LEFT JOIN (
  -- Agregamos PRIMEIRO, reduzindo de 100 (ou milhões) linhas para apenas o nº de departamentos ativos
  SELECT id_depart, COUNT(*) AS total
  FROM funcionarios
  GROUP BY id_depart
) AS contagem ON d.id_depart = contagem.id_depart
ORDER BY total_funcionarios DESC;


-- Otimização 2: Agrupamento por ID (Eficiência de Hash)

ANALYZE departamentos;
ANALYZE funcionarios;




set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
  d.nome,
  COUNT(f.id_fun) AS total_funcionarios
FROM departamentos AS d
LEFT JOIN funcionarios AS f ON d.id_depart = f.id_depart
-- Agrupar pelo ID (inteiro) é computacionalmente mais barato que por Nome (texto)
GROUP BY d.id_depart
ORDER BY total_funcionarios DESC;

-------------------------------------------------------------------------

-- Querie 2 original


set search_path to bd054_schema, public;
ANALYZE funcionarios;
ANALYZE salario;

set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
s.salario_bruto AS salario_bruto
FROM
funcionarios f
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

-- Querie 2 otimizada - Usando DISTINCT ON para evitar subquery por funcionário. Distinct on pega automaticamente o ultimo salário

ANALYZE funcionarios;
ANALYZE salario;

set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT 
  f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
  s_recentes.salario_bruto
FROM funcionarios f
LEFT JOIN (
  -- Seleciona apenas UM registo por id_fun (o primeiro, baseado no ORDER BY)
  SELECT DISTINCT ON (id_fun) 
    id_fun, 
    salario_bruto
  FROM salario
  ORDER BY id_fun, Data_inicio DESC
) s_recentes ON f.id_fun = s_recentes.id_fun
WHERE s_recentes.salario_bruto > (SELECT AVG(salario_bruto) FROM salario)
ORDER BY s_recentes.salario_bruto DESC;


--------------------------------------------------------------------------
-- Querie 3 original
ANALYZE departamentos;
ANALYZE funcionarios;
ANALYZE salario;


set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT d.nome, SUM(s.salario_bruto) AS tot_remun 
FROM departamentos AS d
LEFT JOIN funcionarios AS f 
ON d.id_depart = f.id_depart
LEFT JOIN salario AS s 
ON f.id_fun = s.id_fun
WHERE s.Data_inicio = (   -- garante que só apanhamos o salário mais recente
SELECT MAX(s2.Data_inicio)
FROM salario s2
WHERE s2.id_fun = f.id_fun -- para este funcionário específico
)
GROUP BY d.nome
ORDER BY tot_remun DESC;


-- Querie 3 otimizada - Usando CTE para pré-selecionar salários recentes

ANALYZE departamentos;
ANALYZE funcionarios;
ANALYZE salario;


set search_path to bd054_schema, public;
EXPLAIN ANALYZE
WITH SalariosRecentes AS (
  -- 1. Encontra o salário mais recente para CADA funcionário em UM SÓ SCAN + SORT.
  -- Esta é a etapa mais crítica para performance.
  SELECT DISTINCT ON (id_fun)
    id_fun,
    salario_bruto
  FROM salario
  ORDER BY id_fun, Data_inicio DESC
)
SELECT
  d.nome,
  COALESCE(SUM(sr.salario_bruto), 0) AS tot_remun 
FROM departamentos AS d
-- 2. Faz o JOIN com os funcionários.
LEFT JOIN funcionarios AS f ON d.id_depart = f.id_depart
-- 3. Faz o JOIN com a lista de salários recentes (apenas uma linha por funcionário).
LEFT JOIN SalariosRecentes AS sr ON f.id_fun = sr.id_fun
-- 4. Agrupa pelo nome, conforme solicitado.
GROUP BY d.nome
ORDER BY tot_remun DESC;

------------------------------------------------------------------------------------

--4. Querie 4 original

set search_path to bd054_schema, public;

ANALYZE funcionarios;
ANALYZE salario;

EXPLAIN ANALYZE
SELECT f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
s.salario_liquido AS salario_liquido
FROM 
funcionarios AS f
LEFT JOIN salario AS s ON f.id_fun = s.id_fun
WHERE s.Data_inicio = (       --  garante que é o salário mais recente
SELECT MAX(s2.Data_inicio)
FROM salario s2
WHERE s2.id_fun = f.id_fun -- para este funcionário
  )
ORDER BY 
salario_liquido DESC -- Ordena pelo salário atual
LIMIT 3;



-----Query 4 otimizada - Usando DISTINCT ON para evitar subquery por funcionário. Distinct on pega automaticamente o ultimo salário(muito rapido com o index que temos criado)~
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT 
    f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
    s.salario_liquido
FROM funcionarios f
JOIN (
    SELECT DISTINCT ON (id_fun)
           id_fun,
           salario_liquido
    FROM salario
    ORDER BY id_fun, data_inicio DESC
) s ON f.id_fun = s.id_fun
ORDER BY s.salario_liquido DESC
LIMIT 3;


------------------------------------------------------------------------------

-- Querie 6 original

set search_path to bd054_schema, public;
EXPLAIN ANALYZE
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


-- Query 6 Otimizada
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
WITH ContagemAderentes AS (
    -- 1. Pré-calculamos quantos aderentes tem CADA formação
    SELECT id_for, COUNT(id_fun) AS num_aderentes
    FROM teve_formacao
    GROUP BY id_for
)
SELECT
  f.id_for,
  f.nome_formacao,
  c.num_aderentes
FROM formacoes AS f
JOIN ContagemAderentes AS c ON f.id_for = c.id_for
WHERE c.num_aderentes > (
    -- 2. Calculamos a média global aqui.
    -- Como não depende de 'f' nem 'c', o SQL calcula isto só uma vez e reutiliza.
    SELECT AVG(num_aderentes) FROM ContagemAderentes
)
ORDER BY c.num_aderentes DESC;

-----------------------------------------------------------------------------

-- Querie 7 original. 
set search_path to bd054_schema, public;
EXPLAIN ANALYZE 
SELECT 
f.id_fun,
f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
SUM(b.valor) AS tot_benef  -- soma dos valores acumulados de benefícios que um funcionário possa ter
FROM funcionarios AS f
JOIN beneficios AS b 
ON f.id_fun = b.id_fun
-- filtrar seguros de saúde
WHERE b.tipo = 'Seguro Saúde'
GROUP BY nome_completo, f.id_fun
-- filtrar para obter apenas a media dos beneficios que sao seguro de saúde
HAVING SUM(b.valor) > (
  SELECT AVG(valor) 
  FROM beneficios
  WHERE tipo = 'Seguro Saúde'
)
ORDER BY f.id_fun ASC;


-- query 7 otimizada
/* Na query 7, agrupamos por primeiro_nome e ultimo_nome em vez de usar a expressão concatenada nome_completo,
 o que reduz custo de processamento. Além disso, iniciamos o join pela tabela beneficios já filtrada pelo tipo,
  diminuindo o volume de dados a processar antes da agregação. 
*/

set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT 
    f.id_fun,
    f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
    SUM(b.valor) AS tot_benef
FROM beneficios AS b
JOIN funcionarios AS f 
    ON f.id_fun = b.id_fun
WHERE b.tipo = 'Seguro Saúde'
GROUP BY f.id_fun, f.primeiro_nome, f.ultimo_nome
HAVING SUM(b.valor) > (
    SELECT AVG(valor)
    FROM beneficios
    WHERE tipo = 'Seguro Saúde'
)
ORDER BY f.id_fun;

---------------------------------------------------------------------------------

--8. Funcionário com mais dias de férias aprovadas
-- Objetivo: identificar o/os funcionário com mais dias de férias
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
  f.id_fun,
  f.primeiro_nome,        -- nome do funcionário
  fer.num_dias,       -- número de dias de férias
  fer.data_inicio       -- a data de inicio ajuda a perceber o prquê de certas repetições
FROM funcionarios AS f
JOIN ferias AS fer ON f.id_fun = fer.id_fun
-- subquery identifica o valor máximo de dias de férias aprovadas
WHERE fer.num_dias = (
  SELECT MAX(num_dias) 
  FROM ferias 
  WHERE estado_aprov = 'Aprovado'
)
ORDER BY f.id_fun;

/* Como o Index Only Scan sobre o índice idx_ferias_estado_numdias_desc retorna rapidamente a maior quantidade de dias de férias aprovadas,
e como o Hash Join com a tabela funcionarios processa poucas linhas em milissegundos, podemos concluir que a query já está bem otimizada.
Além disso, o índice idx_ferias_estado_numdias_desc ajuda a acelerar tanto a filtragem pelo estado aprovado quanto a seleção do máximo num_dias,
garantindo uma execução eficiente da query. */

--------------------------------------------------------------------------------------------

--9.  Departamentos com média salarial acima da média salarial geral, com a média de avaliação 
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
  d.nome AS nome_depart,            -- nome do departamento
  COALESCE(AVG(a.avaliacao_numerica),0) AS media_aval, -- média da pontuação de avaliação dos funcionários do departamento, o null conta como 0
  AVG(s.salario_bruto) AS media_salario  -- média salarial dos funcionários do departamento
FROM funcionarios AS f
RIGHT JOIN departamentos AS d
  ON d.id_depart = f.id_depart
JOIN avaliacoes AS a 
  ON f.id_fun = a.id_fun
JOIN salario AS s
  ON f.id_fun = s.id_fun
-- agrupa por departamento para calcular a média de cada um
GROUP BY d.nome
-- filtra apenas os departamentos em que a média salarial é maior que a média salarial geral
HAVING AVG(s.salario_bruto) > (
  SELECT AVG(salario_bruto)
  FROM salario
)
ORDER BY media_aval DESC;


/*Como todos os seq scans estão a processar poucas linhas e como os hash joins e hash aggregantes também estão a ser rápidos (menos de 2 ms),
podemos concluir que a query já está bem otimizada. 
Além disso, índices como o ind_fun_depart, ind_salario_fun_data e ind_avaliacao_num ajudam a acelerar os joins e filtros o que já otimiza a query.
*/
----------------------------------------------------------------------

--10. Dependentes e funcionário respetivo 
-- Objetivo: mostrar cada dependente com o respetivo funcionário titular e o departamento desse funcionário
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
  f.id_fun, 
  f.primeiro_nome || ' '|| f.ultimo_nome AS nome_funcionario, -- id e nome do funcionário titular
  dep.nome   as nome_dep,                      -- nome do departamento do funcionário
  STRING_AGG(d.nome || ' (' || d.parentesco || ')', ', ') AS dependentes -- agrega todos os dependnetes numa unica linha
FROM dependentes AS d
-- junta Dependentes com Funcionarios para saber quem é o titular
JOIN Funcionarios f ON d.id_fun = f.id_fun
-- junta Funcionarios com Departamentos para saber a qual departamento o titular pertence
JOIN departamentos AS dep 
ON f.id_depart = dep.id_depart
GROUP BY f.id_fun, f.primeiro_nome, f.ultimo_nome, dep.nome -- necessário devido ao string_agg
ORDER BY nome_funcionario; -- orderna por ordem alfabética


/* Embora o Hash Join (1,450 ms) e o Hash Aggregate (2,472 ms) tenham tempos de execução ligeiramente mais elevados que outros passos,
estes valores são normais dado o número de linhas processadas (751 e 343 linhas, respetivamente).
Os Seq Scans são rápidos e processam poucas linhas, e o Index Bitmap Scan no índice ind_tipo_beneficio acelera o filtro por tipo de benefício.
Portanto, não existem gargalos significativos e podemos concluir que a query já está bem otimizada. Índices como ind_tipo_beneficio, 
ind_fun_depart e ind_salario_fun_data ajudam a acelerar joins e filtros, contribuindo para a eficiência geral da execução.*/

-----------------------------------------------------------------------------

--11. Vagas 
-- Objetivo: calcular a média de candidatos por departamento, com o número de vagas em cada departamento
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT
  dep.id_depart,
  dep.nome AS nome_depart,                        -- departamento
  COUNT(v.id_vaga) AS num_vagas,                -- quantas vagas existem no departamento
  -- média de candidatos por vaga nesse departamento, coalesce para cotar null como 0
  COALESCE(AVG(cand_a.num_cand), 0)  AS media_candidatos     
FROM departamentos as dep
-- associar todas as vagas ao seu departamento
LEFT JOIN vagas AS v
  ON v.id_depart = dep.id_depart
-- a subquery calcula o número de candidatos por vaga, num_cand
-- o LEFT JOIN associa esses dados às vagas, garantindo que nenhuma vaga é excluida
LEFT JOIN ( 
  SELECT 
  id_vaga, 
  COUNT(id_cand) as num_cand
  FROM candidato_a
  GROUP BY id_vaga
) AS cand_a
ON cand_a.id_vaga = v.id_vaga 
GROUP BY dep.id_depart, dep.nome 
-- ordena para ver primeiro os departamentos com maior média de candidatos
ORDER BY media_candidatos DESC;


/* Nesta query, todos os Seq Scans (departamentos, vagas, candidato_a) processam poucas linhas e são extremamente rápidos (menos de 0,2 ms).
Os Hash Joins e Hash Aggregates também têm tempos de execução baixos (máximo 0,510 ms), 
mesmo incluindo a subquery que agrega o número de candidatos por vaga.
O Sort final processa apenas 8 linhas, portanto é insignificante em termos de custo.
Com base nestes valores, podemos concluir que a query já está bem otimizada. A presença de índices sobre chaves de join,
como ind_fun_depart ou índices sobre id_depart e id_vaga, contribui para acelerar os joins e agregações.*/

---------------------------------------------------------------------------------------

--12. Número de dependentes 
-- Objetivo: Número de dependentes de cada funcionário
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT f.id_fun,f.primeiro_nome, 
  COUNT(d.id_fun) AS num_dependentes  
FROM funcionarios As f
LEFT JOIN dependentes AS d 
  ON f.id_fun = d.id_fun  -- criar tabela incluindo todos os funcionários associando aos dependentes
GROUP BY f.id_fun, f.primeiro_nome
ORDER BY num_dependentes desc;  


/* Nesta query, os Seq Scans sobre funcionarios e dependentes processam poucas linhas e são muito rápidos (menos de 0,4 ms).
O Hash Right Join e o HashAggregate também têm tempos de execução baixos (1,367 ms e 2,059 ms, respetivamente) 
e lidam com menos de 2000 linhas, o que indica que não há gargalos significativos.
O Sort final processa apenas 1000 linhas, com tempo de 2,392 ms, o que é aceitável dado o volume.
Portanto, podemos concluir que a query já está otimizada. 
Índices como ind_fun_depart e ind_parentesco_dependentes ajudam a acelerar os joins e a agregação, 
embora neste caso o ganho seja marginal devido ao pequeno número de linhas.*/

------------------------------------------------------------------------------------

--13. Funcionário que não fizeram auto-avaliação
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT 
    f.primeiro_nome,
    f.ultimo_nome,
    av.autoavaliacao
FROM funcionarios AS f 
JOIN avaliacoes AS av
  ON f.id_fun = av.id_fun
-- se a autoavaliacao é null, é porque não existe avaliação preenchida
WHERE av.autoavaliacao IS NULL;
------------------------------------------------------------------------------------

--14. Numero de faltas e faltas justificadas por departamento
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT 
    d.id_depart,
    d.nome,
    COUNT(fal.id_fun) AS total_faltas, -- contar as faltas dos funcionarios
    COUNT(fal.justificacao) AS total_faltas_just  -- contar numero de justificadas
FROM departamentos d
-- vão ser associados funcionarios aos departamentos
LEFT JOIN funcionarios AS f 
  ON d.id_depart = f.id_depart
-- associar faltas a funcionários
LEFT JOIN faltas AS fal 
  ON f.id_fun = fal.id_fun
GROUP BY d.nome, d.id_depart
ORDER BY total_faltas DESC;

/* Apesar de o HashAggregate (~3,1 ms) e o Hash Right Join (~2,6 ms) apresentarem tempos ligeiramente mais altos, 
eles processam um número reduzido de linhas (8 e 2803, respetivamente) e não envolvem loops adicionais.
Portanto, a query já está bem otimizada para o volume atual de dados.
Índices como ind_fun_depart e ind_justificacao_faltas ajudam a acelerar os joins e os filtros, 
garantindo que mesmo operações de agregação e contagem são rápidas.
O Sort final também processa poucas linhas, não representando gargalo. */

---------------------------------------------

--15. Departamentos cuja média salarial é maior que a média total, o seu número de funcionários e a sua média
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT d.Nome, COUNT(f.ID_fun) AS Numero_Funcionarios,
AVG(s.salario_bruto) AS Media_Salarial_Departamento
FROM departamentos AS d
LEFT JOIN funcionarios AS f 
ON d.ID_depart = f.ID_depart
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


-- Querie 15 otimizada - Usando CTE para pré-selecionar salários recentes

set search_path to bd054_schema, public;
EXPLAIN ANALYZE
WITH salario_atual AS (
    SELECT s1.id_fun, s1.salario_bruto
    FROM salario s1
    JOIN (
        SELECT id_fun, MAX(data_inicio) AS max_data
        FROM salario
        GROUP BY id_fun
    ) s2
    ON s1.id_fun = s2.id_fun AND s1.data_inicio = s2.max_data
)
SELECT 
    d.nome, 
    COUNT(f.id_fun) AS numero_funcionarios,
    AVG(sa.salario_bruto) AS media_salarial_departamento
FROM departamentos d
LEFT JOIN funcionarios f ON d.id_depart = f.id_depart
LEFT JOIN salario_atual sa ON f.id_fun = sa.id_fun
GROUP BY d.nome
HAVING AVG(sa.salario_bruto) > (
    SELECT AVG(salario_bruto)
    FROM salario_atual
)
ORDER BY media_salarial_departamento DESC;


/* Com o CTE, pré-filtramos os salários mais recentes, evitando subqueries repetidas dentro do WHERE. 
Substituímos o Nested Loop por Hash Joins e Hash Aggregates, o que acelera os joins e a agregação. 
Os índices como `ind_salario_fun_data` e `ind_fun_depart` ajudam a buscar rapidamente salários e funcionários, 
tornando a query muito mais eficiente. */





---------------------------------------------

-- Querie 16 original
set search_path to bd054_schema, public;
EXPLAIN ANALYZE
SELECT 
  h.nome_empresa, 
  -- agrega os nomes completos dos funcionários que trabalharam nessa empresa
  STRING_AGG(f.primeiro_nome || ' ' || f.ultimo_nome, ', ') AS funcionarios
FROM historico_empresas AS h
-- junta histórico aos funcionários
JOIN funcionarios AS f 
  ON f.id_fun = h.id_fun
GROUP BY h.nome_empresa
-- mantém apenas as empresas com mais de um funcionário, ou seja, onde pelo menos dois já trabalharam
HAVING COUNT(f.id_fun) > 1;


-- Querie 16 otimizada
set search_path to bd054_schema, public;
EXPLAIN ANALYZE


WITH empresas_filtradas AS (
SELECT
h.nome_empresa,
f.id_fun,
f.primeiro_nome,
f.ultimo_nome
FROM historico_empresas AS h
JOIN funcionarios AS f
ON f.id_fun = h.id_fun
)
SELECT
ef.nome_empresa,
STRING_AGG(ef.primeiro_nome || ' ' || ef.ultimo_nome, ', ') AS funcionarios
FROM empresas_filtradas ef
GROUP BY ef.nome_empresa
HAVING COUNT(ef.id_fun) > 1;


------------------------------------------------------------------------------------------

-- Querie 17 original
SELECT 
  f.id_fun,
  f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
  COUNT(fal.data) AS total_faltas
FROM funcionarios AS f
LEFT JOIN faltas AS fal 
  ON f.id_fun = fal.id_fun
GROUP BY f.id_fun, f.primeiro_nome, f.ultimo_nome
-- filtrar funcionários que têm a soma de faltas igual a 0
HAVING COUNT(fal.data) = 0
ORDER BY f.id_fun;
------------------------------------------------------------------------------------------

-- Querie 18 original
SELECT 
    d.nome,
    ROUND((COUNT(DISTINCT teve.id_fun)::decimal / calcular_num_funcionarios_departamento(d.id_depart)::decimal) * 100, 2) AS taxa_adesao
-- Round arredonda a 2 casas decimais, o count com recurso ao distinct conta os funcionários que participaram em pelo menos uma formação, 
-- dividindo-se pelo numero total de pessoas no departamento
FROM departamentos AS d
LEFT JOIN funcionarios AS f 
  ON d.id_depart = f.id_depart
-- associar funcionários por departamento
LEFT JOIN teve_formacao AS teve 
  ON f.id_fun = teve.id_fun
-- associar funcionários pelas presenças a formações que tiveram
GROUP BY d.nome, d.id_depart
ORDER BY taxa_adesao DESC;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Querie 19 original
SELECT
    DISTINCT -- Previne duplicados se o funcionário trabalhou na 'Moura' 2x
    f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
    s.salario_bruto AS salario_atual,
    b.tipo AS tipo_beneficio,
    h.nome_empresa AS trabalhou_em -- Esta coluna será sempre 'Moura'
FROM 
    funcionarios AS f
-- 1. Encontra o PERÍODO DE REMUNERAÇÃO MAIS RECENTE, assumindo que num funcionamento normal de uma empresa, o salário mais alto seja o mais recente
JOIN remuneracoes AS r 
    ON f.id_fun = r.id_fun
    AND r.Data_inicio = (
        SELECT MAX(r2.Data_inicio) 
        FROM remuneracoes r2 
        WHERE r2.id_fun = f.id_fun
    )
-- 2. Verifica o SALÁRIO para ESSE período
JOIN salario AS s 
    ON r.id_fun = s.id_fun 
    AND r.Data_inicio = s.Data_inicio -- Garante que é do período recente
    AND s.salario_bruto > 1500        -- Aplica o filtro do salário
-- 3. Verifica o BENEFÍCIO para ESSE período
JOIN beneficios AS b
    ON r.id_fun = b.id_fun 
    AND r.Data_inicio = b.Data_inicio -- Garante que é do período recente
    AND b.tipo = 'Seguro Saúde'       -- Aplica o filtro do benefício
-- 4. Verifica o HISTÓRICO (em qualquer altura)
JOIN historico_empresas AS h 
    ON f.id_fun = h.id_fun 
    AND h.nome_empresa = 'Moura';
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Querie 20 original
SELECT f.id_fun, f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
sal.salario_bruto AS salario_atual,
d.nome AS nome_departamento,
(SELECT COUNT(*) -- subquery para contar formações 
FROM teve_formacao AS teve
WHERE teve.id_fun = f.id_fun
  ) AS num_formacoes
FROM funcionarios AS f 
LEFT JOIN departamentos AS d ON f.id_depart = d.id_depart
LEFT JOIN salario AS sal ON f.id_fun = sal.id_fun
WHERE sal.Data_inicio = (   -- Garante que só vemos o salário mais recente do funcionário
SELECT MAX(s_main.Data_inicio)
FROM salario s_main
WHERE s_main.id_fun = f.id_fun
    )
AND sal.salario_bruto > ( -- Compara esse salário com a MÉDIA ATUAL do departamento
SELECT AVG(s2.salario_bruto) 
FROM funcionarios AS f2 
LEFT JOIN salario AS s2 ON f2.id_fun = s2.id_fun
WHERE f2.id_depart = f.id_depart -- Do mesmo departamento
AND s2.Data_inicio = ( -- E que o salário (s2) seja o mais recente desse funcionário (f2), assume-se que a tendência natural é o maior salário ser sempre o mais recente
SELECT MAX(s3.Data_inicio)
FROM salario s3
WHERE s3.id_fun = f2.id_fun
    )
)
ORDER BY nome_departamento, salario_atual DESC;
-------------------------------------------------------------------------------------------------------------------------------

-- Querie 21 original
SELECT 
f.id_fun,
f.primeiro_nome || ' ' || f.ultimo_nome AS nome_completo,
s.salario_liquido,
-- distinct evita multiplicacao desnecessária entre tabelas com relações n:m entre elas
SUM(DISTINCT fe.num_dias)  as ferias_aprovadas,
COUNT(d.sexo) AS num_dep_Fem
FROM funcionarios AS f 
JOIN salario AS s 
  ON f.id_fun = s.id_fun 
JOIN ferias as fe 
  ON f.id_fun = fe.id_fun
JOIN dependentes AS d 
  ON f.id_fun = d.id_fun 
-- filtrar sexo feminino, salario liquido acima de 1550 euros e as férias aprovadas são as únicas contadas
WHERE (d.sexo = 'Feminino' AND s.salario_liquido >1500 and fe.estado_aprov = 'Aprovado')
GROUP BY f.id_fun,nome_completo, s.salario_liquido;
-------------------------------------------------------------------------------------------------------------------------------

-- Querie 22 original
SELECT 
d.nome,
f.id_depart, 
-- num_fem calculado abaixo, coalesce para cotar pessoas sem dependentes como zero, não como null
COALESCE(AVG(dep.num_fem),0) AS media_fem
-- subquery usada para da entidade dependentes ser filtrada apenas pessoas do sexo feminino e associar ao id_fun
-- daqui se cria num_fem usado para calcular a média acima referida
FROM (
  SELECT 
  id_fun, 
  COUNT(*) AS num_fem
  FROM dependentes
  WHERE sexo = 'Feminino' 
  GROUP BY id_fun
) AS dep
--  joins usados para associar id_depart e nome do departamento à média, agrupando-os com o group by
-- right join, não apenas join, para garantir que mesmo departamentos sem dependentes femininos são incluídos  
 RIGHT JOIN funcionarios AS f 
  ON f.id_fun = dep.id_fun
RIGHT JOIN departamentos as d 
  ON d.id_depart = f.id_depart
GROUP BY d.nome, f.id_depart;







ANALYZE departamentos;
ANALYZE funcionarios;
EXPLAIN ANALYZE
SELECT
  d.nome,              -- nome do departamento
  COUNT(f.id_fun) AS total_funcionarios -- número total de funcionários no departamento
FROM departamentos AS d
-- LEFT JOIN permite listar também departamentos sem funcionários
LEFT JOIN funcionarios AS f 
ON d.id_depart= f.id_depart
-- agrupa os resultados por departamento para fazer a contagem corretamente
GROUP BY d.nome
ORDER BY total_funcionarios DESC;