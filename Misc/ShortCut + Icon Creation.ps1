$ShortCutFILEPATH = ''
$ProgramFILEPATH = ''
$ICONFILEPATH = ''

#Creates Shell to create Shortcut
$Shell = New-Object -ComObject WScript.Shell

#Where Shortcut will be created
$ShortCut = $Shell.CreateShortcut($ShortCutFILEPATH)

#Program / Software / File --- File Path
$ShortCut.TargetPath = "$ProgramFILEPATH"

#Icon Path
$ShortCut.IconLocation = "$ICONFILEPATH"

#Saves Shortcut
$ShortCut.Save()