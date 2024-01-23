function Get-FileMetaData {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-21-2020
            Version: 2020.08.21

        .DESCRIPTION
            Retrieves the meta data information from files
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName', 'PSPath')]
        [string[]]$Path,
        [Switch]$WithValuesOnly
    )
 
    begin {
        $oShell = New-Object -ComObject Shell.Application
    }
 
    process {
        $Path | ForEach-Object {
            if (Test-Path -Path $_ -PathType Leaf) {
                $FileItem = Get-Item -Path $_
 
                $oFolder = $oShell.Namespace($FileItem.DirectoryName)
                $oItem = $oFolder.ParseName($FileItem.Name)
 
                If (![Boolean]$oFolder -and ![Boolean]$oItem) { Continue }

                $HashTable = @{}

                0..287 | ForEach-Object {
                    $ExtPropName = $oFolder.GetDetailsOf($oFolder.Items, $_)
                    $ExtValName = $oFolder.GetDetailsOf($oItem, $_)
                    
                    If (($WithValuesOnly.IsPresent -and [Boolean]$ExtValName) -or !$WithValuesOnly.IsPresent) {
                        $HashTable.$ExtPropName = $ExtValName
                    }
                }
                [PSObject]$HashTable
            }
        }
    }
    end {
        $oShell = $null
    }
}