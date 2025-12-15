// Query 1: Número de funcionários por departamento
/*
db.funcionarios.aggregate([
  // 1. Agrupar por ID de departamento (que está dentro de 'profissional')
  {
    $group: {
      _id: '$profissional.id_depart_sql',
      total_funcionarios: { $sum: 1 }
    }
  },
  // 2. Ir buscar o nome do departamento
  {
    $lookup: {
      from: 'departamentos',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },
  // 3. Formatar saída
  {
    $project: {
      nome: { $first: '$dep.nome' },
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
  // Assumindo a lógica do 'mais recente' via Sort:
  { $unwind: '$historico_salarial' },
  { $sort: { 'historico_salarial.inicio': -1 } },
  {
    $group: {
      _id: '$id_sql', // Agrupar por funcionário primeiro para apanhar o último salário
      id_depart: { $first: '$profissional.id_depart_sql' },
      salario_atual: { $first: '$historico_salarial.base' }
    }
  },
  
  // 2. Agora agrupar por Departamento e somar
  {
    $group: {
      _id: '$id_depart',
      tot_remun: { $sum: '$salario_atual' }
    }
  },

  // 3. Nome do Departamento
  {
    $lookup: {
      from: 'departamentos',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },

  {
    $project: {
      nome: { $first: '$dep.nome' },
      tot_remun: 1
    }
  },
  { $sort: { tot_remun: -1 } }
]);
*/


// Query 4: Top 3 funcionários com maior salário líquido
/*
db.funcionarios.aggregate([
  { $unwind: '$historico_salarial' },
  { $sort: { 'historico_salarial.inicio': -1 } },
  // Pegar no último salário de cada um
  {
    $group: {
      _id: '$id_sql',
      nome_completo: { $first: '$identificacao.nome_completo' },
      salario_liquido: { $first: '$historico_salarial.liquido' }
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
  { $unwind: '$registo_ausencias.ferias' },
  
  // Calcular dias de férias: (Data Fim - Data Inicio) + 1
  {
    $addFields: {
      dias: {
        $add: [
          {
            $dateDiff: {
              startDate: { $toDate: '$registo_ausencias.ferias.inicio' },
              endDate: { $toDate: '$registo_ausencias.ferias.fim' },
              unit: 'day'
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
      _id: '$profissional.id_depart_sql',
      media_dias_ferias: { $avg: '$dias' }
    }
  },
  
  // Buscar nome
  {
    $lookup: {
      from: 'departamentos',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },
  
  {
    $project: {
      nome: { $first: '$dep.nome' },
      media_dias_ferias: { $round: ['$media_dias_ferias', 0] }
    }
  }
]);
*/


/*
// Query 6: Comparação com média global nas formações 
db.funcionarios.aggregate([
  { $unwind: '$formacoes_realizadas' },
  
  // Contar quantas pessoas fizeram cada formação
  {
    $group: {
      _id: '$formacoes_realizadas.id_formacao_sql',
      num_aderentes: { $sum: 1 }
    }
  },
  
  // Calcular média global de aderentes
  {
    $setWindowFields: {
      partitionBy: null,
      output: { media_global: { $avg: '$num_aderentes' } }
    }
  },
  
  // Filtrar quem está acima da média
  {
    $match: {
      $expr: { $gt: ['$num_aderentes', '$media_global'] }
    }
  },
  
  // Buscar nome da formação
  {
    $lookup: {
      from: 'formacoes',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'form'
    }
  },
  
  {
    $project: {
      id_for: '$_id',
      nome_formacao: { $first: '$form.nome' },
      num_aderentes: 1
    }
  },
  { $sort: { num_aderentes: -1 } }
]);
*/

// Query 7: Seguro Saúde acima da média
/*
db.funcionarios.aggregate([
  { $unwind: '$historico_salarial' },
  { $unwind: '$historico_salarial.beneficios' },
  
  // Filtrar apenas Seguro Saúde
  { $match: { 'historico_salarial.beneficios.tipo': 'Seguro Saúde' } },
  
  // Calcular Média Global do valor do Seguro Saúde
  {
    $setWindowFields: {
      partitionBy: null,
      output: { media_beneficio: { $avg: '$historico_salarial.beneficios.valor' } }
    }
  },
  
  // Agrupar por funcionário (somar valores se tiver mais que um seguro, improvável mas possível)
  {
    $group: {
      _id: '$id_sql',
      nome_completo: { $first: '$identificacao.nome_completo' },
      tot_benef: { $sum: '$historico_salarial.beneficios.valor' },
      media_beneficio: { $first: '$media_beneficio' }
    }
  },
  
  // Comparar
  {
    $match: {
      $expr: { $gt: ['$tot_benef', '$media_beneficio'] }
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
  { $unwind: '$registo_ausencias.ferias' },
  { $match: { 'registo_ausencias.ferias.estado': 'Aprovado' } },
  
  // Calcular dias
{
    $addFields: {
      dias: {
        $add: [
          {
            $dateDiff: {
              startDate: { $toDate: '$registo_ausencias.ferias.inicio' },
              endDate: { $toDate: '$registo_ausencias.ferias.fim' },
              unit: 'day'
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
      id_fun: '$id_sql',
      primeiro_nome: { $arrayElemAt: [{ $split: ['$identificacao.nome_completo', ' '] }, 0] },
      num_dias: '$dias',
      data_inicio: '$registo_ausencias.ferias.inicio'
    }
  },
  
  // Encontrar o MAX dias globalmente
  {
    $setWindowFields: {
      partitionBy: null,
      output: { max_dias: { $max: '$num_dias' } }
    }
  },
  
  // Filtrar apenas os registos iguais ao MAX
  {
    $match: {
      $expr: { $eq: ['$num_dias', '$max_dias'] }
    }
  },
  { $sort: { id_fun: 1 } }
]);
*/



// Query 10: Dependentes e funcionário respetivo
/*
db.funcionarios.aggregate([
  { $unwind: '$dependentes' },
  
  // Buscar nome departamento
  {
    $lookup: {
      from: 'departamentos',
      localField: 'profissional.id_depart_sql',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },
  
  {
    $project: {
      id_fun: '$id_sql',
      nome_funcionario: '$identificacao.nome_completo',
      nome_dep: { $first: '$dep.nome' },
      dependente_info: { 
        $concat: ['$dependentes.nome', ' (', '$dependentes.parentesco', ')'] 
      }
    }
  },
  
  // Agrupar de volta para fazer a lista (STRING_AGG do SQL)
  {
    $group: {
      _id: '$id_fun',
      nome_funcionario: { $first: '$nome_funcionario' },
      nome_dep: { $first: '$nome_dep' },
      dependentes: { $push: '$dependente_info' } // Cria array
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
      num_cand: { $size: '$candidaturas_recebidas' }
    }
  },
  // Agrupar por departamento
  {
    $group: {
      _id: '$id_depart_sql',
      num_vagas: { $sum: 1 },
      media_candidatos: { $avg: '$num_cand' }
    }
  },
  // Buscar nome departamento
  {
    $lookup: {
      from: 'departamentos',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },
  {
    $project: {
      nome_depart: { $first: '$dep.nome' },
      num_vagas: 1,
      media_candidatos: { $ifNull: ['$media_candidatos', 0] }
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
      id_depart: '$profissional.id_depart_sql',
      total_faltas: { $size: { $ifNull: ['$registo_ausencias.faltas', []] } },
      // Filtrar justificadas (onde justificacao não é null)
      faltas_justificadas: {
        $size: {
          $filter: {
            input: { $ifNull: ['$registo_ausencias.faltas', []] },
            as: 'falta',
            cond: { $ne: ['$$falta.justificacao', null] }
          }
        }
      }
    }
  },
  
  // Agrupar por departamento
  {
    $group: {
      _id: '$id_depart',
      total_faltas: { $sum: '$total_faltas' },
      total_faltas_just: { $sum: '$faltas_justificadas' }
    }
  },
  
  // Buscar nome
  {
    $lookup: {
      from: 'departamentos',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },
  
  {
    $project: {
      id_depart: '$_id',
      nome: { $first: '$dep.nome' },
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
  { $unwind: '$historico_salarial' },
  { $sort: { 'historico_salarial.inicio': -1 } },
  {
    $group: {
      _id: '$id_sql',
      id_depart: { $first: '$profissional.id_depart_sql' },
      salario_atual: { $first: '$historico_salarial.base' }
    }
  },

  // 2. Calcular Média Global (Window Function)
  {
    $setWindowFields: {
      partitionBy: null,
      output: { media_global: { $avg: '$salario_atual' } }
    }
  },

  // 3. Agrupar por Departamento
  {
    $group: {
      _id: '$id_depart',
      num_funcionarios: { $sum: 1 },
      media_departamento: { $avg: '$salario_atual' },
      media_global: { $first: '$media_global' }
    }
  },

  // 4. Filtrar: Média Dept > Média Global
  {
    $match: {
      $expr: { $gt: ['$media_departamento', '$media_global'] }
    }
  },

  // 5. Lookup Nome Departamento
  {
    $lookup: {
      from: 'departamentos',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },

  {
    $project: {
      Nome: { $first: '$dep.nome' },
      Numero_Funcionarios: '$num_funcionarios',
      Media_Salarial_Departamento: { $round: ['$media_departamento', 2] }
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
      id_fun: '$id_sql',
      nome_completo: '$identificacao.nome_completo',
      total_faltas: { 
        $size: { $ifNull: ['$registo_ausencias.faltas', []] } 
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
      id_depart: '$profissional.id_depart_sql',
      tem_formacao: { 
        $cond: { if: { $gt: [{ $size: '$formacoes_realizadas' }, 0] }, then: 1, else: 0 } 
      }
    }
  },

  // 2. Agrupar por departamento
  {
    $group: {
      _id: '$id_depart',
      total_funcs: { $sum: 1 },
      total_com_formacao: { $sum: '$tem_formacao' }
    }
  },

  // 3. Calcular Taxa e Buscar Nome
  {
    $lookup: {
      from: 'departamentos',
      localField: '_id',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },

  {
    $project: {
      nome: { $first: '$dep.nome' },
      taxa_adesao: {
        $round: [
          { $multiply: [{ $divide: ['$total_com_formacao', '$total_funcs'] }, 100] }, 
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
  // 1. Filtrar quem trabalhou na 'Moura' (Histórico)
  { $match: { 'historico_empresas.empresa': 'Moura' } },

  // 2. Aceder ao histórico salarial
  { $unwind: '$historico_salarial' },

  // 3. Ordenar por data para garantir que o primeiro é o mais recente (Igual ao MAX data_inicio)
  { $sort: { 'historico_salarial.inicio': -1 } },

  // 4. Agrupar para ficar apenas com o registo salarial MAIS RECENTE
  {
    $group: {
      _id: '$id_sql',
      nome_completo: { $first: '$identificacao.nome_completo' },
      salario_atual: { $first: '$historico_salarial.base' },
      beneficios: { $first: '$historico_salarial.beneficios' },
      trabalhou_em: { $first: 'Moura' } // Já sabemos que é Moura pelo filtro inicial
    }
  },

  // 5. Aplicar os filtros de Salário e Benefício
  {
    $match: {
      'salario_atual': { $gt: 1500 },
      'beneficios.tipo': 'Seguro Saúde'
    }
  },

  // 6. Projeção final
  {
    $project: {
      nome_completo: 1,
      salario_atual: 1,
      tipo_beneficio: 'Seguro Saúde',
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
  { $unwind: '$historico_salarial' },
  { $sort: { 'historico_salarial.inicio': -1 } },
  {
    $group: {
      _id: '$id_sql',
      nome_completo: { $first: '$identificacao.nome_completo' },
      id_depart: { $first: '$profissional.id_depart_sql' },
      salario_atual: { $first: '$historico_salarial.base' },
      num_formacoes: { $first: { $size: '$formacoes_realizadas' } }
    }
  },

  // 2. Calcular Média DO DEPARTAMENTO (PartitionBy id_depart)
  {
    $setWindowFields: {
      partitionBy: '$id_depart',
      output: { media_departamento: { $avg: '$salario_atual' } }
    }
  },

  // 3. Filtrar quem ganha mais que a média do seu próprio grupo
  {
    $match: {
      $expr: { $gt: ['$salario_atual', '$media_departamento'] }
    }
  },

  // 4. Lookup Nome Departamento
  {
    $lookup: {
      from: 'departamentos',
      localField: 'id_depart',
      foreignField: 'id_sql',
      as: 'dep'
    }
  },

  {
    $project: {
      nome_completo: 1,
      salario_atual: 1,
      nome_departamento: { $first: '$dep.nome' },
      num_formacoes: 1
    }
  },
  { $sort: { nome_departamento: 1, salario_atual: -1 } }
]);
*/


// ============================================================================
// OPERAÇÕES CRUD (Create, Read, Update, Delete)
// Usaremos o mesmo funcionário em todos os exemplos
// ============================================================================

// Exemplo de Create: Inserir um novo funcionário
/*
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

// Exemplo de Read (simples): Encontrar funcionário por NIF e por ID

db.funcionarios.findOne({ 'identificacao.nif': '9677967710' });
db.funcionarios.findOne({ id_sql: 1500 });

// Exemplo Read (Busca em Embeddings): Encontrar funcionários que já trabalharam na empresa 'Tech Company'

db.funcionarios.find(
  { 'historico_empresas.empresa': 'Tech Company' }, 
  { 'identificacao.nome_completo': 1, 'historico_empresas.$': 1, _id: 0 }
);

// Exemplo de Update: Atualizar o email de um funcionário

db.funcionarios.updateOne(
  { id_sql: 1500 },
  { $set: { 'contactos.email': 'marco.casquilho@example.com' } }
);

// Exemplo de Delete: Remover um funcionário pelo ID

db.funcionarios.deleteOne({ id_sql: 1500 });
*/



/**
 * =================================================================================
 * PROJETO DE MIGRAÇÃO DE DADOS (SQL -> MONGODB)
 * CONJUNTO DE QUERIES OTIMIZADAS: FLEXIBILIDADE & ANÁLISE COMPLEXA
 * =================================================================================
 * * Este ficheiro contém 15 queries demonstrativas:
 * - 10 Queries sobre a coleção principal 'funcionarios'
 * - 5 Queries sobre as coleções satélite (vagas, candidatos, avaliacoes)
 * * Os exemplos variam entre buscas flexíveis (Find) e processamento analítico (Aggregate).
 */

// =================================================================================
// PARTE 1: COLEÇÃO 'FUNCIONARIOS' (10 Queries)
// =================================================================================

// =================================================================================
// PARTE 1: COLEÇÃO 'FUNCIONARIOS' (10 Queries)
// =================================================================================

/**
 * 1. Pesquisa Flexível (Regex)
 * CONCEITO: Pesquisa textual sem "Case Sensitivity".
 */
db.funcionarios.find({
    // $or: Permite verificar duas condições. Se uma for verdadeira, retorna o documento.
    $or: [
        // /Silva/i -> A barra '/' inicia o Regex, o 'i' significa "case-insensitive" (ignora maiúsculas).
        { "identificacao.nome_completo": /Silva/i },
        
        // Dot Notation ("info_profissional.cargo"): Permite entrar dentro do objeto 'info_profissional' 
        // para verificar o campo 'cargo' diretamente.
        { "info_profissional.cargo": /Gestor/i }
    ]
}, 
// Projeção: O segundo objeto do find diz quais campos queremos ver (1) ou esconder (0).
{ 
    "identificacao.nome_completo": 1, 
    "info_profissional.cargo": 1 
});


/**
 * 2. Custo Estimado de Ausências (Aggregation Complexa)
 * CONCEITO: Cruzar dados (Lookup), filtrar arrays e calcular valores matemáticos.
 */
db.funcionarios.aggregate([
    // ESTÁGIO 1: $lookup (O "JOIN" do MongoDB)
    // Vai à coleção 'ausencias' buscar documentos onde 'funcionario_id' é igual ao nosso 'id_sql'.
    {
        $lookup: {
            from: "ausencias",
            localField: "id_sql",
            foreignField: "funcionario_id",
            as: "registo_ausencias" // O resultado fica num array chamado 'registo_ausencias'
        }
    },

    // ESTÁGIO 2: $match (Filtro)
    // "registo_ausencias.0": Verifica se o índice 0 do array existe. 
    // Isto filtra fora os funcionários que não têm qualquer registo de ausência (array vazio).
    { $match: { "registo_ausencias.0": { $exists: true } } },

    // ESTÁGIO 3: $project (Cálculos)
    {
        $project: {
            nome: "$identificacao.nome_completo",
            
            // $multiply: Multiplica o valor diário pelo total de dias de falta.
            custo_total: {
                $multiply: [
                    // A. Calcular Salário Diário: Salário Base a dividir por 30
                    { $divide: ["$salario_atual.base", 30] }, 
                    
                    // B. Calcular Total de Dias de Falta
                    { 
                        $sum: { 
                            // $map: Como 'ausencias' é um array, usamos o map para iterar sobre ele (tipo um loop for).
                            // Nota: Usamos $first porque o lookup devolve um array, e nós queremos o objeto lá dentro.
                            $map: { 
                                input: { $first: "$registo_ausencias.ausencias" }, 
                                as: "a", // Variável temporária para cada falta
                                in: { $ifNull: ["$$a.num_dias", 1] } // Se 'num_dias' não existir, assume 1 dia.
                            } 
                        } 
                    }
                ]
            }
        }
    },
    
    // ESTÁGIO 4: Ordenar do maior custo para o menor (-1)
    { $sort: { custo_total: -1 } },
    
    // ESTÁGIO 5: Mostrar apenas os top 5
    { $limit: 5 }
]);


/**
 * 3. Histórico de Empresas Anteriores
 * CONCEITO: Verificar existência de dados num array embutido.
 */
db.funcionarios.find({
    // $exists: true -> Garante que o campo existe.
    // $ne: [] -> Garante que o array não está vazio ("Not Equal" a vazio).
    "historico_empresas": { $exists: true, $ne: [] }
}, 
{ 
    "identificacao.nome_completo": 1, 
    "historico_empresas.empresa": 1 
}).limit(5);


/**
 * 4. Histograma Salarial
 * CONCEITO: Agrupamento estatístico automático ($bucket).
 */
db.funcionarios.aggregate([
    {
        // $bucket: Cria "baldes" (grupos) baseados em valores numéricos.
        // É excelente para estatísticas salariais ou etárias sem ter de escrever muitos 'if/else'.
        $bucket: {
            groupBy: "$salario_atual.base", // O campo que vamos analisar
            boundaries: [0, 1000, 1500, 2000, 3000, 5000], // Os intervalos dos baldes
            default: "Mais de 5000", // Onde colocar valores acima do último limite
            output: {
                "total": { $sum: 1 }, // Conta quantos caíram neste balde
                "media": { $avg: "$salario_atual.base" } // Calcula a média deste balde
            }
        }
    }
]);


/**
 * 5. Benefícios Mais Comuns por Departamento
 * CONCEITO: Explodir arrays ($unwind) para agrupar por itens individuais.
 */
db.funcionarios.aggregate([
    // 1. Filtrar apenas quem tem benefícios para não processar nulos inutilmente
    { $match: { "salario_atual.beneficios": { $exists: true, $ne: [] } } },
    
    // 2. $unwind (Desconstruir):
    // Se o João tem 3 benefícios [Saúde, Carro, Bónus], o $unwind transforma
    // o documento do João em 3 documentos separados, um para cada benefício.
    // Isto permite-nos agrupar por "tipo de benefício" no passo seguinte.
    { $unwind: "$salario_atual.beneficios" },
    
    // 3. $group
    {
        $group: {
            _id: {
                // Agrupamento Composto: Agrupa por Departamento E por Tipo de Benefício
                dep: "$info_profissional.departamento.nome_depart", 
                tipo: "$salario_atual.beneficios.tipo"
            },
            total: { $sum: 1 } // Conta quantas vezes este par (Dep + Benefício) aparece
        }
    },
    
    // 4. Ordenar alfabeticamente por Departamento (1) e depois por quantidade (-1)
    { $sort: { "_id.dep": 1, total: -1 } }
]);


/**
 * 6. Evolução Salarial (Comparar coleção atual com histórico)
 * CONCEITO: Aritmética entre campos de coleções diferentes.
 */
db.funcionarios.aggregate([
    // 1. Ir buscar o histórico antigo à coleção 'historico_salarial'
    {
        $lookup: {
            from: "historico_salarial",
            localField: "id_sql",
            foreignField: "funcionario_id",
            as: "historico"
        }
    },
    // 2. Garantir que encontrámos histórico
    { $match: { "historico.0": { $exists: true } } }, 
    
    // 3. Selecionar os valores para calcular
    {
        $project: {
            nome: "$identificacao.nome_completo",
            salario_atual: "$salario_atual.base", // Valor que já está no documento do funcionário
            
            // Logica complexa de Array:
            // arrayElemAt: Vai buscar um elemento numa posição específica.
            // O primeiro '0' pega no documento do lookup. O segundo '0' pega no primeiro salário do array 'periodos'.
            primeiro_salario: { 
                $arrayElemAt: [{ $arrayElemAt: ["$historico.periodos.base", 0] }, 0] 
            }
        }
    },
    
    // 4. Calcular a diferença (Matemática simples)
    {
        $project: {
            nome: 1,
            crescimento: { $subtract: ["$salario_atual", "$primeiro_salario"] } 
        }
    },
    { $sort: { crescimento: -1 } },
    { $limit: 5 }
]);


/**
 * 7. Famílias Numerosas
 * CONCEITO: Query avançada com $expr (Expressões).
 */
db.funcionarios.find({
    // $expr: Permite usar operadores de agregação (como $size) dentro de um find() normal.
    // $gt: "Greater Than" (Maior que).
    // $size: Calcula o tamanho do array 'dependentes'.
    $expr: { $gt: [{ $size: "$dependentes" }, 2] }
}, 
{ "identificacao.nome_completo": 1, "dependentes": 1 });


/**
 * 8. Pirâmide Etária
 * CONCEITO: Manipulação de Datas ($dateDiff).
 */
db.funcionarios.aggregate([
    {
        $project: {
            departamento: "$info_profissional.departamento.nome_depart",
            
            // $dateDiff: Calcula a diferença entre duas datas.
            idade: {
                $dateDiff: {
                    startDate: { $toDate: "$identificacao.data_nascimento" }, // Converte string para data
                    endDate: "$$NOW", // Variável global que representa o momento atual ("agora")
                    unit: "year" // Queremos a diferença em ANOS
                }
            }
        }
    },
    {
        $group: {
            _id: "$departamento",
            media_idade: { $avg: "$idade" } // Média simples
        }
    },
    { $sort: { media_idade: 1 } }
]);


/**
 * 9. Funcionários sem Faltas
 * CONCEITO: "Left Anti-Join" (Buscar o que NÃO existe na outra tabela).
 */
db.funcionarios.aggregate([
    // 1. Tentar buscar as faltas
    {
        $lookup: {
            from: "ausencias",
            localField: "id_sql",
            foreignField: "funcionario_id",
            as: "faltas_info"
        }
    },
    // 2. O Segredo: Se o array 'faltas_info' vier vazio (size: 0), 
    // significa que o lookup não encontrou nada na coleção de ausências.
    // Logo, o funcionário nunca faltou.
    { $match: { "faltas_info": { $size: 0 } } },
    
    { $project: { "identificacao.nome_completo": 1 } },
    { $limit: 5 }
]);


/**
 * 10. Lista de Emails
 * CONCEITO: Projeção simples para otimizar leitura de rede.
 */
db.funcionarios.find(
    {}, // Filtro vazio = Trazer todos
    { 
        "identificacao.nome_completo": 1, 
        "contactos.email": 1, 
        "_id": 0 // Esconder o _id (que vem sempre por defeito) para limpar o JSON
    }
).limit(10);


// =================================================================================
// PARTE 2: OUTRAS COLEÇÕES (5 Queries)
// =================================================================================

/**
 * 11. Funil de Vagas
 * CONCEITO: Agrupar dados que estão dentro de um array ($unwind + $group).
 */
db.vagas.aggregate([
    { $match: { estado: "Aberta" } },
    
    // $unwind: "Explode" o array de candidaturas.
    // Se uma vaga tem 10 candidatos, geramos 10 documentos temporários.
    { $unwind: "$candidaturas_recebidas" },
    
    // $group: Agora podemos contar quantos estão "Rejeitados", "Em Entrevista", etc.
    {
        $group: {
            _id: "$candidaturas_recebidas.estado",
            total: { $sum: 1 }
        }
    }
]);


/**
 * 12. Requisitos Complexos
 * CONCEITO: Operador de Array ($all).
 */
db.vagas.find({
    // $all: Garante que o array 'requisitos' contém TODOS os elementos listados.
    // Se tiver só "Java" mas não "Inglês", não devolve.
    "requisitos": { $all: ["Java", "Inglês Fluente"] }
});


/**
 * 13. Top Avaliações
 * CONCEITO: Filtrar sub-documentos após $unwind.
 */
db.avaliacoes.aggregate([
    // O documento 'avaliacoes' tem um array dentro dele com o mesmo nome.
    { $unwind: "$avaliacoes" },
    
    // Filtramos apenas as avaliações com nota 5
    { $match: { "avaliacoes.pontuacao": 5 } },
    
    // Contamos quantas notas 5 cada funcionário teve
    {
        $group: {
            _id: "$funcionario_id",
            total_5_estrelas: { $sum: 1 }
        }
    },
    { $sort: { total_5_estrelas: -1 } }
]);


/**
 * 14. Candidatos Gmail
 * CONCEITO: Regex em campo de contacto.
 */
db.candidatos.find({
    // A expressão regular termina com $ para garantir que é o final da string.
    // Evita falsos positivos como "gmail.com.br" se quiséssemos ser estritos (mas aqui apanha tudo).
    "contactos.email": /@gmail\.com$/
}, { nome: 1, "contactos.email": 1 });


/**
 * 15. Vagas Populares
 * CONCEITO: Tratamento de nulos ($ifNull) e tamanho de array.
 */
db.vagas.aggregate([
    {
        $project: {
            id: "$id_sql",
            // $size: Conta os elementos.
            // $ifNull: Se o array 'candidaturas_recebidas' não existir (null), 
            // usa um array vazio [] para o $size não dar erro e devolver 0.
            num_candidaturas: { $size: { $ifNull: ["$candidaturas_recebidas", []] } }
        }
    },
    { $sort: { num_candidaturas: -1 } }, // Ordenar Decrescente
    { $limit: 5 }
]);