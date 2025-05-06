# ****************************************************************************************************************************************************************************
# Rode esse script se quiser uma saída mais rápida no terminal                                                                                                               *
# Get-Mailbox -ResultSize Unlimited | Get-MailboxStatistics | Sort-Object TotalItemSize -Descending | Select-Object DisplayName, TotalItemSize -First $topMailBoxRankingInt  *
# ****************************************************************************************************************************************************************************

$topMailBoxRanking = Read-Host "Quantas caixas de email deseja visualizar"
$topMailBoxRankingInt = [int]$topMailBoxRanking

function Get-ExchangeMailBoxSize($topMailBoxRanking) {
    $start = Get-Date

    Write-Host "`nIniciando a coleta das caixas de e-mail..." -ForegroundColor Cyan

    $result = @()
    $i = 0
    
    Try {
        Get-Mailbox -ResultSize Unlimited | ForEach-Object {
            $mailbox = $_
            $i++
    
            Try {
                $stats = Get-MailboxStatistics -Identity $mailbox.Guid
    
                if ($stats -and $stats.TotalItemSize -and $stats.TotalItemSize.Value) {
                    Write-Host "$($i): $($mailbox.DisplayName) | $($stats.TotalItemSize) | <$($mailbox.UserPrincipalName)>" -ForegroundColor DarkCyan

                    $rawSize = $stats.TotalItemSize.ToString()
                    if ($rawSize -match '\(([\d,]+)\sbytes\)') {
                        $bytes = [int64]($matches[1] -replace ',', '')
                    }

    
                    $output = [PSCustomObject]@{
                        "#"            = $i 
                        Name           = $mailbox.DisplayName
                        Email          = $mailbox.UserPrincipalName
                        Tamanho        = $stats.TotalItemSize
                        TamanhoEmBytes = $bytes
                        Emails         = $stats.ItemCount
                    }
    
                    $result += $output
                }
                else {
                    Write-Host "Erro de tamanho: $($mailbox.DisplayName) <$($mailbox.UserPrincipalName)>" -ForegroundColor Red
                }
            }
            Catch {
                Write-Host "Erro ao obter estatísticas de $($mailbox.DisplayName) <$($mailbox.UserPrincipalName)>: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    Catch {
        Write-Host "Erro geral durante a execução: $($_.Exception.Message)" -ForegroundColor Red
    }
    

    $topMailBoxes = $result | Sort-Object -Property TamanhoEmBytes -Descending | Select-Object -First $topMailBoxRankingInt
    Write-Host "`nTop $topMailBoxRankingInt caixas de email:`n" -ForegroundColor Yellow
    $topMailBoxes | Select-Object Name, Email, Tamanho, Emails | Format-Table -AutoSize

    $csvPath = "..\output\top_${topMailBoxRankingInt}_caixas_de_email.csv"
    $topMailBoxes | Select-Object Name, Email, Tamanho, Emails | Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8

    $end = Get-Date
    $duration = $end - $start
    Write-Host "Tempo: $($duration.Hours)h $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Cyan

}

Get-ExchangeMailBoxSize