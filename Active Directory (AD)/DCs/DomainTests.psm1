param($Domain)

#region Variables

$GPO_BackupPath = "$PSScriptRoot\Backups\GPOs\$Domain"

# Stale Thresholds in days
$UserLLDThreshold = 90
$UserWCrThreshold = 90
$ComputerLLDThreshold = 90
$ComputerWCrThreshold = 90
$GroupWCrThreshold = 90
$GroupWChThreshold = 90
$OUWCrThreshold = 90
$GPOWCrThreshold = 90
$GPOWChThreshold = 90

$BackupADUsersLDAPFilter = '(samaccountname=*)'
$BackupADUsersAttributes = @(
    'DistinguishedName'
    'Name'
    'SamAccountName'
    'UserPrincipalName'
    'EmailAddress'
    'EmailAddressCorporate'
    'GoogleID'
    'WorkForceID'
    'WhenCreated'
    'LastLogonDate'
    'MemberOf'
)

$StaleUserLDAPFilter = '(& (lastLogonTimestamp<={0}) (whenCreated<={1}) (!(userAccountControl:1.2.840.113556.1.4.803:=2)) )' -f @(
    (Get-Date).AddDays(-$UserLLDThreshold).Date.ToFileTime()
    (Get-Date).AddDays(-$UserWCrThreshold).Date.ToUniversalTime().ToString('yyyyMMddHHmmss.0Z')
)

$StaleComputerLDAPFilter = '(& (lastLogonTimestamp<={0}) (whenCreated<={1}) (!(userAccountControl:1.2.840.113556.1.4.803:=2)) )' -f @(
    (Get-Date).AddDays(-$ComputerLLDThreshold).Date.ToFileTime()
    (Get-Date).AddDays(-$ComputerWCrThreshold).Date.ToUniversalTime().ToString('yyyyMMddHHmmss.0Z')
)

$StaleGroupLDAPFilter = '(& (whenCreated<={0}) (whenChanged<={1}) (!(memberof=*)) (!(objectCategory=computer)))' -f @(
    (Get-Date).AddDays(-$GroupWCrThreshold).Date.ToUniversalTime().ToString('yyyyMMddHHmmss.0Z')
    (Get-Date).AddDays(-$GroupWChThreshold).Date.ToUniversalTime().ToString('yyyyMMddHHmmss.0Z')
)

#endregion Variables


#region Prep

if (-not (Test-Path -Path $GPO_BackupPath)) {
    New-Item -ItemType Directory -Path $GPO_BackupPath -Force | Out-Null
}

#endregion Prep


#region Generic Tests

#<#
function BackupGPO {
    param(
        $Domain,
        $Path = $GPO_BackupPath
    )
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Backing up GPOs..." -ForegroundColor Cyan

    # Backup All GPOs
    $Data = Backup-GPO -All -Server $Domain -Domain $Domain -Path "$Path" -Comment "$(Get-Date -Format yyyyMMdd_hhmmss)" -Verbose -ErrorAction SilentlyContinue

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[INFO] GPO backup completed: $($Data.count) GPOs"
    }
} # END function BackupGPO

function BackupADUsers {
    param(
        $Domain,
        $LDAPFilter = $BackupADUsersLDAPFilter
    )
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Backing up AD Users with $LDAPFilter..." -ForegroundColor Cyan

    $Data = Get-ADUser -LDAPFilter $LDAPFilter -Server $Domain -Properties * | 
        Select-Object $BackupADUsersAttributes

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[INFO] AD Users backup completed: $($Data.count) users"
    }
} # END function BackupADUsers


function GetStaleUsers {
    param(
        $Domain,
        $LDAPFilter = $StaleUserLDAPFilter
    )
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting Stale AD Users..." -ForegroundColor Cyan

    # Check for stale user accounts
    $Data = Get-ADUser -LDAPFilter $LDAPFilter -Server $Domain -Properties * | 
        Select-Object Name, SamAccountName, UserPrincipalName, EmailAddress, EmailAddressCorporate, GoogleID, WorkForceID, WhenCreated, WhenChanged, LastLogonDate, PasswordLastSet, MemberOf

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[ISSUE] Stale Users found: $($Data.count) users"
    }
} # END function GetStaleADUsers

function GetStaleComputers {
    param(
        $Domain,
        $LDAPFilter = $StaleComputerLDAPFilter
    )
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting Stale AD Computers..." -ForegroundColor Cyan

    # Check for stale computer accounts
    $Data = Get-ADComputer -LDAPFilter $LDAPFilter -Server $Domain -Properties * | 
        Select-Object Name, SamAccountName, DNSHostName, OperatingSystem, OperatingSystemVersion, WhenCreated, WhenChanged, LastLogonDate, PasswordLastSet

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[ISSUE] Stale Computers found: $($Data.count) computers"
    }
} # END function GetStaleADComputers

function GetStaleGroups {
    param(
        $Domain,
        $LDAPFilter = $StaleGroupLDAPFilter
    )
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting Stale AD Groups..." -ForegroundColor Cyan

    # Check for stale groups, no members and older than threshold
    $Data = Get-ADGroup -LDAPFilter $LDAPFilter -Server $Domain -Properties * | 
        Select-Object Name, SamAccountName, WhenCreated, WhenChanged, GroupCategory, GroupScope

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[ISSUE] Stale Groups found: $($Data.count) groups"
    }
} # END function GetStaleADGroups

function GetPwdNeverExpiresUsers {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting Password Never Expires AD Users..." -ForegroundColor Cyan

    # Users with passwords that never expire
    $Data = Get-ADUser -Filter { PasswordNeverExpires -eq $true } -Server $Domain -Properties * | 
        Select-Object Name, SamAccountName, UserPrincipalName, EmailAddress, EmailAddressCorporate, GoogleID, WorkForceID, WhenCreated, WhenChanged, LastLogonDate, PasswordLastSet, MemberOf

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[ISSUE] Password Never Expires for $($Data.count) users"
    }
} # END function GetPwdNeverExpiresADUsers

function GetPwdNotRequiredUsers {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting Password Not Required AD Users..." -ForegroundColor Cyan

    # Users with password not required
    $Data = Get-ADUser -Filter { PasswordNotRequired -eq $true -and samaccountname -notlike '*$' } -Server $Domain -Properties * | 
        Select-Object Name, SamAccountName, UserPrincipalName, EmailAddress, EmailAddressCorporate, GoogleID, WorkForceID, WhenCreated, WhenChanged, LastLogonDate, PasswordLastSet, MemberOf

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[ISSUE] Password Not Required for $($Data.count) users"
    }
} # END function GetPwdNotRequiredADUsers

function GetNoPwdSetUsers {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting Password Not Set AD Users..." -ForegroundColor Cyan

    $Data = Get-ADUser -Filter { PasswordLastSet -eq 0 } -Server $Domain -Properties * | 
        Select-Object Name, SamAccountName, UserPrincipalName, EmailAddress, EmailAddressCorporate, GoogleID, WorkForceID, WhenCreated, WhenChanged, LastLogonDate, PasswordLastSet, MemberOf

    return [PSCustomObject]@{
        ReportSummary = "[ISSUE] Password Not Set for $($Data.count) users"
        Report        = $Data
    }
} # END function GetNoPwdSetADUsers

function srvRecords {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Checking SRV Records..." -ForegroundColor Cyan

    $srvRecords = @(
        "_ldap._tcp.dc._msdcs.$Domain",
        "_kerberos._tcp.dc._msdcs.$Domain",
        "_ldap._tcp.gc._msdcs.$Domain",
        "_ldap._tcp.pdc._msdcs.$Domain"
    )

    $Data = @()
    $ReportSummary = @()
    foreach ($record in $srvRecords) {
        Remove-Variable dnsResult -ErrorAction SilentlyContinue
        Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] SRV Record: $record" -ForegroundColor DarkCyan

        try {
            $dnsResult = Resolve-DnsName -Name $record -Type SRV -ErrorAction Stop
            $Data += $dnsResult
        }
        catch {
            $ReportSummary += "[ISSUE] SRV Record $record not found. $_"
        }
    }

    if (!$ReportSummary) {
        $ReportSummary = "[$($MyInvocation.MyCommand.Name)] All Srv records found"
    }

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = $ReportSummary
    }
} # END function srvRecords
#> 

function OUs {
    param($Domain)
    $Data = @()
    $ReportSummary = @()

    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Checking OUs..." -ForegroundColor Cyan

    $OUs = Get-ADOrganizationalUnit -Filter * -Properties * -Server $Domain
    $DomainDN = 'DC=' + ($Domain.split('.') -join ',DC=')

    $SkipIdentitySources = @(
        'NT AUTHORITY'
        'BUILTIN'
    )

    $SkipIdentities = @(
        'S-1-5-32-554'
        'S-1-5-32-548'
        'Enterprise Admins'
        'Domain Admins'
        'Enterprise Key Admins'
        'Key Admins'
        'Everyone'
        'CREATOR OWNER'
        'SELF'
    )

    $Data = $OUs | Select-Object DistinguishedName, CanonicalName, Name, WhenCreated, WhenChanged, @{n = 'Issues'; e = { @() } }

    for ($i = 0; $i -lt $Data.count; $i++) {
        Remove-Variable ADObjects, NonGroupPerms -ErrorAction SilentlyContinue
        $OU = $Data[$i]
        $Data[$i].Issues = @()
        Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] $($OU.DistinguishedName)" -ForegroundColor DarkCyan


        # No Objects in OU
        $ADObjects = Get-ADObject -SearchBase $OU.DistinguishedName -Filter * -SearchScope OneLevel -ResultSetSize 1
        if ($ADObjects.count -eq 0) {
            $OU.Issues += '[ISSUE] No Objects in OU'
        }

        # Owner
        if ($OU.nTSecurityDescriptor.Owner -notlike '*\Domain Admins') {
            $OU.Issues += "[ISSUE] non-DA owner: $($OU.nTSecurityDescriptor.Owner)"
        }

        # Permissions
        $NonGroupPerms = $OU.nTSecurityDescriptor.Access.Where({
                if ($_.IdentityReference.ToString() -like '*\*') {
                    $Source, $Identity = $_.IdentityReference.ToString().Split('\').Trim()
                }
                else {
                    $Source = $null
                    $Identity = $_.IdentityReference.ToString().Trim()
                }
                !$_.IsInherited -and
                $_.IdentityReference.Value -notlike '*\AD*' -and
                -not ($SkipIdentitySources -icontains $Source -or $SkipIdentities -icontains $Identity)
            }).IdentityReference.Value | Sort-Object -Unique

        $OU.Issues += "[ISSUE] Non Group Permissions: $($NonGroupPerms -join ', ')"

        $OU.Issues = $OU.Issues -join "`n"
    }

    $Data = $Data.Where({ $_.Issues.count -gt 0 })
    if ($Data.Count -gt 0) {
        $ReportSummary = "[ISSUE] $($Data.Count) OUs with $($Data.Issues.Split("`n").Count) Total Issues"

        return [PSCustomObject]@{
            Report        = $Data
            ReportSummary = $ReportSummary
        }
    }
} # END function OUs


#region GPO Tests

function GPOs {
    param(
        $Domain
    )
    $Data = @()
    $DomainPrefix = $Domain.split('.')[0].Trim()
    # Get GPOs
    $GPOs = Get-GPO -All -Server $Domain -Domain $Domain
    $gTotal = $GPOs.Count
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Evaluating $gTotal GPOs..." -ForegroundColor Cyan

    $g = 0
    foreach ($GPO in $GPOs) {
        Remove-Variable GPOReportXML, GPOSettings, ACL, AllowApplyPerms, DenyApplyPerms, AuthUsers, NameConfigIdentifiers, DisabledLinks, SecPrincipalsExclusions, ExclusionsForNaming, SecPrincipals, ImproperlyNamedSecPrincipals -ErrorAction SilentlyContinue
        $g ++
        $Issues = @()

        Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] $g/$gTotal GPO: $($GPO.DisplayName)" -ForegroundColor DarkCyan

        # Get GPO Information
        $GPOReportXML = Get-GPOReport -Id $GPO.Id -Domain $Domain -Server $Domain -ReportType XML
        $GPOSettings = [xml]$GPOReportXML
        $ACL = (New-Object System.DirectoryServices.DirectoryEntry("LDAP://$($GPO.Path)")).ObjectSecurity
        [array]$AllowApplyPerms = $ACL.Access | Where-Object { $_.ObjectType.Guid -eq 'edacfd8f-ffb3-11d1-b41d-00a0c968f939' -and $_.AccessControlType -eq 'Allow' }
        [array]$DenyApplyPerms = $ACL.Access | Where-Object { $_.ObjectType.Guid -eq 'edacfd8f-ffb3-11d1-b41d-00a0c968f939' -and $_.AccessControlType -eq 'Deny' }
        [array]$AuthUsers = $ACL.Access | Where-Object -FilterScript { $_.IdentityReference.Value -eq 'NT AUTHORITY\Authenticated Users' }
        [array]$DefaultEditPerms = @(
            'CREATOR OWNER'
            'NT AUTHORITY\SYSTEM'
            "$DomainPrefix\Enterprise Admins"
            "$DomainPrefix\Domain Admins"
        )
        [array]$CustomEditPerms = $ACL.Access | Where-Object { $_.ObjectType.Guid -eq '00000000-0000-0000-0000-000000000000' -and $_.AccessControlType -eq 'Allow' -and $_.ActiveDirectoryRights -like '*WriteProperty*' -and $DefaultEditPerms -notcontains $_.IdentityReference.Value }
        [string]$NameConfigIdentifiers = $GPO.DisplayName.split('-').Trim()[-1].Where({ $_.Length -lt 8 })

        
        $FilePaths = ($GPOReportXML.split("`n").trim() -imatch '>([A-Z]{1}:\\|\\)[\\ -_0-9a-z]{1,}\.[0-9a-z]{1,}').foreach({ $_.split('>')[1].split('<')[0].Trim() })

        # Disabled Links from GPOReport
        $DisabledLinks = $GPOSettings.LinksTo | Where-Object -FilterScript { $_.Enabled -eq 'false' }
        if ($DisabledLinks.Count -gt 0) {
            $Issues += "[ISSUE] Disabled Links: $($DisabledLinks.SOMPath -join ', ')"
        }

        # MisMatch Computer Version
        if ($GPO.Computer.DSVersion -ne $GPO.Computer.SysvolVersion) {
            $Issues += "[ISSUE] Computer Version Mismatch DS:$($GPO.Computer.DSVersion) SY:$($GPO.Computer.SysvolVersion)"
        }

        # MisMatch User Version
        if ($GPO.User.DSVersion -ne $GPO.User.SysvolVersion) {
            $Issues += "[ISSUE] User Version Mismatch DS:$($GPO.User.DSVersion) SY:$($GPO.User.SysvolVersion)"
        }

        # Stale LinkLess GPOs?
        if (
            ($GPO.ModificationTime -lt (Get-Date).AddDays(-$GPOWChThreshold)) -and
            ($GPO.CreationTime -lt (Get-Date).AddDays(-$GPOWCrThreshold)) -and
            $GPOSettings.GPO.LinksTo.Count -eq 0
        ) {
            $Issues += '[ISSUE] Stale LinkLess GPO'
        }

        # Stale SettingLess GPOs?
        if (
            ($GPO.ModificationTime -lt (Get-Date).AddDays(-$GPOWChThreshold)) -and
            ($GPO.CreationTime -lt (Get-Date).AddDays(-$GPOWCrThreshold)) -and
            ![Bool]$GPOSettings.GPO.User.ExtensionData -and
            ![Bool]$GPOSettings.GPO.Computer.ExtensionData
        ) {
            $Issues += '[ISSUE] Stale Settingless GPO'
        }
        # All Settings Disabled
        elseif ($GPO.GpoStatus -eq 'AllSettingsDisabled') {
            $Issues += '[ISSUE] GPO Disabled'
        }
        # User Settings Configured but User Settings Disabled
        elseif ([Bool]$GPOSettings.GPO.User.ExtensionData -and $GPOSettings.GPO.User.Enabled -eq 'false') {
            $Issues += '[ISSUE] User Settings Configured but Disabled'
        }
        # Computer Settings Configured but Computer Settings Disabled
        elseif ([Bool]$GPOSettings.GPO.Computer.ExtensionData -and $GPOSettings.GPO.Computer.Enabled -eq 'false') {
            $Issues += '[ISSUE] Computer Settings Configured but Disabled'
        }
        # User Settings Enabled but No User Settings Configured
        elseif (![Bool]$GPOSettings.GPO.User.ExtensionData -and $GPOSettings.GPO.User.Enabled -eq 'true') {
            $Issues += '[ISSUE] No User Settings Configured but Enabled'
        }
        # Computer Settings Enabled but No Computer Settings Configured
        elseif (![Bool]$GPOSettings.GPO.Computer.ExtensionData -and $GPOSettings.GPO.Computer.Enabled -eq 'true') {
            $Issues += '[ISSUE] No Computer Settings Configured but Enabled'
        }

        # No Allow Apply Permission
        if ($AllowApplyPerms.Count -eq 0) {
            $Issues += '[ISSUE] No Apply Permission for GPO'
        }
        else {
            # Non Default Security Filtering - make sure GPO suffix is has S
            if (($AllowApplyPerms.Count -gt 1 -or !$AllowApplyPerms.IdentityReference.Value.Contains('NT AUTHORITY\Authenticated Users')) -and $NameConfigIdentifiers -notlike '*S*') {
                $Issues += '[ISSUE] Non Default Security Filtering but GPO name missing S suffix'
                if (@($AllowApplyPerms.Where({ $_.IdentityReference -notlike '* - Apply' })).count -gt 0) {
                    $Issues += '[ISSUE] Apply Security Principals don''t have naming standard'
                }
            }

            # If has Deny Apply - make sure GPO suffix has D
            if ($DenyApplyPerms.Count -gt 0) {
                if ($NameConfigIdentifiers -notlike '*D*') {
                    $Issues += '[ISSUE] Deny Apply present but GPO name missing D suffix'
                }
                if (@($DenyApplyPerms.Where({ $_.IdentityReference -notlike '* - Deny Apply' })).count -gt 0) {
                    $Issues += '[ISSUE] Deny Apply Security Principals don''t have naming standard'
                }
            }
        }

        if ($AllowEditPerms.Count -eq 0) {
            $Issues += '[ISSUE] No Edit Permission for GPO'
        }

        # No Auth Users Read Permission
        if ($AuthUsers.Count -eq 0 -or (!([string[]]$AuthUsers.ActiveDirectoryRights).contains('GenericRead') -and !([string[]]$AuthUsers.ActiveDirectoryRights).contains('ReadProperty, GenericExecute'))) {
            $Issues += '[ISSUE] No Auth Users Read Permission for GPO'
        }

        # Wrong Owner
        if ($ACL.Owner -notlike '*\Domain Admins') {
            $Issues += "[ISSUE] non-DA owner: $($ACL.Owner)"
        }

        # No SysVol Folder
        if (-not (Test-Path -Path "\\$Domain\sysvol\$Domain\Policies\{$($GPO.Id)}")) {
            $Issues += '[ISSUE] No SysVol Folder for GPO'
        } 

        # If has WMI Filter - make sure GPO suffix has W
        if ([Bool]$GPO.WMIFilter.Name -and $NameConfigIdentifiers -like '*W*') {
            $Issues += '[ISSUE] WMI Filter present but GPO name missing W suffix'
        }

        # If has Loopback - make sure GPO suffix has L
        if ($GPOReportXML -match 'Configure user Group Policy loopback processing mode' -and $NameConfigIdentifiers -notlike '*L*') {
            $Issues += '[ISSUE] Loopback present but GPO name missing L suffix'
        }

        # If has changed Refresh Interval - make sure GPO suffix has I
        if ($GPOReportXML -match 'Set Group Policy refresh interval for' -and $NameConfigIdentifiers -notlike '*I*') {
            $Issues += '[ISSUE] Custom Refresh Interval but GPO name missing I suffix'
        }

        # If Improperly Named groups in GPO
        $SecPrincipalsExclusions = @(
            'Domain Admins'
        )
        [array]$SecPrincipals = [regex]::Matches(
            ($GPOReportXML.split("`n").Trim() -match "$DomainPrefix\\" -join "`n"),
            "(<|`")$DomainPrefix\\[A-Za-z \-_]{1,}(>|`")"
        ).Value
        if ($SecPrincipals.count -gt 0) {
            $ImproperlyNamedSecPrincipals = $SecPrincipals.TrimStart('"').TrimEnd('"').Where({ $_ -notlike "$DomainPrefix\GPO - *" -and $SecPrincipalsExclusions -notcontains $_.split('\')[1].Trim() })
            if ($ImproperlyNamedSecPrincipals.Count -gt 0) {
                $Issues += "[ISSUE] Improperly Named Security Principals: $($ImproperlyNamedSecPrincipals -join ', ')"
            }
        }

        if (![Bool]$GPO.Description) {
            $Issues += '[ISSUE] Missing GPO Description'
        }
        elseif ($GPO.Description -notlike '*Purpose:*') {
            $Issues += '[ISSUE] GPO Description Missing Purpose:'
        }

        $ExclusionsForNaming = @(
            'Default Domain Controllers Policy'
            'Default Domain Policy'
            'Tier Model Data Collector - S'
        )
        if ($ExclusionsForNaming -notcontains $GPO.DisplayName) {
            if ($GPO.DisplayName -notlike '* - *') {
                $Issues += '[ISSUE] GPO Name not following naming convention'
            }

            if ($GPO.DisplayName -notmatch '(Endpoint|User|Server|Enterprise)') {
                $Issues += '[ISSUE] GPO Name missing Scope'
            }
        }

        # If has custom ADM - make sure GPO suffix has A
        #if ( ??? -and $NameConfigIdentifiers -notlike '*A*') {
        #    $Issues += '[ISSUE] Custom ADM present but GPO name missing A suffix'
        #}

        # If has Preferences - make sure GPO suffix has P
        #if ( ??? -and $NameConfigIdentifiers -notlike '*P*') {
        #    $Issues += '[ISSUE] Preferences present but GPO name missing P suffix'
        #}


        if ($Issues.count -gt 0) {
            $Data += [PSCustomObject]@{
                GPO    = $GPO.DisplayName
                GUID   = $GPO.Id
                Issues = $Issues -join "`n"
            }
        }
    }

    $ReportSummary = "[$($MyInvocation.MyCommand.Name)] $($Data.Count) GPOs with $($Data.Issues.Split("`n").Count) Total Issues"
    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = $ReportSummary
    }
} # END function GPOs

function GPOOrphanedFolders {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting Orphaned GPO Folders..." -ForegroundColor Cyan

    [array]$Data = Get-ChildItem -Path \\$Domain\sysvol\$Domain\Policies -Filter *-*-*-* | 
        ForEach-Object -Process {
            [PSCustomObject]@{
                Path    = $_.FullName
                GUID    = $_.BaseName
                GPOName = (Get-GPO -Guid "$($_.BaseName)" -Server $Domain -Domain $Domain -ErrorAction SilentlyContinue).DisplayName
            }
        } |
        Where-Object -FilterScript { ![Bool]$_.GPOName }

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[$($MyInvocation.MyCommand.Name)] Orphaned GPO Folders found: $($Data.count) folders"
    }
} # END function GPOOrphanedFolders

function GPOConflictFolders {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Getting GPO Conflict Folders..." -ForegroundColor Cyan

    $Data = Get-ChildItem -Path \\$Domain\SYSVOL\$Domain -Filter *ntfrs_* -Recurse -Force | 
        Select-Object -Property FullName, CreationTime, LastAccessTime, LastWriteTime

    return [PSCustomObject]@{
        Report        = $Data
        ReportSummary = "[ISSUE] GPO Conflict Folders found: $($Data.count) folders"
    }
} # END function GPOConflictFolders

#endregion GPO Tests


#region ADSS Tests

function ADSS_Sites {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Checking ADSS Sites..." -ForegroundColor Cyan
    
    $Data = @()
    $ReportSummary = @()

    [array]$Sites = Get-ADReplicationSite -Filter * -Properties * -Server $Domain
    $Data = $Sites | Select-Object Name, WhenCreated, WhenChanged, @{n = 'Issues'; e = { @() } }

    for ($i = 0; $i -lt $Data.count; $i++) {
        Remove-Variable SiteDCs, dnsResult -ErrorAction SilentlyContinue -Force
        $Site = $Sites[$i]
        $Entry = $Data[$i]
        Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Site: $($Entry.Name)..." -ForegroundColor DarkCyan
        $Entry.Issues = @()
        
        # Has Subnets
        if ($Site.Subnets.count -eq 0) {
            $Entry.Issues += '[ISSUE] No Subnets in Site'
        }

        # Has DCs
        [array]$SiteDCs = Get-ADDomainController -Filter ('Site -eq "{0}"' -f $Site.Name) -Server $Domain
        if ($SiteDCs.count -eq 0) {
            $Entry.Issues += '[ISSUE] No Domain Controllers in Site'
        }

        # Has SRV Record
        try {
            [array]$dnsResult = Resolve-DnsName -Name "_ldap._tcp.$($Site.Name)._sites.dc._msdcs.$Domain" -Type SRV -ErrorAction Stop
        }
        catch {
            $Entry.Issues += "[ISSUE] Failed to Query DNS for AD SS Site SRV Records. $_"
        }
        
        if ($dnsResult.count -eq 0) {
            $Entry.Issues += '[ISSUE] No AD SS Site SRV Records'
        }
        else {
            foreach ($DC in $SiteDCs) {
                if ($dnsResult.NameTarget -notcontains $DC.HostName) {
                    $Entry.Issues += "[ISSUE] No AD SS Site $($Site.Name) SRV Record for $($DC.hostname)"
                }
            }
        }

        $Entry.Issues = $Entry.Issues -join "`n"
    }

    $Data = $Data.Where({ $_.Issues.count -gt 0 })
    if ($Data.Count -gt 0) {
        $ReportSummary = "[ISSUE] $($Data.Count) ADSS Sites with $($Data.Issues.Split("`n").Count) Total Issues"

        return [PSCustomObject]@{
            Report        = $Data
            ReportSummary = $ReportSummary
        }
    }
} # END function ADSS_Sites


function ADSS_SiteLinks {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Checking ADSS Site Links..." -ForegroundColor Cyan
    
    $Data = @()
    $ReportSummary = @()

    [array]$SiteLinks = Get-ADReplicationSiteLink -Filter * -Properties * -Server $Domain
    $Data = $SiteLinks | Select-Object Name, WhenCreated, WhenChanged, options, @{n = 'Issues'; e = { @() } }

    for ($i = 0; $i -lt $Data.count; $i++) {
        Remove-Variable SiteLink -ErrorAction SilentlyContinue -Force
        $SiteLink = $SiteLinks[$i]
        $Data[$i].Issues = @()
        Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Site: $($SiteLink.Name)..." -ForegroundColor DarkCyan

        # USE_NOTIFY
        if ($SiteLink.options -ne 1) {
            $Data[$i].Issues += "[ISSUE] SiteLink deosn't have USE_NOTIFY turned on"
        }

        # Has Sites
        if ($SiteLink.siteList.count -eq 0) {
            $Data[$i].Issues += '[ISSUE] SiteLink has no Sites'
        }

        # Replication Frequency In Minutes
        if ($SiteLink.ReplicationFrequencyInMinutes -ne 15) {
            $Data[$i].Issues += '[ISSUE] SiteLink Replication not 15 minutes'
        }
        $Data[$i].Issues = $Data[$i].Issues -join "`n"
    }

    $Data = $Data.Where({ $_.Issues.count -gt 0 })
    if ($Data.Count -gt 0) {
        $ReportSummary = "[ISSUE] $($Data.Count) SiteLinks with $($Data.Issues.Split("`n").Count) Total Issues"

        return [PSCustomObject]@{
            Report        = $Data
            ReportSummary = $ReportSummary
        }
    }

} # END function ADSS_SiteLinks


#endregion ADSS Tests


#region SPN Tests

function SPNs {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Checking SPNs..." -ForegroundColor Cyan
    
    $Data = (setspn.exe -X -F -T $Domain -P).Trim()

    $DuplicateGroupsCount = [int][regex]::Match(($Data -imatch 'duplicate'), '[0-9]{1,}').Value

    if ($DuplicateGroupsCount -gt 0) {
        return [PSCustomObject]@{
            Report        = $Data
            ReportSummary = "[ISSUE] $DuplicateGroupsCount Duplicate SPNs found"
        }
    }

    return $null
}

#endregion SPN Tests


#endregion Generic Tests


#region Specific Tests

$PrivilegedGroupsOU = 'OU=Administrative Roles,OU=Privileged,OU=CSH Groups,DC=Corp,DC=Commonspirit,DC=org'
function CSH_PrivilegedGroups {
    param($Domain)
    $Data = @()
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Checking CSH Privileged Groups..." -ForegroundColor Cyan

    $PrivilegedGroups = Get-ADGroup -SearchBase $PrivilegedGroupsOU -Filter * -Server $Domain -Properties members, memberof, whencreated, whenchanged

    foreach ($PrivGroup in $PrivilegedGroups) {
        Remove-Variable PrivGroupMembers -ErrorAction SilentlyContinue
        $Issues = @()

        Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Group: $($PrivGroup.SamAccountName)" -ForegroundColor DarkCyan
        
        if ($PrivGroup.Members.Count -eq 0) {
            if ($PrivGroup.whencreated -lt (Get-Date).AddDays(-$GroupWCrThreshold)) {
                if ($PrivGroup.whenChanged -lt (Get-Date).AddDays(-$GroupWChThreshold)) {
                    $Issues += "[ISSUE] '$($PrivGroup.SamAccountName)' is stale for 90+ days and has no members."
                }
            }
        }
        else {
            if (@($PrivGroup.Members -match 'CN=ForeignSecurityPrincipals').count -gt 0) {
                $Issues += "[ISSUE] '$($PrivGroup.SamAccountName)' has $(@($PrivGroup.Members -match 'CN=ForeignSecurityPrincipals').count) Members that are from external domains."
            }
            else {
                [array]$PrivGroupMembers = Get-ADGroupMember -Identity $PrivGroup.SamAccountName -Server $Domain
                [array]$PrivGroupMembersSubGroups = $PrivGroupMembers.Where({ $_.objectClass -eq 'group' })
                if ($PrivGroupMembersSubGroups.count -gt 0) {
                    $Issues += "[ISSUE] '$($PrivGroup.SamAccountName)' has $($PrivGroupMembersSubGroups.count) Members that are Groups"
                }
            }
        }

        if ($PrivGroup.MemberOf.Length -gt 0) {
            $Issues += "[ISSUE] '$($PrivGroup.SamAccountName)' has no permissions."
        }

        if ($Issues.count -gt 0) {
            $Data += [PSCustomObject]@{
                Group  = $PrivGroup.SamAccountName
                Issues = $Issues -join "`n"
            }
        }
    }

    if ($Data.count -gt 0) {
        $ReportSummary = "[ISSUE] $($Data.count) Groups with $($Data.Issues.Split("`n").Count) Issues"

        return [PSCustomObject]@{
            Report        = $Data
            ReportSummary = $ReportSummary
        }
    }
} # END function CSH_PrivilegedGroups

function ManagedGroups {
    param($Domain)
    Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Checking Managed Groups..." -ForegroundColor Cyan

    $Data = @()
    $Groups = Get-ADGroup -LDAPFilter '(managedby=*)' -Properties managedby, nTSecurityDescriptor -Server $Domain

    foreach ($Group in $Groups) {
        Remove-Variable ManagedByOBject, ACE -ErrorAction SilentlyContinue
        $Issues = @()

        Write-Host "[$(Get-Date)] ($Domain) [$($MyInvocation.MyCommand.Name)] Group: $($Group.SamAccountName)" -ForegroundColor DarkCyan

        $ManagedByOBject = Get-ADObject $Group.ManagedBy -Properties samaccountname, ObjectClass
        if ($ManagedByOBject.ObjectClass -ne 'group') {
            $Issues += 'Manager not a group'
        }
        elseif ($ManagedByOBject.samaccountname -notlike 'AD - *') {
            $Issues += 'Manager not properly named'
        }

        $ACE = $Group.nTSecurityDescriptor.Access.Where({ $_.IdentityReference.Value -like "*$($ManagedByOBject.samaccountname)" -and $_.ObjectType -eq [guid]'bf9679c0-0de6-11d0-a285-00aa003049e2' -and $_.AccessControlType -eq 'Allow' -and $_.ActiveDirectoryRights -eq 'WriteProperty' })
        if (![bool]$ACE) {
            $Issues += 'Manager Cannot Update Membership'
        }

        if ($Issues.count -gt 0) {
            $Data += [PSCustomObject]@{
                Group  = $Group.SamAccountName
                Issues = $Issues -join "`n"
            }
        }
    }

    if ($Data.Count -gt 0) {
        $ReportSummary = "[ISSUE] $($Data.Count) Managed Groups with $($Data.Issues.Split("`n").Count) Total Issues"

        return [PSCustomObject]@{
            Report        = $Data
            ReportSummary = $ReportSummary
        }
    }
} # END function ManagedGroups

#endregion Specific Tests