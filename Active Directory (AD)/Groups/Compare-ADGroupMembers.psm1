function Compare-ADGroupMembers {
    <#
        .DESCRIPTION
           Compares the members of multiple AD Groups and returns all the users they have in common
        .NOTES
            Created By: Kyle Hewitt
            Created On: 2020/05/06
            Version: 2020.05.06
    #>
    Param
    (
        [Parameter(Mandatory)][String[]]$Groups,
        [String]$Domain = $env:USERDNSDOMAIN
    )
    Begin {
        If ($Groups.Count -lt 2) {
            Write-Error 'Provide at least 2 Groups to compare.' -ErrorAction Stop
        }

        # Create Searcher for AD
        $ADSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
        
        # Decreases search time by returning only this attribute
        [Void] $ADSearcher.PropertiesToLoad.Add('member')

        # Have search look at the specified domain
        $DomainRoot = "DC=$($Domain.Replace('.',',DC='))"
        $ADSearcher.SearchRoot = "LDAP://$DomainRoot"

        $AllMembers = @()
    }
    Process {
        Foreach ($Group in $Groups) {
            $ADSearcher.Filter = "(|(samaccountname=$Group)(name=$Group)(displayname=$Group)(distinguishedname=$Group))"
            $Members = $ADSearcher.FindOne().Properties.member
            Foreach ($Member in $Members) {
                If (![Boolean]$AllMembers -or !$AllMembers.dn.contains($Member)) {
                    $AllMembers += [PSCustomObject]@{
                        dn  = $Member
                        num = 1
                    }
                }
                Else {
                    ($AllMembers | Where-Object -FilterScript { $_.dn -eq $Member }).num ++
                }
            }
        }
    }
    End {
        $CommonMembers = $AllMembers | 
            Where-Object -FilterScript { $_.num -eq $Groups.Count } |
            Select-Object -ExpandProperty dn |
            Sort-Object

        If ($CommonMembers.Count -eq 0) {
            Write-Warning 'No common members found'
        }
        Else {
            $CommonMembers
        }
    }
}