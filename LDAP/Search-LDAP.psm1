Function Search-LDAP {
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
        [String]$SearchFilter,
        [String[]]$AttributeList,
        [int]$SizeLimit = 0,
        [String]$SearchScope = 'Subtree',
        [Switch]$ExpandAttributes
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

        # Bind to Server
        Try { 
            If ($Credentials -eq $null) { $LDAPConnection.Bind() }
            Else { $LDAPConnection.Bind($Credentials) } 
            Write-Verbose 'Connection Successful'
        }
        Catch {
            Write-Error "Problem while making connection - $($_.Exception.Message)"
            Remove-Variable ModelRequest -ErrorAction SilentlyContinue -Verbose:$False -WhatIf:$False
        }
            
        $SearchRequest = New-Object System.DirectoryServices.Protocols.SearchRequest -ArgumentList $BaseDN, $SearchFilter, $SearchScope, $AttributeList
        $SearchRequest.SizeLimit = $SizeLimit

        Try {
            $SendRequest = $LDAPConnection.SendRequest($SearchRequest)
        }
        Catch {
            Write-Error "Error while sending request. Error: $($_.Exception.Message)"
            Remove-Variable SendRequest, SearchRequest -ErrorAction SilentlyContinue -Verbose:$False -WhatIf:$False
        }
     
        $LDAPConnection.Dispose()
        Remove-Variable SearchRequest, Credentials, c -ErrorAction SilentlyContinue -Verbose:$False -WhatIf:$False

        Try {
            $ReturnedRequest = $SendRequest
        }
        Catch {
            Return (Write-Error $_)
        }

        If ($ExpandAttributes.IsPresent) {
            $ReturnValues = @()
            Foreach ($Entry in $ReturnedRequest.Entries) {
                $EntryHash = [System.Collections.Specialized.OrderedDictionary]@{}
                $EntryHash.DistinguishedName = $Entry.Entries.DistinguishedName

                $Entry.Attributes.GetEnumerator() | ForEach-Object -Process {
                    If ([Boolean]$_.Value) {
                        If ($_.Value.Count -gt 1) {
                            $EntryHash.($_.Name) = @()
                            For ($i = 0; $i -lt $_.Value.Count; $i++) { 
                                $EntryHash.($_.Name) += $_.Value[$i]
                            }
                        }
                        Else {
                            $EntryHash.($_.Name) = $_.Value[0]
                        }
                    }
                    Else {
                        $EntryHash.($_.Name) = $_.Value
                    }
                }

                $ReturnValues += [PSCustomObject]$EntryHash
            }
            Return $ReturnValues
        }
        Else {
            Return $ReturnedRequest
        }
    }
    End {
        Remove-Variable Credentials, ModelQuery, ModelRequest, c -ErrorAction SilentlyContinue -Verbose:$False -WhatIf:$False
    }
}  # End Function Search-LDAP