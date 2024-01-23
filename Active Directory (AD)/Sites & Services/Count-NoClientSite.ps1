[String[]]$DCs = Get-ADDomainController -Filter * | Select-Object -ExpandProperty name 

$Results = @()

Foreach ($DC in $DCs) {
    Remove-Variable ncs, result -ErrorAction SilentlyContinue

    $NCS = Get-Content \\$DC\c$\Windows\debug\netlogon.log |
        Where-Object -FilterScript { $_ -like '*NO_CLIENT_SITE*' }

    [PSCustomObject]@{
        DC       = $DC
        NCSCount = $NCS.Count
    } | Tee-Object -Variable result
    $Results += $Result
}

Clear-Host
$Results | Sort-Object -Property NCSCount -Descending
