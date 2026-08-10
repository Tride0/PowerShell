<#
           Name: Push Item
     Created By: Kyle Hewitt
     Created On: Early 2017
        Version: 2025.7.24
      ShortName: PIT
        Purpose: To copy and/or execute files on remote computers.
          Notes: To execute files, they should be able to run silently, quietly, and non-interactively.
#>

# Delay Script by Seconds
$StartDelay = 0
# Will not Copy, Execute or Wait
$Preview = $False
# Will Output Progress to Console
$ConsoleOutput = $True
# Refresh Stored Computer Information
$RefreshComputerInformation = $False

$DefaultExtProgram = @{
    '.MSI' = 'msiexec.exe'
    '.MSP' = 'msiexec.exe'
    '.MSU' = 'wusa.exe'
    '.PS1' = 'powershell.exe'
}

$DefaultExtensionArguments = @{
    '.PS1' = '-NonInteractive -NoProfile -WindowStyle Hidden -File'
    '.MSI' = '/i'
    '.MSP' = '/quiet /norestart /update'
    '.MSU' = '/quiet /norestart'
}

$Packages = @(
    <# #START NOTES
    @{
        "Enabled"                   = $True # If False Package Will be skipped.
        # Computers   
        'Computers'                 = @() # Can be Array of Strings or File Path to txt list of computers to Include, supports AD Paths, Files
        'ExcludeComputers'          = @() # Can be Array of Strings or File Path to txt list of computers to Exclude from the Include List
        'Credential'                = $null # Must be in a proper format similar to Get-Credential
        # Procedures   
        'DestinationPath'           = 'C:\temp' # File Path must exist or must be able to be created
        'Copy'                      = $True # Copy PushItem to DestinationPath
        'CopyFolder'                = $False # Copy PushItem's Parent Folder
        'Overwrite'                 = $False # If file exists on remote system, Overwrite it
        # Files   
        'PushItem'                  = 'C:\USER\Desktop\File64.msi' # 64bit String FilePath or ScriptBlock
        '32PushItem'                = 'C:\USER\Desktop\File32.msi' # 32bit String FilePath or ScriptBlock
        'Execute'                   = $True # Executes PushItem Path
        'Arguments'                 = '' # Arguments specified after the PushItem
        'ExtensionArguments'        = '' # Arguments specified before the PushItem
        # Delays   
        'ComputerGroupCount'        = 0 # Numbers of Computers to run before Delaying
        'ComputerGroupDelaySeconds' = 0 # Seconds to Delay after ComputerGroupCount is met
        'PrePackageDelaySeconds'    = 0 # Wait Before Package Runs
        'PostPackageDelaySeconds'   = 0 # Wait After Package is Done
        'WaitForProcessID'          = $True # Wait for ProcessID to finish before continuing
        # Clean Up
        'CleanUp'                   = $False # Remove Files after execute, using this could cause the program to not install correctly if clean up happens before it finishes. Especially if using CopyFolder = $True
        'PreCleanUpDelaySeconds'    = 0 # Wait before cleaning up
        'CleanURetryWaitSeconds'    = 300 # Wait Retrying Clean up
        'CleanUpWaitSeconds'        = 300 # Wait before cleaning up
        'CleanUpRetryCount'         = 3 # If CleanUp errored, it will retry after waiting again
        # Logging   
        'LogPath'                   = "$PSScriptRoot\PIT_$(Get-Date -Format yyyyMMdd_hhmmss).log" # Remove to not log
        'LogPathFailures'           = "$PSScriptRoot\PIT_Packages_Failures_$(Get-Date -Format yyyyMMdd_hhmmss).csv" # Remove to not log
    }

    #> #END NOTES # Example Package
    @{
        'Enabled'                    = $True
        # Computers
        'Computers'                  = @(
            
        )
        'ExcludeComputers'           = @()
        'Credential'                 = $null
        # Procedures
        'DestinationPath'            = 'C:\temp'
        'Copy'                       = $True
        'CopyFolder'                 = $False
        'Overwrite'                  = $True
        # Files
        'PushItem'                   = ''
        '32PushItem'                 = ''
        'Execute'                    = $True
        'Arguments'                  = ''
        'ExtensionArguments'         = ''
        # Delays
        'ComputerGroupCount'         = 0
        'ComputerGroupDelaySeconds'  = 0
        'PrePackageDelaySeconds'     = 0
        'PostPackageDelaySeconds'    = 0
        'WaitForProcessID'           = $True
        # Clean Up
        'CleanUp'                    = $False
        'DelayCleanFromStartSeconds' = 0
        'DelayCleanFromEndSeconds'   = 0
        'CleanURetryWaitSeconds'     = 300
        'CleanUpRetryCount'          = 3
        # Logging
        'LogPath'                    = "$PSScriptRoot\PIT\Logs\PIT_$(Get-Date -Format yyyyMMdd_hhmm).log"
        'LogPathFailures'            = "$PSScriptRoot\PIT\Logs\PIT_Packages_Failures_$(Get-Date -Format yyyyMMdd_hhmm).csv"
        # Monitor Completion
    }
)


#region Functions

function Add-ToLog {
    param(
        [Parameter(Mandatory, ValueFromPipeline)]$Value,
        $Path = $Package.LogPath,
        $LineBreaks = 0,
        $PostLineBreaks = 0,
        $ConsoleOutput = $ConsoleOutput
    )
    if (![Boolean]$Path) { $ConsoleOutput = $True }

    # Add Pre Line Breaks
    if ($LineBreaks -gt 0) {
        1..$LineBreaks | ForEach-Object -Process {
            if ($ConsoleOutput) { Write-Host '' }
            if ($Path) {
                '' | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue
            }
        }
    }

    $Color = switch ($Value.Split(':')[0].Trim()) {
        'INFO' { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR' { 'Red' }
        'ACTION' { 'Green' }
        'DELAY' { 'Cyan' }
        { $_ -imatch 'PACKAGE' } { 'Magenta' }
        { $_ -imatch 'COMPUTER' } { 'DarkMagenta' }
        default { 'Gray' }
    }

    # Add Value
    if ($ConsoleOutput) { Write-Host "[$(Get-Date)] $($Value.Split("`n")[0])" -Verbose:$ConsoleOutput -ForegroundColor $Color }
    if ([Boolean]$Path) {
        "[$(Get-Date)] $($Value.Split("`n")[0])" | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue

        $Value.Split("`n") |
            Select-Object -Skip 1 |
                ForEach-Object {
                    if ($ConsoleOutput) { Write-Host "($($LogID)) $_" }
                    "($($LogID)) $_" | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue
                }
    }

    # Add Post Line Breaks
    if ($PostLineBreaks -gt 0) {
        1..$PostLineBreaks | ForEach-Object -Process {
            if ($ConsoleOutput) { Write-Host '' }
            if ([Boolean]$Path) {
                '' | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Remove-Variable ConsoleOutput, LogID -ErrorAction SilentlyContinue -Verbose:$False
} # End Function Add-ToLog

function Invoke-Retry {
    [CmdletBinding()]
    param(
        [ScriptBlock] $ScriptBlock,
        [Int] $RetryCount = 3,
        [Int] $RetryDelaySeconds = 1,
        [String[]] $RetryIfErrorContains,
        [scriptblock] $ScriptBlockIfError
    )
    $ErrorActionPreferencePrior = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    :RetryLoop for ($i = 1; $i -le $RetryCount; $i++) {
        try {
            $ScriptBlock.Invoke()
            $RetryFailed = $False
            break RetryLoop
        }
        catch {
            # Check If Should Retry
            $Retry = $False
            if ($i -lt $RetryCount) {
                if ([Boolean]$RetryIfErrorContains) {
                    :CheckForRetryLoop foreach ($String in $RetryIfErrorContains) {
                        if ("$_" -like "*$String*") {
                            $Retry = $True
                            break CheckForRetryLoop
                        }
                    }
                }
                else { $Retry = $True }
            }

            # Retry Wait or Break
            if ($Retry) {
                "(Invoke-Retry) ERROR: Retrying $i/$RetryCount in $RetryDelaySeconds seconds. $($_)" | Add-ToLog -ErrorAction SilentlyContinue
                # Run Script Block If Error
                if ($null -eq $ScriptBlockIfError) {
                    $ScriptBlockIfError.Invoke()
                }
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            else {
                $RetryFailed = $True
                $e = $($_)
                if ($i -ne 1) {
                    "(Invoke-Retry) ERROR: $i/$RetryCount Last Attempt $($_)" | Add-ToLog -ErrorAction SilentlyContinue
                }
                elseif ($i -eq 1) {
                    "(Invoke-Retry) ERROR: Last Attempt $($_)" | Add-ToLog -ErrorAction SilentlyContinue
                }
                break RetryLoop
            }
        }
    }

    $ErrorActionPreference = $ErrorActionPreferencePrior
    if ($RetryFailed) {
        throw "(Invoke-Retry): ScriptBlock Failed. $e"
    }
} # END Function Invoke-Retry

function Get-ADComputerNames {
    [CmdletBinding()]
    param($OU)
    $ErrorActionPreferencePrior = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    $Searcher = New-Object DirectoryServices.DirectorySearcher
    $Searcher.Filter = "(&(objectCategory=computer)(distinguishedName=*$OU))"
    $Searcher.SearchScope = 'Subtree'
    $Searcher.PropertiesToLoad.Add('Name')

    try {
        $Results = $Searcher.FindAll()
    }
    catch {
        $ErrorActionPreference = $ErrorActionPreferencePrior
        throw $_
    }

    $ComputerNames = @()
    foreach ($Result in $Results) {
        $ComputerNames += $Result.Properties.Name
    }

    return $ComputerNames
}

function Get-ComputerObjectsFromSource {
    [CmdletBinding()]
    param([array]$Source)

    $ReturnValues = @()
    foreach ($Src in $Source) {
        if ($Src -imatch '\r|\n') {
            $FoundComputers = $Src.Split('\n').Split('\r').Trim().Where({ $_ -ne '' })
            if ($FoundComputers -imatch '\\+|[a-z]{1}:|[a-z]{2}=+') {
                $ReturnValues += Get-ComputerObjectsFromSource -Source $FoundComputers
            }
            else {
                $ReturnValues += $FoundComputers
            }
        }
        elseif ($Src -imatch ',' -and $Src -inotmatch ',[a-z]{2}=') {
            return $Src.Split(',').Trim().Where({ $_ -ne '' })
            if ($FoundComputers -imatch '\\+|[a-z]{1}:') {
                $ReturnValues += Get-ComputerObjectsFromSource -Source $FoundComputers
            }
            else {
                $ReturnValues += $FoundComputers
            }
        }
        elseif ($Src -imatch ';') {
            $FoundComputers = $Src.Split(';').Trim().Where({ $_ -ne '' })
            if ($FoundComputers -imatch '\\+|[a-z]{1}:|[a-z]{2}=+') {
                $ReturnValues += Get-ComputerObjectsFromSource -Source $FoundComputers
            }
            else {
                $ReturnValues += $FoundComputers
            }
        }
        elseif ($Src -imatch '\\+|[a-z]{1}:') {
            try {
                if ((Test-Path $Src -PathType Leaf -ErrorAction Stop)) {
                    try {
                        $FoundComputers = (Get-Content $Src -ErrorAction Stop).Split('\n').split('\r').split(',').split(';').Trim()
                        "INFO: $($FoundComputers.Count) Computers found from file: $Src" | Add-ToLog
                        return $FoundComputers
                    }
                    catch {
                        "ERROR: Failed to Get Computer Objects from $Src. Skipping Package. ERROR: $_" | Add-ToLog
                        continue Packages
                    }
                }
                else {
                    "ERROR: Failed to Find $Src. Skipping Package." | Add-ToLog
                    continue Packages
                }
            }
            catch {
                "ERROR: Failed to Find $Src. Skipping Package. ERROR: $_" | Add-ToLog
                continue Packages
            }
        }
        elseif ($Src -imatch '[a-z]{2}=+') {
            try {
                $FoundComputers = Get-ADComputerNames $Src -ErrorAction Stop
                "INFO: $($FoundComputers.Count) AD Computers found at $Src" | Add-ToLog
                return $FoundComputers
            }
            catch {
                "ERROR: Failed to Get Computers from OU. ERROR: $_"
                continue Packages
            }
        }
    }
}

function ConvertTo-TimeRemaining {
    param(
        [DateTime]$TimeStarted,
        [int]$CurrentIteration,
        [int]$FinalIteration
    )
    if ($CurrentIteration -le 1) { return 'N/A' }
    $RemainingIterations = ($FinalIteration - $CurrentIteration)
    if ($RemainingIterations -le 0) { return 'N/A' }
    $TimeRemaining = ((Get-Date) - $TimeStarted).Milliseconds / ($CurrentIteration - 1) * $RemainingIterations

    switch ($TimeRemaining) {
        { $_ -le 1000 } {
            $Amount = $TimeRemaining
            $AmountType = 'ms'
        }
        { $_ -ge 86400000 } {
            $Amount = $TimeRemaining / 1000 / 60 / 60
            $AmountType = 'h'
        }
        { $_ -ge 3600000 } {
            $Amount = $TimeRemaining / 1000 / 60
            $AmountType = 'm'
        }
        { $_ -ge 60000 } {
            $Amount = $TimeRemaining / 1000
            $AmountType = 's'
        }
    }

    return @{
        Display = "$Amount$AmountType"
        EndTime = (Get-Date).Add([System.Math]::Round($TimeRemaining, 0)).ToString('yyyy-MM-dd HH:mm:ss')
    }
}

function Convert-HashToString {
    param(
        [parameter(ValueFromPipeLine)]$Hash,
        $KeyPairDelimiter = ' - ',
        $KeyValueDelimiter = ' : ',
        $ValueWrapper,
        $ValueWrapperStart,
        $ValueWrapperEnd,
        $KeyWrapper
    )

    if ($Hash -is 'PSCustomObject') {
        $Keys = $Hash.PSObject.Properties.name
    }
    else {
        $Keys = $Hash.Keys
    }

    $Str = @()
    foreach ($Key in $Keys) {
        $Value = $Hash.$Key
        
        if ($Value -is [Array]) {
            $Value = $Value | Convert-ArrayToString
        }

        $Str += "$(
            $KeyWrapper +
            $Key +
            $KeyWrapper +

            $KeyValueDelimiter +

            $ValueWrapperStart +
            $ValueWrapper +
            $Value +
            $ValueWrapper +
            $ValueWrapperEnd
        )"
    }

    return ($Str -join $KeyPairDelimiter)
} # END Function Convert-HashToString

function Convert-ObjectToHash {
    param([parameter(ValueFromPipeLine)]$Object)
    $Hash = @{}
    foreach ($Property in $Object.PSObject.properties) {
        $Hash[$Property.Name] = $Property.Value
    }
    return $Hash
} # END Function Convert-ObjectToHash

#endregion Functions


#region Variables

# This is here to store information about certain computers into long-term script memory so it doesn't re-do checks.
if ($null -eq $ComputerStore -or $RefreshComputerInformation) {
    $ComputerStore = @{}
}

#endregion Variables


if ($StartDelay -gt 0 -and !$Preview) {
    "DELAY: $StartDelay seconds. Will Start at $(([DateTime]::Now).AddSeconds($StartDelay))." | Add-ToLog
    [Threading.Thread]::Sleep($StartDelay * 1000)
}

$PackagesLoopStart = Get-Date
$i = 0
$iTotal = $Packages.Count
:Packages foreach ($Package in $Packages) {
    $i ++
    $LogFailures = @()

    $ETA = ConvertTo-TimeRemaining -TimeStarted $PackagesLoopStart -CurrentIteration $i -FinalIteration $iTotal
    "START PACKAGE: $i\$iTotal {ETA: $($ETA.EndTime) ($($ETA.Display))} $($Package.PushItem)" | Add-ToLog -LineBreaks 1
    $Package.StartTime = Get-Date

    #region Checking Package for requirements

    if (!$Package.Enabled) {
        'WARNING: Package is Disabled' | Add-ToLog
        continue Packages
    }

    if ($Package.Computers.count -eq 0) {
        'WARNING: No Computers Specified. Skipping Package.' | Add-ToLog
        continue Packages
    }

    if (!$Package.Execute -and !$Package.Copy) {
        'WARNING: Execute and Copy are False. Skipping Package.' | Add-ToLog
        continue Packages
    }

    if (![Boolean]$Package.PushItem) {
        if (![Boolean]$Package.'32PushItem') {
            'WARNING: No Push Items Specified. Skipping Package.' | Add-ToLog
            continue Packages
        }
    }

    if ([Boolean]$Package.PushItem) {
        if (!(Test-Path $Package.PushItem -ErrorAction SilentlyContinue)) {
            'WARNING: Push Item File Not Found. Skipping Package.' | Add-ToLog
            continue Packages
        }
    }

    if ([Boolean]$Package.'32PushItem') {
        if (!(Test-Path $Package.'32PushItem' -ErrorAction SilentlyContinue)) {
            'WARNING: 32-Bit Push Item File Not Found. Skipping Package.' | Add-ToLog
            continue Packages
        }
    }

    if ($Package.LogPath) {
        try {
            New-Item -Path $Package.LogPath -ItemType File -ErrorAction Stop -Force
        }
        catch {
            "ERROR: Failed to Create LogPath: $($Package.LogPath). Skipping Package. ERROR: $_" | Add-ToLog
            continue Packages
        }
    }
    if ($Package.LogPathFailures) {
        try {
            New-Item -Path $Package.LogPathFailures -ItemType File -ErrorAction Stop -Force
        }
        catch {
            "ERROR: Failed to Create LogPath: $($Package.LogPath). Skipping Package. ERROR: $_" | Add-ToLog
            continue Packages
        }
    }

    # Support for Files and AD Paths
    foreach ($Entry in @($Package.Computers -imatch '[a-z]{2}=+|\\+|[a-z]{1}:|\r|\n|,|;')) {
        $Package.Computers += Get-ComputerObjectsFromSource -Source $Entry
        $Package.Computers.RemoveAt($Package.Computers.IndexOf($Entry))
    }
    
    # Remove Computers that were added to Excluded
    if ($Package.ExcludeComputers.Count -gt 0) {

        foreach ($Entry in @($Package.ExcludeComputers -imatch '[a-z]{2}=+|\\+|[a-z]{1}:|\r|\n|,|;')) {
            $Package.ExcludeComputers += Get-ComputerObjectsFromSource -Source $Entry
            $Package.ExcludeComputers.RemoveAt($Package.ExcludeComputers.IndexOf($Entry))
        }                           

        $ComputersCount = $Package.Computers.Count
        $Package.Computers = (Compare-Object $Package.Computers $Package.ExcludeComputers).Where({ $_.SideIndicator -eq '<=' }).InputObject
        "INFO: $($Package.Computers.Count) Computers Found Post Exclusions ($($ComputersCount - $Package.Computers.Count) Excluded)" | Add-ToLog

        if ($Package.Computers.Count -eq 0) {
            'WARNING: No Computers after Exclusions. Skipping Package.' | Add-ToLog
            continue Packages
        }
    }
    else { 
        "INFO: $($Package.Computers.Count) Computers Found" | Add-ToLog
    }

    # Package Delay
    if ($Package.PrePackageDelaySeconds -gt 0 -and !$Preview) {
        $PreWait = ((Get-Date) - $Package.StartTime).TotalSeconds
        "DELAY: $PreWait seconds. Continuing at $(([DateTime]::Now).AddSeconds($PreWait))." | Add-ToLog
        [Threading.Thread]::Sleep($PreWait * 1000)
    }

    #endregion Checking Package for requirements

    $ComputersLoopStart = Get-Date
    $j = 0
    $jTotal = $Package.Computers.Count
    :Computers foreach ($Computer in $Package.Computers) {
        Remove-Variable ComputerInfo, DestinationPath, OSArch, InstallPath, CopyPath, WMIProcess, ExecuteStatus -ErrorAction SilentlyContinue -Force
        $j ++

        $ETA = ConvertTo-TimeRemaining -TimeStarted $ComputersLoopStart -CurrentIteration $j -FinalIteration $jTotal
        "START COMPUTER: $j/$jTotal {ETA: $($ETA.EndTime) ($($ETA.Display))} $Computer" | Add-ToLog -LineBreaks 1

        if ($ComputerStore.ContainsKey($Computer)) { 
            if ($ComputerStore.$Computer.Ping -eq $False) {
                'WARNING: Failed to Ping. Skipping Computer.' | Add-ToLog
                continue Computers
            }
            elseif ($ComputerStore.$Computer.Credential -eq $False) {
                'WARNING: Cannot connect to machine. Skipping Computer.' | Add-ToLog
                continue Computers
            }
        }
        else {
            $ComputerStore.$Computer = @{
                Computer   = $Computer
                Ping       = $null
                Credential = $null
                OSArch     = $null
                Processes  = @{}
            }
        }

        $WMISplat = @{}

        # Ping Check
        try {
            $ComputerStore.$Computer.Ping = (Test-Connection -ComputerName $Computer -Count 1 -Quiet -ErrorAction Stop)
            "INFO: Ping: $($ComputerStore.$Computer.Ping)" | Add-ToLog
        }
        catch {
            'ERROR: Failed to Ping. Skipping Computer.' | Add-ToLog
            $ComputerStore.$Computer.Ping = $False
            $LogFailures += [PSCustomObject]@{
                Computer   = $Computer
                Package    = $PushItem
                Occurrence = 'Failed to Ping'
                Error      = $_
            }
            continue Computers
        }

        # WMI Check
        if ($null -ne $ComputerStore.$Computer.Credential) {
            if ($ComputerStore.$Computer.Credential -is 'CIMSession') {
                $WMISplat += @{ CimSession = $ComputerStore.$Computer.Credential }
            }
        }
        else {
            try {
                if ([Boolean]$Package.Credential) {
                    $WMISplat += @{ CimSession = New-CimSession -ComputerName $Computer -Credential $Package.Credential -ErrorAction Stop }
                }
                else {
                    # $WMIConnection = $null -ne (Get-WmiObject -ComputerName $Computer -List -Class Win32_Process -ErrorAction Stop)
                    $WMIConnection = Test-WSMan -ComputerName $Computer -ErrorAction Stop
                }
            }
            catch {
                "ERROR: Failed to Connect to WMI. ERROR: $_" | Add-ToLog
                $ComputerStore.$Computer.Credential = $False
                $LogFailures += [PSCustomObject]@{
                    Computer   = $Computer
                    Package    = $PushItem
                    Occurrence = 'Failed to Connect to WMI'
                    Error      = $_
                }
                continue Computers
            }
        }

        if (!$WMISplat.CimSession) {
            $WMISplat.ComputerName = $Computer
        }

        if ($WMIConnection -eq $False) {
            'WARNING: Failed to Connect to WMI. No Error' | Add-ToLog
            $LogFailures += [PSCustomObject]@{
                Computer   = $Computer
                Package    = $PushItem
                Occurrence = 'Failed to Connect to WMI'
                Error      = $_
            }
            continue Computers
        }

        if ([bool]$ComputerStore.$Computer.Processes.$i) {
            if ($Package.WaitForProcessID) {
                "INFO: Waiting for ProcessID $($ComputerStore.$Computer.Processes[$i]) to finish." | Add-ToLog

                $WaitProcessIDSplat = @{
                    Class       = 'Win32_Process'
                    Name        = 'Get'
                    Filter      = "ProcessId = '$($ComputerStore.$Computer.Processes[$i])'"
                    ErrorAction = 'Stop'
                }

                if ($WMISplat.CimSession) {
                    $WaitProcessIDSplat.CimSession = $WMISplat.CimSession
                }
                else {
                    $WaitProcessIDSplat.ComputerName = $Computer
                }

                try {
                    $WMIProcess = Get-CimInstance @WaitProcessIDSplat
                    $WaitStarted = Get-Date
                    while ($WMIProcess) {
                        Write-Progress -Id 1 -Activity "Waiting for ProcessID $($ComputerStore.$Computer.Processes[$i])" `
                            -Status "$(((Get-Date)-$WaitStarted).Seconds) Seconds Elapsed" `
                            -CurrentOperation 'Waiting...'
                        Start-Sleep -Seconds 5
                        $WMIProcess = Get-CimInstance @WaitProcessIDSplat
                    }
                    "INFO: ProcessID $($ComputerStore.$Computer.Processes[$i]) Finished." | Add-ToLog
                }
                catch {
                    "INFO: Cannot find ProcessID $($ComputerStore.$Computer.Processes[$i]). It may have already finished. Continuing. $_" | Add-ToLog
                }
                Write-Progress -Completed:$True -Id 1
            }
            $ComputerStore.$Computer.Processes.$i = $null
        }

        if (![Boolean]$Package.'32PushItem') {
            $PushItem = $Package.'PushItem'
        }
        else {
            # Get OS Architecture
            if ($ComputerStore.$Computer.OSArch -eq $False) {
                'WARNING: Previously could not determine OS Arch. Skipping Computer.' | Add-ToLog
                continue Computers
            }
            elseif (![Boolean]$ComputerStore.$Computer.OSArch) {
                try {
                    if ([IO.Directory]::Exists("\\$Computer\c$\Program Files (x86)")) { $OSArch = 64 }
                    elseif ([IO.Directory]::Exists("\\$Computer\c$\Program Files")) { $OSArch = 32 }
                    else { $OSArch = (Get-WmiObject win32_ComputerSystem -ComputerName $Computer -ErrorAction stop).SystemType -replace ('\D', '') }
                    $ComputerStore.$Computer.OSArch = $OSArch
                    "INFO: OS Arch: $($ComputerStore.$Computer.OSArch)" | Add-ToLog
                }
                catch {
                    $ComputerStore.$Computer.OSArch = $False
                    "ERROR: Could not determine OS Arch. Skipping Computer. ERROR: $_" | Add-ToLog
                    continue Computers
                }
            }

            # Select Push Item to use
            switch ($ComputerStore.$Computer.OSArch) {
                32 { $PushItem = $Package.'32PushItem' }
                64 { 
                    if (![bool]$Package.'PushItem') {
                        'WARNING: No 64Bit Item defined and x64 OS detected. Skipping Computer.' | Add-ToLog
                        continue Computers
                    }
                    $PushItem = $Package.'PushItem' 
                }
                default {
                    'ERROR: Failed to Get OS Architecture. Skipping Computer.' | Add-ToLog
                    $LogFailures += [PSCustomObject]@{
                        Computer   = $Computer
                        Package    = $PushItem
                        Occurrence = 'Failed to Get OS Arch'
                        Error      = $_
                    }
                    continue Computers
                }
            }
            "INFO: OS Architecture: $($ComputerStore.$Computer.OSArch)" | Add-ToLog
        }

        # Copy
        if ($Package.Copy -and !$Preview -and $PushItem -isnot 'ScriptBlock') {
            if ($Package.CopyFolder) { $CopyPath = Split-Path -Path $PushItem -Parent }
            else { $CopyPath = $PushItem }

            try {
                'INFO: Copying Item(s)' | Add-ToLog
                $DestinationPath = "\\$Computer\$($Package.DestinationPath.Replace(':','$'))"
                if ([Bool]$Package.Credential) {
                    Remove-PSDrive -Name 'T' -ErrorAction SilentlyContinue
                    New-PSDrive -Name 'T' -PSProvider FileSystem -Root $DestinationPath -ErrorAction Stop -Credential $Package.Credential | Out-Null
                    $DoesFileExistInDestination = Test-Path "T:\$(Split-Path $PushItem -Leaf)" -ErrorAction Stop
                    if (($DoesFileExistInDestination -and $Package.Overwrite) -or !$DoesFileExistInDestination -or $Package.CopyFolder) {
                        Copy-Item -Path $CopyPath -Destination T:\ -Recurse -Force:$Package.Overwrite -ErrorAction Stop
                    }
                    Remove-PSDrive -Name 'T' -ErrorAction Stop
                }
                else {
                    $DoesFileExistInDestination = Test-Path "$DestinationPath\$(Split-Path $PushItem -Leaf)" -ErrorAction Stop
                    if (($DoesFileExistInDestination -and $Package.Overwrite) -or !$DoesFileExistInDestination -or $Package.CopyFolder) {
                        Copy-Item -Path $CopyPath -Destination $DestinationPath -Recurse -Force:$Package.Overwrite -ErrorAction Stop
                    }
                    'ACTION: Copied Item(s)' | Add-ToLog
                }
            }
            catch {
                "ERROR: Failed to Copy $CopyPath. Skipping Computer. ERROR: $_" | Add-ToLog
                $LogFailures += [PSCustomObject]@{
                    Computer   = $Computer
                    Package    = $PushItem
                    Occurrence = 'Failed to Copy'
                    Error      = $_
                }
                continue Computers
            }
        }

        # Execute
        if ($Package.Execute -and !$Preview) {
            if ($Package.CopyFolder) {
                $InstallPath = "$($Package.DestinationPath)\$(Split-Path (Split-Path $PushItem -Parent) -Leaf)\$(Split-Path $PushItem -Leaf)"
            }
            else {
                $InstallPath = "$($Package.DestinationPath)\$(Split-Path $PushItem -Leaf)"
            }
            $FileExtension = [IO.Path]::GetExtension($InstallPath)

            $PreArguments = $DefaultExtensionArguments[$FileExtension]
            if ($Package.ExtensionArguments) {
                $PreArguments = $Package.ExtensionArguments
            }
            
            $PostArguments = ''
            if ($Package.Arguments) {
                $PostArguments = $Package.Arguments
            }

            if ($DefaultExtProgram.ContainsKey($FileExtension)) {
                $CmdLineArgument = "$($DefaultExtProgram[$FileExtension]) $PreArguments `"$InstallPath`" $PostArguments"
                "INFO: CommandLine: $CmdLineArgument" | Add-ToLog
            }
            elseif ($FileExtension -eq 'ScriptBlock') {
                $CmdLineArgument = "$($DefaultExtProgram['ScriptBlock']) $PreArguments $PushItem $PostArguments"
                "INFO: CommandLine: $CmdLineArgument" | Add-ToLog
                $CmdLineArgument = $CmdLineArgument.Replace('[ScriptBlock]', $PushItem)
            }
            else {
                $CmdLineArgument = "$InstallPath $PostArguments"
                "INFO: CommandLine: $CmdLineArgument" | Add-ToLog
            }

            $CmdLineArgument = $CmdLineArgument.Replace('[Computer]', $Computer)

            if ($PushItem -is 'ScriptBlock') {
                try {
                    Invoke-Command @WMISplat -ScriptBlock $PushItem -ErrorAction Stop
                    "ACTION: Successfully Executed ScriptBlock on $Computer" | Add-ToLog
                }
                catch {
                    "ERROR: Failed to Execute ScriptBlock on $Computer. ERROR: $_" | Add-ToLog
                    $LogFailures += [PSCustomObject]@{
                        Computer   = $Computer
                        Package    = $PushItem.ToString()
                        Occurrence = 'Failed to Execute ScriptBlock'
                        Error      = $_
                    }
                    continue Computers
                }
            }
            else {
                $WMISplat += @{
                    Class = 'Win32_Process' 
                    Name  = 'Create'
                }

                try {
                    $ExecuteStatus = Invoke-CimMethod @WMISplat -Arguments @{ CommandLine = $CmdLineArgument } -ErrorAction Stop
                    $ComputerStore.$Computer.Processes.$i = $ExecuteStatus.ProcessId
                    "INFO: ProcessID: $($ExecuteStatus.ProcessId)" | Add-ToLog
                    switch ($ExecuteStatus.ReturnValue) {
                        0 { "ACTION: Successfully Started Program. ProcessID: $($ExecuteStatus.ProcessId)" | Add-ToLog }
                        2 { "ERROR: Failed To Started Program: Access Denied ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                        3 { "ERROR: Failed To Started Program: Insufficient Privilege($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                        8 { "ERROR: Failed To Started Program: Unknown Failure ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                        9 { "ERROR: Failed To Started Program: Path Not Found ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                        21 { "ERROR: Failed To Started Program: Invalid Parameter ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                        default { "ERROR: Failed To Started Program: Other-Unknown ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                    }
                    if ($ExecuteStatus.ReturnValue -ne 0) {
                        $LogFailures += [PSCustomObject]@{
                            Computer   = $Computer
                            Package    = $PushItem
                            Occurrence = 'Failed to Start Program'
                            Error      = $ExecuteStatus.ReturnValue
                        }
                    }
                }
                catch {
                    "ERROR: Failed to Invoke WMI Method. Error: $_" | Add-ToLog
                    $LogFailures += [PSCustomObject]@{
                        Computer   = $Computer
                        Package    = $PushItem
                        Occurrence = 'Failed to Invoke WMI Method'
                        Error      = $_
                    }
                }
            }
        }

        #Wait Between Defined # of Computers
        if ($Package.DelayGroupWaitSeconds -gt 0 -and ($j % $($Package.ComputerGroupCount)) -eq 0 -and !$Preview) {
            "DELAY: $($Package.DelayGroupWaitSeconds) seconds. Next Computer at $(([DateTime]::Now).AddSeconds($Package.DelayGroupWaitSeconds))." | Add-ToLog
            [Threading.Thread]::Sleep($Package.DelayGroupWaitSeconds * 1000)
        }

        "END COMPUTER: $j\$jTotal $Computer" | Add-ToLog
    }

    if ($LogFailures.Count -gt 1 -and [boolean]$Package.LogPathFailures) {
        try {
            New-Item -Path $Package.LogPathFailures -ItemType File -ErrorAction Stop -Force | Out-Null
            $LogFailures | Export-Csv $Package.LogPathFailures -NoTypeInformation -ErrorAction Stop -Force
        }
        catch {
            "ERROR: Failed to Export Failures to $LogPathFailures. ERROR: $_" | Add-ToLog
        }
    }

    if ($Package.PostPackageDelaySeconds -gt 0 -and !$Preview) {
        "DELAY: $($Package.PostPackageDelaySeconds) seconds. Continuing at $(([DateTime]::Now).AddSeconds($Package.PostPackageDelaySeconds))." | Add-ToLog
        [Threading.Thread]::Sleep($Package.PostPackageDelaySeconds * 1000)
    }

    $Package.EndTime = Get-Date
    "END PACKAGE: $i\$iTotal $($Package.PushItem)" | Add-ToLog -LineBreaks 1
}

#region Monitor Completion

'START: Monitor Package Completion' | Add-ToLog -LineBreaks 2

$i = 0
:CompletionMonitor foreach ($Package in $Packages) {
    $i ++
    :Computers foreach ($Computer in $Package.Computers) {
        if (!$ComputerStore.ContainsKey($Computer)) {
            'WARNING: No Computer Info was Stored. Skipping Computer.' | Add-ToLog
            continue Computers
        }

        if (!$ComputerStore.$Computer.Ping) {
            'WARNING: Ping Failed Earlier. Skipping Computer.' | Add-ToLog
            continue Computers
        }

        $ProcessID = $ComputerStore.$Computer.Processes.$i

        if ($null -eq $ProcessID) {
            'INFO: No ProcessID to wait for. Skipping.' | Add-ToLog
            continue Computers
        }

        $WaitProcessIDSplat = @{
            ComputerName = $Computer
            Class        = 'Win32_Process'
            Name         = 'Get'
            Filter       = "ProcessId = '$($ProcessID)'"
            ErrorAction  = 'Stop'
        }

        if ($null -ne $ComputerStore.$Computer.Credential) {
            if ($ComputerStore.$Computer.Credential -is 'CIMSession') {
                $WaitProcessIDSplat += @{ CimSession = $ComputerStore.$Computer.Credential }
            }
        }
        else {
            try {
                if ([Boolean]$Package.Credential) {
                    $WaitProcessIDSplat += @{ CimSession = New-CimSession -ComputerName $Computer -Credential $Package.Credential -ErrorAction Stop }
                }
                else {
                    # $WMIConnection = $null -ne (Get-WmiObject -ComputerName $Computer -List -Class Win32_Process -ErrorAction Stop)
                    $WMIConnection = Test-WSMan -ComputerName $Computer -ErrorAction Stop
                }
            }
            catch {
                "ERROR: Failed to Connect to WMI. ERROR: $_" | Add-ToLog
                $ComputerStore.$Computer.Credential = $False
                $LogFailures += [PSCustomObject]@{
                    Computer   = $Computer
                    Package    = $PushItem
                    Occurrence = 'Failed to Connect to WMI'
                    Error      = $_
                }
                continue Computers
            }
        }

        if ($WMIConnection -eq $False) {
            'WARNING: Failed to Connect to WMI. No Error' | Add-ToLog
            $LogFailures += [PSCustomObject]@{
                Computer   = $Computer
                Package    = $PushItem
                Occurrence = 'Failed to Connect to WMI'
                Error      = $_
            }
            continue Computers
        }

        try {
            $WMIProcess = Get-CimInstance @WaitProcessIDSplat
            $WaitStarted = Get-Date
            while ($WMIProcess) {
                Write-Progress -Id 1 -Activity "Waiting for ProcessID $($ProcessID)" `
                    -Status "$(((Get-Date)-$WaitStarted).Seconds) Seconds Elapsed" `
                    -CurrentOperation 'Waiting...'
                Start-Sleep -Seconds 5
                $WMIProcess = Get-CimInstance @WaitProcessIDSplat
            }
            "INFO: ProcessID $($ProcessID) Finished." | Add-ToLog
        }
        catch {
            "INFO: Cannot find ProcessID $($ProcessID). It may have already finished. Continuing. $_" | Add-ToLog
        }
        Write-Progress -Completed:$True -Id 1 -Activity "Waiting for ProcessID $($ProcessID)"
        $ComputerStore.$Computer.Processes[$i] = $null
    }
}

'END: Monitor Package Completion' | Add-ToLog -LineBreaks 2

#endregion Monitor Completion

#region Clean Up

'START: CleanUp' | Add-ToLog -LineBreaks 2
$i = 0
$iTotal = $Packages.Count
$PackagesLoopStart = Get-Date
:PackagesCleanUp foreach ($Package in $Packages) {
    Remove-Variable Computers -ErrorAction SilentlyContinue -Force
    $i ++

    $ETA = ConvertTo-TimeRemaining -TimeStarted $PackagesLoopStart -CurrentIteration $i -FinalIteration $iTotal
    "START PACKAGE: $i\$iTotal {ETA: $($ETA.EndTime) ($($ETA.Display))} $($Package.PushItem)" | Add-ToLog -LineBreaks 1

    if (!$Package.CleanUp) {
        'INFO: CleanUp Disabled. Skipping Package.' | Add-ToLog
        continue PackagesCleanUp
    }

    $j = 0
    $jTotal = $Package.Computers.Count
    $ComputersLoopStart = Get-Date
    :ComputersCleanUp foreach ($Computer in $Package.Computers) {
        Remove-Variable ComputerInfo -ErrorAction SilentlyContinue -Force
        $j ++

        $ETA = ConvertTo-TimeRemaining -TimeStarted $ComputersLoopStart -CurrentIteration $j -FinalIteration $jTotal
        "START COMPUTER: $j\$jTotal {ETA: $($ETA.EndTime) ($($ETA.Display))} $Computer" | Add-ToLog

        if (!$ComputerStore.ContainsKey($Computer)) {
            'WARNING: No Computer Info was Stored. Skipping Computer.' | Add-ToLog
            continue ComputersCleanUp
        }

        if (!$ComputerStore.$Computer.Ping) {
            'WARNING: Ping Failed Earlier. Skipping Computer.' | Add-ToLog
            continue ComputersCleanUp
        }

        if ([Boolean]$Package.'32PushItem') {
            switch ($ComputerStore.$Computer.OSArch) {
                32 { $CleanUpItem = $Package.'32PushItem' }
                64 { $CleanUpItem = $Package.'PushItem' }
                default {
                    'WARNING: Failed to find OS Architecture Earlier. Skipping Computer.' | Add-ToLog
                    continue ComputersCleanUp
                }
            }
        }
        else {
            $CleanUpItem = $Package.'PushItem'
        }

        if ($Package.CopyFolder) {
            $CleanUpPath = "\\$Computer\$($Package.DestinationPath.Replace(':','$'))\$(Split-Path $CleanUpItem -Parent)"
        }
        else {
            $CleanUpPath = "\\$Computer\$($Package.DestinationPath.Replace(':','$'))\$(Split-Path $CleanUpItem -Leaf)"
        }

        if (!$Preview) {
            try {
                Invoke-Retry -ScriptBlock {
                    Remove-Item -Path $CleanUpPath -Force -Recurse -Confirm:$False -ErrorAction Stop
                } -RetryCount $Package.CleanUpRetryCount -RetryDelaySeconds $Package.CleanUpWaitSeconds
                "ACTION: Removed $CleanUpPath" | Add-ToLog
            }
            catch {
                "ERROR: Failed to Remove $CleanUpPath. ERROR: $_" | Add-ToLog
            }
        }

        "END COMPUTER: $j\$jTotal $Computer" | Add-ToLog
    }
    "END PACKAGE: $i\$iTotal $($Package.PushItem)" | Add-ToLog -LineBreaks 1
}
'END: CleanUp' | Add-ToLog

#endregion Clean Up

