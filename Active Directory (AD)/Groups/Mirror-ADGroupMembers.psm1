Function Mirror-ADGroupMembers {
    <#
        Created By: Kyle Hewitt
        Created In: 2019
        Version: 2019.0.0
    #>

    Param(
        [String[]]$FromGroup,
        [String]$ToGroup
    )
    Begin {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    Process {
        Foreach ($FGroup in $FromGroup) {
            Write-Host "Mirroring '$FGroup' members to '$ToGroup'"

            $FromMembers = (Get-ADGroup $FGroup -Properties members).Members

            If ($FromMembers.Count -eq 0) {
                Write-Host "'$FGroup' is Empty." -ForegroundColor Yellow
                Return
            }

            # Try to add all members
            Try {
                Add-ADGroupMember `
                    -Identity $ToGroup `
                    -Members $FromMembers `
                    -PassThru -ErrorAction Stop
                Write-Host $FromMembers.Count added to "'$ToGroup'"...
            }

            # Only add members who aren't already a member of the group
            Catch {
                $Already = $AddMembers = @()
                $CurrentMembers = (Get-ADGroup $ToGroup -Properties Members).Members
                :Add Foreach ($Member in $FromMembers) {
                    If ($CurrentMembers -notcontains $Member) {
                        $AddMembers += $Member
                    }
                    Else {
                        $Already += $Member
                    }
                }

                Write-Host ($Already.Count) are already a member of "'$ToGroup'"
                Write-Host ($FromMembers.Count) members in "'$FGroup'"

                If ($Already.Count -lt $FromMembers.Count) {
                    Write-Host Attempting to add $AddMembers.Count members to "'$ToGroup'"
                    Try {
                        Add-ADGroupMember `
                            -Identity $ToGroup `
                            -Members $AddMembers `
                            -PassThru -ErrorAction Stop
                    }
                    Catch {
                        Write-Host "Failed to add members to '$ToGroup'.`n$_" -ForegroundColor Red
                    }

                }
            }
        }
    }
}