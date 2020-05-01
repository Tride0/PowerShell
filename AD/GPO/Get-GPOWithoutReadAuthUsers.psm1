Function Get-GPOWithoutReadAuthUsers
{
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20

        .DESCRIPTION
            Get GPOs that don't have a Authenticated Users with Read permissions on the GPO.
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin
    {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process
    {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() |
            ForEach-Object -Process {
                $ACL = Get-ACL "AD:\$($_.Path)"
                $AuthUsers = $ACL.Access | Where-Object -FilterScript {$_.IdentityReference -like "*Authenticated Users*"}
                
                If ("$($AuthUsers.ActiveDirectoryRights)" -notlike "*read*")
                {
                    $_.DisplayName
                }

                Remove-Variable ACL, AuthUsers -ErrorAction SilentlyContinue
            }
    }
}