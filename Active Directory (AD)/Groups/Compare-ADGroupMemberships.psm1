function Compare-ADGroupMemberships {
    <#
        .DESCRIPTION
           Compare group memberships of multiple objects and return all common groups
        .NOTES
            Created By: Kyle Hewitt
            Created On: 2020/05/06
            Version: 2020.05.06
    #>
    Param
    (
        [Parameter(Mandatory)][String[]]$Objects,
        [String]$Domain = $env:UserDNSDOMAIN
    )
    Begin {
        If ($Objects.Count -lt 2) {
            Write-Error 'Provide at least 2 Objects to compare.' -ErrorAction Stop
        }

        # Create Searcher for AD
        $ADSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
        
        # Decreases search time by returning only this attribute
        [Void] $ADSearcher.PropertiesToLoad.Add('memberof')

        # Have search look at the specified domain
        $DomainRoot = "DC=$($Domain.Replace('.',',DC='))"
        $ADSearcher.SearchRoot = "LDAP://$DomainRoot"

        $AllGroups = @()
    }
    Process {
        Foreach ($Object in $Objects) {
            $ADSearcher.Filter = "(|(samaccountname=$Object)(name=$Object)(displayname=$Object)(distinguishedname=$Object))"
            $Groups = $ADSearcher.FindOne().Properties.memberof
            Foreach ($Group in $Groups) {
                If (![Boolean]$AllGroups -or !$AllGroups.dn.contains($Group)) {
                    $AllGroups += [PSCustomObject]@{
                        dn  = $Group
                        num = 1
                    }
                }
                Else {
                    ($AllGroups | Where-Object -FilterScript { $_.dn -eq $Group }).num ++
                }
            }
        }
    }
    End {
        $CommonGroups = $AllGroups | 
            Where-Object -FilterScript { $_.num -eq $Objects.Count } |
            Select-Object -ExpandProperty dn |
            Sort-Object

        If ($CommonGroups.Count -eq 0) {
            Write-Warning 'No common groups found'
        }
        Else {
            $CommonGroups
        }
    }
}