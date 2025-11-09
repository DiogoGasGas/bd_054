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


