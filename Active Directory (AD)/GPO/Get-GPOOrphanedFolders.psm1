Function Get-GPOOrphanedFolders {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get Orphaned GPO Folders. GPO Folders without a GPO.
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        Get-ChildItem -Path \\$Domain\sysvol\$Domain\Policies -Filter *-*-*-* | 
            ForEach-Object -Process {
                [PSCustomObject]@{
                    Path    = $_.FullName
                    GUID    = $_.BaseName
                    GPOName = (Get-GPO -Guid "$($_.BaseName)" -ErrorAction SilentlyContinue).DisplayName
                }
            } |
            Where-Object -FilterScript { ![Bool]$_.GPOName }
    }
}