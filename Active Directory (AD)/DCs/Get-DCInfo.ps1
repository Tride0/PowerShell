<#
    Created By: Kyle Hewitt
    Created On: 2025-8-26
       Version: 2026.4.8
       Description: This script gathers information about Domain Controllers in specified domains, including hardware details, operating system, and licensing status.
#>

param(
    [string[]]$Domains = @(
        $ENV:USERDNSDOMAIN
    ),
    [String[]]$CheckForServices = @(
        'CcmExec' # SCCM
        'ir_agent' # Rapid7
        'r7ScanAssistant' # Rapid7
        'CSFalconService' # CrowdStrike
        'HealthService' # SCOM
        'SplunkForwarder' # Splunk
    )
)

$OutputResults = @()
$j = 0
$jTotal = $Domains.Count
:Domains foreach ($Domain in $Domains) {
    $j ++
    Write-Host "[$(Get-Date)] $j/$jTotal Processing Domain: $Domain" -ForegroundColor Cyan
    $CredentialSplat = @{
        #Credential = Get-Credential -Message "Enter Credentials for the Domain: $Domain"
    }

    $DCs = Get-ADDomainController -Filter * -Server $Domain @CredentialSplat
    Write-Host "Found $($DCs.Count) Domain Controllers"

    $i = 0
    $iTotal = $DCs.Count
    :DCs foreach ($DC in $DCs) {
        $i ++
        Write-Host "[$(Get-Date)] Processing DC $i/$iTotal`: $($DC.Hostname)" -ForegroundColor DarkCyan
        try {
            Write-Host "Querying Win32_ComputerSystem for $($DC.Hostname)" -ForegroundColor Blue
            $WMI_ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $DC.HostName -ErrorAction Stop @CredentialSplat
            Write-Host "Querying Win32_Processor for $($DC.Hostname)" -ForegroundColor Blue
            $WMI_Processor = Get-WmiObject -Class Win32_Processor -ComputerName $DC.HostName -ErrorAction Stop @CredentialSplat
            Write-Host "Querying Win32_BIOS for $($DC.Hostname)" -ForegroundColor Blue
            $WMI_BIOS = Get-WmiObject -Class Win32_BIOS -ComputerName $DC.HostName -ErrorAction Stop @CredentialSplat
            Write-Host "Querying Win32_LogicalDisk for $($DC.Hostname)" -ForegroundColor Blue
            $WMI_LogicalDisk = Get-WmiObject Win32_LogicalDisk -ComputerName $DC.HostName -ErrorAction Stop @CredentialSplat
            Write-Host "Querying SoftwareLicensingProduct for $($DC.Hostname)" -ForegroundColor Blue
            $WMI_SoftwareLicensingProduct = Get-WmiObject SoftwareLicensingProduct -ComputerName $DC.HostName -ErrorAction Stop @CredentialSplat
            Write-Host "Querying Win32_Service for $($DC.Hostname)" -ForegroundColor Blue
            $WMI_Services = Get-WmiObject -Class Win32_Service -ComputerName $DC.HostName -ErrorAction Stop @CredentialSplat
        }
        catch {
            Write-Host "ERROR: Failed to get a WMI. ERROR: $_" -ForegroundColor Red
            $OutputResults += [psCustomObject]@{
                Domain          = $Domain
                ComputerName    = $DC.Name
                HostName        = $DC.HostName
                IP              = $DC.IPv4Address
                FSMORoles       = ($DC.OperationMasterRoles -join ', ')
                OS              = 'Failed to query WMI'
                SerialNumber    = ''
                CPU_Cores       = ''
                CPU_Speed       = ''
                Memory_Capacity = ''
                Storage         = ''
                OS_License      = ''
                Virtual         = ''
            }
            continue DCs
        }

        $IPAddress = $DC.IPv4Address
        if ($IPAddress -notmatch '\d+\.\d+\.\d+\.\d+') {
            try {
                $IPAddress = (Resolve-DnsName -Name $DC.HostName -ErrorAction Stop).IPAddress
            }
            catch {
                $IPAddress = 'Unknown'
                Write-Host "ERROR: Failed to Determine IP. ERROR: $_"
            }
        }

        $OperatingSystem = $DC.OperatingSystem
        if ($OperatingSystem -eq '') {
            $WMI_OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $DC.HostName -ErrorAction Stop @CredentialSplat
            $OperatingSystem = $WMI_OperatingSystem.Caption
        }

        $SerialNumber = $WMI_BIOS.SerialNumber
        $MemoryCapacity = [System.Math]::Round($WMI_ComputerSystem.TotalPhysicalMemory / 1GB, 2)
        
        $CPUCores = $WMI_ComputerSystem.NumberOfLogicalProcessors
        $CPUSpeed = ($WMI_Processor.MaxClockSpeed | Sort-Object -Unique) -join ', '
        
        $Storage = (
            $WMI_LogicalDisk |
                Where-Object { $_.Size -ne $null } |
                Select-Object DeviceID,
                @{Name = 'Size(GB)'; Expression = { [math]::Round($_.Size / 1GB, 2) } },
                @{Name = 'UsedSpace(GB)'; Expression = { [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2) } },
                @{Name = 'Capacity(%)'; Expression = { [math]::Round(((($_.Size - $_.FreeSpace) / $_.Size) * 100), 2) } } | ForEach-Object {
                    "$($_.DeviceID) $($_.'UsedSpace(GB)')GB / $($_.'Size(GB)')GB ($($_.'Capacity(%)') % Used)"
                }
        ) -join ', '

        $IsVirtual = (
            $WMI_ComputerSystem.Model -like 'Virtual' -or 
            $WMI_ComputerSystem.Manufacturer -like 'Microsoft Corporation' -or
            $WMI_BIOS.SerialNumber -like 'VMware*' -or 
            $WMI_BIOS.SerialNumber -like 'Microsoft Corporation*'
        )

        $ActivationStatus = $WMI_SoftwareLicensingProduct | Where-Object { $_.PartialProductKey } | Select-Object LicenseStatus
        $LicenseStatus = $ActivationStatus.LicenseStatus
        $LicenseResult = $(
            switch ($LicenseStatus) {
                0 { 'Unlicensed' }
                1 { 'Licensed' }
                2 { 'OOBGrace' }
                3 { 'OOTGrace' }
                4 { 'NonGenuineGrace' }
                5 { 'Not Activated' }
                6 { 'ExtendedGrace' }
                default { 'unknown' }
            }
        ) | Sort-Object -Unique
        

        $ServicesStatus = @()
        foreach ($Service in $CheckForServices) {
            Remove-Variable ServiceInfo -ErrorAction SilentlyContinue
            $ServiceInfo = $WMI_Services | Where-Object { $_.Name -eq $Service }
            if ($ServiceInfo) {
                $ServicesStatus += "$($Service): $($ServiceInfo.State)"
            }
            else {
                $ServicesStatus += "$($Service): Not Found"
            }
        }

        $OutputResults += [PSCustomObject]@{
            Domain          = $Domain
            ComputerName    = $DC.Name
            HostName        = $DC.HostName
            IP              = $IPAddress
            FSMORoles       = ($DC.OperationMasterRoles -join ', ')
            OS              = $OperatingSystem
            SerialNumber    = $SerialNumber
            CPU_Cores       = $CPUCores
            CPU_Speed       = $CPUSpeed
            Memory_Capacity = $MemoryCapacity
            Storage         = $Storage
            OS_License      = $LicenseResult
            Virtual         = $IsVirtual
            Services        = ($ServicesStatus -join ', ')
        }
        $OutputResults[-1]
    }
}

$OutputResults.Count

$OutputResults | ConvertTo-Csv -NoTypeInformation | CLIP
Write-Host 'Converted to CSV and Copied to Clipboard' -ForegroundColor Green
