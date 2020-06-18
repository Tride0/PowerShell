Function Clear-ADGroupMemberships {
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
        [Parameter(Mandatory)][String[]]$Object,
        [String]$Domain = $env:USERDNSDOMAIN
    )
    Begin {
        # Create Searcher for AD
        $ADSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
        
        # Decreases search time by returning only this attribute
        [Void] $ADSearcher.PropertiesToLoad.Add('distinguishedname')
        [Void] $ADSearcher.PropertiesToLoad.Add('memberof')

        # Have search look at the specified domain
        $DomainRoot = "DC=$($Domain.Replace('.',',DC='))"
        $ADSearcher.SearchRoot = "LDAP://$DomainRoot"
    }
    Process {
        Foreach ($ObjectName in $Object) {
            # Create Filter to search for group
            $ADSearcher.Filter = "(|(samaccountname=$ObjectName)(name=$ObjectName)(displayname=$ObjectName)(distinguishedname=$ObjectName))"
            
            # Get AD User Object
            $ADObject = $ADSearcher.FindOne()

            # For each group that the user is a member of
            Foreach ($Group in $ADObject.Properties.memberof) {
                # Get the AD Group Object
                $ADGroupObject = [ADSI]"LDAP://$Group"
                # Remove the User from the Group
                $ADGroupObject.member.Remove($($ADObject.Properties.distinguishedname))
                # Commit changes to the AD Group Object
                $ADGroupObject.CommitChanges()
            }
        }
    }
    End {
        $ADSearcher.Dispose()
    }
}
