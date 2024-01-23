Function Get-GPONoLinks {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30

        .DESCRIPTION
            Gets GPOs that have no links
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() | 
            Where-Object -FilterScript { $_ | Get-GPOReport -Domain $Domain -ReportType XML | Select-String -NotMatch '<LinksTo>' } | 
            Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description | 
            Sort-Object -Property DisplayName
    }
}