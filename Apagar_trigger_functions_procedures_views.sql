SET search_path TO bd054_schema, public;

-- ==========================================================
-- 1) TRIGGERS
-- ==========================================================
DROP TRIGGER IF EXISTS trg_validar_dias_ferias ON ferias;
DROP TRIGGER IF EXISTS trg_calc_salario_liquido ON salario;
DROP TRIGGER IF EXISTS trg_registrar_mudanca_cargo ON funcionarios;
DROP TRIGGER IF EXISTS trg_validar_idade_funcionario ON funcionarios;
DROP TRIGGER IF EXISTS trg_cria_utilizador ON funcionarios;
DROP TRIGGER IF EXISTS trg_delete_permissoes ON funcionarios;
DROP TRIGGER IF EXISTS trg_calcular_num_dias_ferias ON ferias;
DROP TRIGGER IF EXISTS trg_validar_datas_dependentes ON dependentes;
DROP TRIGGER IF EXISTS trg_validar_datas_remuneracoes ON remuneracoes;

-- ==========================================================
-- 2) PROCEDURES
-- ==========================================================
DROP PROCEDURE IF EXISTS aprovar_ferias_proc(INT, DATE) CASCADE;
DROP PROCEDURE IF EXISTS adicionar_candidatura_proc(INT, INT, INT) CASCADE;
DROP PROCEDURE IF EXISTS adicionar_uma_formacao(INT, VARCHAR, VARCHAR, DATE, DATE, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS adicionar_avaliacao(INT, INT, DATE, BYTEA, VARCHAR, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS adicionar_funcionario_proc(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE, VARCHAR, INT
) CASCADE;

-- ==========================================================
-- 3) FUNCTIONS (inclui funções de trigger)
-- ==========================================================
-- Funções de trigger
DROP FUNCTION IF EXISTS validar_dias_ferias() CASCADE;
DROP FUNCTION IF EXISTS calc_salario_liquido() CASCADE;
DROP FUNCTION IF EXISTS registrar_mudanca_cargo() CASCADE;
DROP FUNCTION IF EXISTS validar_idade_funcionario() CASCADE;
DROP FUNCTION IF EXISTS cria_utilizador() CASCADE;
DROP FUNCTION IF EXISTS delete_permissoes() CASCADE;
DROP FUNCTION IF EXISTS calcular_num_dias_ferias() CASCADE;
DROP FUNCTION IF EXISTS validar_datas_dependentes() CASCADE;
DROP FUNCTION IF EXISTS validar_datas_remuneracoes() CASCADE;

-- Funções normais
DROP FUNCTION IF EXISTS calcular_total_dias_permitidos(INT) CASCADE;
DROP FUNCTION IF EXISTS descontos(NUMERIC) CASCADE;
DROP FUNCTION IF EXISTS calcular_num_total_funcionarios() CASCADE;
DROP FUNCTION IF EXISTS calcular_num_funcionarios_departamento(INT) CASCADE;
DROP FUNCTION IF EXISTS calcular_num_aderentes_formacao(INT) CASCADE;
DROP FUNCTION IF EXISTS calc_idade(DATE) CASCADE;

-- ==========================================================
-- 4) VIEWS
-- ==========================================================
DROP VIEW IF EXISTS vw_funcionarios_departamentos CASCADE;
DROP VIEW IF EXISTS vw_ferias_aprovadas CASCADE;
DROP VIEW IF EXISTS vw_media_salarial_departamento CASCADE;
DROP VIEW IF EXISTS vw_formacoes_funcionarios CASCADE;
DROP VIEW IF EXISTS vw_vagas_candidatos CASCADE;
DROP VIEW IF EXISTS vw_estatisticas_gerais CASCADE;
DROP VIEW IF EXISTS vw_remun_completa CASCADE;
