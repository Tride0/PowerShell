<#
    AUTHOR: Fabian Müller, Microsoft Deutschland GmbH
    Edited By: kyle Hewitt
    VERSION: v0.4
    DATE: 03.03.2014
    Version Date: 2020.09.14
    
    Description:
        This script will set all users with an adminCount of 1 to 0. Then run the AdminSDHolder SDProp to reset the adminCount to 1 on appropriate accounts. This script will also set inheritance to True and remove all non-inherited ACEs.
        adminCount is set to null by default so if you want to look for accounts that were cleaned by this script you should be able to search for adminCount=0 and to get a list.

    Changes Notes:
        I've added setting the ACL inheritance on users who are no longer protected by adminSDHolder and it will also remove any non-inherited ACEs as well. This will prevent issues where account administrators are unable to administer the account when they should now be able to.
 #>

Clear-Host

# variable definition 
$tempFolder = 'C:\AdminSDHolderReset' 

[string]$exportPathBeforeReset = "$($tempFolder)\adminCountUsersBeforeReset.csv" 
[string]$exportPathAfterReset = "$($tempFolder)\adminCountUsersAfterReset.csv" 
$runProtectAdminGroupsTaskFilePath = "$($tempFolder)\runProtectAdminGroupsTask.ldf"
$runProtectAdminGroupsTask = @('dn:
changetype: modify
add: runProtectAdminGroupsTask
runProtectAdminGroupsTask: 1
-
')

# Check for required tools
Try { 
    Import-Module ActiveDirectory -ErrorAction Stop
    dsacls.exe | Out-Null
    ldifde.exe | Out-Null
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black "[Unexpected error occurred while checking for required tools. ActiveDirectory Module, dsacls.exe, lidfde.exe.`nError: $_]" 
    throw 
} 

# Create Temp folder
Try { 
    Write-Host 'Creating temporary folder if not already present...' 
    If (!(Test-Path $tempFolder)) {
        New-Item -ItemType Directory -Path $tempFolder | Out-Null
    }
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black "[Error while creating working folder $($tempFolder)]" 
    throw 
}

# Create LDIF file
$runProtectAdminGroupsTask | Out-File -FilePath $runProtectAdminGroupsTaskFilePath -Encoding ascii -Force
 
# Get Domain Information
Try { 
    $domain = Get-ADDomain -ErrorAction stop
    $domainPdc = $domain.PDCEmulator
    $domainDn = $domain.DistinguishedName
} 
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black '[Unexpected error occurred while reading PDC Emulator FSMO role owner]' 
    throw 
} 

# look for krbtgt on AdminSDHolder
Try { 
    [array]$AdminSDHolderKrbTgt = dsacls "CN=AdminSDHolder,CN=System,$($domain.DistinguishedName)" | findstr /I 'krbtgt'
    
} 
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black '[Unexpected error occurred while reading the current AdminSDHolder ACL]' 
    throw 
}

if ($AdminSDHolderKrbTgt.Count -gt 0) {
    Write-Host -ForegroundColor Red -BackgroundColor Black "[The AdminSDHolder is already stamped with an ACE for the domain's krbtgt account.`n As the krbtgt account normally would be used within this script as an 'helper ACE object' there is a chance to break the current ACL. `n This script stops now to prevent ACL potential issues.]"     
    exit -1
}

# Export list of all adminCount=1 users
Try { 
    Write-Host "Getting the list of all current adminCount=1 users. Export will be placed to '$exportPathBeforeReset'..." 
    $adminCountUsersBeforeReset = Get-ADUser -LDAPFilter '(adminCount=1)' -Server $domainPdc 
    $adminCountUsersBeforeReset | Export-Csv -Path $exportPathBeforeReset -Force -NoTypeInformation 
     
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black '[Unexpected error occurred while loading ActiveDirectory PowerShell module]' 
    throw 
} 
 

# Set adminCount to 0 on all adminCount=1 users
Try { 
    Write-Host "Resetting adminCount to '0' for all current adminCount=1 users..." 
    $adminCountUsersBeforeReset | Set-ADUser -Replace @{ admincount = 0 } -Server $domainPdc 
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black "[Unexpected error occurred while resetting 'adminCount' attribute to '0']" 
    throw 
} 

# Add krbtgt ACE to AdminSDHolder
Try { 
    dsacls "\\$($domainPdc)\CN=AdminSDHolder,CN=System,$($domainDn)" /G 'krbtgt:GR' | Out-Null
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black "[Unexpected error occurred while setting the AdminSDHolder temporary ACL for the 'krbTGT' account]" 
    throw 
}

# Trigger AdminSdHolder SdProp Process
Try { 
    Write-Host 'Triggering the AdminSDHolder SDPROP process...' 
    ldifde.exe -i -f $($runProtectAdminGroupsTaskFilePath) -s $($domainPdc) | Out-Null
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black "[Unexpected error occurred while importing LDIFDE file to start 'runProtectGroupsTask']" 
    throw 
}

# Wait for AdminSDHolder SDProp Process to finish
$startDate = Get-Date
Write-Host "Waiting 1 minute to let the AdminSDHolder SDPROP process propagate the ACLs (started at $($startDate)) (Finishes at $($StartDate.AddMinutes(1)))..."
Start-Sleep -Seconds 60
    
# Get New List of adminCount=1 users
Write-Host "Getting the list of all current adminCount=1 users. Export will be placed to $exportPathAfterReset." 
$adminCountUsersAfterReset = Get-ADUser -LDAPFilter '(adminCount=1)' -Server $domainPdc 
$adminCountUsersAfterReset | Export-Csv -Path $exportPathAfterReset -Force -NoTypeInformation

# Remove krbtgt from AdminSDHolder ACL
Try { 
    dsacls "\\$($domainPdc)\CN=AdminSDHolder,CN=System,$($domainDn)" /R 'krbtgt' | Out-Null
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black "[Unexpected error occurred while removing the AdminSDHolder temporary ACL for the 'krbTGT' account. It should be removed manually.]" 
    throw 
}

# Run AdminSdHolder SDProp Process
Try { 
    ldifde.exe -i -f $($runProtectAdminGroupsTaskFilePath) -s $($domainPdc) | Out-Null
}  
Catch { 
    Write-Host -ForegroundColor Red -BackgroundColor Black "[Unexpected error occurred while importing LDIFDE file to start 'runProtectGroupsTask']" 
    throw 
}

# Compare Old and New List of AdminCount=1 users for any that were removed
[Array]$Removed = Compare-Object $adminCountUsersBeforeReset.DistinguishedName $adminCountUsersAfterReset.DistinguishedName | Where-Object -FilterScript { $_.SideIndicator -eq '<=' } | Select-Object -expand InputObject
If ($Removed.Count -gt 0) {
    Write-Host "`n`nThe following user objects are not members of protected groups anymore:" -ForegroundColor Red
    $Removed

    Write-Host "`nCorrecting ACLs on Removed Users..."
    Foreach ($User in $Removed) {
        $ACL = Get-Acl "AD:\$User"
        # Setting Inheritance to True
        $ACL.SetAccessRuleProtection($False, $True)
        # Removing all non-inherited ACLs
        Foreach ($ACE in $ACL.Access) {
            If (-not $ACE.IsInherited) {
                [Void] $ACL.RemoveAccessRule($ACE)
            }
        }
        Try {
            Set-Acl -Path $ACL.Path -AclObject $ACL -ErrorAction Stop
        }
        Catch {
            Write-Host "Failed to correct ACL for $User" -ForegroundColor Red
        }
    }
}

# List any new users that were added because of this process
[Array]$NewlyProtectedUsers = Compare-Object $adminCountUsersBeforeReset.DistinguishedName $adminCountUsersAfterReset.DistinguishedName | Where-Object -FilterScript { $_.SideIndicator -eq '=>' } | Select-Object -expand InputObject
If ($NewlyProtectedUsers.Count -gt 0) {
    Write-Host -ForegroundColor Green "`n`nThe following user objects are now protected because they're in protected groups: " 
    $NewlyProtectedUsers
}

Write-Host "`n`nFor additional information see the export files in $($tempFolder)."

Write-Host "`nDone."
