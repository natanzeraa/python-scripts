Clear-Host
Write-Host "`nIniciando coleta de caixas de e-mail..."

# Coleta inicial
$mailboxes = Get-Mailbox -ResultSize Unlimited
$mailboxCount = $mailboxes.Count

if ($mailboxCount -eq 0) {
    Write-Host "Nenhuma caixa de e-mail encontrada." -ForegroundColor Red
    exit
}

# Nome da organização
$orgName = (Get-OrganizationConfig).DisplayName
Write-Host "`nOrganização: $orgName"
Write-Host "`nTotal de caixas de e-mail: $mailboxCount" -ForegroundColor DarkGreen

# Entrada do usuário
[int]$topRankingCount = Read-Host "`nQuantas caixas de e-mail mais ocupadas você deseja visualizar no ranking"

# Função: exibe barra de progresso
function Show-Progress($current, $total) {
    Write-Progress -Activity "Coletando caixas de e-mail" `
        -Status "$current de $total processado(s)" `
        -PercentComplete (($current / $total) * 100)
}

# Função: coleta estatísticas das caixas e monta ranking
function Get-MailboxUsageReport {
    $results = @()
    $current = 0
    $errors = @()
    $startTime = Get-Date

    Write-Host "`nAguarde... coletando estatísticas..." -ForegroundColor DarkCyan

    foreach ($mailbox in $mailboxes) {
        $current++
        Show-Progress -current $current -total $mailboxCount

        try {
            $stats = Get-MailboxStatistics -Identity $mailbox.Guid -ErrorAction Stop

            if ($stats.TotalItemSize -and $stats.TotalItemSize.Value) {
                $rawSize = $stats.TotalItemSize.ToString()
                $bytes = if ($rawSize -match '\(([\d,]+)\sbytes\)') {
                    [int64]($matches[1] -replace ',', '')
                }
                else { 0 }

                $results += [PSCustomObject]@{
                    "#"            = $current
                    Name           = $mailbox.DisplayName
                    Email          = $mailbox.UserPrincipalName
                    Tamanho        = $stats.TotalItemSize
                    TamanhoEmBytes = $bytes
                    Emails         = $stats.ItemCount
                }
            }
            else {
                $errors += "$($mailbox.DisplayName) <$($mailbox.UserPrincipalName)>"
            }
        }
        catch {
            $errors += "$($mailbox.DisplayName) <$($mailbox.UserPrincipalName)>: $($_.Exception.Message)"
        }
    }

    Write-Progress -Activity "Coletando caixas de e-mail" -Completed

    # Resultados
    $topMailboxes = $results | Sort-Object -Property TamanhoEmBytes -Descending | Select-Object -First $topRankingCount

    Write-Host "`nTop $topRankingCount caixas de e-mail mais ocupadas:`n" -ForegroundColor Yellow
    $topMailboxes | Select-Object Name, Email, Tamanho, Emails | Format-Table -AutoSize

    # Exporta CSV
    $csvDir = Join-Path $PSScriptRoot "..\output"
    if (-not (Test-Path $csvDir)) { New-Item -Path $csvDir -ItemType Directory | Out-Null }
    $csvPath = Join-Path $csvDir "top_${topRankingCount}_caixas_de_email.csv"

    $topMailboxes | Select-Object Name, Email, Tamanho, Emails | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8

    Write-Host "`nResultado exportado para: $csvPath" -ForegroundColor Green

    # Duração
    $duration = (Get-Date) - $startTime
    Write-Host "`nDuração: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan

    # Exibe erros, se houver
    if ($errors.Count -gt 0) {
        Write-Host "`n[ERRO] Erros durante a coleta:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    }
}

# Execução principal
Get-MailboxUsageReport
