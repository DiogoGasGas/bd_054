

{
  $jsonSchema: {
    bsonType: 'object',
    required: [
      'id_fun',
      'nif',
      'primeiro_nome',
      'ultimo_nome'
    ],
    properties: {
      id_fun: {
        bsonType: 'int',
        description: 'ID do funcionário (obrigatório)'
      },
      nif: {
        bsonType: 'string',
        description: 'NIF (obrigatório)'
      },
      primeiro_nome: {
        bsonType: 'string',
        description: 'Primeiro nome (obrigatório)'
      },
      ultimo_nome: {
        bsonType: 'string',
        description: 'Último nome (obrigatório)'
      },
      nome_rua: {
        bsonType: 'string',
        description: 'Nome da rua (opcional)'
      },
      nome_localidade: {
        bsonType: 'string',
        description: 'Nome da localidade (opcional)'
      },
      codigo_postal: {
        bsonType: 'string',
        description: 'Código postal (opcional)'
      },
      num_telemovel: {
        bsonType: 'string',
        description: 'Número de telemóvel (opcional)'
      },
      email: {
        bsonType: 'string',
        description: 'Email (opcional)'
      },
      data_nascimento: {
        bsonType: 'string',
        description: 'Data de nascimento (string, opcional)'
      },
      cargo: {
        bsonType: 'string',
        description: 'Cargo (opcional)'
      }
    }
  }
}

{
  $jsonSchema: {
    bsonType: 'object',
    required: [
      'id_depart',
      'nome'
    ],
    properties: {
      id_depart: {
        bsonType: 'int',
        description: 'ID do departamento (inteiro, obrigatório)'
      },
      nome: {
        bsonType: 'string',
        'enum': [
          'Recursos Humanos',
          'Tecnologia da Informação',
          'Financeiro',
          'Marketing',
          'Vendas',
          'Qualidade',
          'Atendimento ao Cliente',
          'Jurídico'
        ],
        description: 'Nome do departamento (apenas valores permitidos, obrigatório)'
      },
      id_gerente: {
        bsonType: 'int',
        description: 'ID do gerente (referência para funcionarios.id_fun, único, opcional)'
      }
    }
  }
}















db.createCollection("candidato_a", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_cand", "id_vaga", "data_cand", "estado", "id_recrutador"],
      properties: {
        id_cand: {
          bsonType: "objectId",
          description: "deve ser um ObjectId que faz referência ao candidato"
        },
        id_vaga: {
          bsonType: "objectId",
          description: "deve ser um ObjectId que faz referência à vaga"
        },
        data_cand: {
          bsonType: "date",
          description: "deve ser uma data"
        },
        estado: {
          bsonType: "string",
          enum: ["Submetido", "Em análise", "Entrevista", "Rejeitado", "Contratado"],
          description: "estado do candidato, valores possíveis: 'Submetido', 'Em análise', 'Entrevista', 'Rejeitado', 'Contratado'"
        },
        id_recrutador: {
          bsonType: "objectId",
          description: "deve ser um ObjectId que faz referência ao recrutador, ou null"
        }
      }
    }
  },
  validationAction: "warn"  // Ou "error" se você quiser que a inserção falhe ao violar a validação
});


db.createCollection("requisitos_vaga", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_vaga", "requisito"],
      properties: {
        id_vaga: {
          bsonType: "objectId",
          description: "deve ser um ObjectId que faz referência à vaga"
        },
        requisito: {
          bsonType: "string",
          description: "deve ser uma string que representa o requisito"
        }
      }
    }
  },
  validationAction: "warn"  // Ou "error" se você quiser que a inserção falhe ao violar a validação
});


db.createCollection("formacoes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_for", "nome_formacao", "data_inicio"],
      properties: {
        id_for: {
          bsonType: "int",
          description: "Identificador único da formação (int)"
        },
        nome_formacao: {
          bsonType: "string",
          description: "Nome da formação (string)"
        },
        descricao: {
          bsonType: "string",
          description: "Descrição da formação (string)"
        },
        data_inicio: {
          bsonType: "date",
          description: "Data de início da formação"
        },
        data_fim: {
          bsonType: "date",
          description: "Data de término da formação (pode ser nula)"
        },
        estado: {
          bsonType: "string",
          enum: ["Planeada", "Em curso", "Concluída", "Cancelada"],
          description: "Estado da formação"
        }
      }
    }
  },
  validationAction: "warn"  // Ou "error" se você quiser que a inserção falhe ao violar a validação
});


db.createCollection("teve_formacao", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_fun", "id_for", "data_inicio"],
      properties: {
        id_fun: {
          bsonType: "objectId",
          description: "Referência ao funcionário (ObjectId)"
        },
        id_for: {
          bsonType: "objectId",
          description: "Referência à formação (ObjectId)"
        },
        certificado: {
          bsonType: "binData",
          description: "Certificado da formação (BinData)"
        },
        data_inicio: {
          bsonType: "date",
          description: "Data de início da formação"
        },
        data_fim: {
          bsonType: "date",
          description: "Data de término da formação (pode ser nula)"
        }
      }
    }
  },
  validationAction: "warn"  // Ou "error" se você quiser que a inserção falhe ao violar a validação
});


db.createCollection("avaliacoes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_fun", "id_avaliador", "data", "avaliacao_numerica", "criterios", "autoavaliacao"],
      properties: {
        id_fun: {
          bsonType: "objectId",
          description: "Referência ao funcionário avaliado (ObjectId)"
        },
        id_avaliador: {
          bsonType: "objectId",
          description: "Referência ao avaliador (ObjectId)"
        },
        data: {
          bsonType: "date",
          description: "Data da avaliação"
        },
        avaliacao: {
          bsonType: "binData",
          description: "Avaliação em formato binário (ex. documento ou imagem)"
        },
        avaliacao_numerica: {
          bsonType: "int",
          description: "Avaliação numérica (pontuação)"
        },
        criterios: {
          bsonType: "string",
          description: "Critérios da avaliação"
        },
        autoavaliacao: {
          bsonType: "string",
          description: "Autoavaliação do funcionário"
        }
      }
    }
  },
  validationAction: "warn"  // Ou "error" se você quiser que a inserção falhe ao violar a validação
});



db.createCollection("utilizadores", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_fun", "password"],
      properties: {
        id_fun: {
          bsonType: "objectId",
          description: "Referência ao funcionário (ObjectId)"
        },
        password: {
          bsonType: "string",
          minLength: 1,
          maxLength: 30,
          description: "Senha do usuário (não pode ser nula)"
        }
      }
    }
  },
  validationAction: "warn"  // Ou "error" se você quiser que a inserção falhe ao violar a validação
});


db.createCollection("permissoes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["id_fun", "permissao"],
      properties: {
        id_fun: {
          bsonType: "objectId",
          description: "Referência ao funcionário (ObjectId)"
        },
        permissao: {
          bsonType: "string",
          description: "Nome da permissão associada ao funcionário"
        }
      }
    }
  },
  validationAction: "warn"  // Ou "error" se você quiser que a inserção falhe ao violar a validação
});
