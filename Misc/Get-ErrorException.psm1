Function Get-ErrorException {
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeLine = $True)]
        [System.Management.Automation.ErrorRecord]
        $Error
    )
    Process {
        $exception = $Error.Exception
        do {
            $exception.GetType().FullName
            $exception = $exception.InnerException
        } while ($exception)
    }
    End {
        Remove-Variable exception -ErrorAction SilentlyContinue
    }
}