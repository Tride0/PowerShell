Function Get-ADSSManualConnections {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 4/30/20
            Version: 2020.04.30
            
        .DESCRIPTION
            Get all AD Site Connections that were configured manually
        
    #>
    Param(
        $Domain = $env:USERDNSDOMAIN
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        $Root = "DC=$($Domain.Replace('.',',DC='))"
    }
    Process {
        Get-ADObject -Server $Domain -SearchBase "CN=Sites,CN=Configuration,$Root" -Filter "objectclass -eq 'nTDSConnection'" -Properties whencreated, fromserver | 
            Where-Object -FilterScript { $_.name -notlike '*-*-*-*-*' } |
            Select-Object -Property WhenCreated,
            @{n = 'FromSite'; e = { $_.fromserver.split(',')[3].split('=')[1] } },
            @{n = 'From'; e = { $_.distinguishedname.split(',')[0].split('=')[1] } },
            @{n = 'ToSite'; e = { $_.distinguishedname.split(',')[4].split('=')[1] } },
            @{n = 'To'; e = { $_.distinguishedname.split(',')[2].split('=')[1] } } |
            Sort-Object -Property WhenCreated
    }
}