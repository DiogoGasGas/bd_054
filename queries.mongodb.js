// Query 1: Número de funcionários por departamento
/*
db.funcionarios.aggregate([
  // 1. Agrupar por ID de departamento (que está dentro de 'profissional')
  {
    $group: {
      _id: "$profissional.id_depart_sql",
      total_funcionarios: { $sum: 1 }
    }
  },
  // 2. Ir buscar o nome do departamento
  {
    $lookup: {
      from: "departamentos",
      localField: "_id",
      foreignField: "id_sql",
      as: "dep"
    }
  },
  // 3. Formatar saída
  {
    $project: {
      nome: { $first: "$dep.nome" },
      total_funcionarios: 1
    }
  },
  { $sort: { total_funcionarios: -1 } }
]);
*/

// Query 3: Total de remuneração por departamento
/*
db.funcionarios.aggregate([
  // 1. Selecionar o salário mais recente (usando $sort e $group ou filtrando onde fim é null)
  // Assumindo a lógica do "mais recente" via Sort:
  { $unwind: "$historico_salarial" },
  { $sort: { "historico_salarial.inicio": -1 } },
  {
    $group: {
      _id: "$id_sql", // Agrupar por funcionário primeiro para apanhar o último salário
      id_depart: { $first: "$profissional.id_depart_sql" },
      salario_atual: { $first: "$historico_salarial.base" }
    }
  },
  
  // 2. Agora agrupar por Departamento e somar
  {
    $group: {
      _id: "$id_depart",
      tot_remun: { $sum: "$salario_atual" }
    }
  },

  // 3. Nome do Departamento
  {
    $lookup: {
      from: "departamentos",
      localField: "_id",
      foreignField: "id_sql",
      as: "dep"
    }
  },

  {
    $project: {
      nome: { $first: "$dep.nome" },
      tot_remun: 1
    }
  },
  { $sort: { tot_remun: -1 } }
]);
*/

// Query 4: Top 3 funcionários com maior salário líquido
/*
db.funcionarios.aggregate([
  { $unwind: "$historico_salarial" },
  { $sort: { "historico_salarial.inicio": -1 } },
  // Pegar no último salário de cada um
  {
    $group: {
      _id: "$id_sql",
      nome_completo: { $first: "$identificacao.nome_completo" },
      salario_liquido: { $first: "$historico_salarial.liquido" }
    }
  },
  // Ordenar e limitar
  { $sort: { salario_liquido: -1 } },
  { $limit: 3 },
  {
    $project: {
      nome_completo: 1,
      salario_liquido: 1,
      _id: 0
    }
  }
]);
*/


// Query 5: Média de férias por departamento (CORRIGIDA)
/*
db.funcionarios.aggregate([
  { $unwind: "$registo_ausencias.ferias" },
  
  // Calcular dias de férias: (Data Fim - Data Inicio) + 1
  {
    $addFields: {
      dias: {
        $add: [
          {
            $dateDiff: {
              startDate: { $toDate: "$registo_ausencias.ferias.inicio" },
              endDate: { $toDate: "$registo_ausencias.ferias.fim" },
              unit: "day"
            }
          },
          1 // Adiciona 1 para tornar a contagem inclusiva
        ]
      }
    }
  },
  
  // Agrupar por departamento
  {
    $group: {
      _id: "$profissional.id_depart_sql",
      media_dias_ferias: { $avg: "$dias" }
    }
  },
  
  // Buscar nome
  {
    $lookup: {
      from: "departamentos",
      localField: "_id",
      foreignField: "id_sql",
      as: "dep"
    }
  },
  
  {
    $project: {
      nome: { $first: "$dep.nome" },
      media_dias_ferias: { $round: ["$media_dias_ferias", 0] }
    }
  }
]);
*/


/*
// Query 6: Comparação com média global nas formações 
db.funcionarios.aggregate([
  { $unwind: "$formacoes_realizadas" },
  
  // Contar quantas pessoas fizeram cada formação
  {
    $group: {
      _id: "$formacoes_realizadas.id_formacao_sql",
      num_aderentes: { $sum: 1 }
    }
  },
  
  // Calcular média global de aderentes
  {
    $setWindowFields: {
      partitionBy: null,
      output: { media_global: { $avg: "$num_aderentes" } }
    }
  },
  
  // Filtrar quem está acima da média
  {
    $match: {
      $expr: { $gt: ["$num_aderentes", "$media_global"] }
    }
  },
  
  // Buscar nome da formação
  {
    $lookup: {
      from: "formacoes",
      localField: "_id",
      foreignField: "id_sql",
      as: "form"
    }
  },
  
  {
    $project: {
      id_for: "$_id",
      nome_formacao: { $first: "$form.nome" },
      num_aderentes: 1
    }
  },
  { $sort: { num_aderentes: -1 } }
]);
*/

// Query 7: Seguro Saúde acima da média
/*
db.funcionarios.aggregate([
  { $unwind: "$historico_salarial" },
  { $unwind: "$historico_salarial.beneficios" },
  
  // Filtrar apenas Seguro Saúde
  { $match: { "historico_salarial.beneficios.tipo": "Seguro Saúde" } },
  
  // Calcular Média Global do valor do Seguro Saúde
  {
    $setWindowFields: {
      partitionBy: null,
      output: { media_beneficio: { $avg: "$historico_salarial.beneficios.valor" } }
    }
  },
  
  // Agrupar por funcionário (somar valores se tiver mais que um seguro, improvável mas possível)
  {
    $group: {
      _id: "$id_sql",
      nome_completo: { $first: "$identificacao.nome_completo" },
      tot_benef: { $sum: "$historico_salarial.beneficios.valor" },
      media_beneficio: { $first: "$media_beneficio" }
    }
  },
  
  // Comparar
  {
    $match: {
      $expr: { $gt: ["$tot_benef", "$media_beneficio"] }
    }
  },
  
  // Remover campo media_beneficio do output
  {
    $project: {
      nome_completo: 1,
      tot_benef: 1,
      _id: 1
    }
  },
  
  { $sort: { _id: 1 } }
]);
*/


// Query 8: Funcionários com mais dias de férias aprovadas
/*
db.funcionarios.aggregate([
  { $unwind: "$registo_ausencias.ferias" },
  { $match: { "registo_ausencias.ferias.estado": "Aprovado" } },
  
  // Calcular dias
{
    $addFields: {
      dias: {
        $add: [
          {
            $dateDiff: {
              startDate: { $toDate: "$registo_ausencias.ferias.inicio" },
              endDate: { $toDate: "$registo_ausencias.ferias.fim" },
              unit: "day"
            }
          },
          1 // Adiciona 1 para tornar a contagem inclusiva
        ]
      }
    }
  },
  
  // Agrupar por funcionário e registo de férias específico (para replicar SQL row output)
  {
    $project: {
      id_fun: "$id_sql",
      primeiro_nome: { $arrayElemAt: [{ $split: ["$identificacao.nome_completo", " "] }, 0] },
      num_dias: "$dias",
      data_inicio: "$registo_ausencias.ferias.inicio"
    }
  },
  
  // Encontrar o MAX dias globalmente
  {
    $setWindowFields: {
      partitionBy: null,
      output: { max_dias: { $max: "$num_dias" } }
    }
  },
  
  // Filtrar apenas os registos iguais ao MAX
  {
    $match: {
      $expr: { $eq: ["$num_dias", "$max_dias"] }
    }
  },
  { $sort: { id_fun: 1 } }
]);
*/


// Query 11. Vagas e candidatos (Baseada na coleção Vagas)
/*
db.vagas.aggregate([
  // Contar candidatos por vaga
  {
    $addFields: {
      num_cand: { $size: "$candidaturas_recebidas" }
    }
  },
  // Agrupar por departamento
  {
    $group: {
      _id: "$id_depart_sql",
      num_vagas: { $sum: 1 },
      media_candidatos: { $avg: "$num_cand" }
    }
  },
  // Buscar nome departamento
  {
    $lookup: {
      from: "departamentos",
      localField: "_id",
      foreignField: "id_sql",
      as: "dep"
    }
  },
  {
    $project: {
      nome_depart: { $first: "$dep.nome" },
      num_vagas: 1,
      media_candidatos: { $ifNull: ["$media_candidatos", 0] }
    }
  },
  { $sort: { media_candidatos: -1 } }
]);
*/


// 14. Numero de faltas e faltas justificadas por departamento
/*
db.funcionarios.aggregate([
  // Calcular totais por funcionário primeiro
  {
    $project: {
      id_depart: "$profissional.id_depart_sql",
      total_faltas: { $size: { $ifNull: ["$registo_ausencias.faltas", []] } },
      // Filtrar justificadas (onde justificacao não é null)
      faltas_justificadas: {
        $size: {
          $filter: {
            input: { $ifNull: ["$registo_ausencias.faltas", []] },
            as: "falta",
            cond: { $ne: ["$$falta.justificacao", null] }
          }
        }
      }
    }
  },
  
  // Agrupar por departamento
  {
    $group: {
      _id: "$id_depart",
      total_faltas: { $sum: "$total_faltas" },
      total_faltas_just: { $sum: "$faltas_justificadas" }
    }
  },
  
  // Buscar nome
  {
    $lookup: {
      from: "departamentos",
      localField: "_id",
      foreignField: "id_sql",
      as: "dep"
    }
  },
  
  {
    $project: {
      id_depart: "$_id",
      nome: { $first: "$dep.nome" },
      total_faltas: 1,
      total_faltas_just: 1
    }
  },
  { $sort: { total_faltas: -1 } }
]);
*/

// Daqui para a frente iremos relaizar operações CRUD (Create, Read, Update, Delete), 
// para exemplificar, usaremos o mesmo funcionário em todos os exemplos.

// Exemplo de Create: Inserir um novo funcionário

db.funcionarios.insertOne({
  id_sql: 1500,
  identificacao: {
    nome_completo: 'Marco Casquilho',
    nif: '9677967710',
    data_nascimento: '1930-05-11'
  },
  contactos: {
    email: 'asquilho@gmail.com',
    telemovel: '986665123',
    morada: {
      rua: 'Rua das Flores',
      cidade: 'Rio Maior',
      cp: '2040-123'
    }
  },
  profissional: {
    cargo: 'Engenheiro de Software',
    id_depart_sql: 2
  },
  autenticacao: {
    password: 'senha123',
    permissoes: ['leitura', 'escrita']
  },
  dependentes: [],
  historico_empresas: [
    {
      empresa: 'Tech Company',
      cargo: 'Junior Developer',
      inicio: '2020-01-15',
      fim: '2022-12-31'
    }
  ],
  formacoes_realizadas: [],
  registo_ausencias: {
    ferias: [],
    faltas: []
  },
  historico_salarial: [
    {
      inicio: '2023-01-01',
      fim: null,
      base: 2500,
      liquido: 2000,
      beneficios: [
        {
          tipo: 'Seguro Saúde',
          valor: 75
        }
      ]
    }
  ]
});

// Exemplo de Read(simples): Encontrar funcionário por NIF e por ID

db.funcionarios.findOne({ "identificacao.nif": "9677967710" });
db.funcionarios.findOne({ id_sql: 1500 });

// Exemplo Read(Busca em Embeddings): Encontrar funcionários que já trabalharam na empresa "Azevedo Lda."

db.funcionarios.find({ 'historico_empresas.empresa' :'Tech Company'}, 
  {"identificacao.nome_completo" :1, 'historico_empresas.$':1, _id:0});

// Exemplo de Update: Atualizar o email de um funcionário

db.funcionarios.updateOne(
  {
  id_sql:1500
  },
{ $set:{'contactos.email': 'marco.casquilho@example.com'}}
);

// Exemplo de Delete: Remover um funcionário pelo ID

db.funcionarios.deleteOne({ id_sql: 1500 });

