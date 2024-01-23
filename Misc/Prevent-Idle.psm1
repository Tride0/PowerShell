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
        #SendKey can be anything but ENTER, SCROLLLOCK, NUMLOCK, and CAPSLOCK press those keys. 'DateTime' writes out the date and time and then presses enter. See: https://ss64.com/vb/sendkeys.html
        $SendKey = 'SCROLLLOCK',
        $KeepOff = $True,
        $IntervalSeconds = 180,
        $DelayStartSeconds = 2
    )
    Begin {
        If ($DelayStartSeconds -gt 0) {
            Write-Host "Prevent-Idle is set for a delay start of $DelayStartSeconds seconds. Starting at $((Get-Date).AddSeconds($DelayStartSeconds))"
            Start-Sleep -Seconds $DelayStartSeconds
        }
        $ObjShell = New-Object -ComObject wscript.shell
        [Void] [Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    }
    Process {
        Switch ($SendKey) {
            'SCROLLLOCK' { $CheckKey = 'Scroll' }
            'NUMLOCK' { $CheckKey = 'NumLock' }
            'CAPSLOCK' { $CheckKey = 'CapsLock' }
        }

        While ($TRUE) {
            
            If (('Scroll', 'CapsLock', 'NumLock') -contains $CheckKey) {
                $ObjShell.SendKeys("{$SendKey}")
                Start-Sleep -Seconds 1
                If ([System.Windows.Forms.Control]::IsKeyLocked($CheckKey) -and $KeepOff) {
                    $ObjShell.SendKeys("{$SendKey}")
                }
            }
            ElseIf ($SendKey -eq 'DateTime') {
                $ObjShell.SendKeys("$(Get-Date)")
                $ObjShell.SendKeys('{ENTER}')
            }
            Else {
                $ObjShell.SendKeys($SendKey)
            }
            Write-Host "[$(Get-Date)] $SendKey'd. Waiting $IntervalSeconds seconds." -ForegroundColor Cyan
            Start-Sleep -Seconds $IntervalSeconds
        }
    }
}