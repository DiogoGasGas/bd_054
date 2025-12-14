# Migração PostgreSQL → MongoDB - Estrutura das Coleções

## 📋 Visão Geral

A migração para MongoDB envolveu a criação de **7 coleções**, representando aproximadamente **30% dos dados** do sistema. A escolha de quais dados migrar baseou-se em critérios técnicos de performance, escalabilidade e padrões de acesso.

---

## 🗂️ Estrutura das Coleções

### **1. `funcionarios` (Documento Principal - LEVE)**

**Objetivo:** Perfil completo do funcionário com dados frequentemente consultados em conjunto.

**Estrutura:**
```javascript
{
  "id_sql": Number,
  "identificacao": {
    "nome_completo": String,
    "nif": String,
    "data_nascimento": Date
  },
  "contactos": {
    "email": String,
    "telemovel": String,
    "morada": {
      "rua": String,
      "localidade": String,
      "cp": String
    }
  },
  "info_profissional": {
    "cargo": String,
    "departamento": {                    // ← EMBEDDING
      "id_depart_sql": Number,
      "nome_depart": String,
      "gerente": Boolean
    }
  },
  "autenticacao": {
    "password": String,
    "permissoes": Array[String]
  },
  "dependentes": Array[{                 // ← EMBEDDING
    "nome": String,
    "parentesco": String,
    "nascimento": Date
  }],
  "historico_empresas": Array[{          // ← EMBEDDING (ordenado por data DESC)
    "empresa": String,
    "cargo": String,
    "inicio": Date,
    "fim": Date | null
  }],
  "formacoes_realizadas": Array[{        // ← REFERÊNCIA
    "id_formacao_sql": Number,
    "inicio": Date,
    "fim": Date | null
  }],
  "salario_atual": {                     // ← EMBEDDING (só o atual)
    "inicio": Date,
    "fim": Date | null,
    "base": Decimal,
    "liquido": Decimal,
    "beneficios": Array[{
      "tipo": String,
      "valor": Decimal
    }]
  }
}
```

**Decisões de Modelação:**
- ✅ **Departamento embeded:** Nome desnormalizado para evitar JOINs; sempre consultado junto
- ✅ **Dependentes embeded:** Poucos registos (2-4), sempre lidos com funcionário
- ✅ **Histórico empresas embeded:** Dados do passado que não crescem mais, ordenados por data mais recente (empresa atual sempre em `[0]`)
- ✅ **Salário atual embeded:** Acesso frequente, 1 registo apenas
- ❌ **Histórico salarial NÃO embeded:** Cresce ao longo do tempo (~1-2 registos/ano)
- ❌ **Férias/Faltas NÃO embeded:** Crescimento elevado (10-50 faltas/ano)


---

### **2. `historico_salarial` (Coleção Separada - Agrupada)**

**Objetivo:** Histórico completo de remunerações por funcionário, consultado apenas quando necessário.

**Estrutura:**
```javascript
{
  "funcionario_id": Number,
  "periodos": Array[{                    // ← Ordenados por data_inicio
    "inicio": Date,
    "fim": Date | null,
    "base": Decimal,                     // ← Do "salario"
    "liquido": Decimal,                  // ← Do "salario"
    "beneficios": Array[{                // ← De "beneficios" (pode estar vazio)
      "tipo": String,
      "valor": Decimal
    }]
  }]
}
```

**Decisões de Modelação:**
- ✅ **Agrupado por funcionário:** 1 documento = todos os períodos salariais de 1 funcionário
- ✅ **Array ordenado:** Períodos ordenados cronologicamente (mais antigo → mais recente)
- ✅ **Benefícios como array:** Pode estar vazio `[]` se o período só tem salário base

**Justificação:**
- Cada período no PostgreSQL é 1 linha em `remuneracoes` + JOIN com `salario` + agregação de `beneficios`
- MongoDB: 1 query simples retorna todo o histórico
- Crescimento: ~1-2 períodos/ano (aceitável em array)

---

### **3. `ausencias` (Coleção Separada - Agrupada e Unificada)**

**Objetivo:** Histórico completo de férias e faltas por funcionário (timeline de ausências).

**Estrutura:**
```javascript
{
  "funcionario_id": Number,
  "ausencias": Array[{                   // ← Ordenadas por data
    // Tipo "ferias"
    "tipo": "ferias",
    "data_inicio": Date,
    "data_fim": Date,
    "num_dias": Number,
    "estado": String                     // "Aprovado" | "Rejeitado" | "Por aprovar"
  }, {
    // Tipo "falta"
    "tipo": "falta",
    "data": Date,
    "justificacao": String | null
  }]
}
```

**Decisões de Modelação:**
- ✅ **Coleção unificada:** Férias e faltas no mesmo array (timeline completa)
- ✅ **Schema híbrido:** Campos diferentes por tipo (`data_inicio/fim` para férias, `data` para faltas)
- ✅ **Ordenação temporal:** Permite visualizar cronologia de todas as ausências
- ✅ **Agrupado por funcionário:** Consistência com `historico_salarial`

**Justificação:**
- PostgreSQL: 2 tabelas separadas (`ferias` + `faltas`) requerem UNION para timeline
- MongoDB: 1 query retorna tudo ordenado
- Crescimento: ~2-4 férias/ano + 5-20 faltas/ano (aceitável)

---

### **4. `avaliacoes` (Coleção Separada - Agrupada)**

**Objetivo:** Histórico de avaliações de desempenho por funcionário avaliado.

**Estrutura:**
```javascript
{
  "funcionario_id": Number,              // ← Funcionário AVALIADO
  "avaliacoes": Array[{                  // ← Ordenadas por data DESC (mais recente primeiro)
    "data": Date,
    "avaliador_id_sql": Number,          // ← REFERÊNCIA ao avaliador
    "pontuacao": Number,
    "conteudo": {
      "criterios": String,
      "autoavaliacao": String,
      "ficheiro_b64": String | null      // ← PDF em Base64
    }
  }]
}
```

**Decisões de Modelação:**
- ✅ **Agrupado por avaliado:** 1 documento = todas as avaliações recebidas por 1 funcionário
- ✅ **Array ordenado:** Avaliações ordenadas por data (mais recente primeiro)
- ✅ **Referência ao avaliador:** `avaliador_id_sql` liga ao funcionário que avaliou
- ✅ **Consistência:** Mesmo padrão de `historico_salarial` e `ausencias`

**Justificação:**
- Caso de uso principal: "Ver histórico de avaliações do funcionário X"
- PostgreSQL: Requer filtro por `id_fun`
- MongoDB: 1 query simples retorna todo o histórico
- Crescimento: ~1-2 avaliações/ano (aceitável em array)

---

### **5. `vagas` (Coleção Separada - Candidaturas Embeded)**

**Objetivo:** Vagas de emprego com candidaturas sempre consultadas em conjunto.

**Estrutura:**
```javascript
{
  "id_sql": Number,
  "estado": String,                      // "Aberta" | "Fechada" | "Suspensa"
  "data_abertura": Date,
  "id_depart_sql": Number,               // ← REFERÊNCIA a departamento
  "requisitos": Array[String],           // ← EMBEDDING
  "candidaturas_recebidas": Array[{      // ← EMBEDDING
    "id_candidato_sql": Number,          // ← REFERÊNCIA a candidato
    "data": Date,
    "estado": String,                    // "Submetido" | "Em análise" | ...
    "recrutador_id_sql": Number          // ← REFERÊNCIA a funcionário
  }]
}
```

**Decisões de Modelação:**
- ✅ **Candidaturas embeded:** Sempre consultadas junto com vaga ("vaga X tem quantos candidatos?")
- ✅ **Requisitos embeded:** Array simples de strings
- ✅ **Referências preservadas:** `id_candidato_sql`, `recrutador_id_sql` ligam a outras coleções

**Justificação:**
- Padrão de acesso: "Mostrar vaga com lista de candidatos"
- PostgreSQL: Requer JOIN com `candidato_a`
- MongoDB: 1 query retorna tudo

---

### **6. `candidatos` (Coleção Separada)**

**Objetivo:** Catálogo de candidatos a vagas.

**Estrutura:**
```javascript
{
  "id_sql": Number,
  "nome": String,
  "contactos": {
    "email": String,
    "telemovel": String
  },
  "documentos": {
    "cv_b64": String | null,             // ← PDF em Base64
    "carta_motivacao_b64": String | null // ← PDF em Base64
  }
}
```

**Decisões de Modelação:**
- ✅ **Coleção separada:** Candidatos podem candidatar-se a múltiplas vagas
- ✅ **Documentos embeded:** CVs/cartas em Base64 (evita gestão de ficheiros)

---

### **7. `formacoes` (Coleção Separada - Catálogo)**

**Objetivo:** Catálogo de formações disponibilizadas pela empresa.

**Estrutura:**
```javascript
{
  "id_sql": Number,
  "nome": String,
  "descricao": String,
  "datas": {
    "inicio": Date,
    "fim": Date
  },
  "estado": String                       // "Planeada" | "Em curso" | "Concluida" | "Cancelada"
}
```

**Decisões de Modelação:**
- ✅ **Coleção separada:** Catálogo partilhado (múltiplos funcionários podem frequentar)
- ✅ **Referências:** `funcionarios.formacoes_realizadas` tem array de `id_formacao_sql`

---

## 📊 Resumo: Embedding vs Referencing

| Dados | Decisão | Razão |
|-------|---------|-------|
| **Departamento** | Embedding (desnormalizado) | Nome consultado frequentemente; evita JOINs |
| **Dependentes** | Embedding | Poucos (2-4); sempre lidos com funcionário |
| **Histórico empresas** | Embedding | Fixo (passado); não cresce mais |
| **Salário atual** | Embedding | Acesso frequente; 1 registo apenas |
| **Histórico salarial** | Coleção separada (agrupada) | Cresce ~1-2/ano; consultado separadamente |
| **Ausências** | Coleção separada (agrupada) | Cresce 10-50/ano; evita documento gigante |
| **Avaliações** | Coleção separada (agrupada) | Cresce ~1-2/ano; histórico por funcionário |
| **Candidaturas** | Embedding em vagas | Sempre consultadas juntas |
| **Candidatos** | Coleção separada | Partilhados entre vagas (M:N) |
| **Formações** | Coleção separada | Catálogo partilhado |

---

## 🎯 Vantagens da Estrutura Escolhida

1. **Performance:** Documento `funcionarios` leve (5-10 KB) → queries rápidas para perfil básico
2. **Escalabilidade:** Dados que crescem ilimitadamente ficam em coleções separadas
3. **Consistência:** Padrão uniforme (agrupamento por funcionário) para todos os históricos (salários, ausências, avaliações)
4. **Flexibilidade:** Schema híbrido em `ausencias` permite férias e faltas juntas
5. **Manutenibilidade:** Estrutura clara e justificável tecnicamente

---

## 📉 Trade-offs Aceites

- **Desnormalização:** Nome do departamento repetido em todos os funcionários (facilita queries, mas requer sincronização em atualizações)
- **Múltiplas queries:** Para perfil completo com históricos (funcionário + salários + ausências + avaliações) são necessárias 4 queries (aceitável dado uso raro)
- **Schema híbrido:** `ausencias` tem estruturas diferentes por tipo (mais flexível, mas requer validação cuidadosa)
