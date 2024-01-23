Function Modify-LDAP {
    [CmdletBinding()]        
    Param(
        [String]$ServerName = $env:USERDNSDOMAIN,
        [String]$BaseDN = "DC=$($env:USERDNSDOMAIN.split('.') -join ',DC=')",
        [ValidateSet('Anonymous', 'Basic', 'Negotiate', 'Ntlm', 'Digest', 'Sicily', 'Dpa', 'Msn', 'External', 'Kerberos')]
        [String]$AuthType = 'Kerberos',
        [String]$LoginUserName,
        [String]$LoginPassword,
        [ValidateSet(389, 636)]
        [int]$Port = 389,
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [String]$DistinguishedName,
        [Parameter(ParameterSetName = 'Add', ValueFromPipelineByPropertyName = $True)]
        [HashTable]$Add,
        [Parameter(ParameterSetName = 'Delete', ValueFromPipelineByPropertyName = $True)]
        [HashTable]$Delete,
        [Parameter(ParameterSetName = 'Replace', ValueFromPipelineByPropertyName = $True)]
        [HashTable]$Replace,
        [Parameter(ParameterSetName = 'Clear', ValueFromPipelineByPropertyName = $True)]
        [String[]]$Clear
    )
    Begin {
        [Void][System.Reflection.Assembly]::LoadWithPartialName('System.DirectoryServices.Protocols')
    }
    Process {
        $LDAPConnection = New-Object System.DirectoryServices.Protocols.LdapConnection ("$ServerName" + ':' + "$Port") 
        $LDAPConnection.SessionOptions.ProtocolVersion = 3

        # SSL Connection or not
        If ($Port -eq 636) {
            $LDAPConnection.SessionOptions.SecureSocketLayer = $true
            $LDAPConnection.SessionOptions.VerifyServerCertificate = { $True }
        } 
        Else { $LDAPConnection.SessionOptions.SecureSocketLayer = $False }
            
        # Authenticated Connection or not (Anonymous)
        If ([Boolean]$LoginUserName -and [Boolean]$LoginPassword) {
            $Credentials = New-Object 'System.Net.NetworkCredential' -ArgumentList $LoginUserName, $LoginPassword 
        }
        Else {
            $Credentials = $null
        }

        #Authentication Type
        If ([Boolean]$Credentials) {
            $LDAPConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Basic
        }
        ElseIf ([Boolean]$AuthType) {
            $LDAPConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::$AuthType
        }
        Else {
            $LDAPConnection.AuthType = [System.DirectoryServices.Protocols.AuthType]::Anonymous
        }

        # Try to connect
        Try { 
            If ($Credentials -eq $null) { $LDAPConnection.Bind() }
            Else { $LDAPConnection.Bind($Credentials) } 
            Write-Verbose 'LDAP Connection Successful'
        }
        Catch {
            Return (Write-Error "Problem while making connection - $($_.Exception.Message)")
        }
        
        $ModifyRequest = New-Object 'System.DirectoryServices.Protocols.ModifyRequest'
        $ModifyRequest.DistinguishedName = $DistinguishedName


        Foreach ($Attr in $Clear) {
            $AttributeModification = New-Object 'System.DirectoryServices.Protocols.DirectoryAttributeModification'
            $AttributeModification.Name = $Attr
            $AttributeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::Replace
            $ModifyRequest.Modifications.Add($AttributeModification) | Out-Null
        }


        $HashNames = 'Delete', 'Replace', 'Add'
        Foreach ($HashName in $HashNames) {
            $Hash = Get-Variable $HashName -ValueOnly
            Foreach ($Attribute in $Hash.keys) {
                Foreach ($Value in $Hash.$Attribute) {
                    $AttributeModification = New-Object 'System.DirectoryServices.Protocols.DirectoryAttributeModification'
                    $AttributeModification.Name = $Attribute
                    $AttributeModification.Operation = [System.DirectoryServices.Protocols.DirectoryAttributeOperation]::$HashName
                    $AttributeModification.Add($Value) | Out-Null
                    $ModifyRequest.Modifications.Add($AttributeModification) | Out-Null
                }
            }
        }

        $ModifyResults = $LDAPConnection.SendRequest($ModifyRequest)
        Return $ModifyResults
    }
    End {
        $LDAPConnection.Dispose()
        Remove-Variable Credentials, ModelQuery, ModelRequest, c -ErrorAction SilentlyContinue -Verbose:$False -WhatIf:$False
        [gc]::Collect()
    }
} # End Function Modify-LDAP