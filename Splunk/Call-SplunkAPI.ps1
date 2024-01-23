Function Call-Splunk {
    Param(
        [Parameter(ParameterSetName = 'Search')]$Search = '',
        [String]$APIBase = 'https://SERVER:8089/services'
    )

    #Provide them the credentials that has access to Splunk. Domain username/pw
    If (![Bool]$Global:Creds) {
        $Global:Creds = Get-Credential 
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        [System.Net.ServicePointManager]::MaxServicePointIdleTime = 5000000
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    Write-Host "`n`n[$(Get-Date)] Search: $Search"
    
    #Create Search Job in Splunk
    $SearchCreation = Invoke-RestMethod -Method Post -Uri "$APIBase/search/jobs/" `
        -Body @{
        search      = $Search
        output_mode = 'json'
        earliest    = '-60m'
    } `
        -Credential $Creds
    Write-Host "[$(Get-Date)] Job SID: $($SearchCreation.sid)"

    #Wait until Job Finishes
    
    $I = 0
    Remove-Variable -Name StartWait -ErrorAction SilentlyContinue
    While ('RUNNING', 'QUEUED' -contains $SearchStatus.entry.content.dispatchState -or ![Boolean]$SearchStatus) {
        $I ++
        $SearchStatus = Invoke-RestMethod -Method GET `
            -Uri "$APIBase/search/jobs/$($SearchCreation.sid)/" `
            -Body @{
            output_mode = 'json'
        } `
            -Credential $Creds

        If ($SearchStatus.entry.content.dispatchState -eq 'RUNNING' -and ![Boolean]$StartWait) { $StartWait = Get-Date }
        $EndWait = Get-Date
        Write-Progress -Activity "Job sid: $($SearchCreation.sid)" -Status "[$(Get-Date)] $I. Job Status: $($SearchStatus.entry.content.dispatchState) Duration: $(($EndWait-$StartWait).TotalSeconds) Sec"
        If ($SearchStatus.entry.content.dispatchState -ne 'Done') { Start-Sleep -Seconds 5 }
    }
    Write-Progress -Completed -Activity "Job sid: $($SearchCreation.sid)"
    Write-Host "[$(Get-Date)] Job Duration: $(($EndWait-$StartWait).TotalSeconds)"

    #Get Results from Job
    $SearchResults = Invoke-RestMethod -Method GET `
        -Uri "$APIBase/search/jobs/$($SearchCreation.sid)/results" `
        -Body @{
        output_mode = 'json'
    } `
        -Credential $Creds
    Write-Host "[$(Get-Date)] Result Count: $($SearchResults.results.count)"
    Write-Output $SearchResults.results
}