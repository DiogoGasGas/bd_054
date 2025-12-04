// Número de funcionários por departamento

db.funcionarios.aggregate([
  // 1. Agrupar e Contar
  {
    $group: {
      _id: "$profissional.id_depart_sql",
      total_funcionarios: { $sum: 1 }
    }
  },
  // 2. Ir buscar o nome do departamento (JOIN)
  {
    $lookup: {
      from: "departamentos",
      localField: "_id",
      foreignField: "id_sql",
      as: "dep_info"
    }
  },
  // 3. Formatar a saída
  {
    $project: {
      nome: { $first: "$dep_info.nome" },
      total_funcionarios: 1
    }
  },
  { $sort: { total_funcionarios: -1 } }
]);


