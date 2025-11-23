-- (nao testei nada)
-- o 4 indice, o composto, implica uma alteração do codigo das queries que ele influencia

---- Criação de índices para otimização de consultas

/* 
Por definição, índices B-tree são criados para colunas com alta cardinalidade e consultas frequentes
sendo úteis para igualdades e intervalos. Índices Hash são mais eficientes para consultas de igualdade em colunas com baixa cardinalidade.
-- Sem qualquer indicação do contrário, os índices são criados como B-tree.
*/

-- =======================================================================================================================================================================================================================
-- =======================================================================================================================================================================================================================



set search_path to bd054_schema, public;
--1
/* Índice B-tree para otimizar consultas que envolvam o id do departamento nos funcionários, foreign key.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por id_depart. 
As queries 1,3,5,9,10,11,15,18,22 serão melhoradas devido aos JOINs que usam do id_depart para relacionar 
as tabelas funcionarios e departamentos. 
*/

CREATE INDEX ind_fun_depart ON funcionarios(id_depart);


-- =======================================================================================================================================================================================================================

--2
/*
Índice B-tree responsável por organizar os dados referentes aos nomes dos departamentos
Otimiza consultas que filtrem por departamentos específicos ou usem ORDER BY por nome
É esperado que as queries 1,3,5,9,10,11,14,15,18,20,22 se beneficiem deste índice devido aos
JOIN, GROUP BY e ORDER BY que envolvem a tabela departamentos nestas queries.
*/

CREATE INDEX ind_nome_depart ON departamentos(nome);


-- =======================================================================================================================================================================================================================

--3
/*
Índice B-tree útil para ordenar os salários brutos dos funcionários.
Melhora o desempenho de consultas que envolvam ORDER BY ou filtrem por salário bruto.
É esperada alta cardinalidade nesta coluna, assim como frequentes consultas.
Queries com filtros de intervalo (>, <, BETWEEN) também se beneficiarão deste índice.
É esperado que as queries 2,9,15,19 e 20 melhorem seu desempenho com este índice devido às 
cláusulas WHERE, HAVING e filtros ( >, <) que envolvem a coluna salario_bruto nestas queries.
*/

CREATE INDEX ind_salario_bruto ON salario(salario_bruto);


-- =======================================================================================================================================================================================================================

--4
/* Índice composto B-tree para otimizar consultas que necessitem do salário mais recente de cada funcionário.
   Melhora o desempenho de buscas que filtrem por id_fun e ordenam por data de início em ordem decrescente.
   Queries que dão return ao salário atual de um funcionário específico serão beneficiadas por este índice
   As queries 2,3,4,9,15,19,20,21, devem beneficiar devido às subqueries que criam gargalos e loops excessivos
   ao buscar o salário mais recente dos funcionários, além disso HAVING e ORDER BY também se beneficiarão deste índice.
*/
CREATE INDEX ind_salario_fun_data ON salario(id_fun, data_inicio DESC);


-- =======================================================================================================================================================================================================================

--5
/* 
Índice B-tree para otimizar consultas que envolvam o tipo dos benefícios.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por tipo dos benefícios.
As queries 7 e 19 irão melhorar o seu desempenho devido aos filtros que pede um tipo específico de benefício, ou 
futuras queries que possam ter esta característica.
*/

CREATE INDEX ind_tipo_beneficio ON beneficios(tipo);

-- =======================================================================================================================================================================================================================

--6
/*
Índice Hash para otimizar consultas que envolvam o valor dos benefícios.
Útil para buscas rápidas por tipos específicos de benefícios, apenas por igualdade,
servirá para testar o desempenho comparativamente ao indice B-tree acima criado.
Assim como acima, por se tratarem de igualdades, as queries 7 e 19 vão beneficiar também, com um desempenho melhor
apesar de ser muito menos prático que o índice B-tree para a maioria dos casos.
*/ 

CREATE INDEX hash_tipo_beneficio ON beneficios USING HASH(tipo);


-- =======================================================================================================================================================================================================================

--7
/*
Índice B-tree para otimizar consultas que envolvam o valor dos benefícios.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por valor dos benefícios.
A query 7 é a única que terá o seu desempenho melhorado por este índice, devido ao SUM afetado indiretamente,
e HAVING que envolvem o valor dos benefícios.
*/

CREATE INDEX ind_valor_beneficio ON beneficios(valor);


-- =======================================================================================================================================================================================================================

--8
/*
Índice B-tree para otimizar consultas relacionadas ao parentesco dos dependentes dos funcionários.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por parentesco.
Este indice é especialmente útil no caso de haverem igualdades para o grau de parentesco, quer num WHERE ou num HAVING.
««««««A query 10 deve ser beneficiado por este índice, devido à agregação por parentesco.»»»»»»»»
*/

CREATE INDEX ind_parentesco_dependentes ON dependentes(parentesco);


-- =======================================================================================================================================================================================================================


--9
/*
Índice Hash para otimizar consultas que envolvam o parentesco dos dependentes.
Útil para buscas rápidas por tipos específicos de parentesco, apenas por igualdade,
servirá para testar o desempenho comparativamente ao indice B-tree acima criado.
*/

CREATE INDEX hash_parentesco_dependentes ON dependentes USING HASH(parentesco);



-- =======================================================================================================================================================================================================================

--10
/*
Índice B-tree para otimizar consultas relacionadas às justificações de faltas dos funcionários
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por justificações.
A query 14 vai beneficiar na parte do COUNT onde a contagem será acelerada. As funcionalidades do
índice B-tree não estão exploradas ao máximo nesta query pois não há ordenações ou filtros por intervalos.
*/

CREATE INDEX ind_justificacao_faltas ON faltas(justificacao);



-- =======================================================================================================================================================================================================================

--11
/*
Índice Hash para otimizar consultas que envolvam as justificações de faltas dos funcionários.
Útil para buscas rápidas por tipos específicos de justificações, apenas por igualdade,
vai servir para testar o desempenho comparando com o indice B-tree acima criado.
Este hash será especialmente útil no caso de haver algum WHERE ou HAVING onde se utiliza uma igualdade para a especifica justificação.
«««««««Assim como acima, a query 14 terá o desempenho melhorado, apresentará uma performance melhor»»»»»»»
devido à natureza das igualdades. 
*/

CREATE INDEX hash_justificacao_faltas ON faltas USING hash(justificacao);


-- =======================================================================================================================================================================================================================

--12
/*
Índice B-tree para otimizar consultas relacionadas às avaliações numéricas dos funcionários.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por avaliação numérica.
A query 9 terá um desempenho melhorado indiretamente, no calculo do AVG não afeta diretamente, caso necessário,
no uso de um WHERE ou ORDER BY envolvendo a avaliação numérica, o índice será útil.
*/

CREATE INDEX ind_avaliacao_num ON avaliacoes(avaliacao_numerica);


-- =======================================================================================================================================================================================================================

--13
/*
Índice composto B-tree útil para melhorar consultas que envolvam o período de férias dos funcionários.
Otimiza buscas que filtrem ou usem ORDER BY por datas de início e fim das férias.
As queries 5,8,21 serão afetadas indiretamente, caso haja necessidade de filtros ou ordenações por estas datas.
*/

CREATE INDEX datas_ferias ON ferias(data_inicio, data_fim);


-- =======================================================================================================================================================================================================================


--14
/* Índice B-tree para otimizar consultas que envolvam o nome da empresa no histórico de trabalho dos funcionários. 
Melhora o desempenho de buscas que filtrem, usem GROUP BY ou ORDER BY pela coluna nome_empresa. 
É esperado que as queries 16 e 19 melhorem o seu desempenho, pois dependem de filtros e agrupamentos por este nome. */

CREATE INDEX ind_nome_historico ON historico_empresas(nome_empresa);

--15
/* Índice B-tree útil para ordenar ou pesquisar pelo nome da formação. 
Otimiza consultas que filtrem por formações específicas ou usem ORDER BY pelo nome. 
A query 6 (que lida com a tabela formacoes) será beneficiada em cenários onde seja necessário pesquisar ou ordenar o resultado pelo nome da formação. */

CREATE INDEX ind_nome_formacao ON formacoes(nome_formacao);


-- =======================================================================================================================================================================================================================

--16
/* Índice B-tree baseado em expressão (Functional Index) para otimizar consultas que usem o nome completo concatenado (primeiro_nome || ' ' || ultimo_nome). 
Melhora o desempenho de buscas que usem esta expressão exata no ORDER BY ou GROUP BY, evitando que o sistema tenha que recalcular a concatenação a cada consulta. 
As queries 2, 4, 7, 10, 20, 21 serão beneficiadas por usarem a expressão de nome completo na ordenação dos resultados. */

CREATE INDEX ind_nome_completo ON funcionarios ((primeiro_nome || ' ' || ultimo_nome));


-- =======================================================================================================================================================================================================================


--17
/* Índice composto B-tree para otimizar consultas que buscam o maior número de dias de férias dentro de um determinado estado (ex: 'Aprovado'). 
Melhora o desempenho de buscas que filtrem por estado e procuram o valor máximo de dias (num_dias em ordem decrescente). 
As queries 8 (funcionário com mais dias de férias aprovadas) e 21 terão um benefício significativo, acelerando a busca pelo máximo de dias dentro do filtro 'Aprovado'. */

CREATE INDEX ind_ferias_estado_numdias_desc ON ferias(estado_aprov, num_dias DESC);


-- =======================================================================================================================================================================================================================

--18
/* Índice composto B-tree para otimizar consultas que envolvam o ID do funcionário e o nome da empresa no histórico de trabalho. 
É ideal para acelerar JOINs entre funcionarios e historico_empresas e a aplicação de filtros no nome da empresa. 
As queries 16 e 19 serão beneficiadas, pois precisam acessar rapidamente o histórico de trabalho do funcionário com um filtro específico no nome da empresa. */

CREATE INDEX ind_hist_emp_idfun_nome ON historico_empresas(id_fun, nome_empresa);


-- =======================================================================================================================================================================================================================

--19
/* Índice Parcial B-tree para otimizar buscas que filtram por dependentes do sexo feminino. 
Este índice armazena apenas os id_fun para os registos onde sexo = 'Feminino', 
reduzindo o volume de dados a ser lido em consultas que utilizam este filtro. 
As queries 21 e 22 terão uma melhoria substancial no seu desempenho, pois o filtro WHERE sexo = 'Feminino' é resolvido de forma muito mais eficiente. */

CREATE INDEX ind_dependentes_fem ON dependentes(id_fun) WHERE sexo = 'Feminino';





-- sugestoes a fazer , historico de empresas, formacoes, nome do funcionario
------------------------------------------------------

set search_path to bd054_schema, public;
DROP INDEX IF EXISTS ind_fun_depart;
DROP INDEX IF EXISTS ind_nome_depart;
DROP INDEX IF EXISTS ind_salario_bruto;
DROP INDEX IF EXISTS ind_salario_fun_data;
DROP INDEX IF EXISTS ind_tipo_beneficio;
DROP INDEX IF EXISTS hash_tipo_beneficio;
DROP INDEX IF EXISTS ind_valor_beneficio;
DROP INDEX IF EXISTS ind_parentesco_dependentes;
DROP INDEX IF EXISTS hash_parentesco_dependentes;
DROP INDEX IF EXISTS ind_justificacao_faltas;
DROP INDEX IF EXISTS hash_justificacao_faltas;
DROP INDEX IF EXISTS ind_avaliacao_num;
DROP INDEX IF EXISTS datas_ferias;
DROP INDEX IF EXISTS ind_nome_historico;
DROP INDEX IF EXISTS ind_nome_formacao;
DROP INDEX IF EXISTS ind_nome_completo;
DROP INDEX IF EXISTS ind_ferias_estado_numdias_desc;
DROP INDEX IF EXISTS ind_hist_emp_idfun_nome; 
DROP INDEX IF EXISTS ind_dependentes_fem;
-- =======================================================================================================================================================================================================================
