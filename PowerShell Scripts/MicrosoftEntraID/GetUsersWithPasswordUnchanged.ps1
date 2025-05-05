Write-Host "`n🪟 Microsoft Entra ID - Filtro por Data de Criação de Usuário"
Write-Host "--------------------------------------------------------------"
Write-Host "Este script filtra usuários do Entra ID com base no intervalo de datas da criação da conta.`n"

Write-Host "🔄 Conectando ao Microsoft Entra ID..."
Connect-MgGraph -Scopes "User.Read.All"
Write-Host "✅ Conectado com sucesso!`n"

$start = Get-Date

# Função para entrada de data válida
function Get-ValidDate($prompt) {
    while ($true) {
        $userInput = Read-Host $prompt
        try {
            return [datetime]::ParseExact($userInput, 'dd-MM-yyyy', $null)
        }
        catch {
            Write-Host "❌ Formato inválido. Use o formato dd-MM-yyyy." -ForegroundColor Red
        }
    }
}

# Recebe as datas do usuário
$startDateObj = Get-ValidDate "📅 Insira a data de início (dd-MM-yyyy)"
$endDateObj = Get-ValidDate "📅 Insira a data final (dd-MM-yyyy)"

# Converte para o formato ISO 8601 exigido pela API
$startDate = $startDateObj.ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate = $endDateObj.ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "`n🔍 Buscando usuários criados entre: $startDateObj e $endDateObj`n"

# Filtro no padrão OData
$filter = "createdDateTime ge $startDate and createdDateTime le $endDate"

# Consulta os usuários
$newUsers = Get-MgUser -Filter $filter -All -Property DisplayName, Mail, UserPrincipalName, CreatedDateTime, LastPasswordChangeDateTime, AccountEnabled, UserType

# Função para filtrar usuários que nunca trocaram a senha
function Get-UsersWithPasswordUnchanged($users) {
    $results = @()
    $i = 0

    foreach ($item in $users) {
        $i++

        if (![string]::IsNullOrWhiteSpace($item.Mail)) {
            if ($item.LastPasswordChangeDateTime -eq $item.CreatedDateTime) {
                $results += [PSCustomObject]@{
                    Nome                    = $item.DisplayName
                    Email                   = $item.Mail
                    UPN                     = $item.UserPrincipalName
                    "Data de criação"       = $item.CreatedDateTime
                    "Última troca de senha" = $item.LastPasswordChangeDateTime
                    "Conta Ativa"           = $item.AccountEnabled ? "Sim" : "Não"
                    "UserType"              = $item.UserType
                }

                Write-Host "$($i): $($item.Mail)" -ForegroundColor DarkGray
            }
        }
        else {
            Write-Host "⚠️ Usuário '$($item.DisplayName)' não possui e-mail válido. Ignorando." -ForegroundColor DarkYellow
        }
    }

    Write-Host "`nUsuários filtrados com sucesso.`n" -ForegroundColor Green
    return $results
}

$finalResult = Get-UsersWithPasswordUnchanged -users $newUsers
$finalResult | Sort-Object Nome | Format-Table -AutoSize

$end = Get-Date
$time = $end - $start
Write-Host "Tempo de execução: $($time.Hours):$($time.Minutes):$($time.Seconds)"
