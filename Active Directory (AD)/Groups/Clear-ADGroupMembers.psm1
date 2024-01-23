Function Clear-ADGroupMembers {
    <#
        .DESCRIPTION
            Removes all members from a group
        .Notes
            Created By: Kyle Hewitt
            Created On: 2020/05/06
            Version: 2020.05.06
    #>
    [cmdletbinding()]
    Param
    (
        [String[]]$Group,
        [String]$Domain = $env:USERDNSDOMAIN
    )
    Begin {
        # Create Searcher for AD
        $ADSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
        
        # Decreases search time by returning only this attribute
        [Void] $ADSearcher.PropertiesToLoad.Add('distinguishedname')

        # Have search look at the specified domain
        $DomainRoot = "DC=$($Domain.Replace('.',',DC='))"
        $ADSearcher.SearchRoot = "LDAP://$DomainRoot"
    }
    Process {
        Foreach ($GroupName in $Group) {
            # Create Filter to search for group
            $ADSearcher.Filter = "(|(samaccountname=$GroupName)(name=$GroupName)(displayname=$GroupName)(distinguishedname=$Groupname))"
            
            # Get AD Group Object
            $ADGroupObject = [ADSI]$ADSearcher.FindOne().Path

            # Clear AD Group attribute
            $ADGroupObject.member.clear()

            # Commit changes to the AD Group Object
            $ADGroupObject.CommitChanges()
        }
    }
    End {
        $ADSearcher.Dispose()
    }
}