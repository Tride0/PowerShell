#Requires -Version 7
<#
    Created By: Kyle Hewitt
    Created On: 2025-09-08
       Version: 2025.10.20
       Purpose: This script checks on the health of AD and its Domain Controllers.
#>
param(
    [ValidateNotNullOrEmpty()]
    $Domain = $env:USERDNSDOMAIN,
    [ValidateRange(1, 20)]
    $ParallelThreads = (Get-CimInstance -ClassName Win32_ComputerSystem).NumberOfLogicalProcessors,

    $LogPath = "$PSScriptRoot\Logs\Check-DCHealth\$(Get-Date -Format 'yyyy\\MM')",
    $LogFileName = "Check-DCHealth_$Domain`_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log",
    # DC Report File Format: Domain, DC, Status
    $ReportPath = "$PSScriptRoot\Reports\$Domain",
    $ReportFile = "$ReportPath\Check-DCHealth_Report_$Domain`_$((Get-Date).ToString('yyyyMMdd_HHmmss')).csv",
    $DCTestsModulePath = "$PSScriptRoot\DCTests.psm1",
    $DomainTestsModulePath = "$PSScriptRoot\DomainTests.psm1",

    $SMTPServer = 'relay.catholicHealth.net',
    $EmailFrom = 'noreply@commonspirit.org',
    $EmailTo = 'kyle.hewitt@commonspirit.org',
    $EmailSubject = "$Domain DC Health Check Report ($(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))"
)
begin {
    if (-not $Domain) {
        Write-Host "[$(Get-Date)] ERROR: No domain specified and unable to determine current domain." -ForegroundColor Red
        return
    }
    
    # Modules
    Import-Module ActiveDirectory -ErrorAction Stop
    Import-Module Microsoft.PowerShell.Security -ErrorAction Stop
    if (-not (Test-Path -Path $DCTestsModulePath)) {
        Write-Host "[$(Get-Date)] ERROR: Unable to find module at path $DCTestsModulePath" -ForegroundColor Red
        return
    }
    if (-not (Test-Path -Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -ErrorAction Stop -Force | Out-Null
    }

    if (-not (Test-Path -Path $ReportPath)) {
        New-Item -Path $ReportPath -ItemType Directory -ErrorAction Stop -Force | Out-Null
    }
    Import-Module $DCTestsModulePath -ErrorAction Stop -Force
    Import-Module $DomainTestsModulePath -ErrorAction Stop -Force -ArgumentList $Domain

    try { Stop-Transcript } catch {}
    Start-Transcript -Path "$LogPath\$LogFileName" -ErrorAction Stop -Force

    $Report = @()
}
process {
    Write-Host "[$(Get-Date)] Starting DC Health Check for domain: $Domain" -ForegroundColor Cyan

    # Get Domain Controllers
    try {
        $DCs = Get-ADDomainController -Filter * -Server $Domain -ErrorAction Stop
    }
    catch {
        Write-Host "[$(Get-Date)] ERROR: Unable to retrieve domain controllers for domain $Domain. $_" -ForegroundColor Red
        return
    }

    $PDCe = $DCs.Where({ $_.OperationMasterRoles -contains 'PDCEmulator' }).hostname


    <# DC Tests
    Write-Host "[$(Get-Date)] Testing $($DCs.count) DCs with $ParallelThreads Parallel Threads"
    $Report += $DCs | ForEach-Object -ThrottleLimit $ParallelThreads -Parallel {
        $DC = $_
        Write-Host "[$(Get-Date)] ($($DC.HostName)) -- Thread Started --" -ForegroundColor Cyan
        $PDCe = $Using:PDCe

        # Used in DCTests module
        $isPDCe = $DC.hostname -eq $PDCe

        # Ping Check
        try {
            $PingResult = Test-Connection -ComputerName $DC.HostName -Count 1 -Quiet -ErrorAction Stop
            if ($PingResult) {
                Write-Host "[$(Get-Date)] ($($DC.HostName)) Ping successful." -ForegroundColor Green
            }
            else {
                Write-Host "[$(Get-Date)] ($($DC.HostName)) Ping Failed." -ForegroundColor Red
                return [PSCustomObject]@{
                    Test   = 'Ping'
                    Domain = $Using:Domain
                    DC     = $DC.HostName
                    Result = 'Failed'
                }
            }
        }
        catch {
            Write-Host "[$(Get-Date)] ERROR: Unable to reach $($DC.HostName). $_" -ForegroundColor Red
            return [PSCustomObject]@{
                Test   = 'Ping'
                Domain = $Using:Domain
                DC     = $DC.HostName
                Result = "Failed: $_"
            }
        }

        # WMIC Check
        try {
            $WSManTest = Invoke-Command -ComputerName $DC.HostName -ScriptBlock { $True }
            if ($WSManTest) {
                Write-Host "[$(Get-Date)] ($($DC.HostName)) WMIC is available." -ForegroundColor Green
            }
            else {
                Write-Host "[$(Get-Date)] ($($DC.HostName)) ERROR: WMIC is not available." -ForegroundColor Red
                return [PSCustomObject]@{
                    Test   = 'Invoke-Command'
                    Domain = $Using:Domain
                    DC     = $DC.HostName
                    Result = "[Invoke-Command] Failed. $_"
                }
            }
        }
        catch {
            Write-Host "[$(Get-Date)] ($($DC.HostName)) ERROR: WinRM is not available: $_" -ForegroundColor Red
            return [PSCustomObject]@{
                Test   = 'Invoke-Command'
                Domain = $Using:Domain
                DC     = $DC.HostName
                Result = "[Invoke-Command] Failed. $_"
            }
        }

        # Checks Module
        try {
            Import-Module $Using:DCTestsModulePath -ErrorAction Stop
        }
        catch {
            Write-Host "[$(Get-Date)] ERROR: Unable to import module at path $DCTestsModulePath. $_" -ForegroundColor Red
            return [PSCustomObject]@{
                Test   = 'Import-Module DC Tests'
                Domain = $Using:Domain
                DC     = $DC.HostName
                Result = "Failed: $_"
            }
        }

        $ReportSummary = @()
        $Tests = (Get-Module DCTests).ExportedCommands.Keys
        :Tests foreach ($Test in $Tests) {
            try {
                $testResult = & $Test -ComputerName $DC.HostName

                if ($null -ne $testResult.Report) {
                    $Extension = if ($testResult.Report -is [string]) { 'txt' } else { 'csv' }
                    $ReportExportFileName = "$Test`_$Using:Domain`_$($DC.Name).$Extension"

                    try {
                        switch ($Extension) {
                            'txt' { $testResult.Report.split("`n").Trim() | Set-Content -Path "$Using:ReportPath\$ReportExportFileName" -Force -ErrorAction Stop }
                            'csv' { $testResult.Report | Export-Csv -Path "$Using:ReportPath\$ReportExportFileName" -NoTypeInformation -Force -ErrorAction Stop }
                        }
                        Write-Host "[$(Get-Date)] ($($DC.HostName)) [$Test] Report exported to $Using:ReportPath\$ReportExportFileName" -ForegroundColor Cyan
                    }
                    catch {
                        Write-Host "[$(Get-Date)] ($($DC.HostName)) ERROR: Unable to write report file for $Test. $_" -ForegroundColor Red
                    }

                    if ($testResult.ReportSummary.Count -gt 0) { 
                        Write-Host "[$(Get-Date)] ($($DC.HostName)) [$Test] $($testResult.ReportSummary.count) ISSUE(S) Found" -ForegroundColor Red
                        Write-Output ([PSCustomObject]@{
                                Test   = $Test
                                Domain = $Using:Domain
                                DC     = $DC.HostName
                                Result = $testResult.ReportSummary -join "`n" 
                            }
                        )
                    }
                }
                else {
                    Write-Host "[$(Get-Date)] ($($DC.HostName)) [$Test] No Report Generated." -ForegroundColor Yellow
                }                    
            }
            catch {
                Write-Host "[$(Get-Date)] ($($DC.HostName)) [$Test] ERROR: Test Failed. $_" -ForegroundColor Red
                Write-Output ([PSCustomObject]@{
                        Test   = $Test
                        Domain = $Using:Domain
                        DC     = $DC.HostName
                        Result = "[$Test] TEST FAILED. $_"
                    }
                )
            }
        } # Tests
    }
    #>


    # Domain Tests
    Write-Host "[$(Get-Date)] ($Domain) Running Domain Tests" -ForegroundColor Cyan
    $DomainTests = (Get-Module DomainTests).ExportedCommands.Keys
    :DomainTests foreach ($DomainTest in $DomainTests) {
        try {
            $testResult = & $DomainTest -Domain $Domain

            if ($null -ne $testResult.Report) {

                $Extension = if ($testResult.Report -is [string]) { 'txt' } else { 'csv' }
                $ReportExportFileName = "$($Domain)_$($DomainTest).$Extension"

                $Report += [PSCustomObject]@{
                    Test   = $DomainTest
                    Domain = $Domain
                    DC     = 'DOMAIN'
                    Result = $testResult.ReportSummary
                }

                try {
                    switch ($Extension) {
                        'txt' { $testResult.Report.split("`n").Trim() | Set-Content -Path "$ReportPath\$ReportExportFileName" -Force -ErrorAction Stop }
                        'csv' { $testResult.Report | Export-Csv -Path "$ReportPath\$ReportExportFileName" -NoTypeInformation -Force -ErrorAction Stop }
                    }
                    Write-Host "[$(Get-Date)] ($($Domain)) [$DomainTest] Report exported to $ReportPath\$ReportExportFileName" -ForegroundColor Cyan
                }
                catch {
                    Write-Host "[$(Get-Date)] ($($Domain)) [$DomainTest] Failed to Write Report. ERROR: $_" -ForegroundColor Red
                }
            }
            else {
                Write-Host "[$(Get-Date)] ($($Domain)) [$DomainTest] No Report Generated." -ForegroundColor Yellow
                $Report += [PSCustomObject]@{
                    Test   = $DomainTest
                    Domain = $Domain
                    DC     = 'DOMAIN'
                    Result = "[$DomainTest] No Report"
                }
            }
        }
        catch {
            Write-Host "[$(Get-Date)] DOMAIN $DomainTest ERROR: Test Failed. $_" -ForegroundColor Red
            $Report += [PSCustomObject]@{
                Test   = $DomainTest
                Domain = $Domain
                DC     = 'DOMAIN'
                Result = "[$DomainTest] Test Failed. $_"
            }
        }
    }


    # Export DC Report
    if ($Report.Count -gt 0) {
        if (-not (Test-Path -Path (Split-Path -Path $ReportFile -Parent))) {
            New-Item -Path (Split-Path -Path $ReportFile -Parent) -ItemType Directory -ErrorAction Stop | Out-Null
        }
        $Report | Export-Csv -Path $ReportFile -NoTypeInformation -Force -ErrorAction Stop
        Write-Host "[$(Get-Date)] DC Health Check Report exported to $ReportFile" -ForegroundColor Cyan
    }
    else {
        Write-Host "[$(Get-Date)] All Domain Controllers are healthy." -ForegroundColor Green
    }


    # Report Summary in EmailBody
    if ($EmailTo -and $EmailFrom -and $SMTPServer) {
        $EmailBody = @()
        if ($Report.Count -gt 0) {
            # Report: Test, Domain, DC, Result
            $EmailBody += "Full Report Folder: $ReportPath`n"
            $EmailBody += 'The following actionable items have been found:'
            $Report | Group-Object -Property DC | Sort-Object { if ($_.name -eq 'Domain') { 0 } else { 1 } } | ForEach-Object {
                $DC = $_.Name
                $Results = ($_.Group | Select-Object -ExpandProperty Result) -join "`n"
                $EmailBody += "<br><b>$DC</b><br>$Results"
            }
        }
        else {
            $EmailBody += 'No ReportSummary found'
        }

        try {
            Send-MailMessage `
                -From $EmailFrom -To $EmailTo -Subject $EmailSubject `
                -BodyAsHtml -Body ($EmailBody.split("`n") -join '<br>') -Attachments $ReportFile `
                -SmtpServer $SMTPServer -Port 25 -ErrorAction Stop
            Write-Host "[$(Get-Date)] Email report sent to $EmailTo" -ForegroundColor Cyan
        }
        catch {
            Write-Host "[$(Get-Date)] ERROR: Unable to send email. $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[$(Get-Date)] Email parameters not fully specified. Skipping email report." -ForegroundColor Yellow
    }

}
end {
    try { Stop-Transcript } catch {}
}
