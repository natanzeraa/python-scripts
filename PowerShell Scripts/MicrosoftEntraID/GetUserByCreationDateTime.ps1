Clear-Host
Write-Host "`n🪟 Microsoft Entra ID - Filtro por Data de Criação de Usuário"
Write-Host "--------------------------------------------------------------"
Write-Host "Este script filtra usuários do Entra ID com base no intervalo de datas da criação da conta.`n"

Write-Host "🔄 Conectando ao Microsoft Entra ID..."
Connect-MgGraph -Scopes "User.Read.All"
Write-Host "✅ Conectado com sucesso!`n"

$start = Get-Date

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

function Show-Progress($current, $total) {
    Write-Progress -Activity "Buscando usuários" `
        -Status "$current de $total processado(s) ($([math]::Round(($current / $total) * 100))%)" `
        -PercentComplete (($current / $total) * 100)
}

$startDateObj = Get-ValidDate "📅 Insira a data de início (dd-MM-yyyy)"

$endDateObj = Get-ValidDate "📅 Insira a data final (dd-MM-yyyy)"

$startDate = $startDateObj.ToString("yyyy-MM-ddTHH:mm:ssZ")

$endDate = $endDateObj.ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Host "`n🔍 Buscando usuários criados entre: $startDateObj e $endDateObj`n"

$filter = "createdDateTime ge $startDate and createdDateTime le $endDate"

$newUsers = Get-MgUser -Filter $filter -All

$newUsersCount = $newUsers.Count

function Get-UsersWithCreationDate($users) {
    $results = @()
    $i = 0
    
    foreach ($item in $users) {
        $userMail = $item.Mail
        $i++
        
        Show-Progress -current $i -total $newUsersCount
        
        if (![string]::IsNullOrWhiteSpace($userMail)) {
            try {
                $fullUser = Get-MgUser -Filter "mail eq '$userMail'" -Property DisplayName, Mail, UserPrincipalName, CreatedDateTime, LastPasswordChangeDateTime, AccountEnabled, UserType
                $results += [PSCustomObject]@{
                    Name                       = $fullUser.DisplayName
                    Mail                       = $fullUSer.Mail
                    UPN                        = $fullUser.UserPrincipalName
                    CreatedDateTime            = $fullUser.CreatedDateTime
                    LastPasswordChangeDateTime = $fullUser.LastPasswordChangeDateTime
                    AccountEnabled             = $fullUser.AccountEnabled ? "Sim" : "Não"
                    UserType                   = if ($fullUser.UserType -eq "Guest") { "Convidado" } else { "Membro" }
                }
            }
            catch {
                Write-Host "❌ Erro ao buscar usuário com e-mail '$userMail': $_" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "⚠️ Usuário '$($user.DisplayName)' não possui e-mail válido. Ignorando." -ForegroundColor DarkYellow

        }
    } Write-Host "`nUsuários criados/convidados entre $startDateObj e $endDateObj`n" -ForeGroundColor Green

    return $results
}

$outputObj = Get-UsersWithCreationDate -users $newUsers

$table = $outputObj | ForEach-Object -Begin { $i = 1 } -Process {
    [PSCustomObject]@{
        "#"               = $i
        "Nome"            = $_.Name
        "Email"           = $_.Mail
        "UPN"             = $_.UPN
        "Data de criação" = $_.CreatedDateTime
        "Senha alterada"  = $_.LastPasswordChangeDateTime
        "Conta ativa"     = $_.AccountEnabled
        "Tipo do usuário" = $_.UserType
    }
    $i++
}

$table | Format-Table -AutoSize

$end = Get-Date

$time = $end - $start

Write-Host "Tempo: $($time.Hours):$($time.Minutes):$($time.Seconds)"
