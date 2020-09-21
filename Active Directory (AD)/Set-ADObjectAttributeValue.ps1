Function Set-ADObjectAttributeValue {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Contact: PushPishPoSh@gmail.com
            Created On: 09-20-2020
            Version: 2020.09.20

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
            Throw "More than 1 object was provided in the ADObject parameter. Only specify 1 to continue."
        }

        If ($ADObject -is [System.DirectoryServices.SearchResult]) {
            $ADObject = $ADObject.GetDirectoryEntry()
        }

        If ($ADObject -like "*,DC=*,DC=*") {
            $ADObject = [System.DirectoryServices.DirectoryEntry]"LDAP://$ADObject"
        }

        If ($ADObject -isnot [System.DirectoryServices.DirectoryEntry]) {
            Throw "Object provided is not the correct type and was not able to be converted to the correct type."
        }

        Function SetValue {
            Param(
                $ADObject,
                $Key,
                $Value
            )
            If ($ADObject.$Key -eq $Value) {
                Return 0
            }
            If ($ADObject.Properties.Contains($Key)) {
                Try {
                    $ADObject.Properties[$Key].Value = $NewValue
                    Return 0
                }
                Catch {
                    Throw "Failed to set '$Value' to '$Key'. Error: $_"
                }
                
            }
            Else {
                Try {
                    $ADObject.Properties[$Key].Add($Value)
                    Return 0
                }
                Catch {
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
        $ADObject.CommitChanges()
    }
    End {
        $ADObject.Close()
        $ADObject.Dispose()
    }
}