// ===================================================================
// SCRIPT PARA REMOVER ÍNDICES (usar se necessário refazer)
// ===================================================================

// ATENÇÃO: Isto remove TODOS os índices exceto _id
// Use apenas se precisar recriar os índices do zero

db.funcionarios.dropIndexes()
db.vagas.dropIndexes()
db.avaliacoes.dropIndexes()
db.candidatos.dropIndexes()
db.formacoes.dropIndexes()
db.departamentos.dropIndexes()


