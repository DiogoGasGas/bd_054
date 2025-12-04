Write-Host "--- A INICIAR MIGRACAO COMPLETA ---" -ForegroundColor Cyan

# 0. LIMPEZA (Opcional mas recomendado: apaga o ficheiro antigo para evitar erros)
if (Test-Path "dados_final.json") { Remove-Item "dados_final.json" }

# 1. EXPORTAR
Write-Host "1. A extrair dados complexos do PostgreSQL..."
psql -h appserver.alunos.di.fc.ul.pt -U bd054 -d bd054 -f exportar_dados.sql

# Verifica se o ficheiro foi criado
if (Test-Path "dados_final.json") {
    
    # 2. IMPORTAR
    Write-Host "2. A importar para a colecao 'funcionarios_migrados' no MongoDB..."
    mongoimport --uri "mongodb://bd054:bd054@appserver.alunos.di.fc.ul.pt:27017/bd054?authSource=bd054" --collection funcionarios_migrados --file dados_final.json --drop

    Write-Host "--- SUCESSO! MIGRACAO CONCLUIDA ---" -ForegroundColor Green
} else {
    Write-Host "ERRO: Falha ao criar o ficheiro JSON." -ForegroundColor Red
}