Function Prevent-Idle {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created In: 2019
            Version: 2020.07.22
	
        .DESCRIPTION
	    Send Keys Reference: https://ss64.com/vb/sendkeys.html
    #>
    Param(
        $SendKey = "SCROLLLOCK",
        $KeepOff = $True,
        $IntervalSeconds = 600
    )
    Begin {
        $ObjShell = New-Object -ComObject wscript.shell
        [Void] [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    }
    Process {
        If ($SendKey -eq 'ScrollLock') {
            $CheckKey = 'Scroll'
        }
        Else {
            $Checkkey = $SendKey
        }

        While ($TRUE) {
            $ObjShell.SendKeys("{$SendKey}")
            If ([System.Windows.Forms.Control]::IsKeyLocked($CheckKey) -and $KeepOff) {
                
                $ObjShell.SendKeys("{$SendKey}")
            }
            Write-Host "[$(Get-Date)] $SendKey'd. Waiting $IntervalSeconds seconds." -ForegroundColor Cyan
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
}
