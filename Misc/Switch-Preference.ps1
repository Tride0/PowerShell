Function Switch-Preference {
    <#
        .NOTES
            Created By: Kyle Hewitt
            Created On: 5/04/20

        .DESCRIPTION
            This function will switch the global preference to a new one. Running the command again against the same Preference will cause it to switch back
    #>
    Param(
        [validateSet('Confirm', 'Debug', 'ErrorAction',
            'Infomration', 'Progress', 'Verbose', 'Warning', 'Whatif')]
        $Preference,
        $NewPreference
    )
    
    $CurrentValue = (Get-Variable -Name "$Preference`Preference" -Scope Global).value
    If ($NewPreference) {
        Write-Verbose "Setting $Preference`Preference to $NewPreference"
        # Store Previous Preference
        Set-Variable -Name "SP_$Preference`Preference" -Value $CurrentValue -Scope Global
        # Set new Preference
        Set-Variable "$Preference`Preference" -Value $NewPreference -Scope Global
    }
    Else {
        # Get Previous Prefeerence
        $SPPreferenceVar = Get-Variable "SP_$Preference`Preference" -Scope Global
        Write-Verbose "Setting $Preference`Preference to $($SPPreferenceVar.Value)"
        # Set Previous preference
        Set-Variable "$Preference`Preference" -Value $SPPreferenceVar.Value -Scope Global
        # Store the New Previous Preference
        Set-Variable "SP_$Preference`Preference" -Value $CurrentValue -Scope Global
    }
}
