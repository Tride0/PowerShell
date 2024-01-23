Function Get-RegHives {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/04/20

        .DESCRIPTION
            Simple function to get all Registry hives of local machine
    #>
    Return ([Microsoft.Win32.Registry].GetFields().Name)
}