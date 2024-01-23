Function Get-GPONoSettings {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Gets all GPOs with have no settings.
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() | 
            Where-Object -FilterScript { ($_ | Get-GPOReport -ReportType Xml) -notmatch '<q[0-9]{1,}.{1,}>' } | 
            Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description | 
            Sort-Object -Property DisplayName
    }
}