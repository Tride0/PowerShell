Function Get-Identities {
    <#
        .Notes
            Created By: Kyle Hewitt
            Created On: 11/20/2019 7:00 AM MST
            Last Edit: 3/3/2020 9:28 AM MST
    #>

    [CmdletBinding()]
    [Alias('gid', 'Get-Id')]
    [OutputType([PSCustomObject[]])]
    Param
    (
        # Will Search through the specified path
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0)][Alias('P')]
        [String[]]$Path = '.\',
        [Alias('A')][Switch]$Inherited = $False,
        # Will Traverse through sub directories
        [Alias('R')][Switch]$Recurse = $False,
        # Will Limit the depth of sub directories it will search through
        [Alias('D')][Int]$Depth,
        # Will Display the output in the console window
        [Alias('PT')][Switch]$PassThru = $True,
        # Will Export the data to the path specified in ExportPath if true
        [Alias('E')][Switch]$Export = $False,
        # Will Export the data to this path
        [Alias('EP')][String]$ExportPath = "$env:USERPROFILE\desktop\Path_Identities_$(Get-Date -Format yyyy_MM_dd).csv",
        # Will Open the file with the exported data
        [Alias('OP')][Switch]$Open = $False,
        [Alias('OW')][Switch]$OverWrite = $False
    )

    Begin {
        Write-Verbose -Message "[$(Get-Date)] Start Setup and Validation"
        $ADSearcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
        $Output = @()
        
        If ($Path.contains('.\')) {
            $Path[$Path.IndexOf(($Path | Where-Object -FilterScript { '.\' }))] = 
            Get-Item .\ | Select-Object -ExpandProperty FullName
        }

        If ($Export.IsPresent) {
            If (!(Test-Path (Split-Path $ExportPath -Parent))) {
                [Void] (New-Item -Path $ExportPath -ItemType Directory -Force )
            }

            If (Test-Path $ExportPath) {
                $OverWriteOptions = Read-Host -Prompt "'$ExportPath' already exists.`nDo you want to overwrite it? [Y]"
                If (![Boolean]$OverWriteOptions -or 'y', 'yes', 't', 'true' -contains $OverWriteOptions) {
                    $OverWriteOptions = $True
                }
            }
        }
        Write-Verbose -Message "[$(Get-Date)] End Setup and Validation"
    }
    Process {
        Write-Verbose -Message "[$(Get-Date)] Path: $Path"
        If ($Recurse.IsPresent) {
            Write-Verbose -Message "[$(Get-Date)] Getting All Sub Directory Paths"
            $Paths = Get-Item -Path $Path
            If ([Boolean]$Depth) {
                Try {
                    [String[]]$Paths += Get-ChildItem -Path $Path -Directory -Recurse -Depth $Depth | 
                        Select-Object -ExpandProperty FullName
                }
                Catch {
                    Write-Error $_
                    Write-Host 'Getting Sub Directories without the use of the Depth Parameter' -ForegroundColor Cyan
                    [String[]]$Paths += Get-ChildItem -Path $Path -Directory -Recurse | 
                        Select-Object -ExpandProperty FullName
                }
            }
            Else {
                [String[]]$Paths += Get-ChildItem -Path $Path -Directory -Recurse | 
                    Select-Object -ExpandProperty FullName
            }
        }
        Else {
            [String[]]$Paths = $Path
        }

        Write-Verbose -Message "[$(Get-Date)] Searching $($Paths.Count) paths for AD Group Identities"
        Foreach ($Path in $Paths) {
            $ACL = Get-Acl -Path $Path
            $Rules = $ACL.Access | 
                Where-Object -FilterScript { (($Inherited.IsPresent -and $_.IsInherited -eq $True ) -or $_.IsInherited -eq $False ) -and 
                    $_.IdentityReference -like '*\*' -and $_.IdentityReference -notlike '*BUILTIN\*' -and
                    $_.IdentityReference -notlike '*NT*\*' 
                }

            Foreach ($Rule in $Rules) {
                # Get just the identity name
                Write-Verbose "[$(Get-Date)] $($Rule.IdentityReference.Value)"

                $Identity = "$($Rule.IdentityReference.Value)".Split('\')[1]

                # Build filter for AD query
                $ADSearcher.Filter = "(samaccountname=$Identity)"

                # Find AD Object
                Write-Verbose "[$(Get-Date)] Getting the AD Object for $Identity"
                $ADResult = $ADSearcher.FindOne()

                # Only include Groups
                If ($ADResult.Properties.objectclass -contains 'group' -and $Output.Identity -notcontains $Identity) {
                    Write-Verbose "[$(Get-Date)] Adding $Identity to Output"
                    $Output += [PSCustomObject]@{
                        Path        = $($Path)
                        Identity    = $Identity
                        AccessType  = $($Rule.AccessControlType)
                        Access      = $($Rule.FileSystemRights)
                        Inherited   = $($Rule.IsInherited)
                        Description = $($ADResult.Properties.description)
                        Notes       = $($ADResult.Properties.info)
                    }
                    
                }
            }
        }
    }
    End {
        If ($PassThru.IsPresent -or !$Export.IsPresent) {
            Write-Verbose -Message "[$(Get-Date)] Outputting Values to Terminal. $($Output.Count)"
            Write-Output -InputObject $Output
        }

        If ($Export.IsPresent) {
            Write-Verbose -Message "[$(Get-Date)] Exporting results to $ExportPath"
            If ($OverWrite.IsPresent) {
                Write-Verbose -Message "[$(Get-Date)] Overwriting $ExportPath"
                $Output | Export-Csv -Path $ExportPath -NoTypeInformation -Force
            }
            Else {
                Write-Verbose -Message "[$(Get-Date)] Writing to $ExportPath"
                $Output | Export-Csv -Path $ExportPath -NoTypeInformation
            }

            If ($Open.IsPresent) {
                Start-Process -FilePath $ExportPath
            }
        }
    }
}