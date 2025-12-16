/**
 * =================================================================================
 * QUERIES MONGODB OTIMIZADAS & COMENTADAS (DIDÁTICO)
 * =================================================================================
 * * Este ficheiro explica o funcionamento interno de cada estágio (Stage) 
 * das queries e agregações.
 */

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
            // $arrayElemAt: Vai buscar um elemento numa posição específica.
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
