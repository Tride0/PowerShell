<#
    Created By: Kyle Hewitt
    Created On: 4/30/2019
    Version: 2022.8.29
    Name: AD Report
#>

Param(
    $SMTPServer = 'smtprelay.address.com',
    $Port = 25,
    $From = 'AD-Checker@address.com',
    $To = @(
        'email@address.com'
    ),
    $Subject = "AD Report $Start",

    $ExportRoot = "$PSScriptRoot\Reports\$(Get-Date -Format yyyy\\MM\\dd)".Replace(':', '$'),

    [String[]]$SkipDCs = ''
)
Begin {

    #region Setup

    $Start = [DateTime]::Now
    #Date Format Variable to use for export files
    $Date = Get-Date -Format yyyyMMdd
    $Global:MailBody = $()

    Import-Module -Name GroupPolicy, ActiveDirectory -ErrorAction Stop

    # Current Domain
    [Array]$Domains = [DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name

    # All Domains
    #$Domains = ([Array][DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name +
    #[Array][DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().Domains.Name +
    #[Array][DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().GetAllTrustRelationships().TargetName +
    #[Array][DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest().GetAllTrustRelationships().TargetName) | Get-Unique

    If ($ExportRoot -notlike '\\*') {
        $ExportRoot = "\\$ENV:ComputerName\$($ExportRoot.Replace(':','$'))"
    }
    [Void] (New-Item -Path $ExportRoot -ItemType Directory -Force)

    #endregion Setup


    #region Functions

    Function SendOut {
        Param(
            [Array]$Info,
            $Title, 
            $Threshold,
            $FileType = 'csv'
        )
        $Path = "$ExportRoot\$Domain`_$Title`_$Date.$FileType"
        $Link = "<a href='$Path'>$Date.$FileType</a>"
        If (![Bool]$Info -or $Info -eq $Null -or $Info.Count -eq 0) {
            $Global:MailBody += "$Domain $Title`: 0<br /><br />"
        }
        ElseIf ($Info.GetType().Name -eq 'ErrorRecord' -or $Info.GetType().Name -like '*Int*' -or ($Info.Gettype().Name -eq 'String' -and $Info.split("`n").Count -le 1)) {
            $Global:MailBody += "$Domain $Title`: $Info - $($Info.ScriptStackTrace)<br /><br />"
        }
        ElseIf ($Title -eq 'SPN_Duplicate') {
            If ($Info.Count -gt $Threshold) {
                $Global:MailBody += "$Domain $Title ($(($info -like '*:*').Count)): $Link<br /><br />"
                Set-Content -Value $Info -Path $Path -Force
            }
            Else {
                $Global:MailBody += "$Domain $Title`: 0<br /><br />"
            }
        }
        ElseIf ($Info.Count -gt $Threshold) {
            $Global:MailBody += "$Domain $Title ($($info.Count)): $Link<br /><br />"
            If ($FileType -eq 'csv') {
                $Info | Export-Csv $Path -NoTypeInformation -Force
            }
            Else {
                Set-Content -Value $Info -Path $Path -Force
            }
        }
        Else {
            $Global:MailBody += "$Domain $Title`: $($Info.Count)<br /><br />"
        }
    }

    Function ForEach-Parallel {
        param
        (
            [Parameter(Mandatory = $True, position = 0)]
            [System.Management.Automation.ScriptBlock] $ScriptBlock,

            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            [PSObject]$InputObject,

            [Parameter(Mandatory = $False)]
            [int]$MaxThreads = ([wmisearcher]'SELECT NumberOfLogicalProcessors FROM Win32_ComputerSystem').Get().NumberOfLogicalProcessors + 1,

            [Parameter(Mandatory = $False)]
            $Parameters = @{}
        )

        Begin {
            $iss = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
            $pool = [Runspacefactory]::CreateRunspacePool(1, $maxthreads, $iss, $host)
            $pool.open()
            $threads = @()
        }

        Process {
            $Run = $True
            
            # Skips if Exempt
            If ($SkipDCs -contains $_) {
                $Run = $False
            }

            # Skips Server if it is not Pingable
            If ($Run) {
                Try { $PingStatus = (New-Object System.Net.NetworkInformation.Ping).Send($_, 1000).Status }
                Catch { $PingStatus = 'Failed' }
                If ($PingStatus -ne 'Success') {
                    $Run = $False
                }
            }

            # Checks for Access to Machine
            If ($Run) {
                $AccessStatus = [System.IO.Directory]::Exists("\\$_\admin$")
                If (!$AccessStatus) {
                    $Run = $False
                }
            }

            If ($Run) {
                $Parameters.Computer = $_
                
                $powershell = [powershell]::Create().addscript($scriptblock).AddParameters($Parameters)
                $powershell.runspacepool = $pool
                $threads += @{
                    instance = $powershell
                    handle   = $powershell.begininvoke()
                }
            }
        }

        End {
            $notdone = $true
            while ($notdone) {
                $notdone = $false
                for ($i = 0; $i -lt $threads.count; $i++) {
                    $thread = $threads[$i]
                    if ($thread) {
                        if ($thread.handle.iscompleted) {
                            $thread.instance.endinvoke($thread.handle)
                            $thread.instance.dispose()
                            $threads[$i] = $null
                        }
                        else {
                            $notdone = $true
                        }
                    }
                }
            }
        }
    }

    Function Test-PendingReboot {
        [cmdletbinding()]
        Param($Computer)
        $PendingReboot = $false
        Try {
            $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"
            if ($WMI_Reg) {
                If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\')).sNames -contains 'RebootPending') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\')).sNames -contains 'RebootRequired') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Control\Session Manager\')).sNames -contains 'PendingFileRenameOperations') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Services\Netlogon\')).sNames -contains 'AvoidSpnSet') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Services\Netlogon\')).sNames -contains 'JoinDomain') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update')).sNames -contains 'RebootRequired') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update')).sNames -contains 'PostRebootReporting') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce')).sNames -contains 'DVDRebootSignal') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'Software\Microsoft\Windows\CurrentVersion\Component Based Servicing')).sNames -contains 'RebootPending') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'Software\Microsoft\Windows\CurrentVersion\Component Based Servicing')).sNames -contains 'RebootInProgress') { $PendingReboot = $true }
                If (($WMI_Reg.EnumKey('2147483650', 'SOFTWARE\Microsoft\ServerManager')).sNames -contains 'CurrentRebootAttempts') { $PendingReboot = $true }

                $Check = $WMI_Reg.GetDWORDValue('2147483650', 'SOFTWARE\Microsoft\Updates', 'UpdateExeVolatile')
                If ($Check.ReturnValue -eq 0 -and [Bool]$Check.uValue -and $Check.uValue -ne 0) { $PendingReboot = $True }
                
                $WMI_Reg.EnumKey('2147483650', 'SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations2').sNames | 
                    ForEach-Object -Process {
                        If ($WMI_Reg.GetDWORDValue('2147483650', 'SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations2', $_).uValue -like '*Pending*') { $PendingReboot = $True }
                    }

            ($WMI_Reg.EnumKey('2147483650', 'SYSTEM').snames -like 'ControlSet*') |
                    ForEach-Object -Process {
                        $MainKey = "SYSTEM\$_\Control\Session Manager\"
                        If ($WMI_Reg.EnumKey('2147483650', $MainKey).snames -contains 'PendingFileRenameOperations') { $PendingReboot = $True }

                        $WMI_Reg.EnumKey('2147483650', "$MainKey\PendingFileRenameOperations2").sNames | 
                            ForEach-Object -Process {
                                If ($WMI_Reg.GetDWORDValue('2147483650', "$MainKey\PendingFileRenameOperations2", $_).uValue -like '*Pending*') { $PendingReboot = $True }
                            }
                        }

                Try {
                    If (([WmiClass]"\\$Computer\ROOT\CCM\ClientSDK:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending -eq 'True') { $PendingReboot = $true }   
                }
                Catch {}
    
                Return $PendingReboot
            }
            Else { 'Cant Get to WMI.' }
        }
        Catch { "$_" }
    }

    #region The Work of It

    $Parameters = @{
        Computer         = ''
        ExportPath       = ''
        NetlogonFilePath = 'c$\Windows\debug\netlogon.log'
        DaysOld          = 7
    }

    $ScriptBlock = {
        Param(
            $Computer,
            $ExportPath,
            $NetlogonFilePath,
            $DaysOld
        )
        
        $FullNetlogonPath = "\\$Computer\$($NetlogonFilePath)"
        If (Test-Path $FullNetlogonPath) {
            If ((Get-Content -TotalCount 1 -Path $FullNetlogonPath).Split(' ').Count -eq 6) {
                # Gets Data
                Import-Csv -Path $FullNetlogonPath -Delimiter ' ' -Header 'Date', 'Time', 'Domain', 'Error', 'Host', 'IP' |
                    # Filters out any non NO_CLIENT_SITE entries and any entries older than $DaysOld
                    Where-Object -FilterScript { $_.IP -notlike '169.254.*' -and $_.Error -like '*NO_CLIENT_SITE*' -and (([DateTime]$_.Date -gt [DateTime]::Now.AddDays(-$DaysOld) -and [DateTime]$_.Date -lt [DateTime]::Now)) } | 
                    # Selects Unique IPS
                    Select-Object -Property @{Name = 'MissingSubnet'; Expression = { "$($_.IP) - $($_.Host)" } } | 
                    Select-Object -ExpandProperty MissingSubnet -Unique |
                    # Adds Content to Export File
                    Add-Content -Path $ExportPath -Force
            }
            Else {
                # Gets Data
                Import-Csv -Path $FullNetlogonPath -Delimiter ' ' -Header 'Date', 'Time', 'Error', 'Host', 'IP' |
                    # Filters out any non NO_CLIENT_SITE entries and any entries older than $DaysOld
                    Where-Object -FilterScript { $_.IP -notlike '169.254.*' -and $_.Error -like '*NO_CLIENT_SITE*' -and (([DateTime]$_.Date -gt [DateTime]::Now.AddDays(-$DaysOld) -and [DateTime]$_.Date -lt [DateTime]::Now)) } | 
                    # Selects Unique IPS
                    Select-Object -Property @{Name = 'MissingSubnet'; Expression = { "$($_.IP) - $($_.Host)" } } |
                    Select-Object -ExpandProperty MissingSubnet -Unique |
                    # Adds Content to Export File
                    Add-Content -Path $ExportPath -Force
            }
        }
    }

    #endregion The Work of It

    #endregion Functions

}
Process {
    :Domains Foreach ($Domain in $Domains) {
        Remove-Variable ExportPath, DCOU, DCs, DC -ErrorAction SilentlyContinue

        Write-Host "Domain: $Domain"

        $ADSearcher = [DirectoryServices.DirectorySearcher]@{
            PageSize = 3
        }

        If (![Bool]$Domain) { Continue Domains }
        Try {
            If (!([System.IO.Directory]::Exists("\\$Domain\SYSVOL"))) {
                $Global:MailBody += "<br />----- $Domain -----<br />Unable to reach \\$Domain\SYSVOL.<br /><br />"
                Continue Domains 
            }
            Else {
                $Global:MailBody += "<br />----- $Domain -----<br /><br />"
            }
        }
        Catch {
            $Global:MailBody += "<br />----- $Domain -----<br />$_ to \\$Domain\SYSVOL.<br /><br />"
            Continue Domains
        }

        $Root = "DC=$($Domain.Split('.') -join ',DC=')"
        $DCOU = "OU=Domain Controllers,$($Root.Trim())"
        $ADSearcher.SearchRoot.Path = "LDAP://$DCOU"
        $ADSearcher.Filter = '(objectclass=Computer)'
        [Void] $ADSearcher.PropertiesToLoad.Add('name')

        # Get all DCs of the domain
        [String[]]$DCs = $ADSearcher.FindAll().Properties.name

        # Reset AD Searcher
        $ADSearcher.SearchRoot.Path = "LDAP://$Root"
        $ADSearcher.PropertiesToLoad.Clear()

        # Gets the Domain
        $DomainDirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Domain', $Domain)
        $ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainDirectoryContext)

        # Gets the Domain's Forest
        $ForestDirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Forest', $ADDomain.Forest)
        $ADForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ForestDirectoryContext)

        # Gets Forest's AD Sites
        $ADSSSites = $ADForest.Sites

        # Gets all the Domains GPOs
        $GPOs = [Microsoft.GroupPolicy.GPDomain]::new("$Domain").GetAllGpos()

        # Query AD Root for OUs
        $ADSearcher.Filter = '(|(objectclass=organizationalUnit)(objectclass=container)(objectclass=Builtin)(objectclass=Builtindomain)(objectclass=domainDNS))'
        $OUs = $ADSearcher.FindAll()

        # Get a random DNS Server
        $DNSServer = (nslookup -type=ns $Domain) | 
            Where-Object -FilterScript { $_ -like '* = *' } |
            ForEach-Object -Process { 
                If ($_ -like '*nameserver*' -or $_ -like '*primary*') {
                    $ns = $_.Split('=')[1]    
                }
                Elseif ($_ -like '*internet address*') {
                    $ns = $_.Split(' ')[0]
                }
                If ([boolean]$ns) {
                    $ns.split('.')[0].Trim()
                }
                Remove-Variable ns -ErrorAction SilentlyContinue 
            } | 
            Get-Random

        SendOut -Title AD_Objects_Remove_adminCount -Threshold 0 -FileType txt -Info $(

            $AdminGroups = 'Account Operators', 'Administrators', 'Backup Operators', 'Domain Admins', 'Domain Controllers', 'Enterprise Admins', 'Print Operators', 'Read-only Domain Controllers', 'Replicator', 'Schema Admins', 'Server Operators'
            $ExcludeUsers = 'krbtgt'
            $ExcludeGroups = 'Cert Publishers', 'Group Policy Creator Owners'

            [string[]]$ActualProtectedObjects = $admingroups | Get-ADGroupMember -Recursive | Select-Object -ExpandProperty distinguishedname -Unique
            $ActualProtectedObjects += $AdminGroups | Get-ADGroup | Select-Object -ExpandProperty distinguishedname 
            $ActualProtectedObjects += $AdminGroups | Get-ADGroup -Properties members | Select-Object -ExpandProperty members
            $ActualProtectedObjects += $ExcludeUsers | Get-ADUser | Select-Object -ExpandProperty distinguishedname
            $ActualProtectedObjects += $ExcludeGroups | Get-ADGroup | Select-Object -ExpandProperty distinguishedname

            Get-ADObject -LDAPFilter '(adminCount=1)' -Server $Domain | 
                Select-Object -ExpandProperty distinguishedname | 
                Where-Object -FilterScript { !$ActualProtectedObjects.Contains($_) } |
                Sort-Object -Property { $_.Length }
        )

        # Accounts with "Password Not Required" set
        SendOut -Title AD_Objects_User_Password_Not_Required -Threshold 0 -Info $(
            Try {
                $ADSearcher.Filter = '(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=32))'
                $Q = $ADSearcher.FindAll().Properties
                If ($Q.Count -gt 0) {
                    $Q | ForEach-Object {
                        [PSCustomObject]@{
                            distinguishedname = $($_.distinguishedname)
                            name              = $($_.name)
                            samaccountname    = $($_.samaccountname)
                            manager           = $($_.manager)
                            whencreated       = $($_.whencreated)
                            whenChanged       = $($_.whenchanged)
                            LastLogonDate     = [DateTime]::FromFileTime("$($_.lastlogontimestamp)")
                            PasswordLastSet   = [DateTime]::FromFileTime("$($_.pwdlastset)")
                            Disabled          = ([Convert]::ToString($_.useraccountcontrol[0], 2)[-2] -eq '1')
                            LockedOut         = $(If ([Boolean]$_.lockouttime -and $_.lockouttime -gt 0 -or (([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]) -eq 1 -and [Boolean]([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]))) { 'True' }
                                Else { 'False' })
                        }
                    }
                }
                Else { 0 }
            }
            Catch { $_ }
        )
        Remove-Variable Q -ErrorAction SilentlyContinue


        # Computers with "Password Doesn't Expire" set
        SendOut -Title AD_Objects_Computer_Password_Dont_Expire -Threshold 0 -Info $(
            Try {
                $ADSearcher.Filter = '(&(objectClass=computer)(userAccountControl:1.2.840.113556.1.4.803:=65536))'
                $Q = $ADSearcher.FindAll().Properties
                If ($Q.Count -gt 0) {
                    $Q | ForEach-Object {
                        [PSCustomObject]@{
                            distinguishedname = $($_.distinguishedname)
                            name              = $($_.name)
                            samaccountname    = $($_.samaccountname)
                            manager           = $($_.manager)
                            whencreated       = $($_.whencreated)
                            whenChanged       = $($_.whenchanged)
                            LastLogonDate     = [DateTime]::FromFileTime("$($_.lastlogontimestamp)")
                            PasswordLastSet   = [DateTime]::FromFileTime("$($_.pwdlastset)")
                            Disabled          = ([Convert]::ToString($_.useraccountcontrol[0], 2)[-2] -eq '1')
                            LockedOut         = $(If ([Boolean]$_.lockouttime -and $_.lockouttime -gt 0 -or (([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]) -eq 1 -and [Boolean]([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]))) { 'True' }
                                Else { 'False' })
                        }
                    }
                }
                Else { 0 }
            }
            Catch { $_ }
        )
        Remove-Variable Q -ErrorAction SilentlyContinue


        # Computers with "Password Doesn't Expire" set
        SendOut -Title AD_Objects_Groups_Empty -Threshold 0 -Info $(
            Try {
                $ADSearcher.Filter = '(&(objectClass=Group)(!(member=*)))'
                $Q = $ADSearcher.FindAll().Properties
                If ($Q.Count -gt 0) {
                    $Q | ForEach-Object {
                        [PSCustomObject]@{
                            distinguishedname = $($_.distinguishedname)
                            name              = $($_.name)
                            samaccountname    = $($_.samaccountname)
                            whencreated       = $($_.whencreated)
                            whenChanged       = $($_.whenchanged)
                        }
                    }
                }
                Else { 0 }
            }
            Catch { $_ }
        )
        Remove-Variable Q -ErrorAction SilentlyContinue


        # Conflict Objects
        SendOut -Title AD_Objects_Conflicts -Threshold 0 -Info $(
            Try {
                $ADSearcher.Filter = '(|(cn=*\0ACNF:*)(ou=*CNF:*))'
                $Q = $ADSearcher.FindAll().Properties
                If ($Q.Count -gt 0) {
                    $Q | ForEach-Object -Process {
                        
                        If ([Bool]$_.useraccountcontrol) {
                            $Enabled = ([Convert]::ToString($_.useraccountcontrol[0], 2)[-2] -eq '0')
                            If ([Boolean]$_.lockouttime -and $_.lockouttime -gt 0 -or (([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]) -eq 1 -and [Boolean]([Convert]::ToString($_.useraccountcontrol[0], 2)[-5]))) { $LockedOut = 'True' }
                            Else { $LockedOut = 'False' }
                            $LastLogon = [DateTime]::FromFileTime("$($_.lastlogon)")
                            $LastLogonDate = [DateTime]::FromFileTime("$($_.lastlogontimestamp)")
                            $PasswordLastSet = [DateTime]::FromFileTime("$($_.pwdLastSet)")
                        }
                        Else {
                            $LockedOut = $Enabled = $PasswordLastSet = $LastLogonDate = $LastLogon = 'No UAC'
                        }

                        $CNF = [PSCustomObject]@{
                            distinguishedname = $($_.distinguishedname)
                            samaccountname    = $($_.samaccountname)
                            manager           = $($_.manager)
                            whencreated       = $($_.whencreated)
                            whenChanged       = $($_.whenchanged)
                            LastLogon         = $($LastLogon)
                            LastLogonDate     = $($LastLogonDate)
                            PasswordLastSet   = $($PasswordLastSet)
                            Enabled           = $($Enabled)
                            LockedOut         = $($LockedOut)
                        }

                        $CNFGuid = ($CNF.distinguishedname -split (',[A-Z]{2}='))[0].split('\')[1]
                        $OriginalDN = $CNF.distinguishedname.replace("\$CNFGuid", '')
                        $ADSearcher.Filter = "distinguishedname=$OriginalDN"
                        $Original = $ADSearcher.FindOne().Properties
                        
                        If ([Bool]$Original.useraccountcontrol) {
                            $Enabled = ([Convert]::ToString($Original.useraccountcontrol[0], 2)[-2] -eq '0')
                            If ([Boolean]$Original.lockouttime -and $Original.lockouttime -gt 0 -or (([Convert]::ToString($Original.useraccountcontrol[0], 2)[-5]) -eq 1 -and [Boolean]([Convert]::ToString($Original.useraccountcontrol[0], 2)[-5]))) { $LockedOut = 'True' }
                            Else { $LockedOut = 'False' }
                            $LastLogon = [DateTime]::FromFileTime("$($Original.lastlogon)")
                            $LastLogonDate = [DateTime]::FromFileTime("$($Original.lastlogontimestamp)")
                            $PasswordLastSet = [DateTime]::FromFileTime("$($Original.pwdLastSet)")
                        }
                        Else {
                            $LockedOut = $Enabled = $PasswordLastSet = $LastLogonDate = $LastLogon = 'No UAC'
                        }
                        
                        If ([Bool]$Original) {
                            $Original = [PSCustomObject]@{
                                distinguishedname = $($Original.distinguishedname)
                                samaccountname    = $($Original.samaccountname)
                                manager           = $($Original.manager)
                                whencreated       = $($Original.whencreated)
                                whenChanged       = $($Original.whenchanged)
                                LastLogon         = $($LastLogon)
                                LastLogonDate     = $($LastLogonDate)
                                PasswordLastSet   = $($PasswordLastSet)
                                Enabled           = $($Enabled)
                                LockedOut         = $($LockedOut)
                            }
                        }
                        Else {
                            $Original = [PSCustomObject]@{
                                distinguishedname = ''
                                samaccountname    = ''
                                manager           = ''
                                whencreated       = ''
                                whenChanged       = ''
                                LastLogon         = ''
                                LastLogonDate     = ''
                                PasswordLastSet   = ''
                                Enabled           = ''
                                LockedOut         = ''
                            }
                        }

                        [PSCustomObject]@{
                            CNF_dn              = $CNF.distinguishedname
                            CNF_san             = $CNF.SamAccountName
                            CNF_Manager         = $CNF.manager
                            CNF_Created         = $CNF.Whencreated
                            CNF_Changed         = $CNF.Whenchanged
                            CNF_LastLogon       = $CNF.LastLogon
                            CNF_LastLogonDate   = $CNF.LastLogonDate
                            CNF_PasswordLastSet = $CNF.PasswordLastSet
                            CNF_Enabled         = $CNF.Enabled
                            CNF_LockedOut       = $CNF.LockedOut
                            O_dn                = $Original.distinguishedname
                            O_san               = $Original.SamAccountName
                            O_Manager           = $Original.manager
                            O_Created           = $Original.WhenCreated
                            O_Changed           = $Original.WhenChanged
                            O_LastLogon         = $Original.LastLogon
                            O_LastLogonDate     = $Original.LastLogonDate
                            O_PasswordLastSet   = $Original.PasswordLastSet
                            O_Enabled           = $Original.Enabled
                            O_LockedOut         = $Original.LockedOut
                        }

                        Remove-Variable CNF, Original, split -ErrorAction SilentlyContinue
                    }
                }
                Else { 0 }
            }
            Catch { $_ }
        )
        Remove-Variable Q -ErrorAction SilentlyContinue


        # Duplicate SPNs
        SendOut -Title SPN_Duplicate -Threshold 5 -FileType txt -Info (
            SetSPN.exe -t $Domain -x -p
        )


        # Gets conflict Objects in GPO
        SendOut -Title GPO_Conflicts -Threshold 0 -Info $(
            Try {
                Get-ChildItem -Path \\$Domain\SYSVOL\$Domain -Filter *ntfrs_* -Recurse -Force | 
                    Select-Object -Property FullName, CreationTime, LastAccessTime, LastWriteTime
            }
            Catch { $_ }
        )


        # GPOs without a folder
        SendOut -Title GPO_Orphaned -Threshold 0 -Info $(
            If ($GPOs.Count -gt 0) {
                $GPOs | 
                    ForEach-Object -Process {
                        [PSCustomObject]@{
                            Name   = $_.DisplayName
                            GUID   = $_.ID
                            Path   = "\\$Domain\sysvol\$Domain\Policies\{$($_.ID)}"
                            Exists = [System.IO.Directory]::Exists("\\$Domain\sysvol\$Domain\Policies\{$($_.ID)}")
                        }
                    } |
                    Where-Object -FilterScript { $_.Exists -eq $False } 
            }
            Else { 'Unable to retrieve GPOs' }
        )


        # Folders without a GPO
        SendOut -Title GPO_Orphaned_Folders -Threshold 0 -Info $(
            Try {
                Get-ChildItem -Path \\$Domain\sysvol\$Domain\Policies -Filter *-*-*-* | 
                    ForEach-Object -Process {
                        [PSCustomObject]@{
                            Path    = $_.FullName
                            GUID    = $_.BaseName
                            GPOName = (Get-GPO -Guid "$($_.BaseName)" -ErrorAction SilentlyContinue).DisplayName
                        }
                    } |
                    Where-Object -FilterScript { ![Bool]$_.GPOName }
            }
            Catch { $_ }
        )


        # GPOs without any links
        SendOut -Title GPO_Without_Links -Threshold 0 -Info $(
            If ($GPOs.Count -gt 0) {
                $GPOs | 
                    Where-Object -FilterScript { $_ | Get-GPOReport -Domain $Domain -ReportType XML | Select-String -NotMatch '<LinksTo>' } | 
                    Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description | 
                    Sort-Object -Property DisplayName
            }
            Else { 'Unable to retrieve GPOs' }
        )

        # GPOs with disabled links
        SendOut -Title GPO_Disabled_Links -Threshold 0 -Info $(
            If ($GPOs.Count -gt 0) {
                $GPOs | ForEach-Object -Process { 
                    $GPO = $_
                ([xml]($GPO | Get-GPOReport -Domain $Domain -ReportType XML)).GPO.LinksTo | 
                        Where-Object -FilterScript { $_.Enabled -eq 'false' } | 
                        Select-Object -Property @{Name = 'GPO'; Expression = { $GPO.DisplayName } }, @{Name = 'Link'; Expression = { $_.SOMPath } }, Enabled, @{Name = 'Enforced'; Expression = { $_.NoOverride } } | 
                        Sort-Object -Property GPO
                    } 
                }
                Else { 'Unable to retrieve GPOs' }
            )


            # GPOs Where Owner is not Domain Admin
            SendOut -Title GPO_Without_DA_Owner -Threshold 0 -Info $(
                If ($GPOs.Count -gt 0) {
                    $GPOs |
                        Where-Object -FilterScript { $_.Owner -ne "$("$($_.DomainName)".split('.')[0])\Domain Admins" } | 
                        Select-Object -Property DisplayName, Owner, CreationTime, ModificationTime, Description |
                        Sort-Object -Property Owner
            }
            Else { 'Unable to retrieve GPOs' }
        )


        # GPOs without Authenticated Users having Read permission
        SendOut -Title GPO_without_Read_AuthUsers -Threshold 0 -FileType txt -Info $(
            $GPOs |
                ForEach-Object -Process {
                    $ACL = Get-Acl "AD:\$($_.Path)"
                    $AuthUsers = $ACL.Access | Where-Object -FilterScript { $_.IdentityReference -like '*Authenticated Users*' }

                    If ("$($AuthUsers.ActiveDirectoryRights)" -notlike '*read*') {
                        $_.DisplayName
                    }

                    Remove-Variable ACL, AuthUsers -ErrorAction SilentlyContinue
                } | Sort-Object
        )


        # GPOs without a apply GPO permission
        SendOut -Title GPO_without_Apply_Perm -Threshold 0 -Info $(
            $GPOs | 
                Where-Object -FilterScript { (Get-Acl "AD:\$($_.Path)").Access.objectType.guid -notcontains 'edacfd8f-ffb3-11d1-b41d-00a0c968f939' } |
                Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description | 
                Sort-Object -Property DisplayName
        )


        # GPOs with all settings disabled
        SendOut -Title GPO_All_Disabled_Settings -Threshold 0 -Info $(
            If ($GPOs.Count -gt 0) {
                $GPOs |
                    Where-Object -FilterScript { $_.GpoStatus -eq 'AllSettingsDisabled' } | 
                    Select-Object -Property DisplayName, Owner, GpoStatus, CreationTime, ModificationTime, Description |
                    Sort-Object -Property DisplayName
            }
            Else { 'Unable to retrieve GPOs' }
        )


        # GPOs with no settings but is enabled
        SendOut -Title GPO_No_Settings_But_Enabled -Threshold 0 -Info $(
            If ($GPOs.Count -gt 0) {
                $GPOs | 
                    ForEach-Object -Process {
                        $GPO = $_
                        $XML = ($GPO | Get-GPOReport -ReportType Xml).Split("`n")

                        $CompStart = $XML.IndexOf($($XML -like '*<Computer>*'))
                        $CompEnd = $XML.IndexOf($($XML -like '*</Computer>*'))
                        $CompSettings = ($XML[$CompStart..$CompEnd]) -match '<q[0-9]{1,}.{1,}>'

                        $UserStart = $XML.IndexOf($($XML -like '*<User>*'))
                        $UserEnd = $XML.IndexOf($($XML -like '*</User>*'))
                        $UserSettings = $XML[$UserStart..$UserEnd] -match '<q[0-9]{1,}.{1,}>'

                        If (
                        ( ![Boolean]$CompSettings -and $GPO.Computer.Enabled ) -or
                        ( ![Boolean]$UserSettings -and $GPO.User.Enabled )
                        ) {
                            $GPO | 
                                Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description,
                                @{n = 'User_Enabled'; e = { $_.User.Enabled } }, @{n = 'User_Settings'; e = { [Boolean]$UserSettings } },
                                @{n = 'Comp_Enabled'; e = { $_.Computer.Enabled } }, @{n = 'Comp_Settings'; e = { [Boolean]$CompSettings } }

                            }
                            Remove-Variable GPO, XML, CompStart, CompEnd, CompSettings, UserStart, UserEnd, UserSettings -ErrorAction SilentlyContinue
                        } |
                        Sort-Object -Property DisplayName
            }
            Else { 'Unable to retrieve GPOs' }
        )


        # GPOs with no settings at all
        SendOut -Title GPO_With_No_Settings -Threshold 0 -Info $(
            If ($GPOs.Count -gt 0) {
                $GPOs | 
                    Where-Object -FilterScript { ($_ | Get-GPOReport -ReportType Xml) -notmatch '<q[0-9]{1,}.{1,}>' } | 
                    Select-Object -Property DisplayName, CreationTime, ModificationTime, Owner, Description | 
                    Sort-Object -Property DisplayName
            }
            Else { 'Unable to retrieve GPOs' }
        )


        # Gets Permissions from AD that probably shouldn't be there
        SendOut -Title AD_Check_Permissions -Threshold 0 -Info $(
            # These GUIDs will be used to translate the ObjectType on the ACE
            $Guids = @()
            # Gets GUIDs from Confirguation about access rights
            Get-ADObject -SearchBase "CN=Configuration,$Root" -LDAPFilter '(&(objectclass=controlAccessRight)(rightsguid=*))' -Properties RightsGuid, DisplayName | 
                ForEach-Object {
                    $Guids += [pscustomobject]@{
                        Name = $_.Name
                        GUID = [GUID]$_.RightsGuid
                    }
                }
            # Gets GUIDs from Schema  about access rights
            Get-ADObject -SearchBase "CN=Schema,CN=Configuration,$Root" -LDAPFilter '(schemaidguid=*)' -Properties LdapDisplayName, SchemaIdGuid | 
                ForEach-Object {
                    $Guids += [pscustomobject]@{
                        Name = $_.LdapDisplayName
                        GUID = [GUID]$_.SchemaIdGuid
                    }
                } 
            
            $ExcludeIDs = @(
                "$($Domain.split('.')[0])\Enterprise Admins"
                "$($Domain.split('.')[0])\Domain Admins"
                "$($Domain.split('.')[0])\Domain Controllers"
                "$($Domain.split('.')[0])\Enterprise Key Admins"
                "$($Domain.split('.')[0])\Key Admins"
                "$($Domain.split('.')[0])\Group Policy Creator Owners"
                "$($Domain.split('.')[0])\Enterprise Read-only Domain Controllers"
                "$($Domain.split('.')[0])\Exchange Servers"
                "$($Domain.split('.')[0])\Exchange Recipient Administrators"
                "$($Domain.split('.')[0])\Exchange Enterprise Servers"
                "$($Domain.split('.')[0])\Exchange Trusted Subsystem"
                "$($Domain.split('.')[0])\Exchange Windows Permissions"
            )

            $OUs |
                # Foreach OU
                ForEach-Object -Process {
                    $OU = $_.Properties.distinguishedname
                    # Look at the Security (ACL)
                    Get-Acl "AD:\$OU" |
                        # Look at the Access Specifically
                        Select-Object -Expand Access |
                        # Only looks at Un-Inherited ACL Entries to prevent un-needed bloat of data
                        Where-Object -FilterScript { $_.IsInherited -eq $False -and $ExcludeIDs -notcontains $_.IdentityReference -and 
                            $_.IdentityReference -notlike 'S-1-5-32-*' -and
                ($_.IdentityReference -like "$($Domain.split('.')[0])\*" -or $_.IdentityReference -like 'S-1-*') } |
                        # Foreach access check object and note as needed
                        ForEach-Object -Process {
                            $ACE = $_

                            $Right = $GUIDs | 
                                Where-Object -FilterScript { $_.GUID -eq $ACE.ObjectType }
                                If (![Bool]$Right) { $Right = @{ Name = $ACE.ObjectType } }

                                [PSCustomObject]@{
                                    OU                    = $($OU)
                                    Object                = $ACE.IdentityReference
                                    IsInherited           = $ACE.IsInherited
                                    ControlType           = $ACE.AccessControlType
                                    ActiveDirectoryRights = $ACE.ActiveDirectoryRights
                                    Right                 = $Right.Name -join ', '
                                    InheritanceType       = $ACE.InheritanceType
                                    InheritanceFlags      = $ACE.InheritanceFlags
                                    PropagationFlags      = $ACE.PropagationFlags
                                }
                                Remove-Variable Right, ACE -ErrorAction SilentlyContinue
                            }
                        }
            Remove-Variable ExcludeIDs, Guids -ErrorAction SilentlyContinue
        )
            

        # Lists the empty OUs
        SendOut -Title AD_OU_Empty -Threshold 0 -FileType txt -Info $(
            $OUs |
                Where-Object -FilterScript { $_.Properties.distinguishedname -like 'OU=*' } |
                # Foreach OU
                ForEach-Object -Process {
                    [Array]$Objects = Get-ADObject -SearchBase $_.Properties.distinguishedname -LDAPFilter '(!(|(objectclass=organizationalUnit)(objectclass=container)(objectclass=Builtin)(objectclass=Builtindomain)(objectclass=domainDNS)))' -ResultSetSize 1
                    $ObjectCount = $Objects.Count
                    If ($ObjectCount -le 1) {
                        $_.Properties.distinguishedname
                    }
                } | Sort-Object -Property { $_.Length } -Descending
        )


        # Lists the OUs that are no protected from deletion
        SendOut -Title AD_OU_No_Deletion_Protection -Threshold 0 -FileType txt -Info $(
            $OUs.Properties.distinguishedname | 
                Where-Object -FilterScript { $_ -like 'OU=*' } |
                # Foreach OU
                ForEach-Object -Process {
                    $ACL = Get-Acl "AD:\$($_)"
                    $Protected = $ACL.Access | Where-Object -FilterScript { $_.IdentityReference -eq 'Everyone' -and $_.AccessControlType -eq 'Deny' -and $_.ActiveDirectoryRights -like '*Delete*' }
                    If (![Boolean]$Protected) {
                        $_
                    }
                    Remove-Variable ACL, Protected -ErrorAction SilentlyContinue
                } | Sort-Object -Property { $_.Length } -Descending
        )
    

        # Lists OUs that have no group policy links
        SendOut -Title AD_OU_No_GP_links -Threshold 0 -FileType txt -Info $(
        ($OUs |
                Where-Object -FilterScript { $_.distinguishedname -like 'OU=*' -and !$_.Properties.gplink }).Properties.distinguishedname
        )


        # Checks all ldap, kerberos and gc DNS SRV Records for DCs to see if they're legitimate
        SendOut -Title DNS_Dead_DC_SRV_Records -Threshold 0 -Info $(
            Get-DnsServerResourceRecord -RRType Srv -ZoneName $Domain -ComputerName $DNSServer |
                Where-Object -FilterScript { 
                    # Filter out just gc, kerberos and ldap SRV records
            ($_.HostName -like '_gc*' -or $_.HostName -like '_Kerberos*' -or $_.HostName -like '_ldap*') -and 
                    # Removes root records from being checked
                    $_.HostName -ne "_ldap._tcp.$Domain" -and $_.HostName -ne '_kerberos._tcp' } |
                ForEach-Object -Process {
                    $CompName = $_.RecordData.DomainName.split('.')[0].ToLower().Trim()
                    Try { $DCCheck = Get-ADDomainController -Identity $CompName -Server $Domain -ErrorAction Stop } Catch {}
                    Try { $ADCompObject = Get-ADComputer -Identity $CompName -Server $Domain -ErrorAction Stop } Catch {}
                    $PingCheck = Test-Connection -ComputerName $CompName -Quiet -Count 1 -ErrorAction SilentlyContinue

                    If (![Boolean]$DCCheck -or !$PingCheck) {
                        [PSCustomObject]@{
                            DCObject              = $False
                            ADComputerObject      = $ADCompObject.DistinguishedName
                            Ping                  = $PingCheck
                            DNS_Record_DN         = $_.DistinguishedName
                            DNS_Record_HostName   = $_.HostName
                            DNS_Record_DomainName = $_.RecordData.DomainName
                        }
                    }

                    Remove-Variable CompName, DCCheck, ADCompObject, PingCheck -ErrorAction SilentlyContinue
                } | 
                Sort-Object -Property DNS_Record_DN -Unique
        )


        # Gets the Manual Connections that were created in AD Sites and Services
        SendOut -Title AD_SS_Manual_Connections -Threshold 0 -Info $(
            Get-ADObject -Server $Domain -SearchBase "CN=Sites,CN=Configuration,$Root" -Filter "objectclass -eq 'nTDSConnection'" -Properties whencreated, fromserver | 
                Where-Object -FilterScript { $_.name -notlike '*-*-*-*-*' } |
                Select-Object -Property @{n = 'FromSite'; e = { $_.fromserver.split(',')[3].split('=')[1] } },
                @{n = 'From'; e = { $_.distinguishedname.split(',')[0].split('=')[1] } },
                @{n = 'ToSite'; e = { $_.distinguishedname.split(',')[4].split('=')[1] } },
                @{n = 'To'; e = { $_.distinguishedname.split(',')[2].split('=')[1] } }, WhenCreated |
                Sort-Object WhenCreated
        )


        # Gets all the AD Sites without subnets
        SendOut -Title AD_SS_Sites_No_Subnets -Threshold 0 -FileType txt -Info $(
            $ADSSSites |
                Where-Object -FilterScript { $_.Subnets.Count -eq 0 } |
                Select-Object -ExpandProperty Name |
                Sort-Object
        )


        # Gets all the AD Sites without DCs
        SendOut -Title AD_SS_Sites_No_DCs -Threshold 0 -FileType txt -Info $(
            $ADSSSites |
                Where-Object -FilterScript { $_.Servers.Count -eq 0 } |
                Select-Object -ExpandProperty Name |
                Sort-Object
        )

        If ([Boolean]$DCs) {
            # region Missing Subnets
            $ExportPath = "$ExportRoot\$Domain`_missing_subnets_$(Get-Date -Format yyyyMMdd).txt"
            $Parameters.ExportPath = $ExportPath

            $DCs | ForEach-Parallel -ScriptBlock $ScriptBlock -Parameters $Parameters

            If ([System.IO.File]::Exists($ExportPath)) {
                Get-Content -Path $ExportPath |
                    Sort-Object -Unique | 
                    Set-Content -Path $ExportPath -Force

                If ((Get-Content -Path $ExportPath).Count -eq 0 -or ![Bool](Get-Content -Path $ExportPath)) {
                    Remove-Item $ExportPath
                }
                
                $Global:MailBody += "$Domain AD_SS_Missing_Subnets ($((Get-Content $ExportPath).Count)): <a href='$ExportPath'> $Date.txt</a><br /><br />"
            }
            Else {
                $Global:MailBody += "$Domain AD_SS_Missing_Subnets: 0<br /><br />"
            }
            # endregion Missing Subnets

            SendOut -Title DC_Out_Of_Date -Threshold 0 -Info $(
                $(
                    Foreach ($DC in $DCs) {
                        Try {
                            $Patches = ([WMISearcher]@{
                                    Scope = "\\$DC\root\cimv2"
                                    Query = 'SELECT InstalledOn FROM WIN32_QuickFixEngineering'
                                }).Get() | 
                                Select-Object -Property @{ Name = 'InstalledOn'; Expression = { [DateTime]$_.InstalledOn } } | 
                                Sort-Object -Property InstalledOn -Descending

                                If ($Patches[0].InstalledOn -lt (Get-Date).AddDays(-45)) {
                                    [PSCustomObject]@{
                                        DC             = $DC
                                        LastDatePatch  = $Patches[0].InstalledOn
                                        PendingReboot  = $(Test-PendingReboot -Computer $DC)
                                        LastBootUpTime = (([WMISearcher]@{
                                                    Scope = "\\$DC\root\cimv2"
                                                    Query = 'SELECT LastBootUpTime FROM win32_operatingsystem'
                                                }).Get()).LastBootUpTime
                                    }
                                }
                            }
                            Catch {
                                [PSCustomObject]@{
                                    DC            = $DC
                                    LastDatePatch = "Error: $_"
                                    PendingReboot = "Ping: $(Test-Connection -ComputerName $DC -Quiet -Count 1)"
                                }
                            }
                        
                            Remove-Variable Patches -ErrorAction SilentlyContinue
                        }
                    ) | Sort-Object -Property LastDatePatch
                )

                SendOut -Title DC_Pending_Reboot -Threshold 0 -Info $(
                    $(
                        Foreach ($DC in $DCs) {
                            Try {
                                $Info = [PSCustomObject]@{
                                    DC            = $DC
                                    PendingReboot = $(Test-PendingReboot -Computer $DC -ErrorAction Stop)
                                }
                            }
                            Catch {
                                $Info = [PSCustomObject]@{
                                    DC            = $DC
                                    PendingReboot = "Ping: $(Test-Connection -ComputerName $DC -Quiet -Count 1)"
                                }
                            }
                            If ($Info.PendingReboot -ne $False) {
                                $Info
                            }
                        }
                    )
                )

                SendOut -Title DC_Low_Storage_Space -Threshold 0 -Info $(
                    $(
                        Foreach ($DC in $DCs) {
                            Try {
                                [Array]$StorageDrive = ([WMISearcher]@{
                                        Scope = "\\$DC\root\cimv2"
                                        Query = "SELECT DeviceID, FreeSpace, Size FROM Win32_LogicalDisk WHERE DriveType='3'"
                                    }).Get()

                                Foreach ($Drive in $StorageDrive) {
                                    $FreeGB = [Math]::Round($Drive.FreeSpace / 1GB, 2)
                                    $TotalGB = [Math]::Round($Drive.Size / 1GB, 2)
                                    $UsedGB = $TotalGB - $FreeGB
                                    If ($UsedGB / $TotalGB * 100 -gt 90) {
                                        [PSCustomObject]@{
                                            DC             = $DC
                                            Drive          = $Drive.DeviceID
                                            TotalSpaceGB   = "$TotalGB GB"
                                            FreeSpaceGB    = "$FreeGB GB"
                                            UsedSpaceGB    = "$UsedGB GB"
                                            FreePercentage = "$([Math]::Round($FreeGB/$TotalGB*100,2)) %"
                                            UsedPercentage = "$([Math]::Round($($TotalGB-$FreeGB)/$TotalGB*100,2)) %"
                                        }
                                    }
                                }
                            }
                            Catch {
                                [PSCustomObject]@{
                                    DC             = $DC
                                    Drive          = "Error: $_"
                                    TotalSpaceGB   = "Ping: $(Test-Connection -ComputerName $DC -Quiet -Count 1)"
                                    FreeSpaceGB    = ''
                                    UsedPercentage = ''
                                }
                            }
                        
                            Remove-Variable Patches -ErrorAction SilentlyContinue
                        }
                    ) | Sort-Object -Property UsedPercentage
                )

                SendOut -Title DC_Services -Threshold 0 -Info $(
                    $Services = 'Active Directory Domain Services', 'Active Directory Web Services', 'DFS Replication', 'DNS Client', 'DNS server', 'Group Policy Client', 'Intersite Messaging', 'Kerberos Key Distribution Center', 'NetLogon', 'Windows Time'
                    Get-Service -DisplayName $Services -ComputerName $DCs | 
                        Where-Object -FilterScript { $_.StartType -ne 'Automatic' -or $_.Status -ne 'Running' } |
                        Select-Object -Property MachineName, Displayname, StartType, Status
            )
        }
        $Global:MailBody += '<br /><br />'
    }
}
End {
    $End = [DateTime]::Now


    $Body = "<html><body>
This report is an accumalation of a bunch of scripts & queries about AD.<br /><br />

Account Used: $ENV:USERNAME<br />
Server Used: $ENV:ComputerName<br /><br />

Start: $Start<br />
End: $End<br />
Duration: $($End-$Start)<br /><br />

<br />----- $ExportRoot -----<br /><br />

$($Global:MailBody -join '<br /><br />')

</body></html>"

    Send-MailMessage `
        -SmtpServer $SMTPServer -Port $Port `
        -From $From -To $To `
        -Subject $Subject -Body $Body -BodyAsHtml
}