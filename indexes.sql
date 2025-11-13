
-- ( nao testei nada)
CREATE INDEX ind_nome_depart ON departamentos(nome);
CREATE INDEX ind_salario_bruto ON salario(salario_bruto);
CREATE INDEX ind_tipo_beneficio ON beneficios(tipo);
CREATE INDEX hash_tipo_beneficio ON beneficios USING hash(tipo);
CREATE INDEX ind_valor_beneficio ON beneficios(valor);
CREATE INDEX ind_parentesco_dependentes ON dependentes(parentesco);
CREATE INDEX hash_parentesco_dependentes ON dependentes USING hash(parentesco);
CREATE INDEX ind_justificacao_faltas ON faltas(justificacao);
CREATE INDEX hash_justificacao_faltas ON faltas USING hash(justificacao);
CREATE INDEX ind_avaliacao_num ON avaliacoes(avaliacao_numerica);
CREATE INDEX datas_ferias ON ferias(data_inico, data_fim);
------------------------------------------------------
DROP INDEX IF EXISTS ind_nome_depart;
DROP INDEX IF EXISTS ind_salario_bruto;
DROP INDEX IF EXISTS ind_tipo_beneficio;
DROP INDEX IF EXISTS hash_tipo_beneficio;
DROP INDEX IF EXISTS ind_valor_beneficio;
DROP INDEX IF EXISTS ind_parentesco_dependentes;
DROP INDEX IF EXISTS hash_parentesco_dependentes;
DROP INDEX IF EXISTS ind_justificacao_faltas;
DROP INDEX IF EXISTS hash_justificacao_faltas;
DROP INDEX IF EXISTS ind_avaliacao_num;
DROP INDEX IF EXISTS datas_ferias;
