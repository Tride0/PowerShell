Function Set-ADObjectAttributeValue {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Contact: PushPishPoSh@gmail.com
            Created On: 09-20-2020
            Version: 2020.09.23

        .DESCRIPTION
            Set values on attributes on an AD Object
    #>

    Param (
        # Single DN or SearchResult Or DirectoryEntry
        $ADObject,
        [HashTable]$Set,
        [HashTable]$Add
    )
    Begin {
        If ($ADObject.Count -gt 1 -or $ADObject -is [Array]) {
            Throw 'More than 1 object was provided in the ADObject parameter. Only specify 1 to continue.'
        }

        If ($ADObject -is [System.DirectoryServices.SearchResult]) {
            $ADObject = $ADObject.GetDirectoryEntry()
        }

        If ($ADObject -like '*,DC=*,DC=*') {
            $ADObject = [System.DirectoryServices.DirectoryEntry]"LDAP://$ADObject"
        }

        If ($ADObject -isnot [System.DirectoryServices.DirectoryEntry]) {
            Throw 'Object provided is not the correct type and was not able to be converted to the correct type.'
        }

        Function SetValue {
            Param(
                $ADObject,
                $Key,
                $Value
            )
            If ($ADObject.$Key -ne $Value) {
                Try {
                    If ($ADObject.Properties.Contains($Key)) {
                        $ADObject.$Key = $Value
                    }
                    Else {
                        $ADObject.Properties[$Key].Add($Value)
                    }
                }
                Catch {
                    $Script:EntryResults.Notes += "Failed to set '$Value' to '$Key'. Error: $_"
                    Throw "Failed to set '$Value' to '$Key'. Error: $_"
                }
            }
        }
    }
    Process {
        # Append Values on Attributes
        Foreach ($Key in $Add.Keys) {
            $NewValue = $ADObject.$Key + $Add.$Key
            SetValue -ADObject $ADObject -Key $key -Value $NewValue
        }

        # Set/Replace Values on Attributes
        Foreach ($Key in $Set.Keys) {
            SetValue -ADObject $ADObject -Key $key -Value $Set.$Key
        }

        # Actually make changes to object
        Try {
            $ADObject.CommitChanges()
        }
        Catch {
            $EntryResults.Notes += "Failed to Set values on user. Error: $_"
        }
    }
    End {
        $ADObject.Close()
        $ADObject.Dispose()
    }
}