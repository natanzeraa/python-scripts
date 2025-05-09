# - Use o comando abaixo como exemplo para rodar suas consultas com a base SQL:
# - Connect-To-SQLServer -server "localhost" -database "Teste" -user "sa" -pass "12345" -query "SELECT Nome, Email FROM Usuarios"

function Connect-To-SQLServer {
    param (
        [Parameter(Mandatory)]
        $server,

        [Parameter(Mandatory)]
        $database,

        [Parameter(Mandatory)]
        $user,

        [Parameter(Mandatory)]
        $pass,

        $query
    )

    # String de conexão
    $connectionString = "Server=$server;Database=$database;User Id=$user;Password=$pass;"

    # Criar conexão e comando
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString

    $command = $connection.CreateCommand()

    if ($query) {
        $command.CommandText = $query
    }

    # Abrir conexão e executar
    $connection.Open()
    $reader = $command.ExecuteReader()

    # Ler resultados
    while ($reader.Read()) {
        $row = @{}
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $columnName = $reader.GetName($i)
            $columnValue = $reader.GetValue($i)
            $row[$columnName] = $columnValue
        }
        Write-Output (New-Object PSObject -Property $row)
    }

    # Fechar conexão
    $reader.Close()
    $connection.Close()

    # Invoke-Sqlcmd -ServerInstance "Servidor\Instancia" -Database "NomeDoBanco" -Username "usuario" -Password "senha" -Query "SELECT * FROM Tabela"
}