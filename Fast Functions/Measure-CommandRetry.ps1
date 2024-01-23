Function Measure-CommandRetry {
    Param( [scriptblock]$ScriptBlock, [int]$Retry = 5 )
    Begin { 
        $Results = @()
    }
    Process {
        for ($i = 0; $i -lt $Retry; $i++) { 
            $Start = [DateTime]::Now

            $ScriptBlock.Invoke() | Out-Null

            $End = [DateTime]::Now

            $Results += $End - $Start
        }
    }
    End {
        Return $Results | Measure-Object -Average -Property $Results[0].PSObject.Properties.name | Select-Object Property, Average
    }
}