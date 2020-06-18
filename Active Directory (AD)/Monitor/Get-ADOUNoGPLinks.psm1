Function Get-ADOUNoGPLinks {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/4/20
            Version: 2020.05.04
            
        .DESCRIPTION
            Get AD OUs with no GP links
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        $Root = "DC=$($Domain.Replace('.',',DC='))"
        $ADSearcher = [DirectoryServices.DirectorySearcher]@{
            # Increase this number to increase the amount of results returned. This is useful for large domains/queries.
            PageSize   = 3 
            Filter     = '(|(objectclass=organizationalUnit)(objectclass=container)(objectclass=Builtin)(objectclass=Builtindomain)(objectclass=domainDNS))'
            SearchRoot = "LDAP://$Root"
        }
    }
    Process {
        ($ADSearcher.FindAll().Properties |
            Where-Object -FilterScript { !$_.Properties.gplink }).Properties.distinguishedname
    }
}