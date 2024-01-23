Add-Type -AssemblyName PresentationCore
$FilePath = [URI]'C:\Users\123\123.mp3'
$WMIPlayer = New-Object System.Windows.Media.MediaPlayer
$WMIPlayer.Open("$FilePath")
Start-Sleep -Seconds 2
$Duration = $WMIPlayer.NaturalDuration.TimeSpan.TotalSeconds
$WMIPlayer.Play()
Start-Sleep $Duration