Function Search-GPO
{
    #Requires -Modules GroupPolicy
    Param(
        [Parameter(ValueFromPipeline=$true, Position=1)]
            [String]$String = $(Read-Host -Prompt "What string do you want to search for?"),
        [String]$Name,
        [String]$Domain = $env:USERDNSDOMAIN
    )
    Begin
    {
        Import-Module -Name GroupPolicy -ErrorAction Stop
    }
    Process
    {
        If ($PSBoundParameters.ContainsKey('Name'))
        {
            [Array]$GPOs = Get-GPO -Name $Name -Domain $Domain
            
        }
        Else
        {
            [Array]$GPOs = Get-GPO -All -Domain $Domain
        }

        Foreach ($GPO in $GPOs)
        {
            $Report = Get-GPOReport -Guid $GPO.Id -ReportType Xml -Domain $Domain
            If ($Report -like "*$String*")
            {
                $GPO.DisplayName
            }
        }
    }
}