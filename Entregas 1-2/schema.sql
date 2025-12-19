set search_path TO bd054_schema, public;

-- ====================================================================
-- TABELA: funcionarios
-- Armazena informações dos funcionários da empresa
-- Criada primeiro sem referência ao departamento para evitar dependência circular
-- ====================================================================

CREATE TABLE funcionarios (
    id_fun INT PRIMARY KEY,   --- id_fun chave primária
    nif VARCHAR(20) UNIQUE NOT NULL,
    primeiro_nome VARCHAR(50) NOT NULL,
    ultimo_nome VARCHAR(50) NOT NULL,
    nome_rua VARCHAR(100),
    nome_localidade VARCHAR(100),
    codigo_postal VARCHAR(10),
    num_telemovel VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    data_nascimento DATE,
    cargo VARCHAR(50)
);

-- ====================================================================
-- TABELA: departamentos
-- Armazena os departamentos da empresa e seu gerente
-- ====================================================================

CREATE TABLE departamentos (
    id_depart INT PRIMARY KEY, --- id_depart chave primária
    nome VARCHAR(100) NOT NULL,
    id_gerente INT UNIQUE,
    FOREIGN KEY (id_gerente) REFERENCES funcionarios(id_fun)  --- id_gerente referencia um funcionário da tabela funcionarios
    ON DELETE SET NULL
    ON UPDATE CASCADE,
    CHECK(nome IN ('Recursos Humanos', 'Tecnologia da Informação', 'Financeiro', 'Marketing', 'Vendas', 'Qualidade', 'Atendimento ao Cliente', 'Jurídico'))  --- Estes são os nomes dos departamentos existentes
);

-- ====================================================================
-- Adicionar relação funcionario-departamento
-- Estabelece a ligação entre funcionários e seus departamentos
-- ====================================================================

ALTER TABLE funcionarios
ADD COLUMN id_depart INT; 

ALTER TABLE funcionarios
ADD FOREIGN KEY (id_depart) REFERENCES departamentos(id_depart)
ON DELETE SET NULL  --- Ao apagar um departamento todos os funcionários desse departamento ficam com o departamento NULL
ON UPDATE CASCADE;

-- ====================================================================
-- TABELA: remuneracoes
-- Entidade fraca - armazena períodos de remuneração dos funcionários
-- ====================================================================

CREATE TABLE remuneracoes (
    id_fun INT,
    data_inicio DATE,
    data_fim DATE,
    PRIMARY KEY (id_fun, data_inicio),   
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK(data_fim >= data_inicio)
);

-- ====================================================================
-- TABELA: salario
-- Especialização de remunerações - armazena valores de salários
-- ====================================================================

CREATE TABLE salario (
    id_fun INT,
    data_inicio DATE,
    salario_bruto DECIMAL(10,2),
    salario_liquido DECIMAL(10,2),
    PRIMARY KEY (id_fun, data_inicio),
    FOREIGN KEY (id_fun, data_inicio) REFERENCES remuneracoes(id_fun, data_inicio)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ====================================================================
-- TABELA: beneficios
-- Especialização de remunerações - armazena benefícios adicionais
-- ====================================================================

CREATE TABLE beneficios (
    id_fun INT,
    data_inicio DATE,
    tipo VARCHAR(50),
    valor DECIMAL(10,2),
    PRIMARY KEY (id_fun, data_inicio, tipo),
    FOREIGN KEY (id_fun, data_inicio) REFERENCES remuneracoes(id_fun, data_inicio)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK (tipo IN ('Subsídio Alimentação', 'Seguro Saúde', 'Carro Empresa', 'Subsídio Transporte', 'Telemóvel Empresa'))
);

-- ====================================================================
-- TABELA: ferias
-- Entidade fraca - regista pedidos de férias dos funcionários
-- ====================================================================

CREATE TABLE ferias (
    id_fun INT,
    data_inicio DATE,
    data_fim DATE,
    num_dias INT,
    estado_aprov VARCHAR(20) DEFAULT 'Por aprovar',
    PRIMARY KEY (id_fun, data_inicio),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK(data_fim > data_inicio),
    CHECK(estado_aprov IN ('Aprovado', 'Rejeitado', 'Por aprovar'))
);

-- ====================================================================
-- TABELA: dependentes
-- Entidade fraca - regista dependentes dos funcionários (familiares)
-- ====================================================================

CREATE TABLE dependentes (
    id_fun INT,
    nome VARCHAR(100),
    sexo VARCHAR(10),
    data_nascimento DATE,
    parentesco VARCHAR(20),
    PRIMARY KEY(id_fun, parentesco, nome),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun) 
    ON DELETE CASCADE
    ON UPDATE CASCADE, 
    CHECK (sexo IN ('Masculino', 'Feminino', 'Outro')) 
);

-- ====================================================================
-- TABELA: faltas
-- Entidade fraca - regista faltas dos funcionários e suas justificações
-- ====================================================================

CREATE TABLE faltas (
    id_fun INT,
    data DATE,
    justificacao VARCHAR(255),
    PRIMARY KEY (id_fun, data),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)    
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ====================================================================
-- TABELA: historico_empresas
-- Entidade fraca - armazena experiência profissional anterior dos funcionários
-- ====================================================================

CREATE TABLE historico_empresas (
    id_fun INT,
    nome_empresa VARCHAR(50),
    cargo VARCHAR(100), 
    data_inicio DATE,
    data_fim DATE,
    PRIMARY KEY (id_fun, data_inicio),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    CHECK (data_fim IS NULL OR data_fim > data_inicio)
);

-- ====================================================================
-- TABELA: candidatos
-- Armazena informações de candidatos a vagas na empresa
-- ====================================================================

CREATE TABLE candidatos (
    id_cand INT,
    nome VARCHAR(100),
    email VARCHAR(100),
    telemovel VARCHAR(20), 
    cv BYTEA, 
    carta_motivacao BYTEA,
    PRIMARY KEY (id_cand)
);

-- ====================================================================
-- TABELA: vagas
-- Regista as vagas de emprego disponíveis na empresa
-- ====================================================================

CREATE TABLE vagas (
    id_vaga INT,
    data_abertura DATE,
    estado VARCHAR(20),
    id_depart INT,
    PRIMARY KEY (id_vaga),
    FOREIGN KEY (id_depart) REFERENCES departamentos(id_depart),
    CHECK (estado IN ('Aberta', 'Fechada', 'Suspensa'))
);

-- ====================================================================
-- TABELA: candidato_a
-- Tabela associativa - relaciona candidatos com vagas a que se candidataram
-- ====================================================================

CREATE TABLE candidato_a (
    id_cand INT,
    id_vaga INT,
    data_cand DATE NOT NULL DEFAULT CURRENT_DATE,
    estado VARCHAR(20) DEFAULT 'Submetido',
    id_recrutador INT,
    PRIMARY KEY (id_cand, id_vaga),
    FOREIGN KEY (id_cand) REFERENCES candidatos(id_cand)
    ON DELETE CASCADE,
    FOREIGN KEY (id_vaga) REFERENCES vagas(id_vaga)
    ON DELETE CASCADE,
    FOREIGN KEY (id_recrutador) REFERENCES funcionarios(id_fun)
    ON DELETE SET NULL,
    CHECK (estado IN ('Submetido', 'Em análise', 'Entrevista', 'Rejeitado', 'Contratado'))
);

-- ====================================================================
-- TABELA: requisitos_vaga
-- Entidade fraca - armazena os requisitos necessários para cada vaga
-- ====================================================================

CREATE TABLE requisitos_vaga (
    id_vaga INT,
    requisito VARCHAR(100),
    PRIMARY KEY (id_vaga, requisito),
    FOREIGN KEY (id_vaga) REFERENCES vagas(id_vaga)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
);

-- ====================================================================
-- TABELA: formacoes
-- Armazena cursos e formações disponibilizados pela empresa
-- ====================================================================

CREATE TABLE formacoes (
    id_for INT,
    nome_formacao VARCHAR(100),
    descricao VARCHAR(255), 
    data_inicio DATE,
    data_fim DATE,
    estado VARCHAR(20) DEFAULT 'Planeada',
    PRIMARY KEY (id_for),
    CHECK (data_fim IS NULL OR data_fim > data_inicio), 
    CHECK (estado IN ('Planeada', 'Em curso', 'Concluida', 'Cancelada'))
);

-- ====================================================================
-- TABELA: teve_formacao
-- Tabela associativa - relaciona funcionários com formações que frequentaram
-- ====================================================================

CREATE TABLE teve_formacao (
    id_fun INT,
    id_for INT, 
    certificado BYTEA,
    data_inicio DATE,
    data_fim DATE,
    PRIMARY KEY (id_fun, id_for),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
    ON DELETE CASCADE   
    ON UPDATE CASCADE,
    FOREIGN KEY (id_for) REFERENCES formacoes(id_for)
    ON DELETE CASCADE   
    ON UPDATE CASCADE,
    CHECK (data_fim IS NULL OR data_fim >= data_inicio) 
);

-- ====================================================================
-- TABELA: avaliacoes
-- Regista avaliações de desempenho dos funcionários
-- ====================================================================

CREATE TABLE avaliacoes (
    id_fun INT,
    id_avaliador INT,
    data DATE,
    avaliacao BYTEA,
    avaliacao_numerica INT,
    criterios VARCHAR(500),
    autoavaliacao VARCHAR(500),
    PRIMARY KEY (id_fun, id_avaliador, data),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    FOREIGN KEY (id_avaliador) REFERENCES funcionarios(id_fun)
    ON DELETE SET NULL 
    ON UPDATE CASCADE
);

-- ====================================================================
-- TABELA: utilizadores
-- Entidade fraca - armazena credenciais de acesso ao sistema
-- ====================================================================

CREATE TABLE utilizadores (
    id_fun INT,
    password VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_fun, password),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ====================================================================
-- TABELA: permissoes
-- Define as permissões de acesso de cada utilizador no sistema
-- ====================================================================

CREATE TABLE permissoes (
    id_fun INT,
    permissao VARCHAR(40),
    PRIMARY KEY(id_fun, permissao),
    FOREIGN KEY(id_fun) REFERENCES funcionarios(id_fun)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
);




-- triggers

set search_path TO bd054_schema, public;


-- Trigger que calcula o numero o numero de dias de ferias automaticamente
-- Tem que ser rodado antes do trigger de validar dias de ferias
CREATE OR REPLACE FUNCTION calcular_num_dias_ferias()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se as datas são válidas
    IF NEW.data_fim < NEW.data_inicio THEN
        RAISE NOTICE 
            'A data de fim (%) não pode ser anterior à data de início (%)',
            NEW.data_fim, NEW.data_inicio;
    END IF;

    -- Calcula o número de dias de férias automaticamente
    NEW.num_dias := NEW.data_fim - NEW.data_inicio + 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado 
CREATE TRIGGER trg_calcular_num_dias_ferias
BEFORE INSERT OR UPDATE ON ferias
FOR EACH ROW
EXECUTE FUNCTION calcular_num_dias_ferias();



--- trigger para validar dias de ferias
set search_path TO bd054_schema, public;
CREATE OR REPLACE FUNCTION validar_dias_ferias()
RETURNS TRIGGER AS $$
DECLARE
    v_dias_permitidos INT;
BEGIN
    -- Usa a função correta que calcula o total de dias permitidos
    v_dias_permitidos := calcular_total_dias_permitidos(NEW.id_fun);

    -- Verifica se o funcionário está a tentar tirar mais dias do que tem direito
    IF NEW.num_dias > v_dias_permitidos THEN
        RAISE NOTICE 
            'O funcionário % não pode tirar % dias, máximo permitido é %', 
            NEW.id_fun, NEW.num_dias, v_dias_permitidos;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_dias_ferias
BEFORE INSERT OR UPDATE ON ferias
FOR EACH ROW
EXECUTE FUNCTION validar_dias_ferias();




-- Função para calcular o total de descontos sobre o salário bruto
CREATE OR REPLACE FUNCTION descontos(p_salario_bruto NUMERIC)
RETURNS NUMERIC AS $$
DECLARE
    v_descontos NUMERIC;  -- Guarda o valor total dos descontos
BEGIN
    -- Aplica uma taxa de 11% de Segurança Social e 12% de IRS
    v_descontos := p_salario_bruto * (0.11 + 0.12);

    -- Retorna o valor total dos descontos calculado
    RETURN v_descontos;
END;
$$ LANGUAGE plpgsql;




--- trigger para calcular salario liquido

CREATE OR REPLACE FUNCTION calc_salario_liquido()
RETURNS TRIGGER AS $$
DECLARE
    v_descontos NUMERIC;
    v_salario_liquido NUMERIC;
BEGIN
    -- Chama a função que calcula os descontos
    v_descontos := descontos(NEW.salario_bruto);

    -- Calcula o salário líquido
    v_salario_liquido := NEW.salario_bruto - v_descontos;

    -- Evita salário líquido negativo
    IF v_salario_liquido < 0 THEN
        RAISE NOTICE 
            'O salário líquido não pode ser negativo: bruto=%, descontos=%', 
            NEW.salario_bruto, v_descontos;
    END IF;

    -- Atualiza o campo da nova linha
    NEW.salario_liquido := v_salario_liquido;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado

CREATE TRIGGER trg_calc_salario_liquido
BEFORE INSERT OR UPDATE ON salario
FOR EACH ROW
EXECUTE FUNCTION calc_salario_liquido();









--- trigger para registar mudanca de cargo no historico_empresas

CREATE OR REPLACE FUNCTION registrar_mudanca_cargo()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se o cargo foi alterado
    IF OLD.cargo IS DISTINCT FROM NEW.cargo THEN
        -- CORREÇÃO: Removemos a referência à coluna "nome_departamento"
        INSERT INTO historico_empresas (id_fun, nome_empresa, cargo, data_inicio, data_fim)
        VALUES (NEW.id_fun, 'Empresa Atual', NEW.cargo, CURRENT_DATE, NULL);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;









-- Trigger que impede de inserir funcionários com menos de 16 anos
CREATE OR REPLACE FUNCTION validar_idade_funcionario()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica a idade mínima
    IF NEW.data_nascimento > CURRENT_DATE - INTERVAL '16 years' THEN
        RAISE NOTICE 
            'O funcionário % tem idade inferior a 16 anos', 
            NEW.primeiro_nome || ' ' || NEW.ultimo_nome;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado
CREATE TRIGGER trg_validar_idade_funcionario
BEFORE INSERT ON funcionarios
FOR EACH ROW
EXECUTE FUNCTION validar_idade_funcionario();





-- Trigger que cria automaticamente um utilizador ao inserir um funcionário
CREATE OR REPLACE FUNCTION cria_utilizador()
RETURNS TRIGGER AS $$
BEGIN
    -- Insere o novo utilizador com password temporária
    INSERT INTO utilizadores (id_fun, password)
    VALUES (NEW.id_fun, 'password_temporaria');
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado
CREATE TRIGGER trg_cria_utilizador
AFTER INSERT ON funcionarios
FOR EACH ROW
EXECUTE FUNCTION cria_utilizador();
-- Elimina as permissões associadas ao funcionário ao apagar o funcionário





-- Trigger que remove permissões associadas a um funcionário eliminado
CREATE OR REPLACE FUNCTION delete_permissoes()
RETURNS TRIGGER AS $$
BEGIN
    -- Apaga as permissões do funcionário removido
    DELETE FROM permissoes WHERE id_fun = OLD.id_fun;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado
CREATE TRIGGER trg_delete_permissoes
AFTER DELETE ON funcionarios
FOR EACH ROW
EXECUTE FUNCTION delete_permissoes();
-- trigger para calcular num dias ferias







-- Trigger que valida a coerência de datas entre funcionário e dependente
CREATE OR REPLACE FUNCTION validar_datas_dependentes()
RETURNS TRIGGER AS $$
DECLARE
    v_data_funcionario DATE;  -- Data de nascimento do funcionário
BEGIN
    -- Busca a data de nascimento do funcionário
    SELECT data_nascimento INTO v_data_funcionario
    FROM funcionarios
    WHERE id_fun = NEW.id_fun;

    -- Se o funcionário não existir, lança erro
    IF v_data_funcionario IS NULL THEN
        RAISE EXCEPTION 'Funcionário com ID % não encontrado.', NEW.id_fun;
    END IF;

    -- Caso o dependente seja um filho(a)
    IF NEW.parentesco = 'Filho(a)' THEN
        IF NEW.data_nascimento <= v_data_funcionario THEN
            RAISE EXCEPTION 
                'O dependente (Filho(a)) deve nascer após o funcionário (ID %).', NEW.id_fun;
        END IF;
    END IF;

    -- Caso o dependente seja pai/mãe
    IF NEW.parentesco = 'Pai/Mãe' THEN
        IF NEW.data_nascimento >= v_data_funcionario THEN
            RAISE EXCEPTION 
                'O dependente (Pai/Mãe) deve ser mais velho que o funcionário (ID %).', NEW.id_fun;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger associado à tabela 'dependentes'
-- É executado antes de cada inserção ou atualização,
-- para garantir que a relação de idade é coerente
CREATE TRIGGER trg_validar_datas_dependentes
BEFORE INSERT OR UPDATE ON dependentes
FOR EACH ROW
EXECUTE FUNCTION validar_datas_dependentes();





-- Trigger que valida as datas de início e fim na tabela 'remuneracoes'
CREATE OR REPLACE FUNCTION validar_datas_remuneracoes()
RETURNS TRIGGER AS $$
BEGIN
    -- Verifica se a data de fim foi fornecida antes de comparar
    IF NEW.data_fim IS NOT NULL AND NEW.data_inicio >= NEW.data_fim THEN
        RAISE NOTICE 
            'A data de início (%) deve ser anterior à data de fim (%)',
            NEW.data_inicio, NEW.data_fim;
    END IF;

    -- Garante que a data de início não está no futuro
    IF NEW.data_inicio > CURRENT_DATE THEN
        RAISE NOTICE 
            'A data de início (%) não pode ser no futuro', NEW.data_inicio;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;






