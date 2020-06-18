Function Mirror-ADObjectMemberships {
    <#
        .DESCRIPTION
            Mirrors other Object(s) memberships to other Object(s)
        .Notes
            Created By: Kyle Hewitt
            Created On: 2020/05/06
            Version: 2020.05.06
    #>
    Param
    (
        [Parameter(Mandatory)][String[]]$FromObject,
        [Parameter(Mandatory)][String[]]$ToObject,
        [String]$Domain = $env:ObjectDNSDOMAIN
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
        # Get Objects to add to Groups
        $ObjectsToAdd = @()
        Foreach ($Object in $ToObject) {
            $ADSearcher.Filter = "(|(samaccountname=$Object)(name=$Object)(displayname=$Object)(distinguishedname=$Object))"
            $ObjectsToAdd += $ADSearcher.FindOne().Properties.distinguishedname
        }

        # Add memberof to list of attributes returned because this is the information we'll need from these Objects
        [Void] $ADSearcher.PropertiesToLoad.Add('memberof')

        # Get Groups to add Objects to
        $GroupsToAddTo = @()
        Foreach ($Object in $FromObject) {
            $ADSearcher.Filter = "(|(samaccountname=$Object)(name=$Object)(displayname=$Object)(distinguishedname=$Object))"
            $GroupsToAddTo += $ADSearcher.FindOne().Properties.memberof
        }
        $GroupsToAddTo = $GroupsToAddTo | Sort-Object -Unique

        #Add Objects to the groups
        Foreach ($Group in $GroupsToAddTo) {
            # Get Group Object to add Objects to
            $ADGroupObject = [adsi]"LDAP://$Group"

            Foreach ($Object in $ObjectsToAdd) {
                # Add Object to group
                [Void] $ADGroupObject.member.Add($Object)
            }

            # Commit Changes to Group to AD
            $ADGroupObject.CommitChanges()

            $ADGroupObject.Dispose()
            Remove-Variable ADGroupObject -ErrorAction SilentlyContinue
        }
    }
    End {
        $ADSearcher.Dispose()
    }
}