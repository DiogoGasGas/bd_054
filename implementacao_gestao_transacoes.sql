-- Teste de ROLLBACK (Falha)
BEGIN;

-- Passo 1: Insere funcionário (Isto funciona)
INSERT INTO funcionarios (id_fun, primeiro_nome, ultimo_nome) 
VALUES (8888, 'Teste', 'Erro');

-- Passo 2: Tenta inserir salário com erro (ex: violação de chave estrangeira ou tipo de dado errado)
-- Aqui forçámos um erro usando um valor inválido para o campo salario_bruto
INSERT INTO salario (id_fun, salario_bruto) 
VALUES (8888, 'Texto em vez de numero'); -- ERRO PROPOSITADO

-- Como deu erro, o PostgreSQL faz o ROLLBACK automático da transação atual.
-- Resultado: O funcionário 8888 NÃO existirá na base de dados, mesmo o passo 1 estando correto.

COMMIT;







-- Teste de COMMIT (Sucesso)
BEGIN;

--Passo 1: Insere funcionário (Isto funciona)
INSERT INTO funcionarios (id_fun, primeiro_nome, ultimo_nome)
VALUES (9999, 'Teste', 'Sucesso');

-- Passo 2: Insere uma palavra-passe válida para o funcionário (Isto também funciona)
INSERT INTO Utilizadores (ID_Fun, Password)
VALUES (9999, 'X2pB9yK7aE3g');

-- Como ambos os passos funcionaram, fazemos o COMMIT da transação.
-- Resultado: O funcionário 9999 EXISTIRÁ na base de dados.
COMMIT;



