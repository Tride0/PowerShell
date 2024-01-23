Function Get-ADSSSitesNoDCs {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get all AD Sites with no DCs assigned to them.
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        $DomainDirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Domain', $Domain)
        $ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainDirectoryContext)
        $ForestDirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Forest', $ADDomain.Forest)
        $ADForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ForestDirectoryContext)
        $ADSSSites = $ADForest.Sites
    }
    Process {
        $ADSSSites |
            Where-Object -FilterScript { $_.Servers.Count -eq 0 } |
            Select-Object -ExpandProperty Name
    }
}