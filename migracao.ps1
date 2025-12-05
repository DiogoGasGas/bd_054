# migracao.ps1

# Configuração da ligação
$mongoUri = "mongodb://bd054:bd054@appserver.alunos.di.fc.ul.pt:27017/bd054?authSource=bd054"

Write-Host "--- A INICIAR MIGRACAO TOTAL (6 COLECOES) ---" -ForegroundColor Cyan

# ---------------------------------------------------------
# 0. LIMPEZA INICIAL
# (Apaga os ficheiros antigos um a um para garantir que não sobra lixo)
# ---------------------------------------------------------
if (Test-Path "departamentos.json") { Remove-Item "departamentos.json" }
if (Test-Path "formacoes.json")     { Remove-Item "formacoes.json" }
if (Test-Path "candidatos.json")    { Remove-Item "candidatos.json" }
if (Test-Path "avaliacoes.json")    { Remove-Item "avaliacoes.json" }
if (Test-Path "vagas.json")         { Remove-Item "vagas.json" }
if (Test-Path "funcionarios.json")  { Remove-Item "funcionarios.json" }

# ---------------------------------------------------------
# 1. EXPORTAR (Postgres -> JSON)
# ---------------------------------------------------------
Write-Host "1. A extrair dados de todas as tabelas (PostgreSQL)..."
# O psql corre o script SQL que gera os 6 ficheiros JSON automaticamente
psql -h appserver.alunos.di.fc.ul.pt -U bd054 -d bd054 -f exportar_dados.sql


# ---------------------------------------------------------
# 2. IMPORTAR (JSON -> MongoDB)
# (Executamos o comando de importação explicitamente para cada coleção)
# ---------------------------------------------------------
Write-Host "2. A importar para o MongoDB..."

# --- Departamentos ---
if (Test-Path "departamentos.json") {
    Write-Host "   -> Importar 'departamentos'..."
    mongoimport --uri $mongoUri --collection departamentos --file departamentos.json --drop
}

# --- Formacoes ---
if (Test-Path "formacoes.json") {
    Write-Host "   -> Importar 'formacoes'..."
    mongoimport --uri $mongoUri --collection formacoes --file formacoes.json --drop
}

# --- Candidatos ---
if (Test-Path "candidatos.json") {
    Write-Host "   -> Importar 'candidatos'..."
    mongoimport --uri $mongoUri --collection candidatos --file candidatos.json --drop
}

# --- Avaliacoes ---
if (Test-Path "avaliacoes.json") {
    Write-Host "   -> Importar 'avaliacoes'..."
    mongoimport --uri $mongoUri --collection avaliacoes --file avaliacoes.json --drop
}

# --- Vagas ---
if (Test-Path "vagas.json") {
    Write-Host "   -> Importar 'vagas'..."
    mongoimport --uri $mongoUri --collection vagas --file vagas.json --drop
}

# --- Funcionarios ---
if (Test-Path "funcionarios.json") {
    Write-Host "   -> Importar 'funcionarios'..."
    mongoimport --uri $mongoUri --collection funcionarios --file funcionarios.json --drop
}

Write-Host "--- MIGRACAO CONCLUIDA COM SUCESSO! ---" -ForegroundColor Green