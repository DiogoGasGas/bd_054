// ===================================================================
// ÍNDICES MONGODB - BD054 (CORRIGIDOS)
// ===================================================================
// Estratégia: Indexar campos usados em queries frequentes
// Nota: _id já tem índice automático em todas as coleções
// ===================================================================


// ===================================================================
// COLEÇÃO: funcionarios
// ===================================================================

// 1. Queries por departamento (Query 1, 3, 5, 14, 15, 18, 20)
// Usado para agrupar, filtrar e agregar por departamento
db.funcionarios.createIndex({ "profissional.id_depart_sql": 1 })

// 2. Buscar salário mais recente (Query 3, 4, 15, 19, 20)
// Usado para ordenar e pegar o último salário do array historico_salarial
db.funcionarios.createIndex({ "historico_salarial.inicio": -1 })

// 3. Filtrar por tipo de benefício (Query 7, 19)
// Usado para queries que procuram funcionários com benefícios específicos
db.funcionarios.createIndex({ "historico_salarial.beneficios.tipo": 1 })

// 4. Buscar por empresa anterior (Query 19)
// Usado para encontrar funcionários que trabalharam em empresas específicas
db.funcionarios.createIndex({ "historico_empresas.empresa": 1 })

// 5. Buscar por NIF (operações CRUD, autenticação, validações)
// UNIQUE porque NIF é identificador único de cada funcionário
db.funcionarios.createIndex({ "identificacao.nif": 1 }, { unique: true })

// 6. Buscar por email (login, recuperação senha, contacto)
// UNIQUE porque email não pode ser duplicado
db.funcionarios.createIndex({ "contactos.email": 1 }, { unique: true })

// 7. Buscar por id_sql (sincronização com PostgreSQL)
// UNIQUE para manter integridade na sincronização entre sistemas
db.funcionarios.createIndex({ "id_sql": 1 }, { unique: true })

// 8. Queries de férias por estado (Query 8)
// Usado para listar férias aprovadas, por aprovar, rejeitadas
db.funcionarios.createIndex({ "registo_ausencias.ferias.estado": 1 })

// 9. Índice composto: Departamento + Data salário (Query 20)
// Otimiza queries que filtram por departamento E ordenam por data de salário
db.funcionarios.createIndex({ 
  "profissional.id_depart_sql": 1, 
  "historico_salarial.inicio": -1 
})

// 10. Índice composto: Empresa anterior + Data salário (Query 19)
// Otimiza queries que filtram histórico de empresas E salário
db.funcionarios.createIndex({ 
  "historico_empresas.empresa": 1,
  "historico_salarial.inicio": -1
})


// ===================================================================
// COLEÇÃO: vagas
// ===================================================================

// 11. Listar vagas por departamento (Query 11)
// Usado para mostrar vagas abertas de um departamento específico
db.vagas.createIndex({ "id_depart_sql": 1 })

// 12. Filtrar vagas por estado (UI: vagas abertas/fechadas/canceladas)
// Usado em listagens e dashboards
db.vagas.createIndex({ "estado": 1 })

// 13. Buscar por id_sql (sincronização PostgreSQL)
db.vagas.createIndex({ "id_sql": 1 }, { unique: true })

// 14. Queries sobre candidatos específicos em vagas
// Usado para ver todas as vagas onde um candidato se candidatou
db.vagas.createIndex({ "candidaturas_recebidas.id_candidato_sql": 1 })

// 15. Queries sobre recrutadores
// Usado para ver candidaturas geridas por um recrutador específico
db.vagas.createIndex({ "candidaturas_recebidas.recrutador_id_sql": 1 })


// ===================================================================
// COLEÇÃO: avaliacoes
// ===================================================================

// 16. Buscar avaliações de um funcionário (ordenadas por data)
// Índice composto para otimizar query do histórico de avaliações
db.avaliacoes.createIndex({ "avaliado_id_sql": 1, "data": -1 })

// 17. Buscar avaliações feitas por um avaliador
// Usado para ver todas as avaliações que um gestor fez
db.avaliacoes.createIndex({ "avaliador_id_sql": 1 })


// ===================================================================
// COLEÇÃO: candidatos
// ===================================================================

// 18. Buscar por id_sql (sincronização PostgreSQL)
db.candidatos.createIndex({ "id_sql": 1 }, { unique: true })

// 19. Buscar candidato por email (contacto, evitar duplicados)
db.candidatos.createIndex({ "contactos.email": 1 })


// ===================================================================
// COLEÇÃO: formacoes
// ===================================================================

// 20. Buscar por id_sql (sincronização PostgreSQL)
db.formacoes.createIndex({ "id_sql": 1 }, { unique: true })

// 21. Filtrar formações por estado (ativas/concluídas/canceladas)
// Usado para mostrar apenas formações disponíveis
db.formacoes.createIndex({ "estado": 1 })


// ===================================================================
// COLEÇÃO: departamentos
// ===================================================================

// 22. Buscar por id_sql (sincronização PostgreSQL)
db.departamentos.createIndex({ "id_sql": 1 }, { unique: true })

// 23. Buscar departamentos geridos por um funcionário específico
// Usado para validações e queries de gestão
db.departamentos.createIndex({ "id_gerente_sql": 1 })


// ===================================================================
// SCRIPT PARA REMOVER ÍNDICES (usar se necessário refazer)
// ===================================================================
/*
// ATENÇÃO: Isto remove TODOS os índices exceto _id
// Use apenas se precisar recriar os índices do zero

db.funcionarios.dropIndexes()
db.vagas.dropIndexes()
db.avaliacoes.dropIndexes()
db.candidatos.dropIndexes()
db.formacoes.dropIndexes()
db.departamentos.dropIndexes()

// Depois execute os createIndex acima novamente
*/
