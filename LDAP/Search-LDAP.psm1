Function Search-LDAP {
    Param(
        [String]$ServerName,
        [String]$BaseDN,
        [String]$LoginUserName,
        [String]$LoginPassword,
        [Int]$NoSSLPort = 389,
        [Int]$SSLPort = 636,
        [Boolean]$ActivateSSL = $True,
        [Boolean]$LDAPAuth = $True,
        [String]$SearchFilter,
        [String[]]$AttributeList,
        [System.DirectoryServices.Protocols.SearchScope]$SearchScope = 'Subtree'
    )
    Begin {
        [Void][System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.Protocols")

        function ConvertFrom-ASCII {
            param($ASCII)
            $letters = @()
            foreach ($char in $ascii){
                $char = [int[]]$char
                $letters += [char[]]$char
            }
            $Output = ("$letters").Replace(" ","")
            Return $Output
        }

        If ($ActivateSSL) { $Port = $SSLPort } 
        Else { $Port = $NoSSLPort }
    }
    Process {
        $c = New-Object System.DirectoryServices.Protocols.LdapConnection ("$ServerName"+":"+"$Port") 

        # SSL Connection or not
        If ($ActivateSSL) {
            $c.SessionOptions.SecureSocketLayer = $true
            $c.SessionOptions.VerifyServerCertificate = { $True }
        } 
        Else { $c.SessionOptions.SecureSocketLayer = $False }
        $c.SessionOptions.ProtocolVersion = 3

        # Authenticated Connection or not (Anonymous)
        If ($LDAP_Auth) {
            $c.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic
            $Credentials = new-object "System.Net.NetworkCredential" -ArgumentList $LoginUserName,$LoginPassword 
        }
        Else {
            $c.AuthType = [System.DirectoryServices.Protocols.AuthType]::Anonymous
            $Credentials = $null
        }

        # Try to connect
        Try { 
            If ($Credentials -eq $null) { $c.Bind() }
            Else { $c.Bind($Credentials) } 
            Write-Verbose "Connection Successful"
        }
        Catch {
            Throw "Problem during connection - $($_.Exception.Message)"
        }

        $ModelQuery = New-Object System.DirectoryServices.Protocols.SearchRequest -ArgumentList $BaseDN,$SearchFilter,$SearchScope,$AttributeList

        Try {
            $ModelRequest = $c.SendRequest($ModelQuery)
        }
        Catch {
            Throw "Error during request. Error: $($_.Exception.Message)"
        }

        Return $ModelRequest 
    }
    End {
        $c.Dispose()
        Remove-Variable Credentials, ModelQuery, ModelRequest, c -ErrorAction SilentlyContinue
        [gc]::Collect()
    }
}