Function Get-GPODisabledLinks {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 09/01/20
            Version: 2020.09.01

        .DESCRIPTION
            Gets GPOs that have links that are disabled
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() | ForEach-Object -Process { 
            $GPO = $_
            ([xml]($GPO | Get-GPOReport -Domain $Domain -ReportType XML)).GPO.LinksTo | 
                Where-Object -FilterScript { $_.Enabled -eq 'false' } | 
                Select-Object -Property @{Name = 'GPO'; Expression = { $GPO.DisplayName } }, @{Name = 'Link'; Expression = { $_.SOMPath } }, Enabled, @{Name = 'Enforced'; Expression = { $_.NoOverride } } | 
                Sort-Object -Property GPO
            }
        }
    }