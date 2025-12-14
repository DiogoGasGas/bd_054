# migracao.ps1

# Configuração da ligação
$mongoUri = "mongodb://bd054:bd054@appserver.alunos.di.fc.ul.pt:27017/bd054?authSource=bd054"

Write-Host "--- A INICIAR MIGRACAO TOTAL (7 COLECOES) ---" -ForegroundColor Cyan

# ---------------------------------------------------------
# 0. LIMPEZA INICIAL
# (Apaga os ficheiros antigos um a um para garantir que não sobra lixo)
# ---------------------------------------------------------
if (Test-Path "Ficheiros Migracao/formacoes.json")            { Remove-Item "Ficheiros Migracao/formacoes.json" }
if (Test-Path "Ficheiros Migracao/candidatos.json")           { Remove-Item "Ficheiros Migracao/candidatos.json" }
if (Test-Path "Ficheiros Migracao/avaliacoes.json")           { Remove-Item "Ficheiros Migracao/avaliacoes.json" }
if (Test-Path "Ficheiros Migracao/vagas.json")                { Remove-Item "Ficheiros Migracao/vagas.json" }
if (Test-Path "Ficheiros Migracao/historico_salarial.json")   { Remove-Item "Ficheiros Migracao/historico_salarial.json" }
if (Test-Path "Ficheiros Migracao/ausencias.json")            { Remove-Item "Ficheiros Migracao/ausencias.json" }
if (Test-Path "Ficheiros Migracao/funcionarios.json")         { Remove-Item "Ficheiros Migracao/funcionarios.json" }

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

# --- Formacoes ---
if (Test-Path "Ficheiros Migracao/formacoes.json") {
    Write-Host "   -> Importar 'formacoes'..."
    mongoimport --uri $mongoUri --collection formacoes --file "Ficheiros Migracao/formacoes.json" --drop
}

# --- Candidatos ---
if (Test-Path "Ficheiros Migracao/candidatos.json") {
    Write-Host "   -> Importar 'candidatos'..."
    mongoimport --uri $mongoUri --collection candidatos --file "Ficheiros Migracao/candidatos.json" --drop
}

# --- Avaliacoes ---
if (Test-Path "Ficheiros Migracao/avaliacoes.json") {
    Write-Host "   -> Importar 'avaliacoes'..."
    mongoimport --uri $mongoUri --collection avaliacoes --file "Ficheiros Migracao/avaliacoes.json" --drop
}

# --- Vagas ---
if (Test-Path "Ficheiros Migracao/vagas.json") {
    Write-Host "   -> Importar 'vagas'..."
    mongoimport --uri $mongoUri --collection vagas --file "Ficheiros Migracao/vagas.json" --drop
}

# --- Historico Salarial ---
if (Test-Path "Ficheiros Migracao/historico_salarial.json") {
    Write-Host "   -> Importar 'historico_salarial'..."
    mongoimport --uri $mongoUri --collection historico_salarial --file "Ficheiros Migracao/historico_salarial.json" --drop
}

# --- Ausencias (ferias + faltas) ---
if (Test-Path "Ficheiros Migracao/ausencias.json") {
    Write-Host "   -> Importar 'ausencias'..."
    mongoimport --uri $mongoUri --collection ausencias --file "Ficheiros Migracao/ausencias.json" --drop
}

# --- Funcionarios ---
if (Test-Path "Ficheiros Migracao/funcionarios.json") {
    Write-Host "   -> Importar 'funcionarios'..."
    mongoimport --uri $mongoUri --collection funcionarios --file "Ficheiros Migracao/funcionarios.json" --drop
}

Write-Host "--- MIGRACAO CONCLUIDA COM SUCESSO! ---" -ForegroundColor Green