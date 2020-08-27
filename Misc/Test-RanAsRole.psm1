
Function Test-RanAsRole {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 08-21-2020
            Version: 2020.08.21

        .DESCRIPTION
            This function will test if the current window was ran as the context of an administrator

            Use this for a list of possible role values
            [System.Security.Principal.WindowsBuiltInRole].GetFields() | Where-Object -FilterScript {$_.FieldType.fullname -eq 'System.Security.Principal.WindowsBuiltInRole'} | Select-Object -ExpandProperty name
    #>
    Param(
        $Role = 'Administrator'
    )
    Return ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::$Role)
}