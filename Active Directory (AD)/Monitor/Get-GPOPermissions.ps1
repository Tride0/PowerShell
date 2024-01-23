Import-Module GroupPolicy, ActiveDirectory -ErrorAction Stop

$ExportPath = "$PSscriptRoot\GPO_Permissions$(Get-Date -Format yyyyMMdd).csv"

$GPOs = Get-GPO -All

Foreach ($GPO in $GPOs) {
    Get-Acl -Path "AD:\$($GPO.Path)" |
        Select-Object -ExpandProperty Access |
        Export-Csv -Path $ExportPath -NoTypeInformation -Append -Force
}
