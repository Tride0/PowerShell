Function Check-ReplicationUserGroupMemberships {
    #Requires -Module ActiveDirectory
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/05/20
            Version: 2020.05.26

        .DESCRIPTION
            This function looks at all domain controllers to check if the user group membership is on all of them.
    #>
    [cmdletbinding()]
    Param(
        [String[]]$DCs = (Get-ADDomainController -Filter *).Name,
        [String]$User,
        [String]$Group
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        $Group = (Get-ADGroup -Identity $Group -ErrorAction Stop).distinguishedname
    }
    Process {
        Foreach ($DC in $DCs) {
            $UserAccount = Get-ADUser -Identity $User -Properties memberof -Server $DC
        
            [PSCustomObject]@{
                DC     = $DC
                Result = $UserAccount.memberof.contains($Group)
            }

            Remove-Variable UserAccount -ErrorAction SilentlyContinue
        }
    }
}