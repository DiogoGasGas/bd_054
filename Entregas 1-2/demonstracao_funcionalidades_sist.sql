set search_path TO bd054_schema, public;
BEGIN;
-- ============================================================
-- DEMONSTRAÇÃO DE FUNCIONALIDADES DO SISTEMA
-- Sistema de Gestão de Recursos Humanos
-- ============================================================


-- ============================================================
-- CENÁRIO 1: Admissão de um novo funcionário
-- Demonstra:
--  - Inserção de funcionário
--  - Validação da idade mínima (trigger)
--  - Criação automática de utilizador (trigger)
--  - Integridade referencial com departamentos
-- ============================================================

-- Inserir um departamento (Não funciona porque já existe um departamento com id 1)
INSERT INTO departamentos (id_depart, nome)
VALUES (1, 'Tecnologia da Informação');

-- Inserir um novo funcionário válido
INSERT INTO funcionarios (
    id_fun, nif, primeiro_nome, ultimo_nome,
    data_nascimento, cargo, id_depart
)
VALUES (
    1111, '123456789', 'Ana', 'Silva',
    '1995-04-10', 'Programadora', 1
);

-- Verificar que o funcionário foi inserido
SELECT * FROM funcionarios WHERE id_fun = 1111;

-- Verificar que o utilizador foi criado automaticamente
-- (trigger trg_cria_utilizador)
SELECT * FROM utilizadores WHERE id_fun = 1111;


-- ============================================================
-- CENÁRIO 2: Gestão salarial do funcionário
-- Demonstra:
--  - Inserção de remuneração
--  - Cálculo automático do salário líquido (trigger)
--  - Uso de função de descontos
-- ============================================================

-- Criar período de remuneração
INSERT INTO remuneracoes (id_fun, data_inicio, data_fim)
VALUES (1111, '2025-01-01', NULL);

-- Inserir salário bruto
INSERT INTO salario (id_fun, data_inicio, salario_bruto)
VALUES (1111, '2025-01-01', 2000);
-- Verificar cálculo automático do salário líquido
SELECT salario_bruto, salario_liquido
FROM salario
WHERE id_fun = 1111;

SELECT * FROM remuneracoes WHERE id_fun = 1111;

-- ============================================================
-- CENÁRIO 3: Pedido e aprovação de férias
-- Demonstra:
--  - Cálculo automático do número de dias de férias
--  - Validação do limite de dias permitidos
--  - Aprovação de férias via procedure
-- ============================================================

-- Funcionário submete pedido de férias
INSERT INTO ferias (id_fun, data_inicio, data_fim)
VALUES (1111, '2025-07-01', '2025-07-10');

-- Verificar que o número de dias foi calculado automaticamente
SELECT id_fun, data_inicio, data_fim, num_dias, estado_aprov
FROM ferias
WHERE id_fun = 1111;

-- Aprovar férias usando procedimento armazenado
CALL aprovar_ferias_proc(1111, '2025-07-01');

-- Confirmar aprovação
SELECT estado_aprov
FROM ferias
WHERE id_fun = 1111 AND data_inicio = '2025-07-01';



-- ============================================================
-- CENÁRIO 4: Gestão de dependentes
-- Demonstra:
--  - Inserção de dependente válida
--  - Validação de coerência de datas (trigger)
-- ============================================================

-- Inserir dependente válido (filho mais novo que o funcionário)
INSERT INTO dependentes (
    id_fun, nome, sexo, data_nascimento, parentesco
)
VALUES (
    1111, 'João Silva', 'Masculino', '2015-06-01', 'Filho(a)'
);

-- Consultar dependentes do funcionário
SELECT * FROM dependentes WHERE id_fun = 1111;


-- ============================================================
-- CENÁRIO 5: Formação e aderência de funcionários
-- Demonstra:
--  - Inserção de formação
--  - Associação funcionário-formação
--  - Uso de função para contar aderentes
-- ============================================================

-- Criar uma formação
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

-- Ver número de aderentes à formação
SELECT calcular_num_aderentes_formacao(10);

-- Ver detalhes da formação
select * from formacoes where id_for = 10; 

-- Verificar associação funcionário-formação
select * from teve_formacao where id_fun = 1111; 
-- ============================================================
-- CENÁRIO 6: Relatórios e views
-- Demonstra:
--  - Uso e verificação de funcionamento de views 
-- ============================================================

-- Ver remuneração completa (salário + benefícios)
SELECT * FROM vw_remun_completa;

-- Ver funcionários e respetivos departamentos
SELECT * FROM vw_funcionarios_departamentos;

-- Ver férias aprovadas
SELECT * FROM vw_ferias_aprovadas;

-- Ver média salarial por departamento
SELECT * FROM vw_media_salarial_departamento;

-- Ver estatísticas globais do sistema
SELECT * FROM vw_estatisticas_gerais;



ROLLBACK;