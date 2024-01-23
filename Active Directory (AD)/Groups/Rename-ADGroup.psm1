Function Rename-ADGroup {
    Param(
        [Parameter(Mandatory = $True, Position = 0)]$OldName,
        [Parameter(Mandatory = $True, Position = 1)]$NewName
    )
    If ($OldName -is [string]) { $OldName = Get-ADGroup $OldName }
    If ($OldName -cne $NewName) {
        Write-Host "'$OldName'" `>> "'$NewName'"
        Try {
            Set-ADGroup -Identity $OldName -DisplayName $NewName -SamAccountName $NewName -ErrorAction Stop
        }
        Catch {
            Set-ADGroup -Identity $NewName -DisplayName $NewName -SamAccountName $NewName
        }
        Rename-ADObject -Identity $OldName -NewName $NewName
    }
}