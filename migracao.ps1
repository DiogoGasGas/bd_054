# migracao.ps1

$PG_HOST = "appserver.alunos.di.fc.ul.pt"
$PG_USER = "bd054"
$PG_DB   = "bd054"
$MONGO_COLL = "funcionarios_migrados" 
$MONGO_URI = "mongodb://bd054:bd054@appserver.alunos.di.fc.ul.pt:27017/bd054?authSource=bd054"

Write-Host "--- A INICIAR MIGRACAO COMPLETA ---" -ForegroundColor Cyan

# 1. EXPORTAR
# Removemos o '-o' daqui. O psql corre o script, e o script cria o ficheiro.
Write-Host "1. A extrair dados complexos do PostgreSQL..."
psql -h $PG_HOST -U $PG_USER -d $PG_DB -f exportar_dados.sql

# Verifica se o ficheiro foi criado
if (Test-Path "dados_final.json") {
    
    # 2. IMPORTAR
    Write-Host "2. A importar para a colecao '$MONGO_COLL' no MongoDB..."
    mongoimport --uri $MONGO_URI --collection $MONGO_COLL --file dados_final.json --drop

    Write-Host "--- SUCESSO! MIGRACAO CONCLUIDA ---" -ForegroundColor Green
} else {
    Write-Host "ERRO: Falha ao criar o ficheiro JSON." -ForegroundColor Red
}