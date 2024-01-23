Function Get-ADUserAttributeTotalValueLength {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 09-03-2020
            Version: 2020.09.03

        .DESCRIPTION
            This script will get the total length of all values in all attributes and return the information for any that are above a threshold.

        .USES
            This script may help with the "Administrative limit for this request was exceeded" error.
    #>

    Param(
        [Parameter(Mandatory)][String]$Identity,
        $Threshold = 100
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        $InfoArr = @()
    }
    Process {
        $User = Get-Aduser $Identity -Properties *

        $properties = $User.PSObject.Members | 
            Where-Object -FilterScript { $_.MemberType -like '*Property*' -and $_.Name -ne 'PropertyNames' } | 
            Select-Object -ExpandProperty name

        Foreach ($prop in $properties) {
            If ("$($User.$prop)".length -gt $Threshold) {
                $InfoArr += [PSCustomObject]@{
                    Attribute         = $prop
                    TotalValuesLength = "$($User.$prop)".length
                }
            }
        }
    }
    End {
        Return ($InfoArr | Sort-Object -Property TotalValuesLength -Descending)
    }
}

