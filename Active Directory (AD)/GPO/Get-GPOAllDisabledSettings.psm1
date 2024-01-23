Function Get-GPOAllDisabledSettings {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Gets all GPOs that have all their settings disabled
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() |
            Where-Object -FilterScript { $_.GpoStatus -eq 'AllSettingsDisabled' } | 
            Select-Object -Property DisplayName, Owner, GpoStatus, CreationTime, ModificationTime, Description |
            Sort-Object -Property DisplayName
    }
}