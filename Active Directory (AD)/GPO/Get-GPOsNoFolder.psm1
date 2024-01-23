Function Get-GPOsNoFolder {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get Orphaned GPOs. GPOs without a folder.
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() | 
            ForEach-Object -Process {
                [PSCustomObject]@{
                    Name   = $_.DisplayName
                    GUID   = $_.ID
                    Path   = "\\$Domain\sysvol\$Domain\Policies\{$($_.ID)}"
                    Exists = [System.IO.Directory]::Exists("\\$Domain\sysvol\$Domain\Policies\{$($_.ID)}")
                }
            } |
            Where-Object -FilterScript { $_.Exists -eq $False } 
    }
}