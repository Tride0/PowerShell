@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Tools.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0.0'

    # Supported PowerShell Editions
    CompatiblePSEditions = @('Desktop', 'Core')

    # Globally Unique Identifier used to uniquely identify this module
    GUID = '9b6d8594-5cb8-4db8-92c2-7f9cb73b9842'

    # Author of this module
    Author = 'Kylel'

    # Company or vendor of this module
    CompanyName = 'Community'

    # Copyright statement for this module
    Copyright = '(c) 2026 Kylel. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Developer tools module for PowerShell codebase syntax verification, structural integrity audits, function boundary extraction, and function measurement coverage audits.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module, for best performance, do not use wildcards
    FunctionsToExport = @(
        'Test-ScriptSyntax'
        'Get-FunctionDefinition'
        'Test-ScriptIntegrity'
        'Test-FunctionMeasurementCoverage'
        'Invoke-CodebaseVerification'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            Tags = @('DeveloperTools', 'AbstractSyntaxTree', 'Integrity', 'Testing', 'Measurement')
        }
    }
}

