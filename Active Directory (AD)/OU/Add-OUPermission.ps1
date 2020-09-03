<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 08-13-2020
        Version: 2020.08.18

    .DESCRIPTION
        For:
            Create and Delete
                . Creating a user requires some modify permissions. Specifically the permission to set the password or to disable the user.
                Permission = CreateChild, DeleteChild
                Inheritance = SelfAndChildren or All
            Modify w/o Full Control
                Permission = CreateChild, DeleteChild, ListChildren, ReadProperty, DeleteTree, ExtendedRight, Delete, GenericWrite
                Inheritance = Descendents
            Unlock
                Permission = ReadProperty, WriteProperty
                Property = lockouttime
            Reset Password
                . Two Entries
                1 Permission = ExtendedRight
                1 Property = Reset Password
                2 Permission = ExntededRight
                2 Property = Change Password
            Group Members
                1 Permission = ReadProperty, WriteProperty
                2 Property = member
            Group/User Memberof
                1 Permission = ReadProperty, WriteProperty
                2 Property = memberof
            Link Unlink GPO
                . Two Entries
                1 Permission = ReadProperty, WriteProperty
                2 ObjectType = organizationalUnit
                3 Inheritance = All
                4 Property = gPLink
                1 Permission = ReadProperty, WriteProperty
                2 ObjectType = organizationalUnit
                3 Inheritance = All
                4 Property = gPOptions
                
#>

Param(
    [String]$CSVPath = "$PSScriptRoot\OUPerm.csv",
    [String]$OUforADAccessGroups = "OU"
)

Begin {
    Import-Module ActiveDirectory -ErrorAction Stop
    
    $rootdse = Get-ADRootDSE
    $GuidMap = @{}
    Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter “(schemaidguid=*)” -Properties lDAPDisplayName,schemaIDGUID | ForEach-Object { $GuidMap[$_.lDAPDisplayName] = [System.GUID]$_.schemaIDGUID }
    Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter “(&(objectclass=controlAccessRight)(rightsguid=*))” -Properties displayName,rightsGuid | ForEach-Object { $GuidMap[$_.displayName] = [System.GUID]$_.rightsGuid }

    If (!(Test-Path -Path $CSVPath)) {
        [PSCustomObject]@{
            OU = ''
            AccessGroupName = ''
            Permission = ([System.DirectoryServices.ActiveDirectoryRights].GetEnumNames() -join ' ; ')
            PermissionType = ([System.Security.AccessControl.AccessControlType].GetEnumNames() -join ', ')
            ObjectType = 'User, Computer, Group, not limited to these'
            Inheritance = ([System.DirectoryServices.ActiveDirectorySecurityInheritance].GetEnumNames() -join ', ')
            Property = 'Leave Blank for all Properties, Change Password, Reset Password, lockouttime not limited to these'
        } | 
            Export-Csv -Path $CSVPath -NoTypeInformation -Force
        & $CSVPath
        Read-Host -Prompt "Fill out CSV then rerun script. Exitting"
        Exit
    }

    #region Functions

    Function Create-Tree {
        <#
            .NOTES
                Created By: Kyle Hewitt
                Created On: 08-05-2020
                Version: 2020.08.05

            .DESCRIPTION
                This function will create a OU tree based on specified DN
        #>
        [cmdletbinding()]
        Param([String[]]$OUs)
        Begin {
            Import-Module ActiveDirectory -ErrorAction Stop
            Function Split-OU {
                Param($DN)
                $SplitDN = $DN.split(',')
                Return @{
                    OU = $DN
                    Parent = $SplitDN[1..($SplitDN.Count-1)] -join ','
                    ChildName = $SplitDN[0].Split('=')[1]
                }
            }
        }
        Process {
            Foreach ($OU in $OUs) {
                $OUInfo = Split-OU -DN $OU
                
                # If the Parent OU doesn't exist, create it first.
                If (![DirectoryServices.DirectoryEntry]::Exists("LDAP://$($OUInfo.Parent)")) {
                    Create-Tree -OUs $OUInfo.Parent
                }

                Try {
                    New-ADOrganizationalUnit -Path $OUInfo.Parent -Name $OUInfo.ChildName -ProtectedFromAccidentalDeletion $False -ErrorAction Stop
                    Write-Host "Created: '$OU'." -ForegroundColor Green
                }
                Catch {
                    Write-Host "Failed to Create '$OU'. Error: $_" -ForegroundColor Red
                    Continue
                }
            }
        }
    }

    #endregion Functions

    
    $CSV = Import-Csv -Path $CSVPath
}
Process {
    :CSV Foreach ($Entry in $CSV) {
        Remove-Variable ADGroup, ACL, ACE, AccessRule, ADRights, ObjectType -ErrorAction SilentlyContinue

        If (![Boolean]$Entry.OU) {
            Write-Host "OU not provided. Skipping." -ForegroundColor Red
            Continue CSv
        }

        If (![DirectoryServices.DirectoryEntry]::Exists("LDAP://$($Entry.OU)")) {
            Try {
                # Create OU
                Create-Tree -OUs $Entry.OU -ErrorAction Stop 
            }
            Catch {
                Write-Host "Failed to Create Tree. Error: $_" -ForegroundColor Red
                Continue CSV
            }
        }
        Else {
            Write-host "Exists: '$($Entry.OU)'" -ForegroundColor Green
        }

        If (![Boolean]$Entry.AccessGroupName) {
            Write-Host "Group Name not provided. Skipping." -ForegroundColor Red
            Continue CSV
        }

        Try {
            $ADGroup = Get-ADGroup $Entry.AccessGroupName -ErrorAction Stop
            Write-Host "Exists: '$($Entry.AccessGroupName)'" -ForegroundColor Green
        }
        Catch {
            # Create Access Group
            Try {
                # Create Group Description
                $GroupDescription = "$($Entry.Permission) $($Entry.Property) Permission for $($Entry.ObjectType) objects in $($Entry.OU)"
                
                # Create Group
                $ADGroup = New-ADGroup -Description $GroupDescription -Path $OUforADAccessGroups -SamAccountName $Entry.AccessGroupName -Name $Entry.AccessGroupName -DisplayName $Entry.AccessGroupName -GroupCategory Security -GroupScope DomainLocal -PassThru -ErrorAction Stop
                Write-Host "Created: '$($Entry.AccessGroupName)'" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed to Create Group. Error: $_" -ForegroundColor Red
                Continue CSV
            }
        }

        If (![Boolean]$Entry.Permission -or ![Boolean]$Entry.ObjectType) {
            Write-Host "Permission and ObjectType not specified. Skipping." -ForegroundColor Red
            Continue CSV
        }

        # Add Access Group to OU
        Try {
            # Get Current ACL of OU
            $ACL = Get-ACL "AD:\$($Entry.OU)" -ErrorAction Stop

            # Build Access Rule Components
            $Identity = [System.Security.Principal.IdentityReference] $ADGroup.SID

            [System.DirectoryServices.ActiveDirectoryRights]$ADRights = $Entry.Permission.Split(';').Trim() -join ', '
            
            If (![Boolean]$Entry.PermissionType) {
                $PermissionType = [System.Security.AccessControl.AccessControlType]::Allow
            }
            Else {
                $PermissionType = [System.Security.AccessControl.AccessControlType]::($Entry.PermissionType)
            }
            
            If (![Boolean]$Entry.Inheritance) {
                $Inheritance = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Descendents
            }
            Else {
                $Inheritance = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::($Entry.Inheritance)
            }


            If (($ADRights -like "*CreateChild*" -or $ADRights -like "*DeleteChild*") -and $ADRights -notlike "*GenericWrite*") {
                $ObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
                $PropertyGUID = $GuidMap["$($Entry.ObjectType)"]
            }
            Else {
                If ($Entry.ObjectType -eq 'All') {
                    $ObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
                }
                Else {
                    $ObjectType = $GuidMap["$($Entry.ObjectType)"]
                }
                If ([Boolean]$Entry.Property) {
                    $PropertyGUID = $GuidMap["$($Entry.Property)"]
                }
            }
            

            # Create Access Role
            If ([Boolean]$PropertyGUID) {
                $accessrule = new-object System.DirectoryServices.ActiveDirectoryAccessRule $identity, $adRights, $PermissionType, $PropertyGUID, $Inheritance, $ObjectType -ErrorAction Stop
            }
            Else {
                $AccessRule = New-object System.DirectoryServices.ActiveDirectoryAccessRule $Identity, $ADRights, $PermissionType, $Inheritance, $ObjectType -ErrorAction Stop 
            }

            #Check for ACE on ACL, if it already exists. Skip it.
            $ACE = $ACL.Access | Where-Object -FilterScript {
                $_.IdentityReference -like "*\$($ADGroup.Name)" -and 
                $_.InheritedObjectType.Guid -eq $ObjectType.Guid  -and 
                $_.InheritanceType -eq $Inheritance -and 
                $_.AccessControlType -eq $PermissionType -and 
                $_.ActiveDirectoryRights -eq $ADRights -and 
                (![Boolean]$PropertyGUID.Guid -or $_.ObjectType.Guid -eq $PropertyGUID.Guid)}
            If ([Boolean]$ACE) { 
                Write-Host "Access Control Entry (ACE) Already Exists. Skipping." -ForegroundColor Yellow
                Continue CSV 
            }
            
            # Add Access Rule to ACL
            $ACL.AddAccessRule($AccessRule)

            # Set new ACL on OU
            Set-Acl -Path "AD:\$($Entry.OU)" -AclObject $ACL -ErrorAction Stop
            Write-Host "Added: '$($Entry.AccessGroupName)' to '$($Entry.OU)' with '$($Entry.Permission)' $($Entry.Property) for '$($Entry.ObjectType)' objects" -ForegroundColor DarkGreen
        } 
        Catch {
            Write-Host "Failed to Edit ACL. Error: $_" -ForegroundColor Red
            Continue CSV
        }
    }
}