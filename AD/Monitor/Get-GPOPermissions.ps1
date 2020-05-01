$GPOs = Get-GPO -All

Foreach ($GPO in $GPOs)
{
    $ADGPO = Get-ADObject -Filter {DisplayName -eq $GPO.DisplayName}
    $ACL = Get-Acl -Path "AD:\$($ADGPO.DistinguishedName)"
}
