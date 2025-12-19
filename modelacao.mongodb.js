// ==========================================
// 1. COLEÇÃO: ausencias
// ==========================================
db.createCollection("ausencias", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "ausencias", "funcionario_id"],
      properties: {
        _id: { bsonType: "objectId" },
        funcionario_id: { bsonType: "int" }, // ID de ligação ao funcionário
        ausencias: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["tipo"],
            properties: {
              data_inicio: { bsonType: "string" },
              data_fim: { bsonType: "string" },
              estado: { bsonType: "string" }, // Ex: Aprovada, Recusada
              justificacao: { bsonType: ["string", "null"] },
              num_dias: { bsonType: "int" },
              tipo: { bsonType: "string" } // Ex: Férias, Doença
            }
          }
        }
      }
    }
  }
});

// ==========================================
// 2. COLEÇÃO: avaliacoes
// ==========================================
db.createCollection("avaliacoes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "avaliacoes", "funcionario_id"],
      properties: {
        _id: { bsonType: "objectId" },
        funcionario_id: { bsonType: "int" },
        avaliacoes: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["avaliador_id_sql", "conteudo", "data", "pontuacao"],
            properties: {
              avaliador_id_sql: { bsonType: "int" },
              data: { bsonType: "string" },
              pontuacao: { bsonType: "int" }, // Escala numérica de desempenho
              conteudo: {
                bsonType: "object",
                required: ["autoavaliacao", "criterios", "ficheiro_b64"],
                properties: {
                  autoavaliacao: { bsonType: ["string", "null"] },
                  criterios: { bsonType: "string" },
                  ficheiro_b64: { bsonType: "null" } // Placeholder para anexos
                }
              }
            }
          }
        }
      }
    }
  }
});

// ==========================================
// 3. COLEÇÃO: candidatos
// ==========================================
db.createCollection("candidatos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "id_sql", "nome", "contactos", "documentos"],
      properties: {
        _id: { bsonType: "objectId" },
        id_sql: { bsonType: "int" },
        nome: { bsonType: "string" },
        contactos: {
          bsonType: "object",
          required: ["email", "telemovel"],
          properties: {
            email: { bsonType: "string" },
            telemovel: { bsonType: "string" }
          }
        },
        documentos: {
          bsonType: "object",
          required: ["cv_b64", "carta_motivacao_b64"],
          properties: {
            cv_b64: { bsonType: "null" },
            carta_motivacao_b64: { bsonType: "null" }
          }
        }
      }
    }
  }
});

// ==========================================
// 4. COLEÇÃO: formacoes
// ==========================================
db.createCollection("formacoes", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "id_sql", "nome", "descricao", "datas", "estado"],
      properties: {
        _id: { bsonType: "objectId" },
        id_sql: { bsonType: "int" },
        nome: { bsonType: "string" },
        descricao: { bsonType: "string" },
        estado: { bsonType: "string" }, // Ex: Agendada, Concluída
        datas: {
          bsonType: "object",
          required: ["inicio", "fim"],
          properties: {
            inicio: { bsonType: "string" },
            fim: { bsonType: "string" }
          }
        }
      }
    }
  }
});

// ==========================================
// 5. COLEÇÃO: funcionarios
// ==========================================
db.createCollection("funcionarios", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "id_sql", "identificacao", "contactos", "info_profissional", "autenticacao", "historico_empresas", "salario_atual"],
      properties: {
        _id: { bsonType: "objectId" },
        id_sql: { bsonType: "int" },
        identificacao: {
          bsonType: "object",
          required: ["nome_completo", "nif", "data_nascimento"],
          properties: {
            nome_completo: { bsonType: "string" },
            nif: { bsonType: "string" },
            data_nascimento: { bsonType: "string" }
          }
        },
        contactos: {
          bsonType: "object",
          required: ["email", "telemovel", "morada"],
          properties: {
            email: { bsonType: "string" },
            telemovel: { bsonType: "string" },
            morada: {
              bsonType: "object",
              required: ["rua", "localidade", "cp"],
              properties: {
                rua: { bsonType: "string" },
                localidade: { bsonType: "string" },
                cp: { bsonType: "string" }
              }
            }
          }
        },
        info_profissional: {
          bsonType: "object",
          required: ["cargo", "departamento"],
          properties: {
            cargo: { bsonType: "string" },
            departamento: {
              bsonType: "object",
              required: ["id_depart_sql", "nome_depart", "gerente"],
              properties: {
                id_depart_sql: { bsonType: "int" },
                nome_depart: { bsonType: "string" },
                gerente: { bsonType: "bool" }
              }
            }
          }
        },
        salario_atual: {
          bsonType: "object",
          required: ["inicio", "fim", "base", "liquido", "beneficios"],
          properties: {
            base: { bsonType: "double" },
            liquido: { bsonType: "double" },
            beneficios: {
              bsonType: "array",
              items: {
                bsonType: "object",
                properties: { tipo: { bsonType: "string" }, valor: { bsonType: "double" } }
              }
            }
          }
        }
      }
    }
  }
});

// ==========================================
// 6. COLEÇÃO: historico_salarial
// ==========================================
db.createCollection("historico_salarial", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "funcionario_id", "periodos"],
      properties: {
        _id: { bsonType: "objectId" },
        funcionario_id: { bsonType: "int" },
        periodos: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["inicio", "fim", "base", "liquido", "beneficios"],
            properties: {
              inicio: { bsonType: "string" },
              fim: { bsonType: ["string", "null"] },
              base: { bsonType: "double" },
              liquido: { bsonType: "double" }
            }
          }
        }
      }
    }
  }
});

// ==========================================
// 7. COLEÇÃO: vagas
// ==========================================
db.createCollection("vagas", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "candidaturas_recebidas", "data_abertura", "estado", "id_depart_sql", "id_sql", "requisitos"],
      properties: {
        _id: { bsonType: "objectId" },
        id_sql: { bsonType: "int" },
        data_abertura: { bsonType: "string" },
        estado: { bsonType: "string" }, // Ex: Aberta, Preenchida
        id_depart_sql: { bsonType: "int" },
        requisitos: { bsonType: "array", items: { bsonType: "string" } },
        candidaturas_recebidas: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["data", "estado", "id_candidato_sql", "recrutador_id_sql"],
            properties: {
              id_candidato_sql: { bsonType: "int" },
              recrutador_id_sql: { bsonType: "int" },
              estado: { bsonType: "string" } // Ex: Em análise, Rejeitado
            }
          }
        }
      }
    }
  }
});






