$OrphanedSIDs = @()
$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
$Root = "DC=$($Domain.Split('.') -join ',DC=')"


#Query AD Root
Get-ChildItem -Path "AD:\$Root" -Recurse |
    #So it only gets containers/OUs/Builtin Containers
    Where-Object -FilterScript { 'organizationalUnit', 'container', 'builtin' -contains $_.ObjectClass } |
    #Foreach OU
    ForEach-Object -Process {
        $OU = $_.DistinguishedName
        #Look at the Security
        Get-Acl -Path AD:\$OU |
            #Look at the Access Specifically
            Select-Object -ExpandProperty Access |
            #Only looks at Un-Inherited ACL Entries to prevent un-needed bloat of data
            Where-Object -FilterScript { $_.IsInherited -eq $False } |
            #Look at what object is applied
            Select-Object -ExpandProperty IdentityReference -Unique |
            #Foreach object check and note as needed
            ForEach-Object -Process {
                If ($_ -like 'S-1-*') {
                    $SID = $_
                    #Adds SID to List if not there already.
                    If ($OrphanedSIDs.SID -notcontains $SID) {
                        $OrphanedSIDs += [PSCustomObject]@{
                            SID = $SID
                            OU  = $OU
                        }
                    }
                    #Adds OU to already present SID entry
                    Else {
                ($OrphanedSIDs |
                            Where-Object -FilterScript { $_.SID -eq $SID }).OU += ", $OU"
                        }
                    }
                }
            }
$OrphanedSIDs