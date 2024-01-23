Function Send-Message {
   <#
      .NOTES
         Created By: Kyle Hewitt
         Created On: 08-21-2020
         Version: 2020.08.21

      .DESCRIPTION
         This function will prompt a message on a remote system
   #>
   Param(
      [String[]]$ComputerName = $ENV:COMPUTERNAME,
      [Parameter(Mandatory)][String]$Message,
      [String]$Session = '*',
      [Int]$TTLSeconds = 22880
   )

   Foreach ($Computer in $ComputerName) {    
      If ((Test-Connection -ComputerName $Computer -Count 1 -Quiet -TimeToLive 4) -or $ENV:COMPUTERNAME) {
         Invoke-WmiMethod -ComputerName $Computer -Class Win32_Process -Name Create -ArgumentList "C:\windows\system32\msg.exe /TIME:$TTLSeconds $Session $Message" -ErrorAction SilentlyContinue |
            Select-Object -Property @{Name = 'Computer'; Expression = { $Computer } }, ProcessID, ReturnValue
      }
   }
}