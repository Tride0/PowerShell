<#
    .NOTES
        Created By: Kyle Hewitt
        Created On: 07-30-2020
        Version: 2020.07.30

    .DESCRIPTION
        This script will move all files into a DateTime folder structure using a datetime associated with the file.

    .IDEAs
        It would be nice to have this script be able to read DateTime off file names and use those to organize the files.

#>

$Path = 'U:\test\Scripts'

$OrganizeTo = 'U:\test\Organized'

# LastWriteTime, LastAccessTime, CreationTime
$DateTimeIdentifier = 'LastWriteTime'

<#
year = y (yyyy)
month = M
day = d
hour = h
Military hour = H
minute = m
second = s

\ is escape

Example:
\y yyyy\\\M MM\\\d dd\\\H HH\\\m mm\\\s ss
y 2020\M 07\d 30\h 13\m 45\s 30
#>
# Folder structure
$ToString = '\y yyyy\\\M MM\\\d dd\\\H HH\\\m mm\\\s ss'


$Files = Get-ChildItem -Path $Path -File -Recurse -Force

Foreach ($File in $Files) {
    $FolderStructure = $File.$DateTimeIdentifier.ToString($ToString)
    
    [Void] (New-Item -Path "$OrganizeTo\$FolderStructure" -Force -ItemType Directory)

    Move-Item -Path $File.FullName -Destination "$OrganizeTo\$FolderStructure" -Force
}

