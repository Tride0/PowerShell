<#
    Created By: Kyle Hewitt
#>

Function Set-Pin {
    Param(
        [parameter(Mandatory = $True)]
        [System.String]$Path, 

        [parameter(Mandatory = $True)]
        [ValidateSet('Pin', 'Unpin')]
        [System.String]$Action, 

        [parameter(Mandatory = $True)]
        [ValidateSet('TaskBar', 'StartMenu')]
        [System.String]$Location
    )

    #Handles Path
    $PathParent = Split-Path -Path $Path -Parent
    $PathLeaf = Split-Path -Path $Path -Leaf

    #Does Task
    (New-Object -ComObject Shell.Application).NameSpace("$PathParent").ParseName("$PathLeaf").InvokeVerb("$($Location + $Action)")
}

