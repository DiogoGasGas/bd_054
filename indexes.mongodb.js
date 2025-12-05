// ==============================
// 1️⃣ Queries por departamento (Query 1, 3, 5, 15, 18)
// Coleção: funcionarios
db.funcionarios.createIndex({ "profissional.departamento_id": 1 })
db.funcionarios.createIndex({ "historico_salarial.inicio": -1 }) // Para pegar salário mais recente

// Coleção: departamentos
db.departamentos.createIndex({ _id: 1 })

// ==============================
// 2️⃣ Queries de salário e benefícios (Query 4, 7, 19, 20)
db.funcionarios.createIndex({ "historico_salarial.inicio": -1 })
db.funcionarios.createIndex({ "historico_salarial.beneficios.tipo": 1 })
db.funcionarios.createIndex({ "_id": 1 })

// ==============================
// 3️⃣ Queries de férias e ausências (Query 5, 8, 14, 17)
db.funcionarios.createIndex({ "profissional.departamento_id": 1 })
db.funcionarios.createIndex({ "registo_ausencias.ferias.inicio": 1 })

// ==============================
// 4️⃣ Queries de formação (Query 6, 18, 20)
db.funcionarios.createIndex({ "formacoes_realizadas.formacao_id": 1 })
db.funcionarios.createIndex({ "profissional.departamento_id": 1 })

// ==============================
// 5️⃣ Queries de dependentes e vagas (Query 10, 11)
db.funcionarios.createIndex({ "profissional.departamento_id": 1 })
db.vagas.createIndex({ "departamento_id": 1 })
db.vagas.createIndex({ "candidaturas_recebidas": 1 }) // Para $size()

// ==============================
// 6️⃣ Queries combinadas por departamento e histórico salarial (Query 12, 13, 16)
db.funcionarios.createIndex({ "profissional.departamento_id": 1, "historico_salarial.inicio": -1 })

// ==============================
// 7️⃣ Índices adicionais importantes
// Para $group ou join por _id
db.funcionarios.createIndex({ "_id": 1 })
db.departamentos.createIndex({ "_id": 1 })
