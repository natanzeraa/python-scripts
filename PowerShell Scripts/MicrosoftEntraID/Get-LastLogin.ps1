function Show-LoginProgress {
    param (
        [Parameter(Mandatory)]
        $curr,
        [Parameter(Mandatory)]
        $total
    )

    Write-Progress -Activity "Buscando logins mais recentes..." `
        -Status "Aguarde: $curr de $total ($([Math]::Round(($curr / $total) * 100))%)" `
        -PercentComplete (($curr / $total) * 100)
}

function Get-RecentLogins {
    param (
        [Parameter(Mandatory)]
        [int]$rankingCount
    )

    $logins = Get-MgAuditLogSignIn -Top $rankingCount

    $results = @()
    $errors = @()
    $i = 0
    $loginCount = $logins.Count

    foreach ($login in $logins) {
        $i++
        Show-LoginProgress -curr $i -total $loginCount

        try {
            $results += [PSCustomObject]@{
                UserDisplayName     = $login.UserDisplayName
                UserPrincipalName   = $login.UserPrincipalName
                CreatedDateTime     = $login.CreatedDateTime.ToLocalTime()
                Status              = $login.Status.ErrorCode -eq 0  ? "✅ Sucesso" : "❌ Erro ($($login.Status.ErrorCode))"
                ResourceDisplayName = $login.ResourceDisplayName
                IPAddress           = $login.IPAddress
            }
        }
        catch {
            $errors += "$($login.UserDisplayName) <$($login.UserPrincipalName)>: $($_.Exception.Message)"
        }
    }

    return $results
}

function Main {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              🪟 Microsoft Entra ID - Últimos Logins                ║" -ForegroundColor Cyan
    Write-Host "║--------------------------------------------------------------      ║" -ForegroundColor Cyan
    Write-Host "║ Autor      : Natan Felipe de Oliveira                              ║" -ForegroundColor Cyan
    Write-Host "║ Descrição  : Mostra os últimos logins indicando o serviço acessado ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "🔄 Conectando ao Microsoft Entra ID..."
    Connect-MgGraph -Scopes "AuditLog.Read.All"  -NoWelcome
    Write-Host "✅ Conectado com sucesso!`n"

    [int]$rankingCount = Read-Host "Quantos resultados deseja visualizar no ranking"

    if (-not $rankingCount -or $rankingCount -lt 1) {
        Write-Host "❌ Insira um valor maior que 0!" -ForegroundColor Red
        exit 1
    }

    $loginResults = Get-RecentLogins -rankingCount $rankingCount

    $rankedOutput = $loginResults | Select-Object -First $rankingCount | ForEach-Object -Begin { $i = 1 } -Process {
        [PSCustomObject]@{
            Rank           = $i
            "Nome"         = $_.UserDisplayName
            "UPN"          = $_.UserPrincipalName
            "Último login" = $_.CreatedDateTime
            "Status"       = $_.Status
            "App usado"    = $_.ResourceDisplayName
            "IP"           = $_.IPAddress
        }
        $i++
    }

    $rankedOutput | Format-Table -AutoSize
}

try {
    Main
}
catch {
    Write-Host "❌ Ocorreu um erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
