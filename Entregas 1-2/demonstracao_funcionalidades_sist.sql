set search_path TO bd054_schema, public;
BEGIN;
-- ============================================================
-- Demonstração de Funcionalidades do Sistema 
-- Objetivo: Mostrar operações CRUD e outras ações ligadas aos requisitos funcionais
-- e casos de uso da entrega 1 e demonstrar como funcionam.
-- ============================================================

-- ============================================================
-- CENÁRIO 1: Registo de Funcionário
-- RF: 1, 2
-- CU: 5.1 - Registo de Funcionário
-- ============================================================

-- Inserir um novo funcionário
INSERT INTO funcionarios (
    id_fun, nif, primeiro_nome, ultimo_nome,
    data_nascimento, cargo, id_depart
)
VALUES (
    1111, '123456789', 'Ana', 'Silva',
    '1995-04-10', 'Programadora', 1
);

-- Verificar que o funcionário foi inserido (CRUD - Read)
SELECT * FROM funcionarios WHERE id_fun = 1111;

-- Verificar criação automática de utilizador (trigger)
SELECT * FROM utilizadores WHERE id_fun = 1111;

-- Explicação:
-- O INSERT representa o registo de funcionário (RF1, CU5.1)
-- O SELECT confirma o registo
-- A trigger cria_utilizador representa a criação automática de credenciais (RF2)

-- ============================================================
-- CENÁRIO 2: Gestão Salarial
-- RF: 12, 13
-- CU: Atualizar Dados de Funcionário / Consultar Benefícios
-- ============================================================

-- Criar período de remuneração
INSERT INTO remuneracoes (id_fun, data_inicio, data_fim)
VALUES (1111, '2025-01-01', NULL);

-- Inserir salário bruto
INSERT INTO salario (id_fun, data_inicio, salario_bruto)
VALUES (1111, '2025-01-01', 2000);

-- Verificar cálculo automático do salário líquido (trigger)
SELECT salario_bruto, salario_liquido
FROM salario
WHERE id_fun = 1111;

-- Explicação:
-- Inserção em remuneracoes e salario representa atualização de salário (RF12)
-- Trigger calc_salario_liquido calcula o líquido automaticamente, cumprindo regras de negócio (RF13)

-- ============================================================
-- CENÁRIO 3: Pedido e Aprovação de Férias
-- RF: 9, 10
-- CU: 5.3 - Registar Férias e Ausências
-- ============================================================

-- Funcionário submete pedido de férias
INSERT INTO ferias (id_fun, data_inicio, data_fim)
VALUES (1111, '2025-07-01', '2025-07-10');

-- Verificar número de dias calculado automaticamente
SELECT id_fun, data_inicio, data_fim, num_dias, estado_aprov
FROM ferias
WHERE id_fun = 1111;

-- Aprovar férias via procedimento armazenado
CALL aprovar_ferias_proc(1111, '2025-07-01');

-- Confirmar aprovação
SELECT estado_aprov
FROM ferias
WHERE id_fun = 1111 AND data_inicio = '2025-07-01';

-- Explicação:
-- INSERT registra pedido de férias (RF9, CU5.3)
-- Trigger calcula num_dias automaticamente
-- CALL aprovar_ferias_proc representa aprovação pelo administrador (RF10)

-- ============================================================
-- CENÁRIO 4: Gestão de Dependentes
-- RF: 20
-- CU: 5.8 - Registar Dependentes
-- ============================================================

-- Inserir dependente válido
INSERT INTO dependentes (
    id_fun, nome, sexo, data_nascimento, parentesco
)
VALUES (
    1111, 'João Silva', 'Masculino', '2015-06-01', 'Filho(a)'
);

-- Consultar dependentes do funcionário
SELECT * FROM dependentes WHERE id_fun = 1111;

-- Explicação:
-- INSERT cumpre RF20 ao registar dependente
-- Trigger validar_datas_dependentes assegura integridade de datas (CU5.8)

-- ============================================================
-- CENÁRIO 5: Formação de Funcionários
-- RF: 17, 18
-- CU: Associar Funcionário a Formação
-- ============================================================

-- Criar formação
INSERT INTO formacoes (
    id_for, nome_formacao, descricao, data_inicio, data_fim, estado
)
VALUES (
    10, 'Formação SQL', 'Curso de SQL Avançado',
    '2025-03-01', '2025-03-15', 'Concluida'
);

-- Associar funcionário à formação
INSERT INTO teve_formacao (id_fun, id_for, data_inicio, data_fim)
VALUES (1111, 10, '2025-03-01', '2025-03-15');

-- Consultar número de aderentes
SELECT calcular_num_aderentes_formacao(10);

-- Explicação:
-- INSERT em formacoes representa criação de curso
-- INSERT em teve_formacao representa associação de funcionário a formação (RF17, CU)
-- Função calcular_num_aderentes_formacao cumpre RF18

-- ============================================================
-- CENÁRIO 6: Consultas e Relatórios
-- RF: 4, 5, 8
-- CU: Consultar Benefícios / Consultar Funcionários
-- ============================================================

-- Ver remuneração completa
SELECT * FROM vw_remun_completa;

-- Ver funcionários e departamentos
SELECT * FROM vw_funcionarios_departamentos;

-- Ver férias aprovadas
SELECT * FROM vw_ferias_aprovadas;

-- Ver média salarial por departamento
SELECT * FROM vw_media_salarial_departamento;

-- Ver estatísticas globais
SELECT * FROM vw_estatisticas_gerais;

-- Explicação:
-- Views permitem consultas consolidadas, alinhadas com RF4, RF5, RF8
-- Representam casos de uso de consulta de funcionários e benefícios




ROLLBACK;


