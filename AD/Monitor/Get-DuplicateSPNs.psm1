Function Get-DuplicateSPNs
{
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20

        .DESCRIPTION
            Get Duplicate SPNs in a domain
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Process
    {
        SetSPN.exe -t $Domain -x -p
    }
}