(nao testei nada)
o 4 indice, o composto, implica uma alteração do codigo das queries que ele influencia

---- Criação de índices para otimização de consultas

/* 
Por definição, índices B-tree são criados para colunas com alta cardinalidade e consultas frequentes
sendo úteis para igualdades e intervalos. Índices Hash são mais eficientes para consultas de igualdade em colunas com baixa cardinalidade.
    Sem qualquer idnicação do contrário, os índices são criados como B-tree.
*/

-- =======================================================================================================================================================================================================================
-- =======================================================================================================================================================================================================================

/* Índice B-tree para otimizar consultas que envolvam o id do departamento nos funcionários, foreign key.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por id_depart. 
As queries 1,3,5,9,10,11,15,18,22 serão melhoradas devido aos JOINs que usam do id_depart para relacionar 
as tabelas funcionarios e departamentos. 
*/

CREATE INDEX ind_fun_depart ON funcionarios(id_depart);

/*
Índice B-tree responsável por organizar os dados referentes aos nomes dos departamentos
Otimiza consultas que filtrem por departamentos específicos ou usem ORDER BY por nome
É esperado que as queries 1,3,5,9,10,11,14,15,18,20,22 se beneficiem deste índice devido aos
JOIN, GROUP BY e ORDER BY que envolvem a tabela departamentos netsas queries.
*/

CREATE INDEX ind_nome_depart ON departamentos(nome);

/*
Índice B-tree útil para ordenar os salários brutos dos funcionários.
Melhora o desempenho de consultas que envolvam ORDER BY ou filtrem por salário bruto.
É esperada alta cardinalidade nesta coluna, assim como frequentes consultas.
Queries com filtros de intervalo (>, <, BETWEEN) também se beneficiarão deste índice.
É esperado que as queries 2,9,15,19 e 20 melhorem seu desempenho com este índice devido às 
cláusulas WHERE, HAVING e filtros ( >, <) que envolvem a coluna salario_bruto nestas queries.
*/

CREATE INDEX ind_salario_bruto ON salario(salario_bruto);

/* Índice composto B-tree para otimizar consultas que necessitem do salário mais recente de cada funcionário.
   Melhora o desempenho de buscas que filtrem por id_fun e ordenam por data de início em ordem decrescente.
   Queries que dão return ao salário atual de um funcionário específico serão beneficiadas por este índice
   As queries 2,3,4,9,15,19,20,21, devem benenficiar devido às subqueries que criam gargalos e loops excessivos
   ao buscar o salário mais recente dos funcionários, além disso HAVING e ORDER BY também se beneficiarão deste índice.
*/
CREATE INDEX ind_salario_fun_data ON salario(id_fun, data_inicio DESC);

/* 
Índice B-tree para otimizar consultas que envolvam o tipo dos benefícios.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por tipo dos benefícios.
As queries 7 e 19 irão melhorar o seu desempenho devido aos filtros que pede um tipo específico de benefício, ou 
futuras queries que possam ter esta característica.
*/

CREATE INDEX ind_tipo_beneficio ON beneficios(tipo);

/*
Índice Hash para otimizar consultas que envolvam o valor dos benefícios.
Útil para buscas rápidas por tipos específicos de benefícios, apenas por igualdade,
servirá para testar o desempenho comparativamente ao indice B-tree acima criado.
Assim como acima, por se tratarem de igualdades, as queries 7 e 19 vão beneficiar também, com um desempenho melhor
apesar de ser muito menos prático que o índice B-tree para a maioria dos casos.
*/ 

CREATE INDEX hash_tipo_beneficio ON beneficios USING HASH(tipo);

/*
Índice B-tree para otimizar consultas que envolvam o valor dos benefícios.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por valor dos benefícios.
A query 7 é a única que terá o seu desempenho melhorado por este índice, devido ao SUM afetado indiretamente,
e HAVING que envolvem o valor dos benefícios.
*/

CREATE INDEX ind_valor_beneficio ON beneficios(valor);

/*
Índice B-tree para otimizar consultas relacionadas ao parentesco dos dependentes dos funcionários.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por parentesco.
A query 10 deve ser beneficiado por este índice, devido à agregação por parentesco.
*/

CREATE INDEX ind_parentesco_dependentes ON dependentes(parentesco);

/*
Índice Hash para otimizar consultas que envolvam o parentesco dos dependentes.
Útil para buscas rápidas por tipos específicos de parentesco, apenas por igualdade,
servirá para testar o desempenho comparativamente ao indice B-tree acima criado.
*/

CREATE INDEX hash_parentesco_dependentes ON dependentes USING HASH(parentesco);

/*
Índice B-tree para otimizar consultas relacionadas às justificações de faltas dos funcionários
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por justificações.
A query 14 vai beneficiar na parte do COUNT onde a contagem será acelerada. As funcionalidades do
índice B-tree não estão exploradas ao máximo nesta query pois não há ordenações ou filtros por intervalos.
*/

CREATE INDEX ind_justificacao_faltas ON faltas(justificacao);

/*
Índice Hash para otimizar consultas que envolvam as justificações de faltas dos funcionários.
Útil para buscas rápidas por tipos específicos de justificações, apenas por igualdade,
vai servir para testar o desempenho comparando com o indice B-tree acima criado.
Assim como acima, a query 14 terá o desempenho melhorado, apresentará uma performance melhor
devido à natureza das igualdades. 
*/

CREATE INDEX hash_justificacao_faltas ON faltas USING hash(justificacao);

/*
Índice B-tree para otimizar consultas relacionadas às avaliações numéricas dos funcionários.
Melhora o desempenho de buscas que filtrem ou usem ORDER BY por avaliação numérica.
A query 9 terá um desempenho melhorado indiretamente, no caclulo do AVG não afeta diretamente, caso necessário,
no uso de um WHERE ou ORDER BY envolvendo a avaliação numérica, o índice será útil.
*/

CREATE INDEX ind_avaliacao_num ON avaliacoes(avaliacao_numerica);

/*
Índice composto B-tree útil para melhorar consultas que envolvam o período de férias dos funcionários.
Otimiza buscas que filtrem ou usem ORDER BY por datas de início e fim das férias.
As queries 5,8,21 serão afetadas indiretamente, caso haja necessidade de filtros ou ordenações por estas datas.
*/

CREATE INDEX datas_ferias ON ferias(data_inico, data_fim);


-- sugestoes a fazer , historico de empresas, formacoes
------------------------------------------------------

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
