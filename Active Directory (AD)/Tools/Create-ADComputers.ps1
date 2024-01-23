Function Create-ADComputers {
    <#
        .DESCRIPTION
            This script/tool is used to dynamically create AD Computers from a csv file.
        .NOTES
            Created By: Kyle Hewitt
            Created On: 2020/05/08
            Version: 2020.11.25
    #>
    Param(
        [String] $CSVPath = "$PSScriptRoot\Create_ADComputers.csv",
        
        [Boolean] $ExportResults = $True,
        [String] $ResultsPath = "$PSScriptRoot\Create_ADComputers_Results_$(Get-Date -Format yyyyMMdd_hhmmss).csv",
        
        [Boolean] $FailureLog = $True,
        [String] $FailureLogPath = "$PSScriptRoot\Create_ADComputers_Failures_$(Get-Date -Format yyyyMMdd_hhmmss).csv",
        
        [Boolean] $Log = $True,
        [String] $LogPath = "$PSScriptRoot\Create_ADComputers_Log_$(Get-Date -Format yyyyMMdd_hhmmss).txt",
        
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

            If ([Boolean]$Object.OtherAttributes) {
                Foreach ($Attr in $Object.OtherAttributes.GetEnumerator()) {
                    $Object.($Attr.Key) = $Attr.Value
                }
                $Object.Remove('OtherAttributes')
            }

            If ($Object.Credential) {
                $Object.RunAsUserName = $Object.Credential.UserName
                $Object.Remove('Credential') | Out-Null
            }

            Foreach ($Header in $Headers) {
                If (![Boolean]$Object.$Header) {
                    $Object.$Header = ''
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
        $NewADComputerAvailableParameters = (Get-Command New-ADComputer).Parameters.GetEnumerator() | 
            Where-Object -FilterScript { 'String', 'String[]', 'Nullable`1', 'SecureString' -contains $_.Value.ParameterType.Name -and $_.key -notlike '*Variable' } | 
            Select-Object -ExpandProperty Key

        Add-ToLog -Value 'Checking if CSV File Exists'
        # If CSV file doesn't exist
        If (!(Test-Path -Path $CSVPath)) {
            Add-ToLog -Value 'Creating CSV File'
            # Create CSV file
            [PSCustomObject]@{ } | 
                Select-Object -Property 'Name', 'Path', 'Server', 'RunAsUserName', 'RunAsPassword' |
                Export-Csv -Path $CSVPath -NoTypeInformation -Force
            
            Write-Host "New-ADComputer Parameters:`n$(($NewADComputerAvailableParameters | Sort-Object) -join "`n")"
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
        If ($AttributeNames -notcontains 'name') {
            Write-Error -Message "$CSVPath does not contain a 'Name' column. It's mandatory." -ErrorAction Stop
            & $CSVPath
            Exit
        }
        

        # Go through each entry in the CSV file and create the Computers
        :CSVInfoForEach Foreach ($Entry in $CSVInfo) {
            Remove-Variable NewADComputerParameters, Domain, DomainContext, DomainObject -ErrorAction SilentlyContinue

            $NewADComputerParameters = [System.Collections.Specialized.OrderedDictionary]@{ }

            If (![Boolean]$Entry.Name) {
                Add-ToFailureLog -Info $Entry -Note 'Name not provided. Skipped.'
                Add-ToLog -Value 'Name not provided. Skipping.'
                Continue CSVInfoForEach
            }

            # If both UserName and Password were provided for this entry use those credentials to perform the actions
            If ([Boolean]$Entry.RunAsPassword -and [Boolean]$Entry.RunAsUserName) {
                $NewADComputerParameters.Credential = New-Object -TypeName System.Management.Automation.PSCredential (
                    $Entry.RunAsUserName,
                    (ConvertTo-SecureString -String ($Entry.RunAsPassword) -AsPlainText -Force)
                )
            }

            # Create hashtables to splat onto the cmdlets
            :AttributeNamesForEach Foreach ($Attribute in $AttributeNames) {
                If (![Boolean]$Entry.$Attribute) { Continue AttributeNamesForEach }
                
                If ('False', 'True' -icontains $Entry.$Attribute) {
                    $Entry.$Attribute = Get-Variable -Name $Entry.$Attribute -ValueOnly
                }

                If ($NewADComputerAvailableParameters -Contains $Attribute) {
                    Add-ToLog -Value "Adding $Attribute to NewADComputer cmdlet Parameters with a value of $($Entry.$Attribute)." -Terminal $False
                    $NewADComputerParameters.$Attribute = $Entry.$Attribute
                }
                Else {
                    Add-ToLog -Value "Adding $Attribute with a value of $($Entry.$Attribute) to the otherAttributes cmdlet Parameter." -Terminal $False
                    If ($NewADComputerParameters.Keys -contains 'OtherAttributes') {
                        $NewADComputerParameters.OtherAttributes.$Attribute = [String]$Entry.$Attribute
                    }
                    Else {
                        $NewADComputerParameters.OtherAttributes = @{ $Attribute = [String]$Entry.$Attribute }
                    }
                }
            }
            
            Add-ToLog -Value 'Getting Domain Controller to run commands against.'
            # Gets random Domain Controller based off of path if one has not already been chosen for this domain
            If ([Boolean]$NewADComputerParameters.Path -and ![Boolean]$NewADComputerParameters.Server) {
                $DomainRoot = ($NewADComputerParameters.Path.Split(',') -like 'DC=*') -Join ','
                $Domain = ($NewADComputerParameters.Path.Split(',') -like 'DC=*').Replace('DC=', '') -join '.'

                # Verify Domain exists and is reachable
                If (![adsi]::exists("LDAP://$DomainRoot")) {
                    Add-ToFailureLog -Info $NewADComputerParameters -Note "$Domain not found"
                    Add-ToLog -Value "$Domain not found. Skipping."
                    Continue CSVInfoForEach
                }

                # Verify AD OU exists
                If (![adsi]::Exists("LDAP://$($NewADComputerParameters.Path)")) {
                    Add-ToFailureLog -Info $NewADComputerParameters -Note "AD OU in Path column does not exist $($Entry.Path)"
                    Add-ToLog -Value "$($NewADComputerParameters.Path) does not exist. Skipping."
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
                $NewADComputerParameters.Server = $Global:DCs.$Domain
            }
            # Get Current Domain if path or server was not specified
            ElseIf (![Boolean]$NewADComputerParameters.Server) {
                Add-ToLog -Value 'Getting Domain Controller from Current Domain.'
                $ErrorActionPreference = 'Stop'
                Try {
                    $DomainObject = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                    $Domain = "$($DomainObject.name)"
                    If (![Boolean]$Global:DCs.$Domain) {
                        $Global:DCs.$Domain = $DomainObject.DomainControllers.Name | Get-Random
                    }
                    $NewADComputerParameters.Server = $Global:DCs.$Domain
                }
                Catch {
                    Add-ToLog -Value "Failed to get Domain Controller from Current Domain. Error: $_"
                }
                $ErrorActionPreference = 'Continue'
            }
            If (![Boolean]$NewADComputerParameters.Server) {
                Add-ToFailureLog -Info $NewADComputerParameters -Note 'Domain Controller not found.'
                Add-ToLog -Value 'Domain Controller not found. Skipping.'
                Continue CSVInfoForEach
            }
            ElseIf ($NewADComputerParameters.Server -like '*.*') {
                $Split = $NewADComputerParameters.Server.Split('.')
                $Domain = $Split[1..$($Split.Count)] -join '.'
            }
            Else {
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().name
            }

            Add-ToLog -Value "Running commands against $($NewADComputerParameters.Server). ($Domain)"

            # Create AD Computer Object
            Try {
                Add-ToLog -Value "Creating $($NewADComputerParameters.Name)."
                New-ADComputer @NewADComputerParameters -ErrorAction Stop
            }
            Catch {
                Add-ToFailureLog -Info $NewADComputerParameters -Note "Failed to create Computer. Error: $_"
                Add-ToLog -Value "Failed to create Computer. Error: $_"
                If ($_.Exception -notlike '*already exists*' -and $_.Exception -notlike '*attribute or value does not exist*') {
                    $Global:DCs.Remove($Domain)
                }
                Continue CSVInfoForEach
            }

            # Convert Certain Values from certain types to others and separate all OtherAttributes values to separate columns
            $NewADComputerParameters = Format-Information -Object $NewADComputerParameters -Headers $AttributeNames

            If ($ExportResults) {
                Add-ToLog -Value "Exporting Results to $ResultsPath."
                ([PSCustomObject]$NewADComputerParameters) | 
                    Export-Csv $ResultsPath -NoTypeInformation -Append -Force
            }
            Else {
                [PSCustomObject]$NewADComputerParameters
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
