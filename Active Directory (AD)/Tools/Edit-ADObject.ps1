Function Edit-ADObjects {
    <#
        .DESCRIPTION
            This script/tool is used to edit AD Objects dynamically from a csv file.
        .NOTES
            Created By: Kyle Hewitt
            Created On: 2020/05/22
            Version: 2020.11.25
    #>
    Param(
        [String] $CSVPath = "$PSScriptRoot\Edit_ADObjects.csv",
        
        [Boolean] $ExportResults = $True,
        [String] $ResultsPath = "$PSScriptRoot\Edit_ADObjects_Results_$(Get-Date -Format yyyyMMdd_hhmmss).csv",
        
        [Boolean] $FailureLog = $True,
        [String] $FailureLogPath = "$PSScriptRoot\Edit_ADObjects_Failures_$(Get-Date -Format yyyyMMdd_hhmmss).csv",
        
        [Boolean] $Log = $True,
        [String] $LogPath = "$PSScriptRoot\Edit_ADObjects_Log_$(Get-Date -Format yyyyMMdd_hhmmss).txt",
        
        [Boolean] $PassThru = $True
    )
    Begin {
        #region Functions

        Function Add-ToFailureLog {
            Param(
                $Info,
                $Note
            )
            If (!$FailureLog) { Return }
            $Info.Note = $Note
            [PSCustomObject](Format-Information -Object $Info -Headers $AttributeNames) |
                Export-Csv -Path $FailureLogPath -NoTypeInformation -Append -Force
        }

        Function Add-ToLog {
            [cmdletbinding()]
            Param(
                [Parameter(Position = 0)]$Value,
                $Path = $LogPath,
                $Terminal = $PassThru
            )
            If ($Terminal) { Write-Host "[$(Get-Date)] $Value" }
            Add-Content -Value "[$(Get-Date)] $Value" -Path $Path -Force
        }

        Function Format-Information {
            Param(
                $Object,
                $Headers = $AttributeNames
            )
            
            If ([Boolean]$Object.Replace) {
                Foreach ($Attr in $Object.Replace.GetEnumerator()) {
                    $Object.($Attr.Key) = $Attr.Value
                }
                $Object.Remove('Replace')
            }

            If ($Object.Credential) {
                $Object.RunAsUserName = $Object.Credential.UserName
                $Object.Remove('Credential') | Out-Null
            }

            Foreach ($Header in $Headers) {
                If ($Header -eq 'Identity' -and [Boolean]$Entry.Identity) {
                    $Object.$Header = $Entry.Identity
                }
                ElseIf ($Object.Clear -contains $Header) {
                    $Object.$Header = 'Clear'
                }
                ElseIf (![Boolean]$Object.$Header) {
                    $Object.$Header = ''
                }
            }

            

            For ($i = 0; $i -lt $Object.Keys.Count; $i++) {
                $Key = ([string[]]$Object.Keys)[$i]
                If ($Object.$Key -is [Array]) {
                    $Object.$Key = $Object.$Key -join "`n"
                }
                ElseIf ($Object.$Key -is [System.Security.SecureString]) {
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Object.$Key))
                    $Object.$Key = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                }
            }

                
            Return $Object
        }

        #endregion Functions

        Add-ToLog -Value 'Importing ActiveDirectory Module'
        Import-Module ActiveDirectory -ErrorAction Stop

        Add-ToLog -Value 'Checking and Creating Parent Directories'
        # Create Path Parent Folder if not created already
        $ResultsPath, $FailureLogPath, $LogPath |
            ForEach-Object -Process {
                # Create parent Directory if it doesn't exist
                If (!(Test-Path -Path (Split-Path -Path $_ -Parent))) {
                    [Void] (New-Item -Path (Split-Path -Path $_ -Parent) -ItemType Directory -Force)
                }
            }

        # Get List of available parameters so they can be used on the correct cmd let and parameter
        $SetADObjectAvailableParameters = (Get-Command Set-ADObject).Parameters.GetEnumerator() | 
            Where-Object -FilterScript { 'String', 'Nullable`1', 'SecureString' -contains $_.Value.ParameterType.Name -and $_.key -notlike '*Variable' } | 
            Select-Object -ExpandProperty Key

        Add-ToLog -Value 'Checking if CSV File Exists'
        # If CSV file doesn't exist
        If (!(Test-Path -Path $CSVPath)) {
            Add-ToLog -Value 'Creating CSV File'
            # Create CSV file
            [PSCustomObject]@{ Identity = 'Use samaccountname, userprincipalname or distinguishedname' } | 
                Select-Object -Property 'Identity', 'Path', 'Server', 'RunAsUserName', 'RunAsPassword' |
                Export-Csv -Path $CSVPath -NoTypeInformation -Force
            
            Write-Host "Set-ADObject Parameters:`n$(($SetADObjectAvailableParameters | Sort-Object) -join "`n")"
            Add-ToLog -Value 'Opening CSV File'
            # Open CSV File
            Start-Process -FilePath $CSVPath

            # Exit Powershell
            Add-ToLog -Value 'Exiting PowerShell'
            Exit
        }

        # Stores Domain Controllers for specific Domains
        $Global:DCs = @{ }
    }
    Process {
        # Import data from CSV file
        Add-ToLog -Value "Importing $CSVPath."
        [Array]$CSVInfo = Import-Csv -Path $CSVPath -ErrorAction Stop
        
        # Get column headers and use them as the attribute names
        Add-ToLog -Value "Getting Headers of $CSVPath."
        $AttributeNames = (Get-Content -Path $CSVPath -TotalCount 1).Split(',').Replace('"', '')
        Add-ToLog -Value "Headers: $($AttributeNames -join ' , ')"

        # If a name column isn't provided then exit out of script
        If ($AttributeNames -notcontains 'Identity') {
            Write-Error -Message "$CSVPath does not contain a 'Identity' column. It's mandatory." -ErrorAction Stop
            & $CSVPath
            Exit
        }
        

        # Go through each entry in the CSV file and create the Objects
        :CSVInfoForEach Foreach ($Entry in $CSVInfo) {
            Remove-Variable EditADObjectParameters, Domain, DomainContext, DomainObject -ErrorAction SilentlyContinue

            $SetADObjectParameters = [System.Collections.Specialized.OrderedDictionary]@{ }

            If (![Boolean]$Entry.Identity) {
                Add-ToFailureLog -Info $Entry -Note 'No identity was provided. Skipped.'
                Add-ToLog -Value 'No identity was provided. Skipping.'
                Continue CSVInfoForEach
            }
            
            # If both UserName and Password were provided for this entry use those credentials to perform the actions
            If ([Boolean]$Entry.RunAsPassword -and [Boolean]$Entry.RunAsUserName) {
                $SetADObjectParameters.Credential = New-Object -TypeName System.Management.Automation.PSCredential (
                    $Entry.RunAsUserName,
                    (ConvertTo-SecureString -String ($Entry.RunAsPassword) -AsPlainText -Force)
                )
            }

            # Create hashtables to splat onto the cmdlets
            :AttributeNamesForEach Foreach ($Attribute in $AttributeNames) {
                If ($Attribute -eq 'Identity') { Continue AttributeNamesForEach }
                If ('False', 'True' -icontains $Entry.$Attribute) {
                    $Entry.$Attribute = Get-Variable -Name $Entry.$Attribute -ValueOnly
                }
                If ($Entry.$Attribute -eq 'Clear') {
                    Add-ToLog -Value "Adding $Attribute with a value of $($Entry.$Attribute) to the Clear cmdlet Parameter." -Terminal $False
                    If ($SetADObjectParameters.Keys -contains 'Clear') {
                        $SetADObjectParameters.Clear += "$Attribute"
                    }
                    Else {
                        [String[]]$SetADObjectParameters.Clear = "$Attribute"
                    }
                }
                ElseIf ($SetADObjectAvailableParameters -Contains $Attribute) {
                    Add-ToLog -Value "Adding $Attribute to Set-ADObject cmdlet Parameters with a value of $($Entry.$Attribute)." -Terminal $False
                    $SetADObjectParameters.$Attribute = "$($Entry.$Attribute)"
                }
                ElseIf ([Boolean]$Entry.$Attribute) {
                    Add-ToLog -Value "Adding $Attribute with a value of $($Entry.$Attribute) to the Replace cmdlet Parameter." -Terminal $False
                    If ($SetADObjectParameters.Keys -contains 'Replace') {
                        $SetADObjectParameters.Replace.$Attribute = "$($Entry.$Attribute)"
                    }
                    Else {
                        $SetADObjectParameters.Replace = @{ $Attribute = [String]$Entry.$Attribute }
                    }
                }
            }
            
            Add-ToLog -Value 'Getting Domain Controller to run commands against.'
            # Gets random Domain Controller based off of path if one has not already been chosen for this domain
            If ([Boolean]$SetADObjectParameters.Path -and ![Boolean]$SetADObjectParameters.Server) {
                $DomainRoot = ($SetADObjectParameters.Path.Split(',') -like 'DC=*') -Join ','
                $Domain = ($SetADObjectParameters.Path.Split(',') -like 'DC=*').Replace('DC=', '') -join '.'

                # Verify Domain exists and is reachable
                If (![adsi]::exists("LDAP://$DomainRoot")) {
                    Add-ToFailureLog -Info $SetADObjectParameters -Note "Domain '$Domain' not found"
                    Add-ToLog -Value "Domain '$Domain' not found. Skipping."
                    Continue CSVInfoForEach
                }

                # Verify AD OU exists
                If (![adsi]::Exists("LDAP://$($SetADObjectParameters.Path)")) {
                    Add-ToFailureLog -Info $SetADObjectParameters -Note "AD OU in Path column does not exist $($Entry.Path)"
                    Add-ToLog -Value "$($SetADObjectParameters.Path) does not exist. Skipping."
                    Continue CSVInfoForEach
                }

                If (![Boolean]$Global:DCs.$Domain) {
                    Add-ToLog -Value "Getting Domain Controller from $Domain."
                    $ErrorActionPreference = 'Stop'
                    Try {
                        $DomainContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new('Domain', $Domain)
                        $DomainObject = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
                        $Global:DCs.$Domain = $DomainObject.DomainControllers.Name | Get-Random
                    }
                    Catch {
                        Add-ToLog -Value "Failed to get Domain Controller from $Domain. Error: $_"
                    }
                    $ErrorActionPreference = 'Continue'
                }
                $SetADObjectParameters.Server = $Global:DCs.$Domain
            }
            # Get Current Domain if path or server was not specified
            ElseIf (![Boolean]$SetADObjectParameters.Server) {
                Add-ToLog -Value 'Getting Domain Controller from Current Domain.'
                $ErrorActionPreference = 'Stop'
                Try {
                    $DomainObject = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                    $Domain = "$($DomainObject.name)"
                    If (![Boolean]$Global:DCs.$Domain) {
                        $Global:DCs.$Domain = $DomainObject.DomainControllers.Name | Get-Random
                    }
                    $SetADObjectParameters.Server = $Global:DCs.$Domain
                }
                Catch {
                    Add-ToLog -Value "Failed to get Domain Controller from Current Domain. Error: $_"
                }
                $ErrorActionPreference = 'Continue'
            }
            If (![Boolean]$SetADObjectParameters.Server) {
                Add-ToFailureLog -Info $SetADObjectParameters -Note 'Domain Controller not found.'
                Add-ToLog -Value 'Domain Controller not found. Skipping.'
                Continue CSVInfoForEach
            }
            ElseIf ($SetADObjectParameters.Server -like '*.*') {
                $Split = $SetADObjectParameters.Server.Split('.')
                $Domain = $Split[1..$($Split.Count)] -join '.'
            }
            Else {
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().name
            }

            Add-ToLog -Value "Running commands against $($SetADObjectParameters.Server). ($Domain)"

            # Edit AD Object
            Try {
                Add-ToLog -Value "Setting $($Entry.Identity)."
                Get-ADObject -ldapFilter "(|(samaccountname=$($Entry.Identity))(userprincipalname=$($Entry.Identity))(distinguishedname=$($Entry.Identity)))" -ErrorAction Stop | Set-ADObject @EditADObjectParameters -ErrorAction Stop
            }
            Catch {
                
                If ($_.Exception -is [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]) {
                    Add-ToFailureLog -Info $SetADObjectParameters -Note "Failed to find Object. Error: $_"
                }
                Else {
                    Add-ToFailureLog -Info $SetADObjectParameters -Note "Failed to edit Object. Error: $_"
                }
                Add-ToLog -Value "Failed to edit Object. Error: $_"
                If ($_.Exception -notlike '*already exists*' -and $_.Exception -notlike '*attribute or value does not exist*') {
                    $Global:DCs.Remove($Domain)
                }
                
                Continue CSVInfoForEach
            }
            
            # Convert Certain Values from certain types to others and separate all Replace values to separate columns
            $SetADObjectParameters = Format-Information -Object $SetADObjectParameters -Headers $AttributeNames
                
            If ($ExportResults) {
                Add-ToLog -Value "Exporting Results to $ResultsPath."
                ([PSCustomObject]$SetADObjectParameters) | 
                    Export-Csv $ResultsPath -NoTypeInformation -Append -Force
            }
            Else {
                [PSCustomObject]$SetADObjectParameters
            }
        }
    }
    End {
        If (Test-Path $ResultsPath) {
            & $ResultsPath
        }
        If (Test-Path $FailureLogPath) {
            & $FailureLogPath
        }
        Remove-Variable -Name DCs -ErrorAction SilentlyContinue
    }
}