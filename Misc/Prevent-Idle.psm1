Function Prevent-Idle
{
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created In: 2019
	
        .DESCRIPTION
	    Send Keys Reference: https://ss64.com/vb/sendkeys.html
    #>
    Param(
        $SendKey = "SCROLLLOCK",
        $IntervalSeconds = 600
    )
    Begin
    {
        $ObjShell = New-Object -ComObject wscript.shell
    }
    Process
    {
        While ($TRUE)
        {
            $ObjShell.SendKeys("{$SendKey}")
            Write-Host "[$(Get-Date)] $SendKey'd. Waiting $IntervalSeconds seconds." -ForegroundColor Cyan
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
}
