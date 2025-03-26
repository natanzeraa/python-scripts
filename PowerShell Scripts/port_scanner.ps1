Param (
    [string]$ip,
    [string]$portRange,
    [string]$throttleLimit
)

$ports = $portRange -split '-' | ForEach-Object { [int]$_ }
$ports = $ports[0]..$ports[1]

$ports | ForEach-Object -Parallel {
    try {
        $connection = Test-NetConnection -ComputerName $using:ip -Port $_ -WarningAction SilentlyContinue
        if ($connection.TcpTestSucceeded) {
            Write-Host "SUCCESS: TCP connect to ($using:ip : $_) succeeded!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Port $_ is closed!" -ForegroundColor Red
    }
} -ThrottleLimit $throttleLimit