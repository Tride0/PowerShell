Function Get-DeadDCDNSSrvRecords {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            AD_Objects_Computer_Password_Dont_Expire
        
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN,
        $DNSServer
    )
    Begin {
        Import-Module -Name DnsServer -ErrorAction Stop
        If (![Boolean]$DNSServer) {
            $DNSServer = (nslookup -type=ns $Domain) | 
                Where-Object -FilterScript { $_ -like '* = *' } |
                ForEach-Object -Process { 
                    If ($_ -like '*nameserver*' -or $_ -like '*primary*') {
                        $ns = $_.Split('=')[1]    
                    }
                    Elseif ($_ -like '*internet address*') {
                        $ns = $_.Split(' ')[0]
                    }
                    If ([boolean]$ns) {
                        $ns.split('.')[0].Trim()
                    }
                    Remove-Variable ns -ErrorAction SilentlyContinue 
                } |
                Get-Random
        }
    }
    Process {
        Get-DnsServerResourceRecord -RRType Srv -ZoneName $Domain -ComputerName $DNSServer |
            Where-Object -FilterScript { 
                # Filter out just gc, kerberos and ldap SRV records
            ($_.HostName -like '_gc*' -or $_.HostName -like '_Kerberos*' -or $_.HostName -like '_ldap*') -and 
                # Removes root records from being checked
                $_.HostName -ne "_ldap._tcp.$Domain" -and $_.HostName -ne '_kerberos._tcp' } |
            ForEach-Object -Process {
                $CompName = $_.RecordData.DomainName.split('.')[0].ToLower().Trim()
                Try { $DCCheck = Get-ADDomainController -Identity $CompName -Server $Domain -ErrorAction Stop } Catch { }
                Try { $ADCompObject = Get-ADComputer -Identity $CompName -Server $Domain -ErrorAction Stop } Catch { }
                $PingCheck = Test-Connection -ComputerName $CompName -Quiet -Count 1 -ErrorAction SilentlyContinue

                If (![Boolean]$DCCheck -or !$PingCheck) {
                    [PSCustomObject]@{
                        DNS_Record_DomainName = $_.RecordData.DomainName
                        DNS_Record_DN         = $_.DistinguishedName
                        DNS_Record_HostName   = $_.HostName
                        DCObject              = $False
                        ADComputerObject      = $ADCompObject.DistinguishedName
                        Ping                  = $PingCheck
                    }
                }
                Remove-Variable CompName, DCCheck, ADCompObject, PingCheck -ErrorAction SilentlyContinue
            } | 
            Sort-Object -Property DNS_Record_DN -Unique
    }
}