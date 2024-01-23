Function Get-GPOWrongOwner {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Gets GPOs that have the wrong owner
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN,
        $CorrectOwner = "$($Domain.split('.')[0])\Domain Admins"
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() | 
            Where-Object -FilterScript { $_.Owner -ne $CorrectOwner } | 
            Select-Object -Property DisplayName, Owner, CreationTime, ModificationTime, Description |
            Sort-Object -Property Owner
    }
}
