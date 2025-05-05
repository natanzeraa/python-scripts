Write-Host "`n🪟 Microsoft Entra ID - Filtro por Data de Criação de Usuário"
Write-Host "--------------------------------------------------------------"
Write-Host "Este script filtra usuários do Entra ID com base na data de criação da conta.`n"

Write-Host "🔄 Conectando ao Microsoft Entra ID..."
Connect-MgGraph -Scopes "User.Read.All"
Write-Host "✅ Conectado com sucesso!`n"

# Solicita e valida o número de dias
do {
    $days = Read-Host "📅 Quantos dias atrás você quer buscar? (insira um número)"
} while (-not ($days -as [int]))

# Converte para formato ISO 8601
$filterDate = (Get-Date).AddDays(-[int]$days).ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "`n🔍 Buscando usuários criados desde: $filterDate`n"

# Busca usuários filtrando pela data de criação
$newUsers = Get-MgUser -Filter "createdDateTime ge $filterDate" -All

# Exibe os resultados com informações relevantes
$newUsers | Select-Object DisplayName, UserPrincipalName, CreatedDateTime | Sort-Object DisplayName | Format-Table -AutoSize
