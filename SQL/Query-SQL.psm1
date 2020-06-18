$PSScriptRoot
Function Query-SQL {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 12/20/2019
            Version: 2019.12.20

        .DESCRIPTION
    #>

    [cmdletbinding(DefaultParameterSetname = 'UserName')]
    Param(
        [Parameter(Mandatory = $true)] [String]$Query,
        [Parameter(Mandatory = $true)] [String]$Server,
        [Parameter(Mandatory = $true)] [String]$DataBase,
        [Parameter(Mandatory = $False, ParameterSetName = 'UserName')]
        [Parameter(Mandatory = $True, ParameterSetName = 'Credentials')]
        [String] $UserName,
        [Parameter(ParameterSetName = 'Credentials')]
        [securestring] $Password,
        [Parameter(ParameterSetName = 'PSCredential')]
        [PSCredential] $Credential
    )
    Begin {
        If ([Boolean]$Password -or [Boolean]$UserName) {
            If (![Boolean]$UserName) {
                $UserName = Read-Host -Prompt 'Enter UserName'
            }

            If (![Boolean]$Password) {
                $Password = Read-Host -Prompt 'Enter Password' -AsSecureString
                Clear-Host
            }
            $Password.MakeReadOnly()
        }
    }
    Process {
        # Open Connection to server
        $Connection = New-Object System.Data.SQLClient.SQLConnection
        If ([Bool]$Password -or [Bool]$UserName) {
            $Connection.Credential = [System.Data.SqlClient.SqlCredential]::new($UserName, $Password)
        }
        $Connection.ConnectionString = "server=$($Server);database=$($Database);trusted_connection=false;"
        $Connection.Open()

        # Combine Query String and Connection
        $Command = New-Object System.Data.SQLClient.SQLCommand
        $Command.Connection = $Connection
        $Command.CommandText = $Query

        # Get data from Database
        $Reader = $Command.ExecuteReader()

        # Add data to a Datatable
        $Datatable = New-Object System.Data.DataTable
        $Datatable.Load($Reader)

        # Output Data
        write-Output $Datatable
    }
    End {
        # Dispose of connection, password and variables
        $Connection.Close()
        $Password.Dispose()
        Remove-Variable UserName, Password, Query, Server, DataBase, Connection, Command, Reader, DataTable -ErrorAction SilentlyContinue
    }
}