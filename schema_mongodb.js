{
  "_id": ObjectId("..."),
  "id_sql": 101,
  "identificacao": {
    "primeiro_nome": "João",
    "ultimo_nome": "Silva",
    "nif": "123456789",
    "data_nascimento": ISODate("1980-01-01")
  },
  "contactos": {
    "email": "joao@empresa.com",
    "telemovel": "912345678",
    "morada": { "rua": "...", "localidade": "...", "cp": "..." }
  },
  "profissional": {
    "cargo_atual": "Dev Senior",
    "id_departamento": ObjectId("...") // Referência à coleção departamentos
  },
  "autenticacao": { // Tabela 'utilizadores' e 'permissoes'
    "password": "hashed_pass...",
    "permissoes": ["admin", "leitura"]
  },
  "dependentes": [ // Tabela 'dependentes'
    { "nome": "Maria", "parentesco": "Filha", "nascimento": "..." }
  ],
  "historico_externo": [ // Tabela 'historico_empresas'
    { "empresa": "Google", "cargo": "Intern", "inicio": "...", "fim": "..." }
  ],
  "historico_salarial": [ // Fusão de 'remuneracoes', 'salario', 'beneficios'
    {
      "data_inicio": ISODate("2023-01-01"),
      "data_fim": null,
      "salario_base": 2000.00,
      "salario_liquido": 1400.00,
      "beneficios": [
        { "tipo": "Carro Empresa", "valor": 300 }
      ]
    }
  ],
  "formacoes_realizadas": [ // Tabela 'teve_formacao'
    { 
      "id_formacao": ObjectId("..."), 
      "data": "...", 
      "certificado_url": "..." 
    }
  ],
  "registo_ausencias": { // Fusão de 'ferias' e 'faltas'
     "ferias": [{ "inicio": "...", "fim": "...", "estado": "Aprovado" }],
     "faltas": [{ "data": "...", "justificacao": "Gripe" }]
  }
}


{
  "_id": ObjectId("..."),
  "id_sql": 5,
  "nome": "Tecnologia da Informação",
  "id_gerente": ObjectId("...") // Link para o funcionário que manda nisto
}



{
  "_id": ObjectId("..."),
  "id_vaga_sql": 1,
  "estado": "Aberta",
  "data_abertura": ISODate("2024-01-01"),
  "departamento_id": ObjectId("..."),
  "requisitos": ["Java", "SQL", "Inglês"], // Tabela 'requisitos_vaga' (array simples)
  "candidaturas_recebidas": [ // Tabela 'candidato_a'
    {
      "id_candidato": ObjectId("..."), // Referência à coleção candidatos
      "data_candidatura": ISODate("..."),
      "estado": "Entrevista",
      "recrutador_responsavel": ObjectId("...")
    }
  ]
}



{
  "_id": ObjectId("..."),
  "id_cand_sql": 99,
  "nome": "Rui Patrício",
  "contactos": { "email": "...", "telemovel": "..." },
  "documentos": {
    "cv_bin": BinData(...),       // O campo BYTEA vem para aqui
    "carta_motivacao_bin": BinData(...)
  }
}




{
  "_id": ObjectId("..."),
  "data": ISODate("2024-12-01"),
  "avaliado_id": ObjectId("..."),   // Quem sofreu a avaliação
  "avaliador_id": ObjectId("..."),  // Quem fez a avaliação
  "pontuacao": 18,
  "conteudo": {
    "criterios": "Assiduidade, Qualidade...",
    "autoavaliacao": "Acho que fui bem...",
    "ficheiro_avaliacao": BinData(...)
  }
}




{
  "_id": ObjectId("..."),
  "id_for_sql": 50,
  "nome": "Workshop Security",
  "descricao": "...",
  "datas": { "inicio": "...", "fim": "..." },
  "estado": "Planeada"
}



