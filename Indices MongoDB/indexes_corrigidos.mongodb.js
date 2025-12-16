/**
 * =================================================================================
 * ÍNDICES MONGODB OTIMIZADOS - PROJETO DE MIGRAÇÃO
 * =================================================================================
 * Este script cria os índices necessários para suportar as 20 queries do projeto,
 * focando-se em chaves estrangeiras (Lookups), ordenações (Sorts) e filtros frequentes.
 */

// =================================================================================
// 1. COLEÇÃO 'FUNCIONARIOS' (A mais consultada)
// =================================================================================

/**
 * Índice: ID do Departamento
 * Justificativa: Suporta as Queries 1, 3, 5, 15, 18 e 20.
 * Explicação: Estas queries agrupam ($group) ou filtram funcionários por departamento.
 * Sem este índice, o Mongo teria de varrer todos os funcionários (COLLSCAN) para os separar.
 */
db.funcionarios.createIndex({ "profissional.id_depart_sql": 1 });

/**
 * Índice: Data de Início do Salário (Ordem Decrescente)
 * Justificativa: Suporta as Queries 3, 4, 15, 19 e 20.
 * Explicação: Quase todas as queries financeiras começam por pedir o "salário mais recente".
 * O índice {-1} permite ao Mongo encontrar o último salário instantaneamente sem ordenar em memória.
 */
db.funcionarios.createIndex({ "historico_salarial.inicio": -1 });

/**
 * Índice: Tipo de Benefício
 * Justificativa: Suporta as Queries 7 e 19.
 * Explicação: Otimiza a busca por "Seguro Saúde" ou "Carro Empresa" dentro do array de benefícios.
 */
db.funcionarios.createIndex({ "historico_salarial.beneficios.tipo": 1 });

/**
 * Índice: Histórico de Empresas Anteriores
 * Justificativa: Suporta a Query 19.
 * Explicação: Permite encontrar rapidamente quem trabalhou numa empresa específica (ex: "Moura")
 * sem ter de ler o histórico completo de toda a gente.
 */
db.funcionarios.createIndex({ "historico_empresas.empresa": 1 });

/**
 * Índice: Estado das Férias
 * Justificativa: Suporta a Query 8.
 * Explicação: Acelera a filtragem de férias "Aprovadas", ignorando as Pendentes/Rejeitadas.
 */
db.funcionarios.createIndex({ "registo_ausencias.ferias.estado": 1 });

/**
 * Índice: Formações Realizadas (Multikey Index) -- ADICIONADO NOVO
 * Justificativa: Suporta a Query 6 e Query 18.
 * Explicação: Como 'formacoes_realizadas' é um array, este índice permite agrupar 
 * ou filtrar eficientemente por ID de formação.
 */
db.funcionarios.createIndex({ "formacoes_realizadas.id_formacao_sql": 1 });

/**
 * Índice Composto: Departamento + Data Salário
 * Justificativa: Otimização específica para a Query 20.
 * Explicação: Esta query filtra pelo departamento E ordena pelo salário ao mesmo tempo.
 * O índice composto cobre ambas as operações num único passo (ESR Rule: Equality, Sort, Range).
 */
db.funcionarios.createIndex({ 
  "profissional.id_depart_sql": 1, 
  "historico_salarial.inicio": -1 
});

// --- Índices de Integridade e Identificação ---

// ID Original (SQL): Fundamental para todos os $lookup que ligam tabelas
db.funcionarios.createIndex({ "id_sql": 1 }, { unique: true });

// NIF: Identificador único fiscal (Evita duplicados)
db.funcionarios.createIndex({ "identificacao.nif": 1 }, { unique: true });

// Email: Usado para login ou pesquisa rápida de contactos
db.funcionarios.createIndex({ "contactos.email": 1 }, { unique: true });


// =================================================================================
// 2. COLEÇÃO 'VAGAS'
// =================================================================================

/**
 * Índice: Departamento da Vaga
 * Justificativa: Suporta a Query 11.
 * Explicação: Permite listar rapidamente todas as vagas de um departamento específico.
 */
db.vagas.createIndex({ "id_depart_sql": 1 });

/**
 * Índice: Estado da Vaga
 * Justificativa: Filtro de UI (Dashboard).
 * Explicação: Permite mostrar apenas vagas "Abertas" aos candidatos, escondendo as "Fechadas".
 */
db.vagas.createIndex({ "estado": 1 });

/**
 * Índice: Candidato (Dentro do array de candidaturas)
 * Justificativa: Histórico do Candidato.
 * Explicação: Permite saber rapidamente a que vagas o candidato X se candidatou.
 */
db.vagas.createIndex({ "candidaturas_recebidas.id_candidato_sql": 1 });

// ID Original
db.vagas.createIndex({ "id_sql": 1 }, { unique: true });


// =================================================================================
// 3. COLEÇÃO 'AVALIACOES'
// =================================================================================

/**
 * Índice Composto: Avaliado + Data
 * Justificativa: Histórico de Performance.
 * Explicação: Permite recuperar as avaliações de um funcionário ordenadas da mais recente para a mais antiga.
 */
db.avaliacoes.createIndex({ "avaliado_id_sql": 1, "data": -1 });

// ID Original (Não tem id_sql próprio na coleção, usa-se composto ou o _id automático)
// (Neste caso assumimos que as pesquisas são por quem foi avaliado)


// =================================================================================
// 4. COLEÇÃO 'CANDIDATOS'
// =================================================================================

// Email: Evitar que o mesmo candidato se registe duas vezes
db.candidatos.createIndex({ "contactos.email": 1 }, { unique: true });

// ID Original
db.candidatos.createIndex({ "id_sql": 1 }, { unique: true });


// =================================================================================
// 5. COLEÇÃO 'FORMACOES' & 'DEPARTAMENTOS' (Tabelas de Referência)
// =================================================================================

// IDs Originais: Essenciais para que os $lookup (JOINS) das queries principais funcionem.
// Sem isto, cada $lookup faria um scan completo nestas coleções.
db.formacoes.createIndex({ "id_sql": 1 }, { unique: true });
db.departamentos.createIndex({ "id_sql": 1 }, { unique: true });
