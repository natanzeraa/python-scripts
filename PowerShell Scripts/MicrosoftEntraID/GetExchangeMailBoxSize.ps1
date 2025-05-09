# - Acesse a documentação do script através do link abaixo 👇
# - https://github.com/natanzeraa/scripts-and-automation/blob/main/README/PowerShell/GetExchangeMailBoxSize.md

Clear-Host
Write-Host "`nIniciando coleta de caixas de e-mail..." -ForegroundColor Gray

# Obtém todas as caixas de e-mail do ambiente Exchange Online
$mailboxes = Get-Mailbox -ResultSize Unlimited
$mailboxesCount = $mailboxes.Count

# Encerra o script se nenhuma caixa for encontrada
if ($mailboxesCount -eq 0) {
    Write-Host "Nenhuma caixa de e-mail encontrada." -ForegroundColor Red
    exit
}

# Exibe o nome da organização e total de caixas encontradas
$orgName = (Get-OrganizationConfig).DisplayName
Write-Host "`nOrganização: $orgName" -ForegroundColor Gray
Write-Host "`nTotal de caixas de e-mail: $mailboxesCount" -ForegroundColor Gray

# Solicita ao usuário o número de caixas mais ocupadas a serem exibidas no ranking
[int]$topRankingCount = Read-Host "`nQuantas caixas de e-mail mais ocupadas você deseja visualizar no ranking"

# Função: exibe a barra de progresso durante a coleta de dados
function Show-Progress($current, $total) {
    Write-Progress -Activity "Coletando caixas de e-mail" `
        -Status "$current de $total processado(s)" `
        -PercentComplete (($current / $total) * 100)
}

# Função: calcula e exibe o uso total de armazenamento de todas as caixas de e-mail
function Measure-AllMailboxesSize {
    param (
        [Parameter(Mandatory)]
        $mailboxesData
    )

    $totalBytes = ($mailboxesData | Measure-Object -Property TamanhoEmBytes -Sum).Sum
    $totalGB = [math]::Round($totalBytes / 1GB, 2)
    $totalTB = [math]::Round($totalBytes / 1TB, 2)

    Write-Host "`nUso total de todas as $mailboxesCount caixas de e-mail: $totalBytes bytes (~$totalGB GB) (~$totalTB TB)" -ForegroundColor DarkYellow
}

# Função: calcula e exibe o uso total das maiores caixas de e-mail (ranking)
function Measure-RankedMailboxesSize {
    param (
        [Parameter(Mandatory)]
        $mailboxesData,

        [Parameter(Mandatory)]
        [int]$rankingCount
    )

    $totalBytes = ($mailboxesData | Measure-Object -Property TamanhoEmBytes -Sum).Sum
    $totalGB = [math]::Round($totalBytes / 1GB, 2)
    $totalTB = [math]::Round($totalBytes / 1TB, 2)

    Write-Host "`nUso total das $rankingCount maiores caixas de e-mail: $totalBytes bytes (~$totalGB GB) (~$totalTB TB)" -ForegroundColor DarkYellow
}

# Função: calcula e exibe o tamanho médio das caixas de e-mail
function Measure-MailboxesSizeMean {
    param (
        [Parameter(Mandatory)]
        $mailboxesData,

        [Parameter(Mandatory)]
        $totalMailboxesCount
    )

    $totalBytes = ($mailboxesData | Measure-Object -Property TamanhoEmBytes -Sum).Sum
    $mailboxesMedian = ($totalBytes / $totalMailboxesCount)
    $totalGB = [math]::Round($mailboxesMedian / 1GB, 2)
    $totalTB = [math]::Round($mailboxesMedian / 1TB, 4)

    Write-Host "`nUso médio das caixas de email $mailboxesMedian bytes (~$totalGB GB) (~$totalTB TB)" -ForegroundColor DarkYellow
}

# Função principal: coleta estatísticas de uso das caixas, exibe ranking e salva resultados
function Get-MailboxUsageReport {
    $results = @()
    $current = 0
    $errors = @()
    $startTime = Get-Date

    Write-Host "`nAguarde... coletando estatísticas...`n"

    # Loop para coletar estatísticas de cada caixa de e-mail
    foreach ($mailbox in $mailboxes) {
        $current++
        Show-Progress -current $current -total $mailboxesCount

        try {
            $stats = Get-MailboxStatistics -Identity $mailbox.Guid -ErrorAction Stop

            # Verifica se o tamanho da caixa está disponível
            if ($stats.TotalItemSize -and $stats.TotalItemSize.Value) {
                $rawSize = $stats.TotalItemSize.ToString()

                # Extrai o tamanho em bytes usando regex
                $bytes = if ($rawSize -match '\(([\d,]+)\sbytes\)') {
                    [int64]($matches[1] -replace ',', '')
                }
                else { 0 }

                # Armazena os dados da caixa de e-mail
                $results += [PSCustomObject]@{
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

    # Ordena e seleciona as caixas mais ocupadas
    $topMailboxes = $results | Sort-Object -Property TamanhoEmBytes -Descending | Select-Object -First $topRankingCount

    Write-Host "`nTop $topRankingCount caixas de e-mail mais ocupadas:`n" -ForegroundColor Yellow
    $topMailboxes | Select-Object Name, Email, Tamanho, Emails | Format-Table -AutoSize

    # Exibe estatísticas detalhadas
    Measure-RankedMailboxesSize -mailboxesData $topMailboxes -rankingCount $topRankingCount
    Measure-AllMailboxesSize -mailboxesData $results
    Measure-MailboxesSizeMean -mailboxesData $results -totalMailboxesCount $mailboxesCount

    # Define o caminho do diretório e arquivo CSV
    $csvDir = Join-Path $PSScriptRoot "..\output"
    if (-not (Test-Path $csvDir)) {
        New-Item -Path $csvDir -ItemType Directory | Out-Null
    }

    $csvPath = Join-Path $csvDir "top_${topRankingCount}_caixas_de_email.csv"

    # Exporta os dados do ranking para um arquivo CSV
    $topMailboxes | Select-Object Name, Email, Tamanho, Emails | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8
    Write-Host "`nResultado exportado para: $csvPath" -ForegroundColor Green

    # Exibe tempo de execução do script
    $duration = (Get-Date) - $startTime
    Write-Host "`nDuração: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s`n" -ForegroundColor DarkCyan

    # Se houver falhas, exibe os erros encontrados
    if ($errors.Count -gt 0) {
        Write-Host "`n[ERRO] Erros durante a coleta:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    }
}

# Execução principal do script
Get-MailboxUsageReport
