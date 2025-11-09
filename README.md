# Base de Dados BD054

Sistema de gestão de base de dados PostgreSQL para gestão de funcionários, departamentos, salários e projetos.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Configuração da Base de Dados](#configuração-da-base-de-dados)
- [Utilização](#utilização)
- [Geração de Dados](#geração-de-dados)
- [Manutenção](#manutenção)

## 🔧 Pré-requisitos

- [Visual Studio Code](https://code.visualstudio.com/) ou outro IDE de sua preferência
- [Extensão PostgreSQL da Microsoft](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-postgresql) para VS Code
- Python 3.x (apenas para geração de dados)

## 📥 Instalação

### 1. Obter o Repositório

Escolha uma das seguintes opções:

**Opção A: Download direto**
```bash
# Fazer download do repositório
# Descompactar o ficheiro ZIP
# Abrir a pasta no Visual Studio Code
```

**Opção B: Clonar com Git**
```bash
git clone https://github.com/DiogoGasGas/bd_054.git
cd bd_054
```

### 2. Instalar Extensões

No Visual Studio Code, instale:
- **PostgreSQL** (Microsoft) - para gestão da base de dados
- **Python** (Microsoft) - apenas se pretender gerar dados personalizados
- **Jupyter** (Microsoft) - apenas se pretender gerar dados personalizados

## 🗂️ Estrutura do Projeto

```
bd_054/
├── schema.sql                                    # Esquema da base de dados (tabelas)
├── procedures.sql                                # Stored procedures, triggers e views
├── data.sql                                      # Dados de exemplo
├── queries.sql                                   # Queries de teste e exemplos
├── gerar_dados.ipynb                             # Notebook para geração de dados
├── Apagar_trigger_functions_procedures_views.sql # Script de limpeza
├── ApagarTabelas_postgres.sql                    # Script para remover tabelas
└── README.md                                     # Este ficheiro
```

## 🔌 Configuração da Base de Dados

### 1. Adicionar Conexão PostgreSQL

No VS Code, clique no ícone da extensão PostgreSQL e adicione uma nova conexão com os seguintes dados:

| Parâmetro | Valor |
|-----------|-------|
| **Server name** | `appserver.alunos.di.fc.ul.pt` |
| **Authentication Type** | Password |
| **Username** | `bd054` |
| **Password** | `bd054` |
| **Database name** | `bd054` |

### 2. Inicializar a Base de Dados

Execute os seguintes ficheiros **pela ordem indicada** na conexão criada:

1. **`schema.sql`** - Cria as tabelas e estrutura da base de dados
2. **`procedures.sql`** - Adiciona stored procedures, triggers, functions e views
3. **`data.sql`** - Insere dados de exemplo

> ⚠️ **Importante**: A ordem de execução é crucial para evitar erros de dependências.

## 🚀 Utilização

### Executar Queries

Abra o ficheiro `queries.sql` e execute as queries de exemplo para:
- Consultar número de funcionários por departamento
- Listar funcionários com salário acima da média
- Visualizar remunerações por departamento
- E outras consultas de análise

### Executar um Ficheiro SQL

1. Abra o ficheiro SQL desejado
2. Clique com o botão direito no editor
3. Selecione **"Execute Query"** ou use o atalho `Ctrl+Shift+E`

## 🔄 Geração de Dados

Se pretender gerar dados personalizados ou adicionar mais registos:

### 1. Instalar Dependências Python

```bash
pip install faker pandas numpy
```

> **Nota**: As bibliotecas `random` e `datetime` já estão incluídas no Python.

### 2. Executar o Notebook

1. Abra o ficheiro `gerar_dados.ipynb`
2. Selecione um kernel Python
3. Execute todas as células (`Run All`)

Será criado um novo ficheiro `dados_insersao.sql` com os dados gerados.

### 3. Inserir os Novos Dados

Execute o ficheiro `dados_insersao.sql` gerado na sua conexão PostgreSQL.

## 🧹 Manutenção

### Limpar a Base de Dados

Se precisar de reiniciar a base de dados ou corrigir problemas:

#### Opção 1: Remover apenas Triggers, Functions, Procedures e Views

```sql
-- Execute o ficheiro:
Apagar_trigger_functions_procedures_views.sql
```

#### Opção 2: Remover Todas as Tabelas

```sql
-- Execute os ficheiros pela ordem:
1. Apagar_trigger_functions_procedures_views.sql
2. ApagarTabelas_postgres.sql
```

Depois de limpar, repita os passos da [Inicialização da Base de Dados](#2-inicializar-a-base-de-dados).

## 📝 Notas Adicionais

- O schema utiliza `bd054_schema` como namespace
- Certifique-se de que tem permissões adequadas no servidor
- Para questões ou problemas, consulte os comentários nos ficheiros SQL

## 👥 Autores

- Diogo Gaspar nº62145
- João Guiomar nº62179
- Mariana Ferreira nº62180

---

**Última atualização**: Novembro 2025
