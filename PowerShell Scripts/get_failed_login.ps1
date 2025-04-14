<#
.SYNOPSIS
    Script to retrieve Windows Security Event Log entries for failed login attempts (Event ID 4625) within a specific time range.

.DESCRIPTION
    This script uses Get-WinEvent with filtering parameters to retrieve all failed login attempts
    (Event ID 4625) from the Security log between the provided start and end dates.
    The output includes the timestamp and the full message for each event.

.PARAMETER startDate
    The start of the time range to search for failed login attempts.
    
.PARAMETER endDate
    The end of the time range to search for failed login attempts.

.EXAMPLE
    .\get_failed_login.ps1 -startDate "2025-03-25 00:00:00" -endDate "2025-04-14 15:59:59"

.NOTES
    Author: Seu Nome
    Date: 2025-04-14
#>

Param (
    [datetime]$startDate,
    [datetime]$endDate
)

Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    Id        = 4625
    StartTime = $startDate
    EndTime   = $endDate
} | ForEach-Object {
    $xml = [xml]$_.ToXml()
    [PSCustomObject]@{
        TimeCreated      = $_.TimeCreated
        TargetUserName   = $xml.Event.EventData.Data | Where-Object Name -eq 'TargetUserName' | Select-Object -ExpandProperty '#text'
        TargetDomainName = $xml.Event.EventData.Data | Where-Object Name -eq 'TargetDomainName' | Select-Object -ExpandProperty '#text'
        WorkstationName  = $xml.Event.EventData.Data | Where-Object Name -eq 'WorkstationName' | Select-Object -ExpandProperty '#text'
        IpAddress        = $xml.Event.EventData.Data | Where-Object Name -eq 'IpAddress' | Select-Object -ExpandProperty '#text'
        FailureReason    = $xml.Event.EventData.Data | Where-Object Name -eq 'FailureReason' | Select-Object -ExpandProperty '#text'
        Status           = $xml.Event.EventData.Data | Where-Object Name -eq 'Status' | Select-Object -ExpandProperty '#text'
        LogonType        = $xml.Event.EventData.Data | Where-Object Name -eq 'LogonType' | Select-Object -ExpandProperty '#text'
    }
} | Format-Table -AutoSize
# Caso queira exportar o resultado para um arquivo CSV, comente a linha acima e adicione a seguinte:
# } | Export-Csv -Path ".\output\failed_logins.csv" -NoTypeInformation -Encoding UTF8
