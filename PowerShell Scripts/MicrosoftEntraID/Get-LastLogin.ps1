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
                ErrorCode           = $login.Status.ErrorCode
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

function AuditLoginWithErrors {
    param(
        [Parameter(Mandatory)]
        $login
    )

    $MSEntraIStatusCodes = @(
        [PSCustomObject]@{ ErrorCode = 50053; Title = "Conta bloqueada"; Description = "Conta temporariamente bloqueada após várias tentativas falhas" },
        [PSCustomObject]@{ ErrorCode = 50055; Title = "Senha expirada"; Description = "Usuário precisa alterar a senha" },
        [PSCustomObject]@{ ErrorCode = 50056; Title = "Nenhuma credencial fornecida"; Description = "Senha ou autenticação não foi informada" },
        [PSCustomObject]@{ ErrorCode = 50057; Title = "Conta desabilitada"; Description = "Conta de usuário desativada no Azure AD" },
        [PSCustomObject]@{ ErrorCode = 50058; Title = "Sessão inválida"; Description = "Token inválido, geralmente após logout" },
        [PSCustomObject]@{ ErrorCode = 50074; Title = "Falha no desafio de MFA"; Description = "MFA solicitado, mas o usuário não passou" },
        [PSCustomObject]@{ ErrorCode = 50076; Title = "MFA exigido"; Description = "MFA necessário, mas não concluído" },
        [PSCustomObject]@{ ErrorCode = 50126; Title = "Credenciais inválidas"; Description = "Senha incorreta ou usuário não existe" },
        [PSCustomObject]@{ ErrorCode = 50140; Title = "Reautenticação necessária"; Description = "Sessão expirou ou precisa reautenticar" },
        [PSCustomObject]@{ ErrorCode = 50144; Title = "Dispositivo não registrado"; Description = "O dispositivo do usuário não é confiável ou registrado" },
        [PSCustomObject]@{ ErrorCode = 70043; Title = "Sessão interrompida"; Description = "Pode ocorrer por falha de token ou logout forçado" },
        [PSCustomObject]@{ ErrorCode = 70044; Title = "Conta bloqueada por política de identidade"; Description = "Bloqueio por risco, senha comprometida ou política condicional" },
        [PSCustomObject]@{ ErrorCode = 70049; Title = "Dispositivo não em conformidade"; Description = "Dispositivo fora das regras de conformidade do Intune" },
        [PSCustomObject]@{ ErrorCode = 70016; Title = "Cliente não suportado"; Description = "Tentativa de login via cliente ou app bloqueado pelas políticas" },
        [PSCustomObject]@{ ErrorCode = 81010; Title = "Conta bloqueada pelo Identity Protection"; Description = "Login suspeito ou risco identificado pelo Microsoft Entra" },
        [PSCustomObject]@{ ErrorCode = 53003; Title = "Bloqueado por política condicional"; Description = "Acesso bloqueado por regras de localização, grupo, dispositivo, etc" }
    )

    $matched = $MSEntraIStatusCodes | Where-Object { $_.ErrorCode -eq $login.ErrorCode }

    if ($matched) {
        Write-Host "❌ $($login.UserDisplayName) <$($login.UserPrincipalName)> tentou acessar '$($login.ResourceDisplayName)' em $($login.CreatedDateTime) a partir do IP $($login.IPAddress) — Resultado: $($login.Status) ($($login.StatusCode) - $($matched.Title): $($matched.Description))"
    }
    else {
        Write-Host "❌ $($login.UserDisplayName) <$($login.UserPrincipalName)> tentou acessar '$($login.ResourceDisplayName)' em $($login.CreatedDateTime) a partir do IP $($login.IPAddress) — Resultado: $($login.Status) ($($login.StatusCode) - Código desconhecido)"
    }
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
    
    foreach ($result in $loginResults) {
        if ($result.ErrorCode -ne 0) {
            AuditLoginWithErrors -login $result
        }
    }
}

try {
    Main
}
catch {
    Write-Host "❌ Ocorreu um erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
