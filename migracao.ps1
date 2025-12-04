Write-Host "--- A INICIAR MIGRACAO TOTAL (6 COLECOES) ---" -ForegroundColor Cyan

# Lista dos ficheiros que vamos criar
$ficheiros = @("departamentos.json", "formacoes.json", "candidatos.json", "avaliacoes.json", "vagas.json", "funcionarios.json")

# 0. LIMPEZA INICIAL
foreach ($f in $ficheiros) {
    if (Test-Path $f) { Remove-Item $f }
}

# 1. EXPORTAR (Postgres -> JSON)
Write-Host "1. A extrair dados de todas as tabelas..."
psql -h appserver.alunos.di.fc.ul.pt -U bd054 -d bd054 -f exportar_dados.sql

# 2. IMPORTAR (JSON -> MongoDB)
Write-Host "2. A importar para o MongoDB..."

# Configuração da ligação Mongo
$mongoUri = "mongodb://bd054:bd054@appserver.alunos.di.fc.ul.pt:27017/bd054?authSource=bd054"

foreach ($f in $ficheiros) {
    if (Test-Path $f) {
        # O nome da coleção será o nome do ficheiro sem o ".json" (ex: 'vagas')
        $colecao = [System.IO.Path]::GetFileNameWithoutExtension($f)
        
        Write-Host "   -> Importar '$colecao'..."
        mongoimport --uri $mongoUri --collection $colecao --file $f --drop
    } else {
        Write-Host "   ERRO: O ficheiro $f nao foi criado!" -ForegroundColor Red
    }
}

Write-Host "--- MIGRACAO CONCLUIDA COM SUCESSO! ---" -ForegroundColor Green