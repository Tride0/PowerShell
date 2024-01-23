<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-16-2020
        Version: 2020.07.16

    .DESCRIPTION
        This scripts checks the health of AD and summarize it.
#>


Clear-Host

$Computer = ''

Invoke-Command -ComputerName $Computer -ScriptBlock {
    $Computer = hostname
    
    # REPL QUEUE
    $repadmin_queue = repadmin /queue

    If ("$repadmin_queue" -notlike '*Queue contains 0 items*') {
        Write-Host "`nRepadmin Queue`n" -ForegroundColor Magenta
        $repadmin_queue.trim()
    }
    Else {
        Write-Host 'Repadmin Queue is okay.' -ForegroundColor Green
    }


    # REPL SUM

    $repadmin_replsum = (repadmin /replsum).split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim()

    $replsum_failures = $repadmin_replsum -notlike '*0' -notlike '*..*' -notlike '*largest delta*' -notlike '*replication summary*'

    If ($replsum_failures.count -ge 1) {
        Write-Host "`nRepadmin replsum`n" -ForegroundColor Magenta
        $replsum_failures
    }
    Else {
        Write-Host 'Repadmin replsum is okay.' -ForegroundColor Green
    }


    # SHOW REPL

    $repadmin_showrepl = (repadmin /showrepl).split("`n", [System.StringSplitOptions]::RemoveEmptyEntries).Trim()
    $showrepl_failures = $repadmin_showrepl -like '*Last attempt*' -notlike '*was successful*'
    $showrepl_failure_context = @()
    Foreach ($failure in $showrepl_failures) {
        $EndIndex = $repadmin_showrepl.IndexOf($failure)
        :StartIndexSearch for ($i = $EndIndex; $i -gt 0; $i--) { 
            If ($repadmin_showrepl[$i] -like '* via *') {
                $StartIndex = $i
                Break StartIndexSearch
            }
        }
        $showrepl_failure_context += $repadmin_showrepl[$StartIndex..$EndIndex]
    }

    If ($showrepl_failure_context.count -ge 1) { 
        Write-Host "`repadmin showrepl`n" -ForegroundColor Magenta
        $showrepl_failure_context
    }
    Else {
        Write-Host 'Repadmin showrepl is okay.' -ForegroundColor Green
    }


    # DC DIAG

    $dcdiag = (dcdiag).split("`n", [System.StringSplitOptions]::RemoveEmptyEntries) -ne ''
    $dcdiag_failures = $dcdiag -like '*failed test*'
    $dcdiag_failure_context = @()
    Foreach ($failure in $dcdiag_failures) {
        $EndIndex = $dcdiag.IndexOf($failure)
        :StartIndexSearch for ($i = $EndIndex; $i -gt 0; $i--) { 
            If ($dcdiag[$i] -like '*Starting test:*') {
                $StartIndex = $i
                Break StartIndexSearch
            }
        }
        $dcdiag_failure_context += $dcdiag[$StartIndex..$EndIndex]
    }

    If ($dcdiag_failure_context.count -ge 1) { 
        Write-Host "`ndcdiag`n" -ForegroundColor Magenta
        $dcdiag_failure_context | Select-Object -Unique
    }
    Else {
        Write-Host 'dcdiag is okay.' -ForegroundColor Green
    }

}