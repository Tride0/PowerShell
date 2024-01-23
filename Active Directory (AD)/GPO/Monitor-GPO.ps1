<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 05-18-2020
        Version: 2020.10.02

    .DESCRIPTION
        Script will backup and notify of changes since previous backup
#>
Param(
    $BackUpLocation = "$PSScriptRoot\Backups",
    $DiffsLocation = "$BackUpLocation\Diffs",
    $DiffsFilePath = "$DiffsLocation\Differences_$(Get-Date -Format yyyyMMdd_hhmmss).csv",
    $SMTPServer = 'smtp.relay.com',
    $SMTPPort = 25,
    $EMailFrom = 'GPO_Monitor@Domain.com',
    $EmailTo = 'your@email.com',
    $EMailSubject = "$env:USERDNSDOMAIN GPO Monitor $(Get-Date -Format yyyyMMdd)"
)
Begin {
    #Import required modules
    Import-Module ActiveDirectory, GroupPolicy -ErrorAction Stop

    # Locate and import the Last Back Up List
    $LastBackUpListPath = "$BackUpLocation\List.xml"
    If ((Test-Path -Path $LastBackUpListPath)) {
        $LastBackUpList = Import-Clixml -Path $LastBackUpListPath
    }
    Else { $LastBackUpList = '' }
    
    # Get Folder to search for the backups from the last time this ran
    $LastBackUpReports = Get-ChildItem -Path "$BackUpLocation" -Directory -Recurse -Force -Depth 2 |
        Sort-Object -Property CreationTime |
        Where-Object -FilterScript { (Get-ChildItem $_.FullName -Force -File).Count -ge 1 } |
        Select-Object -ExpandProperty FullName -Last 1

    # Create Back up location if it doesn't exist
    If (!(Test-Path -Path $BackUpLocation)) {
        [Void] (New-Item -Path $BackUpLocation -ItemType Directory -Force -ErrorAction Stop)
    }
    # Create Diffs Location if it doesn't exist
    If (!(Test-Path -Path $DiffsLocation)) {
        [Void] (New-Item -Path $DiffsLocation -ItemType Directory -Force -ErrorAction Stop)
    }

    # Create Year and Month folders if they don't exist
    $BackUpReportPath = "$BackUpLocation\$(Get-Date -Format yyyy\\MM\\dd_hhmmss)"
    If (!(Test-Path -Path $BackUpReportPath)) {
        [Void] (New-Item -Path $BackUpReportPath -ItemType Directory -Force -ErrorAction Stop)
    }

    #region Functions
    Function Compare-Settings {
        Param(
            $Previous,
            $Current
        )
        $Changes = @()

        $PreviousList = Get-GPOSettingSummary -GPO $Previous
        $CurrentList = Get-GPOSettingSummary -GPO $Current

        # Removed or Changed
        :PreviousList Foreach ($PrevItem in $PreviousList) {
            # Create Filterscript to Search if the Exact Setting is present
            $FilterScript = @()
            Foreach ($Key in $PrevItem.Keys) {
                $FilterScript += "`$_.'$Key' -eq `$PrevItem.'$Key'"
            }
            $FilterScript = [scriptblock]::Create($FilterScript -join ' -and ')
            
            # Look for Exact Setting
            $ExactSetting = $CurrentList | Where-Object -FilterScript $FilterScript
        
            # Skip this Item if the Exact Setting was found
            If ([BOolean]$ExactSetting) { Continue PreviousList }

            # Look for close setting
            [Array]$Settings = $CurrentList | Where-Object -FilterScript { $_.SettingName -eq $PrevItem.SettingName }
            If ($Settings.Count -gt 1) {
                If ([Boolean]$PrevItem.Path) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.Path -eq $PrevItem.Path }
                }
                ElseIf ([Boolean]$PrevItem.KeyName) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.KeyName -eq $PrevItem.KeyName }
                }
                ElseIf ([Boolean]$PrevItem.Log) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.Log -eq $PrevItem.Log }
                }
                ElseIf ([Boolean]$PrevItem.SystemAccessPolicyName) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.SystemAccessPolicyName -eq $PrevItem.SystemAccessPolicyName }
                }
            }
            If ($Settings.Count -ge 1) {
                

                Foreach ($Setting in $Settings) {
                    Foreach ($Key in $PrevItem.Keys) {
                        If ($Setting.$Key -ne $PrevItem.$Key) {
                            $Changes += @{
                                GPO      = $Current.ParentNode.Name
                                Change   = 'Setting Changed'
                                Previous = $PrevItem.$Key
                                Current  = $Setting.$Key
                                Note     = "$($PrevItem.SettingName) :: $Key"
                            }
                        }
                    }
                }
            }
            Else {
                $Note = $PrevItem.keys | ForEach-Object -Process {
                    "$($_) :: $($PrevItem.$_)"
                }
                $Changes += @{
                    GPO      = $Current.ParentNode.Name
                    Change   = 'Setting Removed'
                    Previous = $PrevItem.SettingName
                    Current  = 'Removed'
                    Note     = $Note -join "`n"
                }
            }
        }
        
        # Additions
        :CurrentList Foreach ($CurItem in $CurrentList) {
            # Create Filterscript to Search if the Exact Setting is present
            $FilterScript = @()
            Foreach ($Key in $PrevItem.Keys) {
                $FilterScript += "`$_.'$Key' -eq `$CurItem.'$Key'"
            }
            $FilterScript = [scriptblock]::Create($FilterScript -join ' -and ')
            
            # Look for Exact Setting
            $ExactSetting = $PreviousList | Where-Object -FilterScript $FilterScript

            If ([BOolean]$ExactSetting) { Continue CurrentList }

            [Array]$Settings = $PreviousList | Where-Object -FilterScript { $_.SettingName -eq $CurItem.SettingName }
            If ($Settings.Count -ge 1) {
                If ([Boolean]$CurItem.Path) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.Path -eq $CurItem.Path }
                }
                ElseIf ([Boolean]$CurItem.KeyName) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.KeyName -eq $CurItem.KeyName }
                }
                ElseIf ([Boolean]$CurItem.Log) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.Log -eq $CurItem.Log }
                }
                ElseIf ([Boolean]$CurItem.SystemAccessPolicyName) {
                    $Settings = $Settings | Where-Object -FilterScript { $_.SystemAccessPolicyName -eq $PrevItem.SystemAccessPolicyName }
                }
            }
            If ($Settings.Count -eq 0) {
                $Note = $CurItem.keys | ForEach-Object -Process {
                    "$($_) :: $($CurItem.$_)"
                }
                $Changes += @{
                    GPO      = $Current.ParentNode.Name
                    Change   = 'Setting Added'
                    Previous = 'Added'
                    Current  = $CurItem.SettingName
                    Note     = $Note -join "`n"
                }
            }
        }
        
        Return $Changes
    } # END FUNCTION Compare-Settings

    Function Compare-Permissions {
        Param(
            $Previous,
            $Current
        )
        $Changes = @()
        
        $PreviousPerms = Get-PermissionSummary $Previous.GPO.SecurityDescriptor.sddl.InnerText
        $CurrentPerms = Get-PermissionSummary $Current.GPO.SecurityDescriptor.sddl.InnerText

        If (![Boolean]$PreviousPerms) {
            $PreviousPerms = ''
        }
        If (![Boolean]$CurrentPerms) {
            $CurrentPerms = ''
        }

        $Comparison = Compare-Object $PreviousPerms $CurrentPerms -Property ID
        
        $New = $Comparison | Where-Object { $_.SideIndicator -eq '=>' -and $_.InputObject -ne '' } | Select-Object -ExpandProperty ID -Unique
        $Removed = $Comparison | Where-Object { $_.SideIndicator -eq '<=' -and $_.InputObject -ne '' } | Select-Object -ExpandProperty ID -Unique

        Foreach ($Entry in $New) {
            $ACL = $CurrentPerms | 
                Where-Object -FilterScript { $_.Id -eq $Entry }
            Foreach ($ACE in $ACL) {
                $Changes += @{
                    GPO      = $Current.GPO.Name
                    Change   = 'New Permission Entry'
                    Previous = 'New'
                    Current  = $ACE.Id
                    Note     = "$($ACE.Type) - $($ACE.Permission -join ' ; ')"
                }
            }
        }

        Foreach ($Entry in $Removed) {
            $ACL = $PreviousPerms | 
                Where-Object -FilterScript { $_.Id -eq $Entry }
            Foreach ($ACE in $ACL) {
                $Changes += @{
                    GPO      = $Current.GPO.Name
                    Change   = 'Removed Permission Entry'
                    Previous = $ACE.Id
                    Current  = 'Removed'
                    Note     = "$($ACE.Type) - $($ACE.Permission -join ' ; ')"
                }
            }
        }

        $CheckForChanges = $CurrentPerms |
            Where-Object -FilterScript { $Removed -notcontains $_.Id -and $New -notcontains $_.Id }

        Foreach ($CurrentACE in $CheckForChanges) {
            $PreviousACE = $PreviousPerms | 
                Where-Object -FilterScript { $_.Id -eq $CurrentACE.Id -and $_.Type -eq $CurrentACE.Type -and $_.Permission -eq $CurrentACE.Permission }
        
            If (![Boolean]$PreviousACE) {
                $PreviousACE = $PreviousPerms | Where-Object -FilterScript { $_.Id -eq $CurrentACE.Id }
                $Changes += @{
                    GPO      = $Current.GPO.Name
                    Change   = 'Changed Permission Entry'
                    Previous = ($PreviousAce | ForEach-Object -Process { "$($_.Type): $($_.Permission)" }) -join "`n"
                    Current  = "$($CurrentACE.Type) - $($CurrentACE.Permission)"
                    Note     = $CurrentACE.Id
                }
            }
        }
        Return $Changes
    } # END FUNCTION Compare-Permissions

    Function Compare-Links {
        Param(
            $Previous,
            $Current
        )
        $Changes = @()
    
        $PreviousList = $Previous.GPO.LinksTo.SOMPath
        $CurrentList = $Current.GPO.LinksTo.SOMPath 
        If (![Boolean]$PreviousList) {
            $PreviousList = ''
        }
        If (![Boolean]$CurrentList) {
            $CurrentList = ''
        }
        
        $Comparison = Compare-Object $PreviousList $CurrentList
        $New = $Comparison | Where-Object { $_.SideIndicator -eq '=>' -and $_.InputObject -ne '' }
        $Removed = $Comparison | Where-Object { $_.SideIndicator -eq '<=' -and $_.InputObject -ne '' }
    
        Foreach ($Link in $New) {
            $Link = $Current.GPO.LinksTo | 
                Where-Object -FilterScript { $_.SOMPath -eq $Link.InputObject }
    
            $Changes += @{
                GPO      = $Current.GPO.Name
                Change   = 'New Link'
                Previous = 'New'
                Current  = $Link.SOMPath
                Note     = "Enabled: $($Link.Enabled) --- Enforced: $($Link.NoOverride)"
            }
        }
    
        Foreach ($Link in $Removed) {
            $Link = $Previous.GPO.LinksTo | 
                Where-Object -FilterScript { $_.SOMPath -eq $Link.InputObject }
    
            $Changes += @{
                GPO      = $Current.GPO.Name
                Change   = 'Removed Link'
                Previous = $Link.SOMPath
                Current  = 'Removed'
                Note     = "Enabled: $($Link.Enabled) --- Enforced: $($Link.NoOverride)"
            }
        }
    
        $CheckForChanges = $Current.GPO.LinksTo |
            Where-Object -FilterScript { $Removed.InputObject -notcontains $_.SOMPath -and $New.InputObject -notcontains $_.SOMPath }
    
        Foreach ($CurrentLink in $CheckForChanges) {
            $PreviousLink = $Previous.GPO.LinksTo |
                Where-Object -FilterScript { $_.SOMPath -eq $CurrentLink.SOMPath }
    
            # Enabled Status
            If ($PreviousLink.Enabled -ne $CurrentLink.Enabled) {
                $Changes += @{
                    GPO      = $Current.GPO.Name
                    Change   = 'Link Enabled Status'
                    Previous = $PreviousLink.Enabled
                    Current  = $CurrentLink.Enabled
                    Note     = $CurrentLink.SOMPath
                }
            }
    
            # Perm Set
            If ($PreviousLink.NoOverride -ne $CurrentLink.NoOverride) {
                $Changes += @{
                    GPO      = $Current.GPO.Name
                    Change   = 'Link Enforcement Status'
                    Previous = $PreviousLink.NoOverride
                    Current  = $CurrentLink.NoOverride
                    Note     = $CurrentLink.SOMPath
                }
            }
            Remove-Variable PreviousLink -ErrorAction SilentlyContinue
        }
        Return $Changes
    } # END FUNCTION Compare-Links

    Function Compare-GPO {
        Param($Previous, $Current)
        $Changes = @()
        # Name
        If ($Previous.GPO.Name -ne $Current.GPO.Name) {
            $Changes += @{
                GPO      = $Current.GPO.Name
                Change   = 'Name'
                Previous = $Previous.GPO.Name
                Current  = $Current.GPO.Name
                Note     = $null
            }
        }

        #Owner
        If ($Previous.gpo.SecurityDescriptor.Owner.Sid.InnerText -ne $Current.gpo.SecurityDescriptor.Owner.Sid.InnerText) {
            $PreviousResult = If ([Boolean]$Previous.gpo.SecurityDescriptor.Owner.Name.InnerText) { $Previous.gpo.SecurityDescriptor.Owner.Name.InnerText } 
            Else { $Previous.gpo.SecurityDescriptor.Owner.Sid.InnerText }
            $CurrentResult = If ([Boolean]$Current.gpo.SecurityDescriptor.Owner.Name.InnerText) { $Current.gpo.SecurityDescriptor.Owner.Name.InnerText } 
            Else { $Current.gpo.SecurityDescriptor.Owner.Sid.InnerText }

            $Changes += @{
                GPO      = $Current.GPO.Name
                Change   = 'Owner'
                Previous = $PreviousResult
                Current  = $CurrentResult
                Note     = $null
            }
        }

        # User Setting Enabled Status
        If ($Previous.GPO.User.Enabled -ne $Current.GPO.User.Enabled) {
            $Changes += @{
                GPO      = $Current.GPO.Name
                Change   = 'User Settings Enabled Status'
                Previous = $Previous.GPO.User.Enabled
                Current  = $Current.GPO.User.Enabled
                Note     = $null
            }
        }

        # Computer Setting Enabled Status
        If ($Previous.GPO.Computer.Enabled -ne $Current.GPO.Computer.Enabled) {
            $Changes += @{
                GPO      = $Current.GPO.Name
                Change   = 'Computer Settings Enabled Status'
                Previous = $Previous.GPO.Computer.Enabled
                Current  = $Current.GPO.Computer.Enabled
                Note     = $null
            }
        }

        # WMI Filter
        If ($Previous.GPO.FilterName -ne $Current.GPO.FilterName) {
            $Changes += @{
                GPO      = $Current.GPO.Name
                Change   = 'WMI Filter'
                Previous = $Previous.GPO.FilterName
                Current  = $Current.GPO.FilterName
                Note     = $null
            }
        }

        $PermissionComparison = Compare-Permissions $Previous $Current
        $LinksComparison = Compare-Links $Previous $Current
        $ComputerSettingComparison = Compare-Settings $Previous.GPO.Computer $Current.GPO.Computer
        $UserSettingComparison = Compare-Settings $Previous.GPO.User $Current.GPO.User
        
        Return ($Changes + $LinksComparison + $PermissionComparison + $ComputerSettingComparison + $UserSettingComparison)
    } # END FUNCTION Compare-GPO

    Function Get-GPOSummary {
        Param($GPO)
        $ComputerSettings = Get-GPOSettingSummary -GPO $GPO.gpo.Computer.ExtensionData.Extension -ToReadableString
        $UserSettings = Get-GPOSettingSummary -GPO $GPO.gpo.User.ExtensionData.Extension -ToReadableString
        $Permissions = Get-PermissionSummary -SDDLString $GPO.GPO.SecurityDescriptor.sddl.InnerText -String

        $Links = Foreach ($Link in $GPO.GPO.LinksTo) {
            "$($Link.SOMPath) - Enabled: $($Link.Enabled) - Enforced: $($Link.NoOverride)"
        }
        $General = "Computer Settings Enabled: $($GPO.GPO.Computer.Enabled)`nUser Settings Enabled: $($GPO.GPO.User.Enabled)`n`nWMI Filter: $($GPO.GPO.FilterName)"

        Return "Name: $($GPO.GPO.Name)`n`nLinks: `n$($Links -join "`n") `n`n$General `n`nUser Settings:`n$($UserSettings -join "`n") `n`nComputer Settings: `n$($ComputerSettings -join "`n") `n`nPermissions: `n$($Permissions -join "`n")"
    } # END FUNCTION Get-GPOSummary

    Function Get-PermissionSummary {
        Param($SDDLString, [Switch]$String)
        (ConvertFrom-SddlString $SDDLString).DiscretionaryAcl | 
            ForEach-Object -Process {
                $Split = $_.Split(':').Split('(').TrimEnd(')').Trim()
                $PermSetList = $Split[2].split(',').Trim()

                If ($PermSetlist.Contains('FullControl')) {
                    $Permission = 'Full Control'
                }
                ElseIf ($PermSetList.Contains('WriteAttributes')) {
                    $Permission = 'Apply Group Policy'
                }
                ElseIf ($PermSetList.Contains('WriteKey')) {
                    $Permission = 'Modify'
                }
                ElseIf ($PermSetList.Contains('Delete') -and $Split[1].Trim() -notlike '*Allow*') {
                    $Permission = 'Delete'
                }
                ElseIf ($PermSetList.Contains('GenericExecute') -or $PermSetList.Contains('Read') -or $PermSetList.Contains('ReadExtendedAttributes')) {
                    $Permission = 'Read'
                }
                Else {
                    $Permission = 'Custom'
                }
         
                If ($String.IsPresent) {
                    "$($Split[1].Trim()): $($Split[0].Trim()): $Permission"
                }
                Else {
                    [PSCustomObject]@{
                        Id         = $Split[0].Trim()
                        Type       = $Split[1].Trim()
                        Permission = $Permission
                    }
                }
            }
    } # END FUNCTION Get-PermissionSummary
    
    Function Get-GPOSettingSummary {
        Param(
            $GPO,
            [Switch]$ToReadableString
        )
        If ([Boolean]$GPO.ExtensionData) {
            $GPO = $GPO.ExtensionData.Extension
        }
        Elseif ([Boolean]$GPO.Extension) {
            $GPO = $GPO.Extension
        }

        If (![Boolean]$GPO.ParentNode.Extension) {
            Return $null
        }

        $Information = @()
        Foreach ($Parent in $GPO) {
            $CurrentChild = $Parent.FirstChild
            Do {
                $HashTable = [System.Collections.Specialized.OrderedDictionary]@{}

                $HashTable.SettingName = $CurrentChild.LocalName + ' - ' + $CurrentChild.Name

                If ($CurrentChild.Name -like 'Se*' -and ($CurrentChild.Name -like '*Privilege' -or $CurrentChild.Name -like '*Right')) {
                    $HashTable.$($CurrentChild.Name) = $($CurrentChild.Member.Name.'#Text' -join ' ; ')
                }
                Else {
                    [String[]]$SkipSettings = 'Supported', 'Explain', 'Category'
                    :SettingNames Foreach ($SettingName in $CurrentChild.ChildNodes.Name) {
                        If ($SettingName -like '*:*') { 
                            $SettingName = $SettingName.Split(':')[1].Trim()
                        }
                        # Skip if Setting is in the Skip
                        If ($SkipSettings.Contains($SettingName) -or ![Boolean]$SettingName) { Continue SettingNames }

                        # If Permissions get read-able summary
                        ElseIf ([Boolean]$CurrentChild.$SettingName.SDDL) {
                            $HashTable.$SettingName = (Get-PermissionSummary -SDDLString $CurrentChild.$SettingName.SDDL.InnerText -String) -join ' ; '
                        }

                        # Catch All
                        Else {
                            # Get the item that will be evaluated
                            If ([Boolean]$CurrentChild.$SettingName) {
                                $ItemToEval = $CurrentChild.$SettingName
                            }
                            ElseIf ([Boolean]$SettingName) {
                                $ItemToEval = $SettingName
                            }
                            # If a value exists for this setting add it
                            If ([Boolean]$ItemToEval) { 
                                
                                #Get the value that will be added to the hashtable
                                If ([Boolean]$ItemToEval.Value) {
                                    $Value = $($ItemToEval.Value) -join ' ; '
                                }
                                ElseIf ([Boolean]$ItemToEval.'#text') {
                                    $Value = $($ItemToEval.'#text') -join ' ; '
                                }                                
                                ElseIf ($ItemToEval -is [System.Array]) {
                                    $Value = $($ItemToEval -join ' ; ')
                                }
                                ElseIf ([Boolean]$ItemToEval.InnerText) {
                                    $Value = $($ItemToEval.InnerText -join ' ; ')
                                }
                                Else {
                                    $Value = $($ItemToEval -join ' ; ') 
                                }

                                # Add value to hashtable
                                If ($value -ne $CurrentChild.Name) {
                                    
                                    # Determine which key to put it under
                                    If ($SettingName.LocalName -eq 'Name' -and $SettingName.ParentNode.LocalName -ne 'Name') {
                                        $Key = ($SettingName.ParentNode.LocalName)
                                    }
                                    ElseIf ([Boolean]$CurrentChild.$SettingName) {
                                        $Key = $SettingName
                                    }
                                    ElseIf ([Boolean]$CurrentChild.LocalName) {
                                        $Key = $($CurrentChild.LocalName)
                                    }
                                    Else {
                                        $Key = 'Note'
                                        
                                    }

                                    # Add $Value to $HashTable under the selected $Key
                                    If ([Boolean]$HashTable.$Key) {
                                        $HashTable.$Key = $HashTable.$Key + ', ' + $Value
                                    }
                                    Else {
                                        $HashTable.$Key = $Value
                                    }
                                }
                            }
                        }
                    }
                }
            
                $Information += $HashTable
            
                $CurrentChild = $CurrentChild.NextSibling
            }
            While ([Boolean]$CurrentChild)
        }
    
        If ($ToReadableString.IsPresent) {
            Return $Information | ForEach-Object -Process {
                "`n"
                Foreach ($Key in $_.Keys) {
                    $ValueSplit = $_.$Key.Split(';').Trim()

                    If ($ValueSplit.Count -gt 1) {
                        "$Key ::`n`t$($ValueSplit -join "`n`t")"
                    }
                    ElseIf ([Boolean]$ValueSplit) {
                        "$Key :: $ValueSplit"
                    }
                    Else {
                        "$Key :: $($_.$Key)"
                    }
                }
            }
        }
        Else {
            Return $Information
        }
    } # END FUNCTION Get-GPOSettingSummary

    #endregion Functions

    
}
Process {
    $ExportInformation = @()

    # Get all current GPOs
    $CurrentGPOs = Get-GPO -All

    # Create/Overwrite LastBackupList
    $CurrentGPOs | Export-Clixml -Path $LastBackUpListPath

    If ([Boolean]$LastBackUpList.ID.GUID) {
        $LastBackUpList = $LastBackUpList.ID.GUID
    }
    Else {
        $LastBackUpList = ''
    }

    # Compare the Last List or GPOs with the Current List of GPOs
    $HighLevelCompare = Compare-Object $LastBackUpList $CurrentGPOs.ID.GUID
    
    # Get List of New GPOs
    $NewGPOs = $HighLevelCompare | Where-Object { $_.SideIndicator -eq '=>' }
    
    # Get List of Removed GPOs
    $RemovedGPOs = $HighLevelCompare | Where-Object { $_.SideIndicator -eq '<=' }
    
    # Get List of Changed GPOs
    $CheckForChanges = $CurrentGPOs |
        Where-Object -FilterScript { $RemovedGPOs.InputObject -notcontains $_.ID.GUID -and $NewGPOs.InputObject -notcontains $_.ID.GUID }
    
    If (![Boolean]$LastBackUpList) {
        # Backup Current GPOs Sysvol Folders
        $CurrentGPOs | Backup-GPO -Path $BackUpReportPath
        # Create XML Report of Current GPOs
        $CurrentGPOs | ForEach-Object { (Get-GPOReport -Name $_.Displayname -ReportType xml) | Export-Clixml -Path "$BackUpReportPath\$($_.ID.GUID).xml" }
    }
    Else {
        # Backup Current GPOs Sysvol Folders
        $CurrentGPOs | Backup-GPO -Path $BackUpReportPath
        # Create XML Report of Current GPOs
        $CurrentGPOs | ForEach-Object { (Get-GPOReport -Name $_.Displayname -ReportType xml) | Export-Clixml -Path "$BackUpReportPath\$($_.ID.GUID).xml" }

        Foreach ($CurrentGPO in $CheckForChanges) {
            # Find Report from last backup
            $PreviousGPOPath = Get-ChildItem -Path $LastBackUpReports -Filter "*$($CurrentGPO.ID.GUID).xml"
            # If there's a backup for this GPO, Import it if not initialize Variable
            If ([Boolean]$PreviousGPOPath.FullName) {
                [XML]$PreviousGPOReport = Import-Clixml -Path $PreviousGPOPath.FullName
            } 
            Else {
                $PreviousGPOReport = ''
            }
            # Create Report of Current GPO Status
            [XML]$CurrentGPOReport = Get-GPOReport -GUID $CurrentGPO.ID.Guid -ReportType xml
            # Compare GPO's Backup Report and GPO's Current Report
            $ExportInformation += Compare-GPO $PreviousGPOReport $CurrentGPOReport
        }

        Foreach ($GP in $NewGPOs) {
            # Create Report from GPO
            [XML]$GPOReport = Get-GPOReport -GUID $GP.InputObject -ReportType xml
            # Create Summary of Report
            $Summary = Get-GPOSummary -GPO $GPOReport
            $ExportInformation += @{
                GPO      = $GPOReport.GPO.Name
                Change   = 'New GPO'
                Previous = 'New'
                Current  = 'New'
                Note     = ($Summary -join "`n")
            }
        }
        
        Foreach ($GP in $RemovedGPOs) {
            # Get Report Path from Last Back up
            $PreviousGPOPath = Get-ChildItem -Path $LastBackUpReports -Filter "*$($GP.InputObject).xml"
            If ([Boolean]$PreviousGPOPath) {
                # Import Backup Report
                [XML]$PreviousGPOReport = Import-Clixml -Path $PreviousGPOPath.FullName
                # Create Summary of BackUp Report
                $Summary = Get-GPOSummary -GPO $PreviousGPOReport
                $ExportInformation += @{
                    GPO      = $PreviousGPOReport.GPO.Name
                    Change   = 'Removed GPO'
                    Previous = 'New'
                    Current  = 'New'
                    Note     = ($Summary -join "`n")
                }
            }
            
        }
    }

    # Export Information
    If ([Boolean]$ExportInformation) {
        $ExportInformation | 
            ForEach-Object -Process { [PSCustomObject]$_ } |
            Select-Object -Property GPO, Change, Previous, Current, Note |
            Export-Csv -Path $DiffsFilePath -NoTypeInformation -Force
        
        $MailBody = "<$DiffsFilePath>`n`n"
        $MailBody += ($ExportInformation | 
                ForEach-Object -Process { [PSCustomObject]$_ } |
                Group-Object -Property GPO | 
                Sort-Object -Property Name |
                ForEach-Object -Process {
                    "`n`n$($_.Name)"
                    $_.Group | ForEach-Object -Process {
                        If ([Bool]$_.Note) {
                            $Note = $($_.Note.Split("`n") -join "`n`t`t")
                        }
                    
                        "`t$($_.Change)`n`t`tPrevious: $($_.Previous)`n`t`tCurrent: $($_.Current)`n`t`tNote: $Note"
                    
                        Remove-Variable note -ErrorAction SilentlyContinue
                    }
                }) -join "`n"

        If ([Boolean]$EmailTo) {
            Send-MailMessage -From $EMailFrom -To $EmailTo `
                -SmtpServer $SMTPServer -Port $SMTPPort `
                -Subject $EMailSubject -Body $MailBody -Attachments $DiffsFilePath
        }

        $OldBackUpReports = Get-ChildItem -Path "$BackUpLocation" -Directory -Recurse -Force -Depth 2 |
            Where-Object { $_.FullName -ne $DiffsLocation -and $_.FullName -like "$BackupLocation\*\*\*" } |
            Sort-Object -Property CreationTime
        
        If ($OldBackUpReports.Count -gt 1) {
            $OldBackUpReports |
                Select-Object -ExpandProperty FullName -First ($OldBackUpReports.Count - 1) | 
                Remove-Item -Recurse -Force
        }
    }
    ElseIf ([Boolean]$LastBackUpList) {
        Remove-Item -Path $BackUpReportPath -Recurse -Force
    }
}
End {
    Get-ChildItem -Path $BackUpLocation -Directory -Depth 2 -Recurse -Force |
        Where-Object -FilterScript { (Get-ChildItem -Path $_.FullName -File -Recurse -Force | Select-Object -First 1).Count -eq 0 } |
        Remove-Item
}