$Computer = '.'
$AccountSId = ''

#$SAMAccountName = ''
#$AccountSID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$(([adsisearcher]"samaccountname=$SAMAccountName").FindOne().properties.objectsid),0).ToString()



$ACL = Invoke-WmiMethod `
    -ComputerName $Computer `
    -Namespace root `
    -Path __systemsecurity `
    -Name GetSecurityDescriptor |
    Select-Object -exp Descriptor

$Ace = (New-Object System.Management.ManagementClass('win32_Ace')).CreateInstance()
$Ace.AccessMask = 51
$ACe.AceFlags = 2
$Ace.AceType = 0

$trustee = (New-Object System.Management.ManagementClass('win32_Trustee')).CreateInstance()
$trustee.SidString = $AccountSID
$Ace.Trustee = $trustee

$ACL.DACL += $Ace


Invoke-WmiMethod `
    -ComputerName $Computer `
    -Namespace root `
    -Path '__systemsecurity=@' `
    -Name 'SetSecurityDescriptor' `
    -ArgumentList $acl.psobject.immediateBaseObject
    
    