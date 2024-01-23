<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 08-13-2020
        Version: 2020.09.15

    .DESCRIPTION
        For:
            Permissions on AdminSDHolder
                Inheritance = All

            Create, Delete without Modify
                . Creating a user requires some modify permissions. Specifically the permission to set the password or to disable the user.
                Permission = CreateChild, DeleteChild
                ObjectType = user, computer, group, etc.
                Inheritance = All

            Modify without Full Control
                Permission = CreateChild, DeleteChild, Self, ReadProperty, WriteProperty
                Inheritance = Descendents
                InheritedObjectType = user, computer, group, etc.

            Create, Delete, Modify
                . Two Entries
                1 Permission = CreateChild, DeleteChild
                1 ObjectType = user, computer, group, etc.
                1 Inheritance = All

                2 Permission = CreateChild, DeleteChild, Self, ReadProperty, WriteProperty
                2 Inheritance = Descendents
                2 InheritedObjectType = user,computer,group,etc.

            Specific Property Permission
                Permission = ReadProperty, WriteProperty
                InheritedObjectType = OBJECT_TYPE (User,Computer,Group,etc.)
                ObjectType = PROPERTY

            Unlock
                Permission = ReadProperty, WriteProperty
                InheritedObjectType = User
                ObjectType = lockouttime
                
            Reset Password
                . Two Entries
                1 Permission = ExtendedRight
                1 ObjectType = Reset Password
                1 InheritedObjectType = User

                2 Permission = ExntededRight
                2 ObjectType = Change Password
                2 InheritedObjectType = User

            Group Members
                Permission = ReadProperty, WriteProperty
                InheritedObjectType = Group
                ObjectType = member

            Group/User Memberof
                Permission = ReadProperty, WriteProperty
                InheritedObjectType = Group, User
                ObjectType = memberof

            Link Unlink GPO
                . Two Entries
                1 Permission = ReadProperty, WriteProperty
                1 InheritedObjectType = organizationalUnit
                1 Inheritance = All
                1 ObjectType = gPLink

                2 Permission = ReadProperty, WriteProperty
                2 InheritedObjectType = organizationalUnit
                2 Inheritance = All
                2 ObjectType = gPOptions
#>

Param(
    [String]$CSVPath = "$PSScriptRoot\OUPerm.csv",
    [String]$OUforADAccessGroups = ''
)

Begin {
    Import-Module ActiveDirectory -ErrorAction Stop
    
    $rootdse = Get-ADRootDSE
    $GuidMap = @{}
    Get-ADObject -SearchBase ($rootdse.SchemaNamingContext) -LDAPFilter '(schemaidguid=*)' -Properties lDAPDisplayName, schemaIDGUID | ForEach-Object { $GuidMap[$_.lDAPDisplayName] = [System.GUID]$_.schemaIDGUID }
    Get-ADObject -SearchBase ($rootdse.ConfigurationNamingContext) -LDAPFilter '(&(objectclass=controlAccessRight)(rightsguid=*))' -Properties displayName, rightsGuid | ForEach-Object { $GuidMap[$_.displayName] = [System.GUID]$_.rightsGuid }

    If (!(Test-Path -Path $CSVPath)) {
        [PSCustomObject]@{
            OU                  = ''
            AccessGroupName     = ''
            Permission          = ([System.DirectoryServices.ActiveDirectoryRights].GetEnumNames() -join ' ; ')
            PermissionType      = ([System.Security.AccessControl.AccessControlType].GetEnumNames() -join ', ')
            InheritedObjectType = ''
            ObjectType          = ''
            Inheritance         = ([System.DirectoryServices.ActiveDirectorySecurityInheritance].GetEnumNames() -join ', ')
        } | 
            Export-Csv -Path $CSVPath -NoTypeInformation -Force
        & $CSVPath
        Write-Host $GuidMap.Keys | Sort-Object
        Write-Host "`nThe above values are options for ObjectType and InheritedObjectType."
        Read-Host -Prompt 'Fill out CSV then rerun script. Exitting'
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
                    OU        = $DN
                    Parent    = $SplitDN[1..($SplitDN.Count - 1)] -join ','
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
        Remove-Variable ADGroup, AccessRule, identity, adRights, PermissionType, ObjectType, Inheritance, InheritedObjectType, ACL, ACE -ErrorAction SilentlyContinue

        If (![Boolean]$Entry.OU) {
            Write-Host 'OU not provided. Skipping.' -ForegroundColor Red
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
            Write-Host "Exists: '$($Entry.OU)'" -ForegroundColor Yellow
        }

        If (![Boolean]$Entry.AccessGroupName) {
            Write-Host 'Group Name not provided. Skipping.' -ForegroundColor Red
            Continue CSV
        }

        Try {
            $ADGroup = Get-ADGroup $Entry.AccessGroupName -ErrorAction Stop
            Write-Host "Exists: '$($Entry.AccessGroupName)'" -ForegroundColor Yellow
        }
        Catch {
            # Create Access Group
            Try {
                # Create Group Description
                $GroupDescription = "$($Entry.Permission) $($Entry.ObjectType) Permission for $($Entry.ObjectType) objects in $($Entry.OU)"
                
                # Create Group
                $ADGroup = New-ADGroup -Description $GroupDescription -Path $OUforADAccessGroups -SamAccountName $Entry.AccessGroupName -Name $Entry.AccessGroupName -DisplayName $Entry.AccessGroupName -GroupCategory Security -GroupScope DomainLocal -PassThru -ErrorAction Stop
                Write-Host "Created: '$($Entry.AccessGroupName)'" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed to Create Group. Error: $_" -ForegroundColor Red
                Continue CSV
            }
        }

        If (![Boolean]$Entry.Permission) {
            Write-Host 'Permission not specified. Skipping.' -ForegroundColor Red
            Continue CSV
        }

        # Add Access Group to OU
        Try {
            # Get Current ACL of OU
            $ACL = Get-Acl "AD:\$($Entry.OU)" -ErrorAction Stop

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

            If ([Boolean]$Entry.ObjectType) {
                $ObjectType = $GuidMap["$($Entry.ObjectType)"]
            }
            Else {
                $ObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
            }

            If ([Boolean]$Entry.InheritedObjectType) {
                $InheritedObjectType = $GuidMap["$($Entry.InheritedObjectType)"]
            }
            Else {
                $InheritedObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
            }

            # Create Access Role
            $AccessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $Identity, $ADRights, $PermissionType, $ObjectType, $Inheritance, $InheritedObjectType -ErrorAction Stop
            
            #Check for ACE on ACL, if it already exists. Skip it.
            $ACE = $ACL.Access | Where-Object -FilterScript {
                $_.IdentityReference -like "*\$($ADGroup.Name)" -and 
                $_.InheritedObjectType.Guid -eq $InheritedObjectType.Guid -and 
                $_.InheritanceType -eq $Inheritance -and 
                $_.AccessControlType -eq $PermissionType -and 
                $_.ActiveDirectoryRights -eq $ADRights -and 
                $_.ObjectType.Guid -eq $ObjectType.Guid }

            If ([Boolean]$ACE) { 
                Write-Host 'Access Control Entry (ACE) Already Exists. Skipping.' -ForegroundColor Yellow
                Continue CSV 
            }
            
            # Add Access Rule to ACL
            $ACL.AddAccessRule($AccessRule)

            # Set new ACL on OU
            Set-Acl -Path "AD:\$($Entry.OU)" -AclObject $ACL -ErrorAction Stop
            Write-Host "Added: '$($Entry.AccessGroupName)' to '$($Entry.OU)' with '$($Entry.Permission)' $($Entry.ObjectType) for '$($Entry.ObjectType)' objects" -ForegroundColor DarkGreen
        } 
        Catch {
            Write-Host "Failed to Edit ACL. Error: $_" -ForegroundColor Red
            Continue CSV
        }
    }
}
