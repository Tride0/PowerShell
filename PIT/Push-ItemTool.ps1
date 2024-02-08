<#
    Name: Push Item
    Version : 2.1.0
    Created By: Kyle Hewitt
    Created On: first quarter of 2017
    Version: 2018.06.01
    ShortName: PIT
    Purpose: to copy and/or execute files on remote computers
#>

#(Array-able)
[String[]]$Computers = @'

'@.Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim()
#(Array-able)
[String[]]$Exclude = ''

#(Array-able)
[String[]]$PushItems = ''
#(Array-able, must have the same number as or less than $PushItems)
[String[]]$32BitPushItems = ''

#At least One Must $True (Array-able)
$Execute = $True
$Copy = $True
#Destination Path Drive Letter should be left out entirely.
#Example "Windows\Temp" or "Windows\System32" or "Users\Public\Desktop"
$DestinationPath = 'temp'

#(Array-able)
[String[]]$ExeArgs = ''

#Copies Parent folder of file being executed if marked $True (Array-able)
[Array]$Package = $False

#Ping TimeOut (Milliseconds)
$PingTimeOut = 1000

#Delay before the pushes start, 0 will cause no wait. (Seconds)
$Delay = 0
#Delay between PushItems, 0 will cause no wait. (Seconds)
$DelayBetweenPushItems = 0

#Delay between a defined amount of computers, 0 in either will cause no wait. (Seconds)
$ComputersAtOneTime = 0
$DelayBetweenComputers = 0

#If marked $True removes files that were copied.
$CleanUp = $False
#Time to wait to remove copied files (seconds)
$CleanUpWaitTime = 300
#Attempts at removing Item
$CleanUpAttemptLimit = 3

#Log Failures $True | False
$LogFailures = $False
#CSV File
$LogFailurePath = "$ENV:USERPROFILE\desktop\PIT Failures.csv"

#$ErrorActionPreference = "SilentlyContinue"; Clear
Clear-Host

#region Checks


#region Checks if running as admin

If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Not an administrator, restarting & prompting for credentials.' -ForegroundColor Red
    Start-Process ([Diagnostics.Process]::GetCurrentProcess().Path) -ArgumentList "-File `"$($Script:MyINvocation.MyCommand.Path)`"" -Verb RunAs
    Exit
}
Else {
    Write-Host 'Administrator!' -ForegroundColor Green
}

#endregion Checks if running as admin


#region Checks Paths Provided

Remove-Variable Temp -ErrorAction SilentlyContinue

ForEach ($Path in ($PushItems + $32BitPushItems)) {
    If ([Boolean]$Path) {
        If ([IO.File]::Exists($Path) -or [IO.Directory]::Exists($Path)) {
            Write-Host "$Path found!" -ForegroundColor Green
        }
        Else {
            Write-Host "$Path Could Not Be Found" -ForegroundColor Red
            $Temp = 1
        }
    }
}

If ($Temp -eq 1) {
    Write-Host "Correct Paths to Continue.`nExiting. To cancel Exit use Ctrl-C." -ForegroundColor Red
    Pause
    Exit
}

#endregion Checks Paths Provided


#region Checks Computers & Exclude Variable for File Paths

Remove-Variable TempComputers -ErrorAction SilentlyContinue

Foreach ($Item in $Computers) {
    If ([IO.File]::Exists($Item)) {
        [String[]]$TempComputers += [IO.File]::ReadAllLines($Item)
        If ([IO.File]::ReadAllLines($Item).Count -ge 1) {
            Write-Host "$([IO.File]::ReadAllLines($Item).Count) Computer(s) found in $Item from $`Computers" -ForegroundColor Green
        }
        Else {
            Write-Host "No computer(s) found in $Item. Close to try again or" -ForegroundColor Red
            Pause
        }
    }
    Else {
        [String[]]$TempComputers += $Item
    }
}

$Computers = $TempComputers


Foreach ($Item in $Exclude) {
    If ([IO.File]::Exists($Item)) {
        $TempExclude += [IO.File]::ReadAllLines($Item)
        If ([IO.File]::ReadAllLines($Item).Count -ge 1) {
            Write-Host "$([IO.File]::ReadAllLines($Item).Count) computer(s) found in $Item from $`Exclude" -ForegroundColor Yellow
        }
        Else {
            Write-Host "No computer(s) found in $Item. Close to try again or" -ForegroundColor Red
            Pause
        }
    }
    Else {
        $TempExclude += $Item
    }
}

$Exclude = $TempExclude

#endregion Checks Computers & Exclude Variable for File Paths


#region Checks Exclude List against Computer List
$Temp = @()

If ($Computers.Count -eq 0) {
    Write-Host "No Computer(s) found in $`Computers.`nExiting. To Cancel Exit use Ctrl-C." -ForegroundColor Red
    Pause
    Exit
}
ElseIf ([Boolean]$Exclude) {
    ForEach ($Computer in $Computers) {
        If ($Exclude -notContains $Computer) {
            $Temp += $Computer
        }
        Else {
            If ($null -ne $ExcludedTemp) { $ExcludedTemp += ', ' }
            $ExcludedTemp += $Computer
        }
    }

    If ($Computers.Count -eq 0) {
        Write-Host "All computer(s) excluded.`nExiting. To cancel Exit use Ctrl-C." -ForegroundColor Red
        Pause
        Exit
    }
    Else {
        Write-Host "$($Computers.Count-($Computers.Count-$Temp.Count)) Computer(s) found! " -NoNewline -ForegroundColor Green
        Write-Host "$($ExcludedTemp.Split(', ').Count) Computer(s) Excluded." -ForegroundColor Magenta
        Write-Host "Excluded Computer(s): $ExcludedTemp"
        $Computers = $Temp
    }
}
Else {
    Write-Host "$($Computers.Count) Computer(s) Found!" -ForegroundColor Green
}

Remove-Variable Temp, ExcludedTemp -ErrorAction SilentlyContinue
#endregion Checks Exclude List against Computer List


#region Checks if at least Execute or Copy is enabled

$Temp = $False
Switch ($null) {
    { $Execute.Count -eq 0 } {
        Write-Host '$Execute does not contain a value.' -ForegroundColor Red
        $Temp = $True
    }
    { $Copy.Count -eq 0 } {
        Write-Host '$Copy does not contain a value.' -ForegroundColor Red
        $Temp = $True
    }
    { $Temp } {
        Write-Host 'Exiting. To Cancel Exit use Ctrl-C.' -ForegroundColor Red
        Pause
        Exit
    }
}

#endregion Checks if at least Execute or Copy is enabled

If (![Boolean]$ComputersAtOneTime) { $ComputersAtOneTime = 0 }
If (![Boolean]$DelayBetweenComputers) { $DelayBetweenComputers = 0 }
If (![Boolean]$DelayBetweenPushItems) { $DelayBetweenPushItems = 0 }
If (![Boolean]$Delay) { $Delay = 0 }
If (![Boolean]$PingTimeOut -or $PingTimeOut -eq 0) { $PingTimeOut = 1000 }
If (![Boolean]$DestinationPath) { $DestinationPath = 'TempDir' }
If (![Boolean]$CleanUpWaitTime) { $CleanUpWaitTime = 0 }
If (![Boolean]$CleanUpAttemptLimit) { $CleanUpAttemptLimit = 1 }

#endregion Checks


#region Functions


Function Copy-File ([String]$SourcePath, [String]$DestinationPath) {
    If ([IO.File]::GetAttributes($SourcePath) -like '*Directory*') {
        If (![IO.File]::Exists($SourcePath)) {
            [Void][IO.Directory]::CreateDirectory("$DestinationPath\$([IO.Path]::GetFileName($SourcePath))")
        }
        ForEach ($File in ([IO.Directory]::GetFiles($SourcePath) + [IO.Directory]::GetDirectories($SourcePath))) {
            If ([IO.File]::GetAttributes($SourcePath) -eq 'Directory') {
                Copy-File -SourcePath $File -DestinationPath "$DestinationPath\$([IO.Directory]::GetParent($File).Name)"
            }
            Else {
                [IO.File]::Copy($File, "$DestinationPath\$([IO.Path]::GetFileName($SourcePath))\$([IO.Path]::GetFileName($File))", $True)
            }
        }
    }
    Else {
        If (![IO.Directory]::Exists($DestinationPath)) {
            [Void][IO.Directory]::CreateDirectory($DestinationPath)
        }
        [IO.File]::Copy($SourcePath, "$DestinationPath\$([IO.Path]::GetFileName($SourcePath))", $True)
    }
}


Function Out-FailureLog ($Computer, $PushItem, $FailureInfo, $Continue = $True) {

    If ($LogFailures) {
        If (![Boolean]$LogFailureInfo) {
            $Global:LogFailureInfo = @()
        }

        $LogFailureInfo += [PSCustomObject]@{
            Computer    = $Computer
            PushItem    = $PushItem
            FailureInfo = $FailureInfo
        }
    }
    If ($Continue) { Continue }
}


#endregion Functions


#region Delay

If ($Delay -gt 0) {
    Write-Host "`nWaiting $Delay seconds before starting pushes.`nWait started at $([DateTime]::Now).`nWait will end at $(([DateTime]::Now).AddSeconds($Delay))`n" -ForegroundColor Cyan
    [Threading.Thread]::Sleep($Delay * 1000)
}

#endregion Delay


$P, $Copied = 0, @()
ForEach ($PushItem in $PushItems) {
    $P ++; $C = $Count = $IntervalCount = 0

    #Gets ExecuteState
    If ($Execute.Count -eq 1) { $ExecuteState = $Execute }
    ElseIf ([Boolean]$Execute[$P]) { $ExecuteState = $Execute[$P] }
    Else { $ExecuteState = $Execute[0] }

    #Gets Copy State
    If ($Copy.Count -eq 1) { $CopyState = $Copy }
    ElseIf ([Boolean]$Copy[$P]) { $CopyState = $Copy[$P] }
    Else { $CopyState = $Copy[0] }

    #Gets PackageState
    If ($Package.Count -eq 1) { $PackageState = $Package }
    ElseIf ([Boolean]$Package[$P]) { $PackageState = $Package[$P] }
    Else { $PackageState = $Package[0] }

    If ($ExecuteState -ne $True -and $CopyState -ne $True) {
        Write-Host 'Neither Copy or Execute is Enabled for this package. Skipping Package.' -ForegroundColor Red
        Continue
    }

    ForEach ($Computer in $Computers) {
        $C ++; Remove-Variable Install, CompleteTempDirPath, DriveLetter -ErrorAction SilentlyContinue
        Write-Host "`n[$([DateTime]::Now)] $P/$($PushItems.Count). $([IO.Path]::GetFileName($PushItem)) - $($Computers.IndexOf($Computer)+1)/$($Computers.Count). $Computer" -ForegroundColor Magenta


        #Ping
        Try {
            $PingStatus = (New-Object Net.NetworkInformation.Ping).Send($Computer, $PingTimeOut).Status
            If ($PingStatus -eq 'Success') {
                Write-Host 'Ping' -ForegroundColor Yellow -NoNewline
            }
            Else {
                Write-Host "Ping Status: $PingStatus" -ForegroundColor Red
                Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo "Ping Status: $PingStatus"
            }
        }
        Catch {
            Write-Host 'No Ping. Skipping.' -ForegroundColor Red
            Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo 'No Ping'
        }


        #region Drive Letter

        $DriveLetter = ($Copied | Where-Object -FilterScript { $_.Name -eq $Computer }).DriveLetter
        If (![Boolean]$DriveLetter) {
            If ([IO.Directory]::Exists("\\$Computer\C$")) { $DriveLetter = 'C' }
            Else {
                ForEach ($Letter in [Char[]]([Char]'A'..[Char]'Z')) {
                    If ([IO.Directory]::Exists("\\$Computer\$Letter$")) {
                        $DriveLetter = $Letter
                        Break
                    }
                }
            }
            If (![Boolean]$DriveLetter) {
                $DriveLetter = ([Management.ManagementClass]"\\$Computer\ROOT\CIMV2:Win32_OperatingSystem").GetInstances().SystemDrive[0]
            }
        }
        If (![Boolean]$DriveLetter) {
            Write-Host " - Couldn't Get Drive Letter. Skipping." -ForegroundColor Red
            Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo "Couldn't Get Drive Letter"
        }
        Else {
            Write-Host " - $DriveLetter" -ForegroundColor Green -NoNewline
        }

        #endregion Drive Letter


        $CompleteDestinationPath = "\\$Computer\$DriveLetter$\$DestinationPath"

        #region OSArch

        If (![Boolean]$32BitPushItems) { $Install = $PushItems[$P - 1] }
        Else {
            #Gets OS Arch
            $OSArch = ($Copied | Where-Object -FilterScript { $_.Name -eq $Computer }).OSArch
            If (![Boolean]$OSArch) {
                If ([IO.Directory]::Exists("\\$Computer\$DriveLetter$\Program Files (x86)")) { $OSArch = 64 }
                ElseIf ([IO.Directory]::Exists("\\$Computer\$DriveLetter$\Program Files")) { $OSArch = 32 }
                Else {
                    $OSArch = [Text.RegularExpressions.Regex]::Match(([Management.ManagementClass]"\\$Computer\ROOT\CIMV2:Win32_ComputerSystem").GetInstances().SystemType, '\d+').Value
                }
                If (![Boolean]$OSArch) {
                    Write-Host " - Couldn't Get OS Architecture. Skipping." -ForegroundColor Red
                    Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo "Couldn't Get OS Architecture"
                }
            }
            #Selects File to Push based off OSArch
            If ($OSArch -like '*64*') { $Install = $PushItems[$P - 1] }
            ElseIf ($OSArch -like '*32*' -or $OSArch -like '*86*') { $Install = $32BitPushItems[$P - 1] }

            Write-Host " - $OSArch" -ForegroundColor Green -NoNewline
        }
        #Checks to make sure Exe or File is Found to push.
        If (![IO.Directory]::Exists($Install) -and ![IO.File]::Exists($Install)) {
            Write-Host " - Couldn't Find File To Execute, Exiting." -ForegroundColor Red
            Pause
            Exit
        }

        #endregion OSArch


        #region Copy

        If ($CopyState) {
            $CopyTemp = $Install
            If ($PackageState) {
                $CopyTemp = [IO.Directory]::GetParent($CopyTemp).FullName
            }
            #Removes any leading / or \, to prevent from double copying
            If ($CopyTemp[-1] -eq '\' -or $CopyTemp[-1] -eq '/') {
                $CopyTemp = $CopyTemp.Remove($CopyTemp.Length - 1, 1)
            }


            Write-Host " - Copying $([IO.Path]::GetFileName($CopyTemp))" -ForegroundColor Yellow -NoNewline

            Copy-File -SourcePath $CopyTemp -DestinationPath $CompleteDestinationPath

            If ($PackageState) {
                $CompleteInstallPath = "$($DriveLetter):\$DestinationPath\$([IO.Directory]::GetParent($Install).Name)\$([IO.Path]::GetFileName($Install))"
            }
            Else {
                $CompleteInstallPath = "$($DriveLetter):\$DestinationPath\$([IO.Path]::GetFileName($Install))"
            }

            If (![IO.File]::Exists("$CompleteDestinationPath\$([IO.Path]::GetFileName($CopyTemp))") -and ![IO.Directory]::Exists("$CompleteDestinationPath\$([IO.Path]::GetFileName($CopyTemp))")) {
                Write-Host ', Copy Failed. Skipping.' -ForegroundColor Red
                Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo 'Copy Failed'
            }
            Else {
                Write-Host ', Copied.' -ForegroundColor Green -NoNewline
            }
        }

        #endregion Copy


        #Creates/Edits Computer Information to prevent repetition of information retrieval
        If ($Copied.Name -notContains $Computer) {
            [Array]$Copied += [PSCustomObject]@{
                Name        = $Computer
                OSArch      = $OSArch
                DriveLetter = $DriveLetter
                StartTime   = [DateTime]::Now
                ElapsedTime = 0
                RemoveCount = 0
            }
        }
        Else {
            ($Copied | Where-Object -FilterScript { $_.Name -eq $Computer }).StartTime = [DateTime]::Now
        }


        #region Install

        If ($ExecuteState) {
            Try {
                $WMIProcess = ([Management.ManagementClass]"\\$Computer\ROOT\CIMV2:win32_process")
            }
            Catch {
                If ($Error[0] -like '*Access is Denied*') {
                    Write-Host ' - Access Denied. Skipping.' -ForegroundColor Red
                    Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo 'Access Denied'
                }
                ElseIf ($Error[0] -like '*RPC server is unavailable*') {
                    Write-Host ' - RPC server is unavailable. Skipping.' -ForegroundColor Red
                    Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo 'RPC Server is unavailable'
                }
                Else {
                    Write-Host " - Couldn't Connect to $Computer. SKipping." -ForegroundColor Red
                    Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo "Couldn't Connect to Computer"
                }
            }

            Write-Host " - $([IO.Path]::GetExtension($CompleteInstallPath))" -ForegroundColor Yellow -NoNewline

            Switch ([IO.Path]::GetExtension($CompleteInstallPath)) {
                '.MSI' {
                    $Status = $WMIProcess.InvokeMethod('Create', "msiexec.exe /quiet /norestart /i `"$CompleteInstallPath`"")
                }

                '.MSP' {
                    $Status = $WMIProcess.InvokeMethod('Create', "msiexec.exe /quiet /norestart /update `"$CompleteInstallPath`"")
                }

                '.MSU' {
                    $Status = $WMIProcess.InvokeMethod('Create', "wusa.exe /quiet /norestart `"$CompleteInstallPath`"")
                }

                '.PS1' {
                    $Status = $WMIProcess.InvokeMethod('Create', "Powershell.exe -File `"$CompleteInstallPath`" -NonInteractive -NoProfile -WindowStyle Hidden")
                }
                Default {
                    $Status = $WMIProcess.InvokeMethod('Create', "`"$CompleteInstallPath`" $ExeArgs")
                }
            }

            If ($Status -eq 0) {
                Write-Host ' - Successful' -ForegroundColor Green
                $Count ++
            }
            Else {
                Write-Host " - Failure: Error Code $Status" -ForegroundColor Red
                Out-FailureLog -Computer $Computer -PushItem $PushItem -FailureInfo "Couldn't Get Drive Letter" -Continue $False
            }
        }

        #endregion Install

        #Wait Between Defined # of Computers
        If ($DelayBetweenComputers -gt 0 -and $ComputersAtOneTime -gt 0) {
            If ($IntervalCount -eq $ComputersAtOneTime) {
                $SleepTimer = $DelayBetweenComputers
                While ($SleepTimer -ne 0) {
                    Write-Host "Waiting $SleepTimer Seconds" -ForegroundColor Cyan

                    If ($SleepTimer -lt 30) {
                        [Threading.Thread]::Sleep($SleepTimer * 1000)
                        $SleepTimer -= $SleepTimer
                    }
                    Else {
                        [Threading.Thread]::Sleep(30000)
                        $SleepTimer -= 30
                    }
                }
                $IntervalCount = 0
            }
            Else {
                $IntervalCount ++
            }
        }
    }

    #Delay Between Patches
    If ($DelayBetweenPushItems -gt 0 -and $PushItems.Count -gt 1) {
        Write-Host "`nWaiting $DelayBetweenPushItems seconds starting next push ($([IO.Directory]::GetParent($PushItems[$PushItems.IndexOf($PushItem)+1]).Name)).`nWait started at $([DateTime]::Now).`nWill end at $(([DateTime]::Now).AddSeconds($DelayBetweenPushItems))`n" -ForegroundColor Cyan
        [Threading.Thread]::Sleep($DelayBetweenPushItems * 1000)
    }

    Write-Host "$PushItem ran on $Count Successfully." -ForegroundColor White -BackgroundColor Black
}


If ($LogFailures) {
    $Global:LogFailureInfo | Export-Csv $LogFailurePath -NoTypeInformation -NoClobber -Force
}


#Remove Files
If ($CleanUp) {
    $N = 0; $RemoveStartTime = [DateTime]::Now
    While ([Boolean]($Copied.Name -ne '') -and [Boolean]($Copied -ne '')) {
        ForEach ($Entry in $Copied) {
            If ($Entry.Name -eq '') { Continue }
            If ($Entry.RemoveCount -eq $CleanUpAttemptLimit) { $N ++ }

            Write-Host "$([DateTime]::Now) - Complete: $N\$($Copied.Count). $($Entry.Name)" -ForegroundColor Magenta -NoNewline

            If ($Entry.RemoveCount -eq $CleanUpAttemptLimit) {
                $Entry.Name = ''
                Write-Host " - Attempted $CleanUpAttemptLimit Times, Won't Try Again." -ForegroundColor Red
                Continue
            }

            $TimeDifference = (([DateTime]::Now) - $Entry.StartTime).Minutes
            If ($TimeDifference -lt $CleanUpWaitTime / 60) {
                Write-Host " - $TimeDifference Minutes Til Deletion." -ForegroundColor Yellow
                $Entry.ElapsedTime = $TimeDifference
                Continue
            }

            Try {
                $PingStatus = (New-Object Net.NetworkInformation.Ping).Send("$($Entry.Name)", $PingTimeOut).Status
                If ($PingStatus -eq 'Success') {
                    Write-Host ' - Ping' -ForegroundColor Green -NoNewline
                }
                Else {
                    Write-Host " - Ping Status: $PingStatus, No Removal." -ForegroundColor Red
                    $Entry.RemoveCount ++
                    Continue
                }
            }
            Catch {
                Write-Host ' - Ping Failed, No Removal.' -ForegroundColor Red
                $Entry.RemoveCount ++
                Continue
            }

            $CompleteTempDir = "\\$($Entry.Name)\$($Entry.DriveLetter)$\$DestinationPath"

            If ([IO.Directory]::Exists($CompleteInstallPath)) {
                [IO.File]::Delete($CompleteTempDir, $True)

                If (![IO.Directory]::Exists($CompleteInstallPath)) {
                    Write-Host ' - Removed!' -ForegroundColor Green
                    $Entry.Name = ''
                    $N ++
                }
                Else {
                    Write-Host " - Couldn't Remove." -ForegroundColor Red
                    $Entry.RemoveCount ++
                }
            }
        }

        If ($CleanUpWaitTime -gt 0) {
            If ($Copied.ElapsedTime -lt $CleanUpWaitTime) {
                $Seconds = $CleanUpWaitTime - ([Int32](Sort-Object -InputObject (Where-Object -InputObject $Copied -FilterScript { $_.ElapsedTime -NotLike 'Done' }) -Property ElapsedTime -Descending)[0].ElapsedTime) * 60
            }

            Write-Host "`nWaiting $Seconds Seconds To Attempt Removal Again.`n" -ForegroundColor Cyan
            [Threading.Thread]::Sleep($Seconds * 1000)
        }
    }
}
