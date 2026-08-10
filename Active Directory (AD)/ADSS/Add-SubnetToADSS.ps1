<#
    Created By: Kyle Hewitt
    Created On: 2026-05-19
    Version: 2026.05.19
    Name: Add-SubnetToADSS
    Description: 
    Purpose: 
    Plan:
    Formatting:
        Write-Host Colors:
            Magenta - Information
            Cyan - Status Updates
            Blue - Actions
            Green - Successes
            Yellow - Warnings
            Red - Errors
            Gray - No Action/Neutral
            Dark Variations of the colors should be used for 2nd level loops
        Write-Host Format:
            [$(Get-Date)] [LogLevel] {Function} Message -ForegroundColor Color
        Log Levels:
            INFO - General Information
            STATUS - Status Updates on the Process
            ACTION - Actions being taken
            SUCCESS - Successful Actions
            WARNING - Warnings that should be noted
            ERROR - Errors that should be noted
        Foreach Loops:
            Always Name the Loop for use with continue and break statements
            iteration counts and totals should be tracked and displayed in status updates
            iteration counts variables should be initialized to 0 before the loop and incremented at the beginning of the loop
            iteration counts variables should be named with an 'i' prefix and a descriptive name (e.g. $iFolders, $iAccessTypes, $iUsers)
            Use Write-Progress to provide feedback on the progress of the loop, including an ETA based
                Write-Progress -Activity "Processing $ScriptName" -Status "$i/$TotalItems ETA: $($ETA.Display) ($($ETA.EndTime))" -PercentComplete (($i / $TotalItems) * 100) -CurrentOperation "$Key"
            Nested Loops should not use Write-Progress, use Write-Host with status updates instead
#>

$ScriptName = 'Add-SubnetToADSS'

#Subnet,Site
$Data = @'

'@.split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim().Where({ @($null, '') -notcontains $_ })

$LogPath = "$PSScriptRoot\Logs\$ScriptName\Transcript_$ScriptName`_$(Get-Date -Format yyyyMMdd_hhmmss).log"
$CSVOutputPath = "$PSScriptRoot\Logs\$ScriptName\CSVReport_$ScriptName`_$(Get-Date -Format yyyyMMdd_hhmmss).csv"
$Log = $True
$PauseDataLoop = $False
$PauseFor = 1

function ConvertTo-TimeRemaining {
    param(
        [DateTime]$TimeStarted,
        [int]$CurrentIteration,
        [int]$FinalIteration
    )
    if ($CurrentIteration -le 1) { return 'N/A' }
    $RemainingIterations = ($FinalIteration - $CurrentIteration)
    if ($RemainingIterations -le 0) { return 'N/A' }
    try {
        $TimeRemaining = ((Get-Date) - $TimeStarted) / ($CurrentIteration - 1) * $RemainingIterations
        $DisplayMethod = $TimeRemaining.psObject.Properties.Where({ $_.Name -like 'Total*' -and $_.Value -gt 2 }) | Sort-Object Value | Select-Object -First 1
        if ($null -eq $DisplayMethod) { return 'N/A' }
        else {
            return @{
                Display = ([string][Math]::Round( $DisplayMethod.Value, 3)) + ' ' + $DisplayMethod.Name.Replace('Total', '').Replace('sec', 'Sec') -creplace '[a-z]', ''
                EndTime = (Get-Date).Add($TimeRemaining).ToString('yyyy-MM-dd HH:mm:ss')
            }
        }
    }
    catch {
        $TimeRemaining = [Math]::Round(((Get-Date) - $TimeStarted).TotalSeconds / ($CurrentIteration - 1) * $RemainingIterations, 1)

        $DivideBy = 60
        $TRLabel = 'Seconds'
        $TRLabels = @(
            '60:Minutes'
            '60:Hours'
            '24:Days'
            '7:Weeks'
            '4:Months'
            '12:Years'
        )
        $TRi = 0
        while ($TimeRemaining -gt $DivideBy) {
            $TRLabel = $TRLabels[$TRi]
            [int]$DivideBy, $TRLabel = $TRLabel.Split(':')
            $TimeRemaining = [Math]::Round($TimeRemaining / $DivideBy, 1)
            $TRi ++		
        }

        $EndTime = switch ($TRLabel) {
            'Seconds' { (Get-Date).AddSeconds($TimeRemaining).ToString('yyyy-MM-dd HH:mm:ss') }
            'Minutes' { (Get-Date).AddMinutes($TimeRemaining).ToString('yyyy-MM-dd HH:mm:ss') }
            'Hours' { (Get-Date).AddHours($TimeRemaining).ToString('yyyy-MM-dd HH:mm:ss') }
            'Days' { (Get-Date).AddDays($TimeRemaining).ToString('yyyy-MM-dd HH:mm:ss') }
            'Weeks' { (Get-Date).AddDays($TimeRemaining * 7).ToString('yyyy-MM-dd HH:mm:ss') }
            'Months' { (Get-Date).AddDays($TimeRemaining * 28).ToString('yyyy-MM-dd HH:mm:ss') }
        }

        return @{
            Display = $TimeRemaining + ' ' + $TRLabel
            EndTime = $EndTime
        }
    }
}

# Key, Action, Notes (Relevant Information & Error Messages) (Whenever the 'data' loop ends) (NO OTHER COLUMNS)
$CSVReport = @()
# '[Key],[Action]'
$Successes = @()
# '[Key],Error: [Error Message]'
$Failures = @()

if ($Log) { Stop-Transcript -ea si; Start-Transcript -Path $LogPath }
$i = 0
$iTotal = $Data.Count
$DataLoopStart = Get-Date
:Data foreach ($Entry in $Data[$i..$iTotal]) {
    if ($PauseDataLoop -and $i -le $PauseFor -and $i -ne 0) { Pause }
    Remove-Variable ETA -ErrorAction SilentlyContinue -Force -Verbose:$false # ! Variables to Clear between iterations
    $Key = $Entry

    $i ++
    $ETA = ConvertTo-TimeRemaining -TimeStarted $DataLoopStart -CurrentIteration $i -FinalIteration $iTotal
    Write-Progress -Activity "Processing $ScriptName" -Status "Processing item $i of $iTotal" -PercentComplete (($i / $iTotal) * 100) -CurrentOperation "$Key"

    $Subnet, $Site = $Entry.Trim() -split ','

    $ADSubnet = Get-ADReplicationSubnet -Filter "Name -eq '$Subnet'" -ErrorAction SilentlyContinue
    if ($null -eq $ADSubnet) {
        try {
            New-ADReplicationSubnet -Name $Subnet -Site $Site -ErrorAction Stop -PassThru
            $Successes += "$Key"
            $CSVReport += [PSCustomObject]@{
                Key    = $Key
                Action = "Successfully added Subnet '$Subnet' to Site '$Site'"
                Notes  = ''
            }
            Write-Host "[$(Get-Date)] Successfully added Subnet '$Subnet' to Site '$Site'" -ForegroundColor Green
        }
        catch {
            $Failures += "$Key,Error: $_"
            $CSVReport += [PSCustomObject]@{
                Key    = $Key
                Action = "Failed to add Subnet '$Subnet' to Site '$Site'"
                Notes  = $_.ToString()
            }
            Write-Host "[$(Get-Date)] Failed to add Subnet '$Subnet' to Site '$Site'. Error: $_" -ForegroundColor Red
        }
    }
    else {
        if ($ADSubnet.Site -notlike "CN=$Site,*") {
            $Failures += "$Key,Error: Subnet already exists in Site: $($ADSubnet.Site)"
            $CSVReport += [PSCustomObject]@{
                Key    = $Key
                Action = "Failed to add Subnet '$Subnet' to Site '$Site'"
                Notes  = "Subnet already exists in Site: $($ADSubnet.Site)"
            }
            Write-Host "[$(Get-Date)] Failed to add Subnet '$Subnet' to Site '$Site'. Error: Subnet already exists in Active Directory" -ForegroundColor Red
        }
        else {
            Write-Host "[$(Get-Date)] Subnet already part of Site: $Site" -ForegroundColor Yellow
        }
    }
}
$DataLoopEnd = Get-Date
$LoopDuration = $DataLoopEnd - $DataLoopStart
Write-Host "[$(Get-Date)] Elapsed Time: $([Math]::Round($LoopDuration.TotalSeconds,3)) Seconds" -ForegroundColor Cyan
Write-Host "[$(Get-Date)] Average Iteration: $([Math]::Round($LoopDuration.TotalSeconds / $iTotal, 3)) Seconds" -ForegroundColor Cyan
Write-Host "[$(Get-Date)] SCRIPT END"

$CSVReport | Export-Csv -Path $CSVOutputPath -NoTypeInformation -Force

Write-Host "Successes: $($Successes.Count)`n$($Successes -join "`n")" -ForegroundColor Green
Write-Host "Failures: $($Failures.Count)`n$($Failures -join "`n")" -ForegroundColor Red

if ($Log) { Stop-Transcript -ea si }