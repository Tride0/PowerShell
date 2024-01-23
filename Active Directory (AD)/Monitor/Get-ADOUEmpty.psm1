Function Get-ADOUEmpty {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get AD OUs that are empty, excluding sub OUs
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        $Root = "DC=$($Domain.Replace('.',',DC='))"
        $ADSearcher = [DirectoryServices.DirectorySearcher]@{
            # Increase this number to increase the amount of results returned. This is useful for large domains/queries.
            PageSize = 3 
            Filter   = '(|(objectclass=organizationalUnit)(objectclass=container)(objectclass=Builtin)(objectclass=Builtindomain)(objectclass=domainDNS))'
        }
    }
    Process {
        $ADSearcher.FindAll().Properties |
            Where-Object -FilterScript { $_.distinguishedname -notlike '=*-*-*-*,' -and
                $_.distinguishedname -notlike '*CN=OpsMgrLatencyMonitors*' -and
                $_.distinguishedname -notlike "*CN=System,$Root*" } |
            ForEach-Object -Process {
                $ADSearcher.SearchRoot.Path = "LDAP://$($_.distinguishedname)"
                $ADSearcher.Filter = '(!(|(objectclass=organizationalUnit)(objectclass=container)(objectclass=Builtin)(objectclass=Builtindomain)(objectclass=domainDNS)))'
                [Array]$Objects = $ADSearcher.FindOne()
                $ObjectCount = $Objects.Count
                If ($ObjectCount -le 1) {
                    $_.distinguishedname
                }
            } | Sort-Object
    }
}
