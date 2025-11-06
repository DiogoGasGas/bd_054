set search_path TO bd054_schema, public;

--- Criar a tabela dos funcionários primeiro sem o id do departamento

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

-- Criar a tabela departamentos

CREATE TABLE departamentos (
    id_depart INT PRIMARY KEY, --- id_depart chave primária
    nome VARCHAR(100) NOT NULL,
    id_gerente INT UNIQUE,
    FOREIGN KEY (id_gerente) REFERENCES funcionarios(id_fun)  --- id_gerente referencia um funcionário da tabela funcionarios
    ON DELETE SET NULL
    ON UPDATE CASCADE,
    CHECK(nome IN ('Recursos Humanos', 'Tecnologia da Informação', 'Financeiro', 'Marketing', 'Vendas', 'Qualidade', 'Atendimento ao Cliente', 'Jurídico'))  --- Estes são os nomes dos departamentos existentes
);

--- Adicionar a coluna id do departamento na tabela funcionarios e esse id referencia um dos departamentos da tabela departamentos

ALTER TABLE funcionarios
ADD COLUMN id_depart INT; 

ALTER TABLE funcionarios
ADD FOREIGN KEY (id_depart) REFERENCES departamentos(id_depart)
ON DELETE SET NULL  --- Ao apagar um departamento todos os funcionários desse departamento ficam com o departamento NULL
ON UPDATE CASCADE;

-- Criar tabela remuneracoes entidade fraca dos funcionarios

CREATE TABLE remuneracoes (
    id_fun INT,
    data_inicio DATE,
    data_fim DATE,
    PRIMARY KEY (id_fun, data_inicio),   
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK(data_fim > data_inicio)
);

--- Criar tabela salarios especialização das remuneracoes

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

--- Criar tabela beneficios especialização das remuneracoes

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

--- Criar tabela ferias entidade fraca dos funcionarios

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

--- Criar tabela dependentes entidade fraca dos funcionarios (filhos, pai, mãe, conjugue, outro)

CREATE TABLE dependentes (
    id_fun INT,
    nome VARCHAR(100),
    sexo VARCHAR(10),
    data_nascimento DATE,
    parentesco VARCHAR(20),
    PRIMARY KEY(id_fun, nome),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun) 
    ON DELETE CASCADE
    ON UPDATE CASCADE, 
    CHECK (sexo IN ('Masculino', 'Feminino', 'Outro')) 
);

--- Criar tabela faltas entidade fraca dos funcionarios

CREATE TABLE faltas (
    id_fun INT,
    data DATE,
    justificacao VARCHAR(255),
    PRIMARY KEY (id_fun, data),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)    
    ON DELETE CASCADE
    ON UPDATE CASCADE
);


--- Criar tabela historico_empresas entidade fraca dos funcionarios

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


--- Criar tabela candidatos 

CREATE TABLE candidatos (
    id_cand INT,
    nome VARCHAR(100),
    email VARCHAR(100),
    telemovel VARCHAR(20), 
    cv BYTEA, 
    carta_motivacao BYTEA,
    PRIMARY KEY (id_cand)
);


--- Criar tabela vagas


CREATE TABLE vagas (
    id_vaga INT,
    data_abertura DATE,
    estado VARCHAR(20),
    id_depart INT,
    PRIMARY KEY (id_vaga),
    FOREIGN KEY (id_depart) REFERENCES departamentos(id_depart),
    CHECK (estado IN ('Aberta', 'Fechada', 'Suspensa'))
);


--- Criar tabela candidato_a (tabela associativa entre candidatos e vagas)

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


--- Criar tabela requisitos_vaga (tabela fraca de vagas)

CREATE TABLE requisitos_vaga (
    id_vaga INT,
    requisito VARCHAR(100),
    PRIMARY KEY (id_vaga, requisito),
    FOREIGN KEY (id_vaga) REFERENCES vagas(id_vaga)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
);


--- Criar tabela formacoes

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


--- Criar tabela teve_formacao (tabela associativa entre funcionarios e formacoes)
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


--- Criar tabela avaliacoes

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


--- Criar tabela utilizadores entidade fraca dos funcionarios

CREATE TABLE utilizadores (
    id_fun INT,
    password VARCHAR(30) NOT NULL,
    PRIMARY KEY (id_fun, password),
    FOREIGN KEY (id_fun) REFERENCES funcionarios(id_fun)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

--- Criar tabela permissoes

CREATE TABLE permissoes (
    id_fun INT,
    permissao VARCHAR(40),
    PRIMARY KEY(id_fun, permissao),
    FOREIGN KEY(id_fun) REFERENCES funcionarios(id_fun)
    ON DELETE CASCADE 
    ON UPDATE CASCADE
);


