Function Check-ReplicationUserGroupMemberships
{
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/05/20

        .DESCRIPTION
        Th
    #>
    [cmdletbinding()]
    Param(
        $DCs = (Get-ADDomainController -Filter *).Name,
        $User,
        $Group
    )
    Begin
    {
        Import-Module ActiveDirectory -ErrorAction Stop
        $Group = (Get-ADGroup -Identity $Group -ErrorAction Stop).distinguishedname
        $Results = @()
    }
    Process
    {
        Foreach ($DC in $DCs)
        {
            $UserAccount = Get-ADUser -Identity $User -Properties memberof -Server $DC
        
            [PSCustomObject]@{
                DC = $DC
                Result = $UserAccount.memberof.contains($Group)
            }

            Remove-Variable UserAccount -ErrorAction SilentlyContinue
        }
    }
}