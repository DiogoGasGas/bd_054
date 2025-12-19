
set search_path to bd054_schema, public;

-- cenário 1:
-- Teste de ROLLBACK (Falha)
BEGIN;

-- Passo 1: Insere funcionário (Isto funciona corretamente)
INSERT INTO funcionarios (id_fun, nif, primeiro_nome, ultimo_nome) 
VALUES (8888, '123456789', 'Teste', 'Erro');

-- Passo 2: Insere um registo de salário com um valor inválido (Isto vai falhar)
INSERT INTO salario (id_fun, data_inicio, salario_bruto, salario_liquido) 
VALUES (8888, '2026-01-21', 'Texto em vez de numero', 1234); 

-- O PostgreSQL vai dar erro: "invalid input syntax for type numeric"
-- A transação faz ROLLBACK.

COMMIT;

ROLLBACK;
-- =======================================================================================================================================================================================================================



-- cenário 2:
-- Teste de COMMIT (Sucesso)
SET search_path TO bd054_schema, public;
BEGIN;

--Passo 1: Insere funcionário (Isto funciona)
INSERT INTO funcionarios (id_fun, nif, primeiro_nome, ultimo_nome)
VALUES (9999, '123456879', 'Teste', 'Sucesso');

-- Passo 2: Insere uma palavra-passe válida para o funcionário (Isto também funciona)
INSERT INTO Utilizadores (ID_Fun, Password)
VALUES (9999, 'X2pB9yK7aE3g');

-- Como ambos os passos funcionaram, fazemos o COMMIT da transação.
-- Resultado: O funcionário 9999 EXISTIRÁ na base de dados.
COMMIT;

ROLLBACK;

-- =======================================================================================================================================================================================================================



-- Cenário 3: Contratação de um candidato e fecho da respetiva vaga
BEGIN;

-- Passo 1: Atualizar o estado do candidato para 'Contratado'
-- (Vamos supor que o candidato 50 se candidatou à vaga 10)
UPDATE candidato_a
SET estado = 'Contratado', data_cand = CURRENT_DATE
WHERE id_cand = 50 AND id_vaga = 10;

-- Passo 2: Fechar a vaga (já que foi preenchida)
UPDATE vagas
SET estado = 'Fechada'
WHERE id_vaga = 10;

-- Se ambos os updates funcionarem, confirmamos a operação.
COMMIT;


ROLLBACK;


-- =======================================================================================================================================================================================================================


-- Cenário 4: Inserção de múltiplos períodos de férias (Atomicidade)
BEGIN;

-- Passo 1: Inserir o primeiro pedido de férias (Dados VÁLIDOS)
-- Isto funcionaria se fosse executado sozinho.
INSERT INTO ferias (id_fun, data_inicio, data_fim, num_dias, estado_aprov)
VALUES (20, '2024-06-01', '2024-06-15', 15, 'Por aprovar');

-- Passo 2: Inserir o segundo pedido de férias (Dados INVÁLIDOS - Erro de Datas)
-- Neste caso a data de fim (dia 1) é anterior à data de início (dia 20).
-- Isto viola a CHECK constraint da tabela ferias.
INSERT INTO ferias (id_fun, data_inicio, data_fim, num_dias, estado_aprov)
VALUES (20, '2024-08-20', '2024-08-01', 20, 'Por aprovar');

-- CONCLUSÃO: 
-- O PostgreSQL deteta o erro no Passo 2 e faz o ROLLBACK automático.
-- Resultado: Nem as férias de Agosto, nem as férias de Junho (Passo 1) ficam gravadas.

COMMIT;

ROLLBACK;

-- =======================================================================================================================================================================================================================
-- cenário 5: Promoção de Funcionário
SET search_path TO bd054_schema, public;
BEGIN;

-- Passo 1: Mudar o cargo do funcionário (Vamos promover o ID 10)
UPDATE funcionarios
SET cargo = 'Senior Developer'
WHERE id_fun = 10;

-- Passo 2: Atualizar o salário correspondente à promoção
INSERT INTO salario (id_fun, data_inicio, salario_bruto, salario_liquido)
VALUES (10, CURRENT_DATE, 3500.00, 2400.00);

-- Se ambos funcionarem, a promoção é oficializada.
COMMIT;

ROLLBACK;
-- =======================================================================================================================================================================================================================

-- Cenário 6: Registo de Avaliação e Atribuição de Permissão
BEGIN;

-- Vamos usar o ID 30 como funcionário e o ID 1 como avaliador
-- 1. Inserir a avaliação de desempenho
INSERT INTO avaliacoes (id_fun, id_avaliador, data, avaliacao_numerica, criterios, autoavaliacao)
VALUES (30, 1, CURRENT_DATE, 4, 'Liderança e Qualidade', 'Atingi todos os objetivos.');

-- 2. Atribuir uma nova permissão no sistema como resultado desta avaliação
INSERT INTO permissoes (id_fun, permissao)
VALUES (30, 'ACESSO_RELATORIOS_GESTAO');

-- Sucesso: O COMMIT garante que o funcionário tem a avaliação registada E a permissão.
COMMIT;

ROLLBACK;
-- =======================================================================================================================================================================================================================


-- cenário 7: Inserção de Dependente com Violação de Chave Primária
BEGIN;

-- Vamos usar o ID 50 como funcionário.

-- Passo 1: Inserir o dependente 'Pedro' como 'Filho' (Isto funciona)
INSERT INTO dependentes (id_fun, nome, parentesco, sexo, data_nascimento)
VALUES (50, 'Pedro', 'Filho', 'Masculino', '2010-01-01');

-- Passo 2: Tentar inserir o EXATO MESMO dependente novamente
-- Isto vai FALHAR, pois a combinação (50, 'Filho', 'Pedro') já existe no Passo 1.
INSERT INTO dependentes (id_fun, nome, parentesco, sexo, data_nascimento)
VALUES (50, 'Pedro', 'Filho', 'Masculino', '2010-01-01');

-- O PostgreSQL falha no Passo 2 com erro: "violates primary key constraint"
-- A transação faz ROLLBACK.
-- Resultado: O dependente 'Pedro' não é adicionado à base de dados.

COMMIT;

ROLLBACK;


-- =======================================================================================================================================================================================================================
-- cenário 8: Demissão de Funcionário com Erro na Atualização do Funcionário substituto
BEGIN;

-- 1. DELETE do funcionário 100 (Simulando a demissão)
-- Esta ação dispara o CASCADE: apaga o salário, férias, dependentes, utilizadores, etc.
-- Também faz SET NULL no id_gerente do departamento que ele geria.
DELETE FROM funcionarios
WHERE id_fun = 100; 

-- 2. Tentar ATUALIZAR um dado crucial (NIF) do funcionário 200 (o substituto) com um ERRO
-- O NIF é 'NOT NULL' na sua tabela, logo, tentar definir o NIF para NULL (vazio) é proibido.
UPDATE funcionarios
SET nif = NULL
WHERE id_fun = 200; 

-- O Passo 2 falha: "violates not-null constraint on column nif"
-- A transação falha e faz ROLLBACK.
-- Resultado: O funcionário 100 não é apagado (não é demitido) e o NIF do funcionário 200 não é alterado.

COMMIT;

ROLLBACK;
-- =======================================================================================================================================================================================================================


-- cenário 9: Gestão de Candidaturas com Atualização de Estado e Recrutador
BEGIN;
-- Tenhamos em conta que o candidato 3 se candidatou às vagas 40 e 894.

-- Passo 1: Atualizar o estado da candidatura para 'Em análise'
UPDATE candidato_a
SET estado = 'Em análise'
WHERE id_cand = 3 AND id_vaga = 40;

-- Passo 2: Atribuir o recrutador responsável pela análise
UPDATE candidato_a
SET id_recrutador = 2
WHERE id_cand = 3 AND id_vaga = 894;

-- O COMMIT garante que o estado da candidatura só é alterado se o recrutador for atribuído.
COMMIT;

ROLLBACK;


