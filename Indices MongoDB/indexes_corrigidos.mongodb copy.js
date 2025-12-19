// ===================================================================
// ÍNDICES MONGODB - BD054 (Alinhado com 7 Coleções)
// ===================================================================
// Estratégia: Indexar campos usados nas 15 queries + operações CRUD
// Nota: _id já tem índice automático em todas as coleções
// ===================================================================


// ===================================================================
// COLEÇÃO: funcionarios
// ===================================================================

// 1. Queries por cargo (Query 1: pesquisa flexível por cargo)
// Permite buscar "Gestor", "Analista", etc. com regex case-insensitive
db.funcionarios.createIndex({ "info_profissional.cargo": 1 });

// 2. Queries por departamento (Query 5, 8: agregações por departamento)
// Usado para agrupar benefícios, calcular médias de idade, etc.
db.funcionarios.createIndex({ "info_profissional.departamento.nome_depart": 1 });

// 3. Queries por departamento ID (sincronização, filtros, joins)
// Usado para ligar com vagas (id_depart_sql) e análises estatísticas
db.funcionarios.createIndex({ "info_profissional.departamento.id_depart_sql": 1 });

// 4. Buscar por empresa anterior (Query 3: histórico de empresas)
// Usado para encontrar funcionários que trabalharam em empresas específicas
db.funcionarios.createIndex({ "historico_empresas.empresa": 1 });

// 5. Queries de benefícios (Query 5: benefícios mais comuns)
// Usado após $unwind para agrupar por tipo de benefício
db.funcionarios.createIndex({ "salario_atual.beneficios.tipo": 1 });

// 6. Queries salariais (Query 4: histograma salarial, agregações)
// Usado para $bucket, filtros de faixa salarial, estatísticas
db.funcionarios.createIndex({ "salario_atual.base": 1 });

// 7. Queries por data de nascimento (Query 8: pirâmide etária)
// Usado para calcular idade ($dateDiff) e análises demográficas
db.funcionarios.createIndex({ "identificacao.data_nascimento": 1 });

// 8. Buscar por NIF (CRUD, autenticação, validações)
// UNIQUE porque NIF é identificador único de cada funcionário
db.funcionarios.createIndex({ "identificacao.nif": 1 }, { unique: true });

// 9. Buscar por nome completo (Query 1: pesquisa flexível, autocomplete)
// Permite buscar "Silva", "João", etc. com regex
db.funcionarios.createIndex({ "identificacao.nome_completo": 1 });

// 10. Buscar por email (login, recuperação senha, contacto, Query 10)
// UNIQUE porque email não pode ser duplicado no sistema
db.funcionarios.createIndex({ "contactos.email": 1 }, { unique: true });

// 11. Buscar por id_sql (sincronização PostgreSQL, lookups)
// UNIQUE para manter integridade na sincronização entre sistemas
db.funcionarios.createIndex({ "id_sql": 1 }, { unique: true });

// 12. Índice composto: Departamento + Salário (análises salariais por depto)
// Otimiza queries que filtram por departamento E analisam salários
db.funcionarios.createIndex({ 
  "info_profissional.departamento.id_depart_sql": 1, 
  "salario_atual.base": -1 
});


// ===================================================================
// COLEÇÃO: historico_salarial (SEPARADA - agrupada por funcionario_id)
// ===================================================================

// 13. Buscar histórico de um funcionário (Query 6: evolução salarial)
// UNIQUE porque há apenas 1 documento por funcionário_id (contém array periodos)
db.historico_salarial.createIndex({ "funcionario_id": 1 }, { unique: true });

// 14. Queries sobre períodos salariais (datas de início/fim)
// Usado para ordenar períodos, buscar salário em data específica
db.historico_salarial.createIndex({ "periodos.data_inicio": -1 });

// 15. Queries sobre benefícios históricos
// Usado para analisar evolução de benefícios ao longo do tempo
db.historico_salarial.createIndex({ "periodos.beneficios.tipo": 1 });


// ===================================================================
// COLEÇÃO: ausencias (SEPARADA - agrupada por funcionario_id)
// ===================================================================

// 16. Buscar ausências de um funcionário (Query 2: custo de ausências)
// UNIQUE porque há apenas 1 documento por funcionário_id (contém array ausencias)
db.ausencias.createIndex({ "funcionario_id": 1 }, { unique: true });

// 17. Filtrar por tipo de ausência (férias vs faltas)
// Usado para relatórios separados de férias e faltas
db.ausencias.createIndex({ "ausencias.tipo": 1 });

// 18. Queries por data de ausência (relatórios mensais/anuais)
// Usado para listar ausências em período específico
db.ausencias.createIndex({ "ausencias.data": -1 });

// 19. Queries por estado (aprovadas, pendentes, rejeitadas)
// Usado para dashboard de aprovações pendentes
db.ausencias.createIndex({ "ausencias.estado": 1 });

// 20. Índice composto: Tipo + Data (relatórios específicos)
// Otimiza queries como "férias aprovadas em 2024"
db.ausencias.createIndex({ 
  "ausencias.tipo": 1, 
  "ausencias.data": -1 
});


// ===================================================================
// COLEÇÃO: avaliacoes (SEPARADA - agrupada por funcionario_id)
// ===================================================================

// 21. Buscar avaliações de um funcionário (Query 13: top avaliações)
// UNIQUE porque há apenas 1 documento por funcionário_id (contém array avaliacoes)
db.avaliacoes.createIndex({ "funcionario_id": 1 }, { unique: true });

// 22. Queries por pontuação (Query 13: funcionários com nota 5)
// Usado para filtrar após $unwind (avaliações com nota específica)
db.avaliacoes.createIndex({ "avaliacoes.pontuacao": 1 });

// 23. Queries por avaliador (ver avaliações feitas por um gestor)
// Usado para análise de padrões de avaliação por gestor
db.avaliacoes.createIndex({ "avaliacoes.avaliador_id_sql": 1 });

// 24. Queries por data (relatórios de avaliações recentes)
// Usado para ordenar e filtrar avaliações por período
db.avaliacoes.createIndex({ "avaliacoes.data": -1 });


// ===================================================================
// COLEÇÃO: vagas
// ===================================================================

// 25. Filtrar vagas por estado (Query 11: funil de vagas abertas)
// Usado em listagens e dashboards (Aberta, Fechada, Cancelada)
db.vagas.createIndex({ "estado": 1 });

// 26. Listar vagas por departamento (filtro departamental)
// Usado para mostrar vagas abertas de um departamento específico
db.vagas.createIndex({ "id_depart_sql": 1 });

// 27. Queries por requisitos (Query 12: requisitos complexos)
// Usado para buscar vagas com skill específica ("Java", "Python")
db.vagas.createIndex({ "requisitos": 1 });

// 28. Buscar por id_sql (sincronização PostgreSQL)
// UNIQUE para manter integridade com sistema original
db.vagas.createIndex({ "id_sql": 1 }, { unique: true });

// 29. Queries sobre estado de candidaturas (Query 11: funil)
// Usado para contar candidaturas "Aprovadas", "Rejeitadas", etc.
db.vagas.createIndex({ "candidaturas_recebidas.estado": 1 });

// 30. Queries sobre candidatos específicos
// Usado para ver todas as vagas onde um candidato se candidatou
db.vagas.createIndex({ "candidaturas_recebidas.id_candidato_sql": 1 });

// 31. Índice composto: Estado + Departamento (dashboard de RH)
// Otimiza queries como "vagas abertas no Departamento Financeiro"
db.vagas.createIndex({ 
  "estado": 1, 
  "id_depart_sql": 1 
});


// ===================================================================
// COLEÇÃO: candidatos
// ===================================================================

// 32. Buscar por id_sql (sincronização PostgreSQL, lookups)
// UNIQUE para manter integridade com sistema original
db.candidatos.createIndex({ "id_sql": 1 }, { unique: true });

// 33. Buscar candidato por email (Query 14: candidatos Gmail)
// Usado para contacto, evitar duplicados, regex @gmail.com
db.candidatos.createIndex({ "contactos.email": 1 });

// 34. Buscar por nome (autocomplete, pesquisa)
// Usado para encontrar candidatos por nome parcial
db.candidatos.createIndex({ "nome": 1 });


// ===================================================================
// COLEÇÃO: formacoes
// ===================================================================

// 35. Buscar por id_sql (sincronização PostgreSQL)
// UNIQUE para manter integridade com sistema original
db.formacoes.createIndex({ "id_sql": 1 }, { unique: true });

// 36. Filtrar formações por estado (ativas/concluídas/canceladas)
// Usado para mostrar apenas formações disponíveis no catálogo
db.formacoes.createIndex({ "estado": 1 });

// 37. Queries por data de início (ordenar formações cronologicamente)
// Usado para listar formações futuras ou passadas
db.formacoes.createIndex({ "datas.inicio": 1 });

// 38. Queries por área (filtrar por tipo de formação)
// Usado para buscar formações de "Tecnologia", "Gestão", etc.
db.formacoes.createIndex({ "area": 1 });


// ===================================================================
// VERIFICAÇÃO DE ÍNDICES (executar após criar)
// ===================================================================
/*
// Ver índices criados em cada coleção:
db.funcionarios.getIndexes()
db.historico_salarial.getIndexes()
db.ausencias.getIndexes()
db.avaliacoes.getIndexes()
db.vagas.getIndexes()
db.candidatos.getIndexes()
db.formacoes.getIndexes()

// Estatísticas de uso de índices (após executar queries):
db.funcionarios.aggregate([{ $indexStats: {} }])
db.vagas.aggregate([{ $indexStats: {} }])
// ... (repetir para outras coleções)
*/


// ===================================================================
// SCRIPT PARA REMOVER ÍNDICES (usar se necessário refazer)
// ===================================================================
/*
// ATENÇÃO: Isto remove TODOS os índices exceto _id
// Use apenas se precisar recriar os índices do zero

db.funcionarios.dropIndexes()
db.historico_salarial.dropIndexes()
db.ausencias.dropIndexes()
db.avaliacoes.dropIndexes()
db.vagas.dropIndexes()
db.candidatos.dropIndexes()
db.formacoes.dropIndexes()

// Depois execute os createIndex acima novamente
*/
