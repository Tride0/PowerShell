<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 05-18-2020
        Version: 2020.06.10

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
    $EmailTo = '',
    $EMailSubject = "GPO Monitor $(Get-Date -Format yyyyMMdd)"
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
    If (!(Test-path -path $BackUpLocation)) {
        [Void] (New-Item -Path $BackUpLocation -ItemType Directory -Force -ErrorAction Stop)
    }
    # Create Diffs Location if it doesn't exist
    If (!(Test-path -path $DiffsLocation)) {
        [Void] (New-Item -Path $DiffsLocation -ItemType Directory -Force -ErrorAction Stop)
    }

    # Create Year and Month folders if they don't exist
    $BackUpReportPath = "$BackUpLocation\$(Get-Date -Format yyyy\\MM\\dd_hhmmss)"
    If (!(Test-path -path $BackUpReportPath)) {
        [Void] (New-Item -Path $BackUpReportPath -ItemType Directory -Force -ErrorAction Stop)
    }

    #region Functions
    Function Compare-Settings {
        Param(
            $Previous,
            $Current,
            $GPO
        )
        $Changes = @()

        $PreviousList = $Previous.ExtensionData.Extension.Account.Name
        $CurrentList = $Current.ExtensionData.Extension.Account.Name 
        If (![Boolean]$PreviousList) {
            $PreviousList = ''
        }
        If (![Boolean]$CurrentList) {
            $CurrentList = ''
        }
        
        $Comparison = Compare-Object $PreviousList $CurrentList
        $New = $Comparison | Where-Object { $_.SideIndicator -eq "=>" -and $_.InputObject -ne '' }
        $Removed = $Comparison | Where-Object { $_.SideIndicator -eq "<=" -and $_.InputObject -ne '' }

        
        Foreach ($Setting in $New) {
            $Setting = $Current.ExtensionData.Extension.Account |
            Where-Object { $Setting.InputObject -eq $_.Name }
                
            $Changes += @{
                GPO      = $GPO
                Change   = 'Setting Added'
                Previous = 'New'
                Current  = $Setting.ChildNodes[0].'#text'
                Note     = $Setting.ChildNodes[1].'#text'
            }
        }
        
        Foreach ($Setting in $Removed) {
            $Setting = $Previous.ExtensionData.Extension.Account |
            Where-Object { $Setting.InputObject -eq $_.Name }
                
            $Changes += @{
                GPO      = $GPO
                Change   = 'Setting Removed'
                Previous = $Setting.ChildNodes[0].'#text'
                Current  = 'Removed'
                Note     = $Setting.ChildNodes[1].'#text'
            }
        }

        $CheckForChanges = $Current.ExtensionData.Extension.Account |
        Where-Object -FilterScript { $Removed.InputObject -notcontains $_.Name -and $New.InputObject -notcontains $_.Name }

        Foreach ($CurrentSetting in $CheckForChanges) {
            $PreviousSetting = $Previous.ExtensionData.Extension.Account |
            Where-Object -FilterScript { $_.Name -eq $CurrentSetting.Name }
            
            # Perm Set
            If ($PreviousSetting.ChildNodes[1].'#text' -ne $CurrentSetting.ChildNodes[1].'#text') {
                $Changes += @{
                    GPO      = $GPO
                    Change   = 'Setting Value Changed'
                    Previous = $PreviousSetting.ChildNodes[1].'#text'
                    Current  = $CurrentSetting.ChildNodes[1].'#text'
                    Note     = $CurrentSetting.Name
                }
            }
            Remove-Variable PreviousSetting -ErrorAction SilentlyContinue
        }

        Return $Changes
    } # END FUNCTION Compare-Settings

    Function Compare-Permissions {
        Param(
            $Previous,
            $Current
        )
        $Changes = @()
        $PreviousPerms = (convertfrom-sddlstring $Previous.GPO.SecurityDescriptor.sddl.InnerText).DiscretionaryAcl | 
        ForEach-Object -Process {
            $Split = $_.Split(':').Split('(').TrimEnd(')').Trim()
            $PermSetList = $Split[2].split(',').Trim()

            If ($PermSetlist.Contains('Delete')) {
                $Permission = 'Edit Settings, Delete, Modify Security'
            }
            ElseIf ($PermSetList.Contains('WriteKey')) {
                $Permission = 'Edit Settings'
            }
            ElseIf ($PermSetList.Contains('WriteAttributes')) {
                $Permission = 'Apply Group Policy'
            }
            ElseIf ($PermSetList.Contains('GenericExecute')) {
                $Permission = 'Read'
            }
            Else {
                $Permission = 'Custom'
            }
         
            [PSCustomObject]@{
                Id         = $SPlit[0].Trim()
                Type       = $Split[1].Trim()
                Permission = $Permission
            }
        }

        $CurrentPerms = (convertfrom-sddlstring $Current.GPO.SecurityDescriptor.sddl.InnerText).DiscretionaryAcl | 
        ForEach-Object -Process {
            $Split = $_.Split(':').Split('(').TrimEnd(')').Trim()
            $PermSetList = $Split[2].split(',').Trim()

            If ($PermSetlist.Contains('FullControl')) {
                $Permission = 'Edit Settings, Delete, Modify Security'
            }
            ElseIf ($PermSetList.Contains('WriteKey')) {
                $Permission = 'Edit Settings'
            }
            ElseIf ($PermSetList.Contains('WriteAttributes')) {
                $Permission = 'Apply Group Policy'
            }
            ElseIf ($PermSetList.Contains('GenericExecute')) {
                $Permission = 'Read'
            }
            Else {
                $Permission = 'Custom'
            }
         
            [PSCustomObject]@{
                Id         = $SPlit[0].Trim()
                Type       = $Split[1].Trim()
                Permission = $Permission
            }
        }

        If (![Boolean]$PreviousPerms) {
            $PreviousPerms = ''
        }
        If (![Boolean]$CurrentPerms) {
            $CurrentPerms = ''
        }

        $Comparison = Compare-Object $PreviousPerms $CurrentPerms -Property ID
        
        $New = $Comparison | Where-Object { $_.SideIndicator -eq "=>" -and $_.InputObject -ne '' } | Select-Object -ExpandProperty ID -Unique
        $Removed = $Comparison | Where-Object { $_.SideIndicator -eq "<=" -and $_.InputObject -ne '' } | Select-Object -ExpandProperty ID -Unique

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
        $New = $Comparison | Where-Object { $_.SideIndicator -eq "=>" -and $_.InputObject -ne '' }
        $Removed = $Comparison | Where-Object { $_.SideIndicator -eq "<=" -and $_.InputObject -ne '' }
    
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
        $ComputerSettingComparison = Compare-Settings $Previous.GPO.Computer $Current.GPO.Computer $Current.GPO.Name
        $UserSettingComparison = Compare-Settings $Previous.GPO.User $Current.GPO.User $Current.GPO.Name
        
        Return ($Changes + $LinksComparison + $PermissionComparison + $ComputerSettingComparison + $UserSettingComparison)
    } # END FUNCTION Compare-GPO

    Function Get-AllChildren {
        Param($Root)
        For ($i = 0; $i -lt $Root.ChildNodes.count; $i++) {
            $CurrentChild = $Root.ChildNodes[$i]
            for ($j = 0; $j -lt $CurrentChild.ChildNodes.count; $j++) { 
                "$($CurrentChild.ChildNodes[$j].LocalName) :: $($CurrentChild.ChildNodes[$j].InnerText -join ',')"
            }
        }
    } # END FUNCTION Get-AllChildren

    Function Get-GPOSummary {
        Param($GPO)
        $ComputerSettings = Get-AllChildren -Root $GPO.gpo.Computer.ExtensionData.Extension
        $UserSettings = Get-AllChildren -Root $GPO.gpo.User.ExtensionData.Extension
        $Permissions = (convertfrom-sddlstring $GPO.GPO.SecurityDescriptor.sddl.InnerText).DiscretionaryAcl | 
        ForEach-Object -Process {
            $Split = $_.Split(':').Split('(').TrimEnd(')').Trim()
            $PermSetList = $Split[2].split(',').Trim()

            If ($PermSetlist.Contains('FullControl')) {
                $Permission = 'Edit Settings, Delete, Modify Security'
            }
            ElseIf ($PermSetList.Contains('WriteKey')) {
                $Permission = 'Edit Settings'
            }
            ElseIf ($PermSetList.Contains('WriteAttributes')) {
                $Permission = 'Apply Group Policy'
            }
            ElseIf ($PermSetList.Contains('GenericExecute')) {
                $Permission = 'Read'
            }
            Else {
                $Permission = 'Custom'
            }
         
            "$($Split[1].Trim()): $($SPlit[0].Trim()): $Permission"
        }
        

        $Links = Foreach ($Link in $GPO.GPO.LinksTo) {
            "$($Link.SOMPath) - Enabled: $($Link.Enabled) - Enforced: $($Link.NoOverride)"
        }
        $General = "Computer Settings Enabled: $($GPO.GPO.Computer.Enabled)`nUser Settings Enabled: $($GPO.GPO.User.Enabled)`n`nWMI Filter: $($GPO.GPO.FilterName)"

        Return "Name: $($GPO.GPO.Name)`n`nLinks: `n$($Links -join "`n") `n`n$General `n`nUser Settings:`n$($UserSettings -join "`n") `n`nComputer Settings: `n$($ComputerSettings -join "`n") `n`nPermissions: `n$($Permissions -join "`n")"
    } # END FUNCTION Get-GPOSummary

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
    $NewGPOs = $HighLevelCompare | Where-Object { $_.SideIndicator -eq "=>" }
    
    # Get List of Removed GPOs
    $RemovedGPOs = $HighLevelCompare | Where-Object { $_.SideIndicator -eq "<=" }
    
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
                [XML]$PreviousGPOReport = Import-CliXml -Path $PreviousGPOPath.FullName
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
                [XML]$PreviousGPOReport = Import-CliXml -Path $PreviousGPOPath.FullName
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
                    "`t$($_.Change)`n`t`tPrevious: $($_.Previous)`n`t`tCurrent: $($_.Current)`n`t`tNote: $($_.Note.Split("`n") -join "`n`t`t")"
                }
            }) -join "`n"

        If ([Boolean]$EmailTo) {
            Send-MailMessage -From $EMailFrom -To $EmailTo `
                -SmtpServer $SMTPServer -Port $SMTPPort `
                -Subject $EMailSubject -Body $MailBody -Attachments $DiffsFilePath
        }
    }
    Else {
        Remove-Item -Path $BackUpReportPath -Recurse -Force
    }
}