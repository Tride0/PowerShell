Function Get-ADGroupNoMembers {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get AD Group Ojbects with no members
    #>
    Begin {
        $ADSearcher = [DirectoryServices.DirectorySearcher]@{
            # Increase this number to increase the amount of results returned. This is useful for large domains/queries.
            PageSize = 3 
            Filter   = '(&(objectClass=Group)(!(member=*)))'
        }
    }
    Process {
        $ADSearcher.FindAll().Properties | 
            ForEach-Object -Process {
                [PSCustomObject]@{
                    distinguishedname = $($_.distinguishedname)
                    name              = $($_.name)
                    samaccountname    = $($_.samaccountname)
                    whencreated       = $($_.whencreated)
                    whenChanged       = $($_.whenchanged)
                }
            }
    }
}
