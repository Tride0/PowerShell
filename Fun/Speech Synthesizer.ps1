[reflection.assembly]::loadwithpartialname('System.Speech') | Out-Null
$SayIt = New-Object System.Speech.Synthesis.SpeechSynthesizer
$SayIt.Speak('Look... lets not get into this. But i know what you did last summer')