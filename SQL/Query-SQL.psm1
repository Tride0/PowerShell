Function Query-SQL {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 12/20/2019
            Version: 2021.02.25

        .DESCRIPTION
    #>

    [cmdletbinding(DefaultParameterSetname = 'UserName')]
    Param(
        [Parameter(Mandatory = $true)] [String]$Query,
        [String]$Server,
        [String]$DataBase,
        [Parameter(Mandatory = $False, ParameterSetName = 'UserName')]
        [Parameter(Mandatory = $True, ParameterSetName = 'Credentials')]
        [String] $UserName,
        [Parameter(ParameterSetName = 'Credentials')]
        $Password,
        [Parameter(ParameterSetName = 'PSCredential')]
        [PSCredential] $Credential,
        [String]$ConnectionString
    )
    Begin {
        If ([Boolean]$Password -or [Boolean]$UserName) {
            If (![Boolean]$UserName) {
                $UserName = Read-Host -Prompt 'Enter UserName'
            }

            If (![Boolean]$Password) {
                $Password = Read-Host -Prompt 'Enter Password' -AsSecureString
                $Password.MakeReadOnly()
                Clear-Host
            }
        }
        If ([Boolean]$Password -and $Password -is [string]) {
            $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $Password.MakeReadOnly()
        }
    }
    Process {
        # Open Connection to server
        $Connection = New-Object System.Data.SQLClient.SQLConnection
        If ([Bool]$Password -or [Bool]$UserName) {
            $Connection.Credential = New-Object System.Data.SqlClient.SqlCredential -ArgumentList ($UserName, $Password)
        }

        If ([Boolean]$ConnectionString) {
            $Connection.ConnectionString = $ConnectionString
        }
        Else {
            $Connection.ConnectionString = "server=$($Server);database=$($Database);MultipleActiveResultSets=True;Connection Timeout=120"
        }

        Try {
            $Connection.Open()
        }
        Catch {
            Write-Error -Message "Failed to open connection. Error: $_"
        }

        # Combine Query String and Connection
        $Command = New-Object System.Data.SQLClient.SQLCommand
        $Command.Connection = $Connection
        $Command.CommandText = $Query

        
        If ($Connection.State -ne 'Closed') {
            # Get data from Database
            $Reader = $Command.ExecuteReader()
        
            # Add data to a Datatable
            $Datatable = New-Object System.Data.DataTable
            $Datatable.Load($Reader)
            
            # Output Data
            Write-Output $Datatable
        }
        Else {
            Write-Host 'Connection is closed.' -ForegroundColor Red
        }
        
    }
    End {
        # Dispose of connection, password and variables
        $Connection.Close()
        $Password.Dispose()
        Remove-Variable UserName, Password, Query, Server, DataBase, Connection, Command, Reader, DataTable -ErrorAction SilentlyContinue
    }
}