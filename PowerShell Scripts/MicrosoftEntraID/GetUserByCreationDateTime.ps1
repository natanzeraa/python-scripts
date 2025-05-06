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
$newUsers = Get-MgUser -Filter $filter -All

# Busca os usuários do EntraID e monta um objeto completo com as informações necessárias
function Get-UsersWithCreationDate($users) {
    $results = @()
    $i = 0

    foreach ($item in $users) {
        $userMail = $item.Mail
        $i++
        
        if (![string]::IsNullOrWhiteSpace($userMail)) {
            try {
                $fullUser = Get-MgUser -Filter "mail eq '$userMail'" -Property DisplayName, Mail, UserPrincipalName, CreatedDateTime, LastPasswordChangeDateTime, AccountEnabled, UserType
                $results += [PSCustomObject]@{
                    Nome                    = $fullUser.DisplayName
                    Email                   = $fullUSer.Mail
                    UPN                     = $fullUser.UserPrincipalName
                    "Data de criação"       = $fullUser.CreatedDateTime
                    "Última troca de senha" = $fullUser.LastPasswordChangeDateTime
                    "Conta Ativa"           = $fullUser.AccountEnabled ? "Sim" : "Não"
                    "UserType"              = $fullUser.UserType
                }

                Write-Host "$($i): $($fullUser.Mail)" -ForegroundColor DarkGray
            }
            catch {
                Write-Host "❌ Erro ao buscar usuário com e-mail '$userMail': $_" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "⚠️ Usuário '$($user.DisplayName)' não possui e-mail válido. Ignorando." -ForegroundColor DarkYellow

        }
    } Write-Host "`nUsuários criados entre $startDateObj e $endDateObj`n" -ForeGroundColor Green

    return $results
}

$finalResult = Get-UsersWithCreationDate -users $newUsers
$finalResult | Sort-Object DisplayName | Format-Table -AutoSize


$end = Get-Date
$time = $end - $start
Write-Host "Tempo: $($time.Hours):$($time.Minutes):$($time.Seconds)"
