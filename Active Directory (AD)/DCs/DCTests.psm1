$ExternalTimeSource = @(
    '10.122.4.12'
    '10.122.4.13'
)
$DCTests_CPUThreshold = 85
$DCTests_DiskThreshold = 15
$DCTests_MemoryThreshold = 80
$DCTests_PatchingThreshold = 90
$DCTests_RebootThreshold = 30
$RequiredSoftware = @(
    @{ # Splunk
        Name    = 'UniversalForwarder'
        Version = '9.3.5.0'
    }
    @{ # CRWD
        Name    = 'CrowdStrike Sensor Platform'
        Version = '7.29.20108.0'
    }
    @{ # SCCM
        Name    = 'Configuration Manager Client'
        Version = '5.00.9132.1000'
    }
    @{ # SCOM
        Name    = 'Microsoft Monitoring Agent'
        Version = '10.22.10056.0'
    }
    @{ # Rapid7
        Name    = 'Rapid7 Insight Agent'
        Version = '4.0.9.1'
    }
)
$ServicesConfigurations = @(
    @{ 
        Name      = 'NTDS'
        Status    = 'Running'
        StartType = 'Automatic'
    } # NTDS - Active Directory Domain Services - Core ADDS Services
    @{ 
        Name      = 'ADWS'
        Status    = 'Running'
        StartType = 'Automatic'
    } # ADWS - Active Directory Web Services - Required for ADAC and PowerShell AD functions
    @{ 
        Name      = 'kdc'
        Status    = 'Running'
        StartType = 'Automatic'
    } # kdc - Kerberos Key Distribution Center - Provides Kerberos authentication and authorization services
    @{ 
        Name      = 'Netlogon'
        Status    = 'Running'
        StartType = 'Automatic'
    } # Netlogon - Provides user and machine authentication and registration services
    @{ 
        Name      = 'W32Time'
        Status    = 'Running'
        StartType = 'Automatic'
    } # W32Time - Windows Time - Synchronizes date and time on all client and server computers in the network
    @{ 
        Name      = 'RpcLocator'
        Status    = 'Running'
        StartType = 'Automatic'
    } # RpcLocator - Remote Procedure Call (RPC) Locator - Manages the RPC name service database
    @{
        Name      = 'Server'
        Status    = 'Running'
        StartType = 'Automatic'
    } # Server - File and Print Services - Provides file, print, and remote access services
    @{
        Name      = 'IsmServ'
        Status    = 'Running'
        StartType = 'Automatic'
    } # IsmServ - Inter-Site Messaging - Facilitates communication between domain controllers in different sites
    @{ 
        Name      = 'Dfsr'
        Status    = 'Running'
        StartType = 'Automatic'
    } # Dfsr - Distributed File System Replication - Replicates files and folders between DFS namespaces
    @{ 
        Name      = 'DFSNamespace'
        Status    = 'Running'
        StartType = 'Automatic'
    } # DFSNamespace - DFS Namespace - Manages logical views of shared folders and files
    @{ 
        Name      = 'GPSVC'
        Status    = 'Running'
        StartType = 'Automatic'
    } # GPSVC - Group Policy Client - Manages the application of Group Policy settings
    @{
        Name      = 'Workstation'
        Status    = 'Running'
        StartType = 'Automatic'
    } # Workstation - Provides network connections and communications
)

# Test output format: hashtable with: Report, ReportSummary

function repadminQueue {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [repadminQueue] Checking Replication Queue..." -ForegroundColor Cyan

    $repadmin_queue = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        repadmin /queue
    } -ErrorAction Stop

    if ("$repadmin_queue" -notlike '*Queue contains 0 items*') {
        return [PSCustomObject]@{
            Report        = $repadmin_queue -join "`n`n"
            ReportSummary = '[repadminQueue] Repadmin Queue not empty' 
        }
    }
} # END function repadminQueue

function repadminShowrepl {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Replication Status..." -ForegroundColor Cyan

    $repadmin_showrepl = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        (repadmin /showrepl).split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim()
    } -ErrorAction Stop

    $showrepl_failures = $repadmin_showrepl -like '*Last attempt*' -notlike '*was successful*'
    $showrepl_failure_context = @()
    foreach ($failure in $showrepl_failures) {
        $EndIndex = $repadmin_showrepl.IndexOf($failure)
        :StartIndexSearch for ($i = $EndIndex; $i -gt 0; $i--) { 
            if ($repadmin_showrepl[$i] -like '* via *') {
                $StartIndex = $i
                break StartIndexSearch
            }
        }
        $showrepl_failure_context += $repadmin_showrepl[$StartIndex..$EndIndex]
    }

    if ($showrepl_failure_context.count -ge 1) { 
        return [PSCustomObject]@{
            Report        = $repadmin_showrepl -join "`n`n"
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] Repadmin Showrepl Failures: " + ($showrepl_failure_context -join "`n")
        }
    }
} # END function repadminShowrepl

function repadminReplsum {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Replication Summary..." -ForegroundColor Cyan

    $repadmin_replsum = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        repadmin /replsum
    } -ErrorAction Stop

    $SourceStartIndex = $repadmin_replsum.IndexOf($repadmin_replsum -like 'Source DSA*') + 1
    $SourceEndIndex = $repadmin_replsum.IndexOf($repadmin_replsum -like 'Destination DSA*') - 1
    $SourceReport = $repadmin_replsum[$SourceStartIndex..$SourceEndIndex].Trim() -replace ' {4,}', ',' -replace ' ', '' | ConvertFrom-Csv -Header @($repadmin_replsum -like 'Source DSA*' -replace ' {2,}', ',' -replace ' %%', ',%%' -split ',')

    $DestinationStartIndex = $repadmin_replsum.IndexOf($repadmin_replsum -like 'Destination DSA*') + 1
    $DestinationReport = $repadmin_replsum[$DestinationStartIndex..$repadmin_replsum.count].Trim() -replace ' {4,}', ',' -replace ' ', '' | ConvertFrom-Csv -Header @($repadmin_replsum -like 'Destination DSA*' -replace ' {2,}', ',' -replace ' %%', ',%%' -split ',')

    $checkReportSummary = @()
    $checkReportSummary += $SourceReport.Where({ $_.'error' })
    $checkReportSummary += $DestinationReport.Where({ $_.'error' })

    if ($checkReportSummary.count -gt 0) {
        $issueDetails = $checkReportSummary | ForEach-Object { $_ | Out-String }
        return [PSCustomObject]@{
            Report        = $repadmin_replsum -join "`n`n"
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] Repadmin Replsum Errors: " + ($issueDetails -join "`n")
        }
    }
} # END function repadminReplsum

function dcdiag {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Running DCDiag /q /c..." -ForegroundColor Cyan

    # /c - comprehensive - runs all tests
    # /q - quiet - only shows errors and warnings
    $dcdiag = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        dcdiag /q /c
    } -ErrorAction Stop

    $dcdiag_ReportSummary = ($dcdiag -match 'failed test')
    if ($dcdiag_ReportSummary.count -gt 0) {
        [array]$dcdiag_ReportSummary = $dcdiag_ReportSummary.Trim().TrimStart('.').Trim().Foreach({ 
                "[$($MyInvocation.MyCommand.Name)] DCDiag Failed: " + $_.split(' ')[-1]
            })
        return [PSCustomObject]@{
            Report        = ($dcdiag.split("`n") -join "`n")
            ReportSummary = $dcdiag_ReportSummary
        }
    }
} # END function dcdiag

function w32tm {
    param($ComputerName = $env:COMPUTERNAME, $PDCe = $PDCe, $ExternalTimeSource = $ExternalTimeSource)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Time Service..." -ForegroundColor Cyan

    $w32tm = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        w32tm /query /status
    } -ErrorAction Stop

    $w32tm = $w32tm.split("`n").Trim()

    $ReportSummary = @()
    if ($w32tm -match 'Stratum: 0') {
        $ReportSummary += '[ISSUE] W32TM Stratum 0 (unsynchronized)'
    }
    if ($w32tm -match 'Source: Local CMOS Clock') {
        $ReportSummary += '[ISSUE] W32TM Source is Local CMOS Clock'
    }
    if ($w32tm -match 'Free-running System Clock') {
        $ReportSummary += '[ISSUE] W32TM Free-running System Clock'
    }
    if ($w32tm -match 'The computer did not resync because no time data was available') {
        $ReportSummary += '[ISSUE] W32TM No time data was available for resync'
    }
    if ($w32tm -match 'The computer did not resync because the maximum allowed time correction was exceeded') {
        $ReportSummary += '[ISSUE] W32TM Maximum allowed time correction exceeded for resync'
    }
    if ($w32tm -match 'The computer did not resync because the time provider is disabled') {
        $ReportSummary += '[ISSUE] W32TM Time provider is disabled'
    }
    if ($w32tm -match 'The computer did not resync because the time service is not running') {
        $ReportSummary += '[ISSUE] W32TM Time service is not running'
    }

    if ($ComputerName -eq $PDCe) {
        if (![Bool]($w32tm -match "Source: ($($ExternalTimeSource -join '|')).{1,}")) {
            $ReportSummary += "[$($MyInvocation.MyCommand.Name)] W32TM PDCe not syncing to external time source. " + $($w32tm -like 'Source: *')
        }
    }
    elseif (![Bool]($w32tm -like "Source: $PDCe")) {
        $ReportSummary += "[$($MyInvocation.MyCommand.Name)] W32TM non-PDCe should be syncing from the PDCe ($PDCe). " + $($w32tm -like 'Source: *')
    }

    if ($ReportSummary.Count -gt 0) {
        return [PSCustomObject]@{
            Report        = $w32tm -split "`n" -join "`n`n"
            ReportSummary = $ReportSummary
        }
    }
} # END function w32tm

function LastReboot {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking When Last Reboot..." -ForegroundColor Cyan

    $LastBootupTime = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        (Get-CimInstance -ClassName win32_operatingsystem -Property lastbootuptime).lastbootuptime
    } -ErrorAction Stop

    if (((Get-Date) - $LastBootupTime).TotalDays -gt $DCTests_RebootThreshold) {
        return [PSCustomObject]@{
            Report        = "Last Bootup Time: $LastBootupTime"
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] Has not been rebooted in $(((Get-Date)-$LastBootupTime).Days) Days"
        }
    }
} # END function LastReboot

function osLicense {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking OS License..." -ForegroundColor Cyan

    $licenseStatus = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        (Get-CimInstance -ClassName SoftwareLicensingProduct -Filter 'PartialProductKey IS NOT NULL AND LicenseStatus IS NOT NULL').LicenseStatus
    } -ErrorAction Stop

    if ($licenseStatus -notcontains 1) {
        return [PSCustomObject]@{
            Report        = $licenseStatus -join "`n`n"
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] OS is not properly licensed. LicenseStatus: " + ($licenseStatus -join ', ')
        }
    }
} # END function osLicense

function cpu {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking CPU..." -ForegroundColor Cyan


    $cpuLoad = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-CimInstance -ClassName 'Win32_Processor' | Select-Object -ExpandProperty LoadPercentage
    } -ErrorAction Stop

    if ($cpuLoad -gt $DCTests_CPUThreshold) {
        return [PSCustomObject]@{
            Report        = $cpuLoad -join "`n`n"
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] High CPU Usage: $cpu`%"
        }
    }
} # END function cpu

function disk {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Disk..." -ForegroundColor Cyan
    
    $disk = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-CimInstance -ClassName 'Win32_LogicalDisk' -Filter 'DriveType=3' | Select-Object 'DeviceID', @{Name = 'FreeSpacePercent'; Expression = { [math]::Round(($_.FreeSpace / $_.Size) * 100, 2) } }
    } -ErrorAction 'Stop' -UseSSL

    if ($disk.FreeSpacePercent -gt 0) {
        $lowSpaceDrives = $disk | Where-Object { $_.FreeSpacePercent -lt $DCTests_DiskThreshold } | ForEach-Object { "$($_.DeviceID): $($_.FreeSpacePercent)`%" }
        if ($lowSpaceDrives.Count -gt 0) {
            return [PSCustomObject]@{
                Report        = $disk
                ReportSummary = "[$($MyInvocation.MyCommand.Name)] Low Disk Space on Drives: " + ($lowSpaceDrives -join ', ')
            }
        }
    }
    else {
        return [PSCustomObject]@{
            Report        = $null
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] Unable to determine disk space."
        }
    }
} # END function disk

function memory {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Memory..." -ForegroundColor Cyan

    $memory = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $totalMemory = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        $freeMemory = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        $usedMemoryPercent = [math]::Round((($totalMemory - $freeMemory) / $totalMemory) * 100, 2)
        return [PSCustomObject]@{ 
            TotalMemoryGB     = $totalMemory
            FreeMemoryGB      = $freeMemory
            UsedMemoryPercent = $usedMemoryPercent 
        }
    } -ErrorAction Stop

    if ($memory.UsedMemoryPercent -gt $DCTests_MemoryThreshold) {
        return [PSCustomObject]@{
            Report        = $memory
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] High Memory Usage: $($memory.UsedMemoryPercent)`%"
        }
    }
} # END function memory

function RequiredSoftware {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Required Software..." -ForegroundColor Cyan

    try {
        $installedSoftware = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-CimInstance -ClassName Win32_Product | 
                Select-Object PSComputerName, Name, Caption, Version
        } -ErrorAction Stop
    }
    catch {
        return [PSCustomObject]@{
            Report        = $null
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] Unable to retrieve installed software. $_"
        }
    }

    $ReportSummary = @()
    :requiredSoftware foreach ($software in $RequiredSoftware) {
        $SoftwareInstances = $installedSoftware.Where({ $_.Name -eq $software.Name })
        
        if ($SoftwareInstances.Count -eq 0) {
            $ReportSummary += "[ISSUE] Required software '$($software.Name)' is not installed."
            continue requiredSoftware
        }
        elseif ($SoftwareInstances.Count -gt 1) {
            $ReportSummary += "[ISSUE] Multiple instances of required software '$($software.Name)' are installed."
        }
        elseif ($software.Version -and ($SoftwareInstances.Version -ne $software.Version)) {

            if ($software.Version -like '*.*') {
                if ($software.Version.length -eq $SoftwareInstances.version.length) {
                    if ([int64]($software.version.replace('.', '')) -lt [int64]($SoftwareInstances.version.replace('.', ''))) {
                        $ReportSummary += "[ISSUE] Required software '$($software.Name)' is lower than installed. Expected: $($software.Version), Found: $($SoftwareInstances.Version)"
                    }
                    elseif ([int64]($software.version.replace('.', '')) -lt [int64]($SoftwareInstances.version.replace('.', ''))) {
                        $ReportSummary += "[ISSUE] Required software '$($software.Name)' is out of date. Expected: $($software.Version), Found: $($SoftwareInstances.Version)"
                    }
                }
            }
            else {
                $ReportSummary += "[ISSUE] Required software '$($software.Name)' version mismatch. Expected: $($software.Version), Found: $($SoftwareInstances.Version)"
            }
        }
    }

    if ($ReportSummary.Count -gt 0) {
        return [PSCustomObject]@{
            Report        = $installedSoftware
            ReportSummary = $ReportSummary
        }
    }
} # END function RequiredSoftware

function MissingSubnets {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Missing Subnets..." -ForegroundColor Cyan
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $netLogonLogPath = 'C:\Windows\debug\netlogon.log'

        if (-not (Test-Path -Path $netlogonLogPath)) {
            return [PSCustomObject]@{
                Report        = $null
                ReportSummary = "[$($MyInvocation.MyCommand.Name)] Netlogon log file not found at $netlogonLogPath"
            }
        }

        try {
            $netLogonLog = Get-Content $netlogonLogPath -ErrorAction Stop
        }
        catch {
            return [PSCustomObject]@{
                Report        = $null
                ReportSummary = "[$($MyInvocation.MyCommand.Name)] Unable to read Netlogon log file at $netlogonLogPath. $_"
            }
        }

        $missingSubnets = @()        
        $netLogonLog -match 'NO_CLIENT_SITE' | ForEach-Object {
            $data = $_.split(' ')
            if (!$missingSubnets.Contains($Data[-1])) {
                $missingSubnets += $data[-1]
            }
        }

        if ($missingSubnets.Count -gt 0) {
            return [PSCustomObject]@{
                Report        = $missingSubnets -join "`n"
                ReportSummary = "[$($MyInvocation.MyCommand.Name)] $($missingSubnets.count) IPs Missing Subnets in ADSS"
            }
        }
    } -ErrorAction Stop
} # END function MissingSubnets

function PatchingHistory {
    param($ComputerName = $env:COMPUTERNAME)
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Patching History..." -ForegroundColor Cyan

    $patchingHistory = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $historyCount = $updateSearcher.GetTotalHistoryCount()

        $updateSearcher.QueryHistory(0, $historyCount) | 
            Where-Object { $_.ResultCode -eq 2 } | 
            Sort-Object -Property Date -Descending
    } -ErrorAction Stop

    if ($patchingHistory.Count -eq 0) {
        return [PSCustomObject]@{
            Report        = $null
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] No patches found in update history."
        }
    }

    [DateTime]$lastPatchDate = $patchingHistory[0].Date
    $daysSinceLastPatch = (Get-Date) - $lastPatchDate
    if ($daysSinceLastPatch.Days -gt $DCTests_PatchingThreshold) {
        return [PSCustomObject]@{
            Report        = $patchingHistory
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] Last patch installed on $lastPatchDate, which is $($daysSinceLastPatch.Days) days ago."
        }
    }
} # END function PatchingHistory

function services {
    param(
        $ComputerName = $env:COMPUTERNAME
    )
    Write-Host "[$(Get-Date)] ($ComputerName) [$($MyInvocation.MyCommand.Name)] Checking Services..." -ForegroundColor Cyan

    $Services = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        Get-Service
    } -ErrorAction Stop

    $Issues = @()
    foreach ($ServiceConfiguration in $ServicesConfigurations) {
        Remove-Variable Service -ErrorAction SilentlyContinue
        $Service = $Services.Where({ $_.Name -eq $ServiceConfiguration.Name })

        if (![Bool]$Service.Name) {
            $Issues += "[WARNING] Service $($ServiceConfiguration.Name) not found"
        }
        if ($Service.Status -ne $ServiceConfiguration.Status) {
            $Issues += "[ISSUE] Service $($Service.Name) status is not $($ServiceConfiguration.Status) ($($Service.Status))"
        }
        if ($Service.StartType -ne $ServiceConfiguration.StartType) {
            $Issues += "[ISSUE] Service $($Service.Name) start type is not $($ServiceConfiguration.StartType) ($($Service.StartType))"
        }
    }

    if ($Issues.count -gt 0) {
        return [PSCustomObject]@{
            Report        = $Issues -join "`n"
            ReportSummary = "[$($MyInvocation.MyCommand.Name)] Problematic service configurations: $($Issues.count)"
        }
    }
} # END function services
