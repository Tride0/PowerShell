<#
    Created By: Kyle Hewitt
    Created On: 10/03/19
    Last Edit: 10/08/19
    Version: 1.0.1
    Purpose: This script is to be used to locate potential owners 

    Notes:
        The script will always export but if PassThru is $true then it will also go through the options on the console
#>

Param(
    $Path = '',
    [Switch]$PassThru = $true,
    $ExportPath = "$ENV:USERPROFILE\desktop\FolderData_$(Get-Date -Format yyyyMMdd_hhmm).csv"
)

Clear-Host

#region Setup

#This snippet is here incase someone wants to use .\ to determine the path
If ($Path -like '.\*') {
    $Path = (Get-Item $Path).FullName
}

#Creates AD Searcher for later use
$ADSearcher = New-Object System.DirectoryServices.DirectorySearcher
#only gets these specific properties from the AD Objects
'objectclass', 'managedby', 'info', 'description', 'name' | 
    ForEach-Object -Process { [Void] $ADSearcher.PropertiesToLoad.Add($_) }

#endregion Setup



## Start Script ##

#region Get all Parent Paths

#Creates Paths Variable and adds root level to it
[String[]]$Paths = $Path
#Creates Temp Variable to use as the stop for the While Loop
$TempPath = $Path
#Gets All Parent Paths to check for an Owner
While ($TempPath.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries).Count -gt 1) {
    #Gets Parent Path
    $ParentPath = Split-Path -Path $TempPath -Parent
    #If Used to prevent errors if TempPath gets too short
    If ([Bool]$ParentPath) {
        #Adds Parent Path to Paths variable for later
        $Paths += $ParentPath
        #Makes the ParentPath the next path to evaluate
        $TempPath = $ParentPath
    }
    #Used to stop Loop for UNC Paths
    Else {
        $TempPath = ''
    }
}
Remove-Variable ParentPath, TempPath -ErrorAction SilentlyContinue

#endregion Get all Parent Paths

#This variable is used to prevent redundant searches
$PreviousIDs = @()

:Paths Foreach ($Path in $Paths) {
    #Clears variables from previous iteration
    Remove-Variable PACEs -ErrorAction SilentlyContinue

    If ($PassThru) {
        Write-Host "`n`n`n$Path" -ForegroundColor Magenta
    }
    
    #Gets the parent ACL to exclude the explicity applied groups
    Try {
        $PACEs = (Get-Acl -Path (Split-Path $Path -Parent) -ErrorAction SilentlyContinue).Access.IdentityReference.value
    }
    Catch {}

    #Gets the ACL that's applied on the folder
    $ACL = Get-Acl -Path $Path
    
    #Gets the access control entries from the ACL
    $ACEs = $ACL | Select-Object -ExpandProperty Access

    #Gets all the IdenityReferences from the ACEs
    $IDRefs = $ACEs |
        Where-Object -FilterScript {
            #The Inherited Groups will be reviewed on the next parent folder
            $_.IsInherited -eq $FALSE -and `
                #There won't be owners on Builtin Groups, this excludes them
                $_.IdentityReference -notlike 'NT AUTHORITY\*' -and `
                $_.IdentityReference -notlike 'BUILTIN\*' -and `
                #This is line is here to exclude more Builtin/Global groups
                $_.IdentityReference -like '*\*' -and `
                #Used to prevent redundant searches
                $PreviousIDs -notcontains $_.IdentityReference -and `
                #Excludes parents ACEs
                $PACEs -notcontains $_.IdentityReference
        } |
        #Selects the IdentityReferences specifically because that's all we want
        Select-Object -ExpandProperty IdentityReference
    
    If (![Bool]$IDRefs -and $PassThru) { 
        
        Write-Host 'Nothing found to check.' -ForegroundColor Red
        Continue Paths 
    }

    #Adds the IdentityReferences from this folder and adds them to the variable to prevent them from being used the next level.
    $PreviousIDs += $IDRefs.Value

    :IDRefs Foreach ($ID in $IDRefs.Value) {
        #Removes the domain prefix from the IdentityReference
        $SAN = $ID.Split('\')[1]
        
        #Gets the AD Object associated with the IdentityReference
        $ADSearcher.Filter = "(samaccountname=$SAN)"
        $ADObject = $ADSearcher.FindOne()

        #Skips any IdentityReference that isn't a group
        If ($ADObject.Properties.objectclass -notcontains 'group') { Continue IDRefs }
        ElseIf ([Bool]$ADObject.Properties.managedby -or [Bool]$ADObject.Properties.info -or [Bool]$ADObject.Properties.description) {
            $Data = [PSCustomObject]@{
                Path        = $Path
                Description = $($ADObject.Properties.description)
                GroupName   = $($ADObject.Properties.name)
                Notes       = $($ADObject.Properties.info)
                ManagedBy   = $($ADObject.Properties.managedby)
            }

            #Exports Data
            $Data | Export-Csv -Path $ExportPath -NoTypeInformation -Append
            
            #Displays data on prompt
            If ($PassThru) {
                Write-Output $Data
            }
        }
    }
    If ($PassThru) {
        If ((Read-Host -Prompt "Press Enter to Check Next Parent... Type 'Exit' to Exit") -eq 'Exit') {
            Exit
        }
    }
    
}

