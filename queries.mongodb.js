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



// Query 10: Dependentes e funcionário respetivo
/*
db.funcionarios.aggregate([
  { $unwind: "$dependentes" },
  
  // Buscar nome departamento
  {
    $lookup: {
      from: "departamentos",
      localField: "profissional.id_depart_sql",
      foreignField: "id_sql",
      as: "dep"
    }
  },
  
  {
    $project: {
      id_fun: "$id_sql",
      nome_funcionario: "$identificacao.nome_completo",
      nome_dep: { $first: "$dep.nome" },
      dependente_info: { 
        $concat: ["$dependentes.nome", " (", "$dependentes.parentesco", ")"] 
      }
    }
  },
  
  // Agrupar de volta para fazer a lista (STRING_AGG do SQL)
  {
    $group: {
      _id: "$id_fun",
      nome_funcionario: { $first: "$nome_funcionario" },
      nome_dep: { $first: "$nome_dep" },
      dependentes: { $push: "$dependente_info" } // Cria array
    }
  },
  
  // O SQL faz STRING_AGG, aqui podemos deixar em array ou juntar numa string se a aplicação precisar
  { $sort: { nome_funcionario: 1 } }
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


// Querie 15. Departamentos cuja média salarial é maior que a média total, o seu número de funcionários e a sua média
/*
db.funcionarios.aggregate([
  // 1. Isolar salário mais recente
  { $unwind: "$historico_salarial" },
  { $sort: { "historico_salarial.inicio": -1 } },
  {
    $group: {
      _id: "$id_sql",
      id_depart: { $first: "$profissional.id_depart_sql" },
      salario_atual: { $first: "$historico_salarial.base" }
    }
  },

  // 2. Calcular Média Global (Window Function)
  {
    $setWindowFields: {
      partitionBy: null,
      output: { media_global: { $avg: "$salario_atual" } }
    }
  },

  // 3. Agrupar por Departamento
  {
    $group: {
      _id: "$id_depart",
      num_funcionarios: { $sum: 1 },
      media_departamento: { $avg: "$salario_atual" },
      media_global: { $first: "$media_global" }
    }
  },

  // 4. Filtrar: Média Dept > Média Global
  {
    $match: {
      $expr: { $gt: ["$media_departamento", "$media_global"] }
    }
  },

  // 5. Lookup Nome Departamento
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
      Nome: { $first: "$dep.nome" },
      Numero_Funcionarios: "$num_funcionarios",
      Media_Salarial_Departamento: { $round: ["$media_departamento", 2] }
    }
  },
  { $sort: { Media_Salarial_Departamento: -1 } }
]);
*/



// Query 17: Funcionários sem faltas registadas
/*
db.funcionarios.aggregate([
  {
    $project: {
      id_fun: "$id_sql",
      nome_completo: "$identificacao.nome_completo",
      total_faltas: { 
        $size: { $ifNull: ["$registo_ausencias.faltas", []] } 
      }
    }
  },
  {
    $match: {
      total_faltas: 0
    }
  },
  { $sort: { id_fun: 1 } }
]);
*/


// Querie 18. Taxa de aderência a formações por departamento
/*
db.funcionarios.aggregate([
  // 1. Calcular se funcionário tem formação (1 ou 0) e qual o seu departamento
  {
    $project: {
      id_depart: "$profissional.id_depart_sql",
      tem_formacao: { 
        $cond: { if: { $gt: [{ $size: "$formacoes_realizadas" }, 0] }, then: 1, else: 0 } 
      }
    }
  },

  // 2. Agrupar por departamento
  {
    $group: {
      _id: "$id_depart",
      total_funcs: { $sum: 1 },
      total_com_formacao: { $sum: "$tem_formacao" }
    }
  },

  // 3. Calcular Taxa e Buscar Nome
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
      taxa_adesao: {
        $round: [
          { $multiply: [{ $divide: ["$total_com_formacao", "$total_funcs"] }, 100] }, 
          2
        ]
      }
    }
  },
  { $sort: { taxa_adesao: -1 } }
]);
*/



// Query 19: Funcionários que trabalharam na empresa Moura, salário > 1500 e têm Seguro Saúde
/*
db.funcionarios.aggregate([
  // 1. Filtrar quem trabalhou na "Moura" (Histórico)
  { $match: { "historico_empresas.empresa": "Moura" } },

  // 2. Aceder ao histórico salarial
  { $unwind: "$historico_salarial" },

  // 3. Ordenar por data para garantir que o primeiro é o mais recente (Igual ao MAX data_inicio)
  { $sort: { "historico_salarial.inicio": -1 } },

  // 4. Agrupar para ficar apenas com o registo salarial MAIS RECENTE
  {
    $group: {
      _id: "$id_sql",
      nome_completo: { $first: "$identificacao.nome_completo" },
      salario_atual: { $first: "$historico_salarial.base" },
      beneficios: { $first: "$historico_salarial.beneficios" },
      trabalhou_em: { $first: "Moura" } // Já sabemos que é Moura pelo filtro inicial
    }
  },

  // 5. Aplicar os filtros de Salário e Benefício
  {
    $match: {
      "salario_atual": { $gt: 1500 },
      "beneficios.tipo": "Seguro Saúde"
    }
  },

  // 6. Projeção final
  {
    $project: {
      nome_completo: 1,
      salario_atual: 1,
      tipo_beneficio: "Seguro Saúde",
      trabalhou_em: 1,
      _id: 0
    }
  }
]);
*/


// Query 20. Listar os funcionários que ganham acima da média salarial do seu próprio departamento, indicando-o, mostrando também o número de formações concluídas
/*
db.funcionarios.aggregate([
  // 1. Isolar salário atual
  { $unwind: "$historico_salarial" },
  { $sort: { "historico_salarial.inicio": -1 } },
  {
    $group: {
      _id: "$id_sql",
      nome_completo: { $first: "$identificacao.nome_completo" },
      id_depart: { $first: "$profissional.id_depart_sql" },
      salario_atual: { $first: "$historico_salarial.base" },
      num_formacoes: { $first: { $size: "$formacoes_realizadas" } }
    }
  },

  // 2. Calcular Média DO DEPARTAMENTO (PartitionBy id_depart)
  {
    $setWindowFields: {
      partitionBy: "$id_depart",
      output: { media_departamento: { $avg: "$salario_atual" } }
    }
  },

  // 3. Filtrar quem ganha mais que a média do seu próprio grupo
  {
    $match: {
      $expr: { $gt: ["$salario_atual", "$media_departamento"] }
    }
  },

  // 4. Lookup Nome Departamento
  {
    $lookup: {
      from: "departamentos",
      localField: "id_depart",
      foreignField: "id_sql",
      as: "dep"
    }
  },

  {
    $project: {
      nome_completo: 1,
      salario_atual: 1,
      nome_departamento: { $first: "$dep.nome" },
      num_formacoes: 1
    }
  },
  { $sort: { nome_departamento: 1, salario_atual: -1 } }
]);
*/