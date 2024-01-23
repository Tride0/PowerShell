Function Get-GPOConflictFolders {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get GPO Conflict Folders
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Process {
        Get-ChildItem -Path \\$Domain\SYSVOL\$Domain -Filter *ntfrs_* -Recurse -Force | 
            Select-Object -Property FullName, CreationTime, LastAccessTime, LastWriteTime
    }
}