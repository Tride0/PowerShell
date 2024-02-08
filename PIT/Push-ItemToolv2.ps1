<#
           Name: Push Item
     Created By: Kyle Hewitt
     Created On: Early 2017
        Version: 2024.1.29
      ShortName: PIT
        Purpose: To copy and/or execute files on remote computers.
          Notes: To execute files, they should be able to run silently, quietly, and non-interactively.
#>

$Packages = @(
    <# #START NOTES
    @{
        'Computers'              = @() # Can be Array of Strings or File Path to txt list of computers to Include
        'ExcludeComputers'       = @() # Can be Array of Strings or File Path to txt list of computers to Exclude from the Include List
        'Copy'                   = $True # Copy PushItem to DestinationPath
        'Execute'                = $True # Executes PushItem Path
        'CopyFolder'             = $False # Copy PushItem's Parent Folder
        'PushItem'               = 'C:\USER\Desktop\File.msi' # File Path to 64-bit File that you want to Execute or copy
        '32PushItem'             = 'C:\USER' # File Path to 32-bit File that you want to Execute or copy
        'Arguments'              = '' # Arguments to be used against the PushItem
            Some File Types have some predefined Arguments
            .MSI = / quiet / norestart $Args / i
            .MSP = / quiet / norestart $Args / update
            .MSU = / quiet / norestart $Args
            .PS1 = $Args -NonInteractive -NoProfile -WindowStyle Hidden
            Default = $Args
            To Find: Ctrl -F $WMIProcess.InvokeMethod
        'DestinationPath'        = 'C:\temp' # File Path must exist or must be able to be created
        'DelayGroupCount'        = 0 # Numbers of Computers to run before Delaying
        'DelayGroupWaitSeconds'  = 0 # Seconds to Delay after GroupCount is met
        'PrePackageWaitSeconds'         = 0 # Wait Before Package Runs
        'PostPackageWaitSeconds'        = 0 # Wait After Package is Done
        'CleanUp'                = $False # Remove Files after execute, using this could cause the program to not install correctly if clean up happens before it finishes. Especially if using CopyFolder = $True
        'CleanURetryWaitSeconds' = 300 # Wait Retrying Clean up
        'CleanUpWaitSeconds'     = 300 # Wait before cleaning up
        'CleanUpRetryCount'      = 3 # If CleanUp errored, it will retry after waiting again
        'LogFailurePath'         = "$PSScriptRoot\PIT_Packages_Failures_$(Get-Date -Format yyyyMMdd_hhmmss).csv" # Remove to not log
        'LogPath'                = "$PSScriptRoot\PIT_$(Get-Date -Format yyyyMMdd_hhmmss).log" # Remove to not log
        'Credential'             = $null # Must be in a proper format similar to Get-Credential
    }

    #> #END NOTES
    [Ordered]@{
        'Computers'              = @()
        'ExcludeComputers'       = @()
        'Copy'                   = $True
        'Execute'                = $True
        'CopyFolder'             = $False
        'PushItem'               = ''
        '32PushItem'             = ''
        'Arguments'              = ''
        'DestinationPath'        = 'C:\temp'
        'DelayGroupCount'        = 0
        'DelayGroupWaitSeconds'  = 0
        'PrePackageWaitSeconds'  = 0
        'PostPackageWaitSeconds' = 0
        'CleanUp'                = $False
        'CleanURetryWaitSeconds' = 300
        'CleanUpRetryCount'      = 3
        'LogFailurePath'         = "$PSScriptRoot\PIT_Packages_Failures_$(Get-Date -Format yyyyMMdd_hhmm).csv"
        'LogPath'                = "$PSScriptRoot\PIT_$(Get-Date -Format yyyyMMdd_hhmm).log"
        'Credential'             = $null
    }
)
# Delay Script by Seconds
$StartDelay = 0
# Will not Copy, Execute or Wait
$Preview = $False
# Will Output Progress to Console
$ConsoleOutput = $True

#region Functions

Function Add-ToLog {
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]$Value,
        $Path = $Package.LogPath,
        $LineBreaks = 0,
        $PostLineBreaks = 0,
        $ConsoleOutput = $ConsoleOutput
    )
    If (![Boolean]$Path) { $ConsoleOutput = $True }

    # Add Pre Line Breaks
    If ($LineBreaks -gt 0) {
        1..$LineBreaks | ForEach-Object -Process {
            Write-Verbose '' -Verbose:$ConsoleOutput
            If ($Path) {
                '' | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Add Value
    Write-Verbose "[$(Get-Date)] $($Value.Split("`n")[0])" -Verbose:$ConsoleOutput
    If ([Boolean]$Path) {
        "[$(Get-Date)] $($Value.Split("`n")[0])" | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue

        $Value.Split("`n") |
            Select-Object -Skip 1 |
            ForEach-Object {
                Write-Verbose "($($LogID)) $_" -Verbose:$ConsoleOutput
                "($($LogID)) $_" | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue
            }
    }

    # Add Post Line Breaks
    If ($PostLineBreaks -gt 0) {
        1..$PostLineBreaks | ForEach-Object -Process {
            Write-Verbose '' -Verbose:$ConsoleOutput
            If ([Boolean]$Path) {
                '' | Add-Content -Path $Path -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Remove-Variable ConsoleOutput, LogID -ErrorAction SilentlyContinue -Verbose:$False
} # End Function Add-ToLog

Function Invoke-Retry {
    [CmdletBinding()]
    Param(
        [ScriptBlock] $ScriptBlock,
        [Int] $RetryCount = 3,
        [Int] $RetryDelaySeconds = 1,
        [String[]] $RetryIfErrorContains,
        [scriptblock] $ScriptBlockIfError
    )
    $ErrorActionPreference = 'Stop'
    :RetryLoop for ($i = 1; $i -le $RetryCount; $i++) {
        Try {
            $ScriptBlock.Invoke()
            $RetryFailed = $False
            Break RetryLoop
        }
        Catch {
            # Check If Should Retry
            $Retry = $False
            If ($i -lt $RetryCount) {
                If ([Boolean]$RetryIfErrorContains) {
                    :CheckForRetryLoop Foreach ($String in $RetryIfErrorContains) {
                        If ("$_" -like "*$String*") {
                            $Retry = $True
                            Break CheckForRetryLoop
                        }
                    }
                }
                Else { $Retry = $True }
            }

            # Retry Wait or Break
            If ($Retry) {
                "(Invoke-Retry) ERROR: Retrying $i/$RetryCount in $RetryDelaySeconds seconds. $($_)" | Add-ToLog -ErrorAction SilentlyContinue
                # Run Script Block If Error
                If ((Test-ForValue $ScriptBlockIfError)) {
                    $ScriptBlockIfError.Invoke()
                }
                Start-Sleep -Seconds $RetryDelaySeconds
            }
            Else {
                $RetryFailed = $True
                $e = $($_)
                If ($i -ne 1) {
                    "(Invoke-Retry) ERROR: $i/$RetryCount Last Attempt $($_)" | Add-ToLog -ErrorAction SilentlyContinue
                }
                ElseIf ($i -eq 1) {
                    "(Invoke-Retry) ERROR: Last Attempt $($_)" | Add-ToLog -ErrorAction SilentlyContinue
                }
                Break RetryLoop
            }
        }
    }
    If ($RetryFailed) {
        Return (Write-Error "(Invoke-Retry): ScriptBlock Failed. $e")
    }
    $ErrorActionPreference = 'Continue'
} # END Function Invoke-Retry

#endregion Functions

#region Variables

# This is here to store information about certain computers into long-term script memory so it doesn't re-do checks.
$ComputerStore = @{}

#endregion Variables

If ($StartDelay -gt 0 -and !$Preview) {
    "Waiting $StartDelay seconds. Will Start at $(([DateTime]::Now).AddSeconds($StartDelay))." | Add-ToLog
    [Threading.Thread]::Sleep($StartDelay * 1000)
}

$i = 0
$iTotal = $Packages.Count
:Packages ForEach ($Package in $Packages) {
    Remove-Variable PackageStartTime, Computers, PreWait -ErrorAction SilentlyContinue -Force
    $i ++
    $LogFailures = @()

    "START PACKAGE: $i\$iTotal $($Package.PushItem)" | Add-ToLog -LineBreaks 1
    $PackageStartTime = Get-Date

    If (!$Package.Execute -and !$Package.Copy) {
        'WARNING: Execute and Copy are False. Skipping Package.' | Add-ToLog
        Continue Packages
    }
    ElseIf (![Boolean]$Package.PushItem) {
        'WARNING: Push Item Missing. Skipping Package.' | Add-ToLog
        Continue Packages
    }
    ElseIf (!(Test-Path $Package.PushItem -ErrorAction SilentlyContinue)) {
        'WARNING: Push Item File Not Found. Skipping Package.' | Add-ToLog
        Continue Packages
    }
    ElseIf ([Boolean]$Package.'32PushItem' -and !(Test-Path $Package.'32PushItem' -ErrorAction SilentlyContinue)) {
        'WARNING: 32-Bit Push Item File Not Found. Skipping Package.' | Add-ToLog
        Continue Packages
    }

    # ExcludeComputers From List
    If ($Package.ExcludeComputers.Count -gt 0) {
        $Computers = (Compare-Object $Package.Computers $Package.ExcludeComputers).Where({ $_.SideIndicator -eq '<=' }).InputObject
        "INFO: $($Computers.Count) Computers Found Post Exclusions" | Add-ToLog
    }
    Else { 
        $Computers = $Package.Computers 
        "INFO: $($Computers.Count) Computers Found" | Add-ToLog
    }

    If ($Package.PrePackageWaitSeconds -gt 0 -and !$Preview) {
        $PreWait = ((Get-Date) - $PackageStartTime).TotalSeconds
        "Waiting $PreWait seconds." | Add-ToLog
        [Threading.Thread]::Sleep($PreWait * 1000)
    }

    $j = 0
    $jTotal = $Computers.Count
    :Computers ForEach ($Computer in $Computers) {
        Remove-Variable ComputerInfo, DestinationPath, OSArch, InstallPath, CopyPath, WMIProcess, ExecuteStatus -ErrorAction SilentlyContinue -Force
        $j ++

        "START COMPUTER: $j/$jTotal $Computer" | Add-ToLog -LineBreaks 1

        If ($ComputerStore.ContainsKey($Computer)) { $ComputerInfo = $ComputerStore.$Computer }
        Else {
            $ComputerInfo = @{
                Computer = $Computer
                Ping     = (Test-Connection -ComputerName $Computer -Count 1 -Quiet)
                OSArch   = ''
            }
        }

        If (!$ComputerInfo.Ping) {
            'ERROR: Failed to Ping. Skipping Computer.' | Add-ToLog
            $LogFailures += [PSCustomObject]@{
                Computer   = $Computer
                Package    = $PushItem
                Occurrence = 'Failed to Ping'
                Error      = $_
            }
            Continue Computers
        }

        $DestinationPath = "\\$Computer\$($Package.DestinationPath.Replace(':','$'))"

        # OS Arch and PushItem Selection
        If ([Boolean]$Package.'32PushItem') {
            If (![Boolean]$ComputerInfo.OSArch) {
                If ([IO.Directory]::Exists("\\$Computer\c$\Program Files (x86)")) { $OSArch = 64 }
                ElseIf ([IO.Directory]::Exists("\\$Computer\c$\Program Files")) { $OSArch = 32 }
                Else { $OSArch = (Get-WmiObject win32_ComputerSystem -ComputerName $Computer).SystemType -Replace ('\D', '') }
                $ComputerInfo.OSArch = $OSArch
            }
            Switch ($ComputerInfo.OSArch) {
                32 { $PushItem = $Package.'32PushItem' }
                64 { $PushItem = $Package.'PushItem' }
                Default {
                    'ERROR: Failed to Get OS Architecture. Skipping Computer.' | Add-ToLog
                    $LogFailures += [PSCustomObject]@{
                        Computer   = $Computer
                        Package    = $PushItem
                        Occurrence = 'Failed to Get OS Arch'
                        Error      = $_
                    }
                    Continue Computers
                }
            }
            "INFO: OS Architecture: $($ComputerInfo.OSArch)" | Add-ToLog
        }
        Else {
            $PushItem = $Package.'PushItem'
        }

        # Copy
        If ($Package.Copy -and !$Preview) {
            If ($Package.CopyFolder) { $CopyPath = Split-Path -Path $PushItem -Parent }
            Else { $CopyPath = $PushItem }

            Try {
                'INFO: Copying Item(s)' | Add-ToLog
                Invoke-Retry -ScriptBlock {
                    Copy-Item -Path $CopyPath -Destination $DestinationPath -Recurse -Force -ErrorAction Stop
                    'ACTION: Copied Item(s)' | Add-ToLog
                }
            }
            Catch {
                "ERROR: Failed to Copy $CopyPath. ERROR: $_" | Add-ToLog
                $LogFailures += [PSCustomObject]@{
                    Computer   = $Computer
                    Package    = $PushItem
                    Occurrence = 'Failed to Copy'
                    Error      = $_
                }
                Continue Computers
            }

        }

        # Execute
        If ($Package.Execute -and !$Preview) {

            If ($Package.CopyFolder) {
                $InstallPath = "$($Package.DestinationPath)\$(Split-Path (Split-Path $PushItem -Parent) -Leaf)\$(Split-Path $PushItem -Leaf)"
            }
            Else {
                $InstallPath = "$($Package.DestinationPath)\$(Split-Path $PushItem -Leaf)"
            }

            $WMISplat = @{
                ComputerName = $Computer
                Class        = 'Win32_Process' 
                Name         = 'Create'
            }

            Try {
                If ([Boolean]$Package.Credential) {
                    $WMISplat += @{ CimSession = New-CimSession -ComputerName $Computer -Credential $Package.Credential -ErrorAction Stop }
                    $WMiConnection = $True
                }
                Else {
                    $WMiConnection = $null -ne (Get-WmiObject -ComputerName $Computer -List -Class Win32_Process -ErrorAction Stop)
                }
            }
            Catch {
                "ERROR: Failed to Connect to WMI. ERROR: $_" | Add-ToLog
                $LogFailures += [PSCustomObject]@{
                    Computer   = $Computer
                    Package    = $PushItem
                    Occurrence = 'Failed to Connect to WMI'
                    Error      = $_
                }
                $WMiConnection = $False
                Continue Computers
            }

            if ($WMiConnection -eq $False) {
                'WARNING: Failed to Connect to WMI. No Error' | Add-ToLog
                $LogFailures += [PSCustomObject]@{
                    Computer   = $Computer
                    Package    = $PushItem
                    Occurrence = 'Failed to Connect to WMI'
                    Error      = $_
                }
                Continue Computers
            }

            Try {
                Switch ([IO.Path]::GetExtension($InstallPath)) {
                    '.MSI' {
                        $CmdLineArgument = "msiexec.exe /quiet /norestart $($Package.Arguments) /i `"$InstallPath`""
                    }

                    '.MSP' {
                        $CmdLineArgument = "msiexec.exe /quiet /norestart $($Package.Arguments) /update `"$InstallPath`""
                    }

                    '.MSU' {
                        $CmdLineArgument = "wusa.exe /quiet /norestart $($Package.Arguments) `"$InstallPath`""
                    }

                    '.PS1' {
                        $CmdLineArgument = "Powershell.exe -File `"$InstallPath`" $($Package.Arguments) -NonInteractive -NoProfile -WindowStyle Hidden"
                    }

                    Default {
                        $CmdLineArgument = "$InstallPath $($Package.Arguments)"
                    }
                }

                Try {
                    $ExecuteStatus = Invoke-CimMethod @WMISplat -Arguments @{ CommandLine = $CmdLineArgument } -ErrorAction Stop
                }
                Catch {
                    "ERROR: Failed to Invoke WMI Method. Error: $_" | Add-ToLog
                    $LogFailures += [PSCustomObject]@{
                        Computer   = $Computer
                        Package    = $PushItem
                        Occurrence = 'Failed to Invoke WMI Method'
                        Error      = $_
                    }
                }

                Switch ($ExecuteStatus.ReturnValue) {
                    0 { "ACTION: Successfully Started Program. ProcessID: $($ExecuteStatus.ProcessId)" | Add-ToLog }
                    2 { "ERROR: Failed To Started Program: Access Denied ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                    3 { "ERROR: Failed To Started Program: Insufficient Privilege($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                    8 { "ERROR: Failed To Started Program: Unknown Failure ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                    9 { "ERROR: Failed To Started Program: Path Not Found ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                    21 { "ERROR: Failed To Started Program: Invalid Parameter ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                    Default { "ERROR: Failed To Started Program: Other-Unknown ($($ExecuteStatus.ReturnValue))" | Add-ToLog }
                }

                If ($ExecuteStatus.ReturnValue -ne 0) {
                    $LogFailures += [PSCustomObject]@{
                        Computer   = $Computer
                        Package    = $PushItem
                        Occurrence = 'Failed to Start Program'
                        Error      = $ExecuteStatus.ReturnValue
                    }
                }
            }
            Catch {
                "ERROR: Failed to Start Program. ERROR: $_" | Add-ToLog
                $LogFailures += [PSCustomObject]@{
                    Computer   = $Computer
                    Package    = $PushItem
                    Occurrence = 'Failed to Start Program'
                    Error      = $_
                }
            }
        }

        #Wait Between Defined # of Computers
        If ($Package.DelayGroupWaitSeconds -gt 0 -and ($j % $($Package.DelayGroupCount)) -eq 0 -and !$Preview) {
            "Waiting $($Package.DelayGroupWaitSeconds) seconds." | Add-ToLog
            [Threading.Thread]::Sleep($Package.DelayGroupWaitSeconds * 1000)
        }

        "END COMPUTER: $j\$jTotal $Computer" | Add-ToLog
    }

    If ($LogFailures.Count -gt 1 -and [boolean]$Package.LogFailurePath) {
        Try {
            New-Item -Path $Package.LogFailurePath -ItemType File -ErrorAction Stop -Force | Out-Null
            $LogFailures | Export-Csv $Package.LogFailurePath -NoTypeInformation -ErrorAction Stop -Force
        }
        Catch {
            "ERROR: Failed to Export Failures to $LogFailurePath. ERROR: $_" | Add-ToLog
        }
    }

    If ($Package.PostPackageWaitSeconds -gt 0 -and !$Preview) {
        "Waiting $($Package.PostPackageWaitSeconds) seconds." | Add-ToLog
        [Threading.Thread]::Sleep($Package.PostPackageWaitSeconds * 1000)
    }

    "END PACKAGE: $i\$iTotal $($Package.PushItem)" | Add-ToLog -LineBreaks 1
}

#region Clean Up

'START: CleanUp' | Add-ToLog -LineBreaks 2
$i = 0
$iTotal = $Packages.Count
:PackagesCleanUp Foreach ($Package in $Packages) {
    Remove-Variable Computers -ErrorAction SilentlyContinue -Force
    $i ++

    "START PACKAGE: $i\$iTotal $($Package.PushItem)" | Add-ToLog

    If (!$Package.CleanUp) {
        'INFO: CleanUp Disabled. Skipping Package.' | Add-ToLog
        Continue PackagesCleanUp
    }

    # ExcludeComputers From List
    "INFO: $($Computers.Count) Computers Found" | Add-ToLog
    $Computers = (Compare-Object $Package.Computers $Package.ExcludeComputers).Where({ $_.SideIndicator -eq '<=' }).InputObject
    "INFO: $($Computers.Count) Computers Found Post Exclusions" | Add-ToLog

    $j = 0
    $jTotal = $Computers.Count
    :ComputersCleanUp Foreach ($Computer in $Computers) {
        Remove-Variable ComputerInfo -ErrorAction SilentlyContinue -Force
        $j ++

        "START COMPUTER: $j\$jTotal $Computer" | Add-ToLog

        If ($ComputerStore.ContainsKey($Computer)) { $ComputerInfo = $ComputerStore.$Computer }
        Else {
            'WARNING: No Computer Info was Stored. Skipping Computer.' | Add-ToLog
            Continue ComputersCleanUp
        }

        If (!$ComputerInfo.Ping) {
            'WARNING: Ping Failed Earlier. Skipping Computer.' | Add-ToLog
            Continue ComputersCleanUp
        }

        If ([Boolean]$Package.'32PushItem') {
            Switch ($ComputerInfo.OSArch) {
                32 { $CleanUpItem = $Package.'32PushItem' }
                64 { $CleanUpItem = $Package.'PushItem' }
                Default {
                    'WARNING: Failed to find OS Architecture Earlier. Skipping Computer' | Add-ToLog
                    Continue ComputersCleanUp
                }
            }
        }
        Else {
            $CleanUpItem = $Package.'PushItem'
        }

        If ($Package.CopyFolder) {
            $CleanUpPath = "\\$Computer\$($Package.DestinationPath.Replace(':','$'))\$(Split-Path $CleanUpItem -Parent)"
        }
        Else {
            $CleanUpPath = "\\$Computer\$($Package.DestinationPath.Replace(':','$'))\$(Split-Path $CleanUpItem -Leaf)"
        }

        If (!$Preview) {
            Try {
                Invoke-Retry -ScriptBlock {
                    Remove-Item -Path $CleanUpPath -Force -Recurse -Confirm:$False -ErrorAction Stop
                } -RetryCount $Package.CleanUpRetryCount -RetryDelaySeconds $Package.CleanUpWaitSeconds
                "ACTION: Removed $CleanUpPath" | Add-ToLog
            }
            Catch {
                "ERROR: Failed to Remove $CleanUpPath. ERROR: $_" | Add-ToLog
            }
        }

        "END COMPUTER: $j\$jTotal $Computer" | Add-ToLog
    }
    "END PACKAGE: $i\$iTotal $($Package.PushItem)" | Add-ToLog -LineBreaks 1
}
'END: CleanUp' | Add-ToLog

#endregion Clean Up
