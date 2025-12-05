//Queries por departamento (Query 1, 3, 5, 15, 18)
// Na coleção funcionarios
db.funcionarios.createIndex({ "profissional.id_depart_sql": 1 })
db.funcionarios.createIndex({ "historico_salarial.inicio": -1 }) // Para pegar salário mais recente
/*Justificação:

O índice em profissional.id_depart_sql acelera group e match por departamento.

O índice em historico_salarial.inicio acelera sort e o $group para pegar o último salário.
*/







// Na coleção departamentos
db.departamentos.createIndex({ id_sql: 1 })


//Queries que filtram pelo histórico salarial ou benefícios (Query 4, 7, 19, 20)
db.funcionarios.createIndex({ "historico_salarial.inicio": -1 })
db.funcionarios.createIndex({ "historico_salarial.beneficios.tipo": 1 })
db.funcionarios.createIndex({ "id_sql": 1 })

/*
Justificação:

Ordenar por início (inicio) ajuda a pegar o salário mais recente sem percorrer todos os documentos.
*/

// Queries com férias ou ausências (Query 5, 8, 14, 17)
db.funcionarios.createIndex({ "profissional.id_depart_sql": 1 })
db.funcionarios.createIndex({ "registo_ausencias.ferias.inicio": 1 })

/*
Justificação:

Índice no departamento acelera group e joins.

Índice em datas de férias ajuda queries que ordenam ou filtram por períodos de férias.~
*/