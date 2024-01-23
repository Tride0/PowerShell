Function Get-ADOUNotProtected {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/4/20
            Version: 2020.05.04
            
        .DESCRIPTION
            Get AD OUs that are not protected from Deletions
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
        $ADSearcher.FindAll().Properties |
            ForEach-Object -Process {
                $ACL = Get-Acl "AD:\$($_.distinguishedname)"
                $Protected = $ACL.Access | Where-Object -FilterScript { $_.IdentityReference -eq 'Everyone' -and $_.ActiveDirectoryRights -eq 'DeleteTree, Delete' -and $_.AccessControlType -eq 'Deny' }
                If (![Boolean]$Protected) {
                    $_.distinguishedname
                }
                Remove-Variable ACL, Protected -ErrorAction SilentlyContinue
            } | Sort-Object
    }
}