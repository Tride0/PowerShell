Function Get-GPOWithoutApplyPerm {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Gets GPOs that don't have a security principal with the Apply Permission
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module GroupPolicy -ErrorAction Stop
    }
    Process {
        [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos() | 
            Where-Object -FilterScript { (Get-Acl -Path "AD:\$($_.Path)").Access.objectType.guid -notcontains 'edacfd8f-ffb3-11d1-b41d-00a0c968f939' } |
            Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description | 
            Sort-Object -Property DisplayName
    }
}