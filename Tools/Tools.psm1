#region #0 Module Header
<#
.SYNOPSIS
    PowerShell Developer Tools Module for Codebase Verification and Analysis.

.DESCRIPTION
    Provides automated tools for syntax validation, structural integrity checks,
    function boundary retrieval, and function measurement coverage audits.
#>
#endregion #0 Module Header


#region #1 Syntax Validation Functions

function Test-ScriptSyntax {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [switch]$Quiet
    )

    $ResolvedPath = (Resolve-Path -Path $FilePath -ErrorAction Stop).Path
    $ParserErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($ResolvedPath, [ref]$null, [ref]$ParserErrors)

    $HasErrors = ($ParserErrors -and $ParserErrors.Count -gt 0)

    if ($Quiet) {
        return (-not $HasErrors)
    }

    if (-not $HasErrors) {
        Write-Host "PARSER SUCCESS: Zero syntax errors detected in: $ResolvedPath" -ForegroundColor Green
        return [PSCustomObject]@{
            FilePath     = $ResolvedPath
            SyntaxErrors = 0
            Passed       = $true
            Errors       = @()
        }
    }
    else {
        Write-Host "PARSER FAILED: $($ParserErrors.Count) syntax errors detected in: $ResolvedPath" -ForegroundColor Red
        foreach ($ErrorRecord in $ParserErrors) {
            Write-Host ("  Line {0,5}, Column {1,4}: {2}" -f $ErrorRecord.Extent.StartLineNumber, $ErrorRecord.Extent.StartColumnNumber, $ErrorRecord.Message) -ForegroundColor Yellow
        }
        return [PSCustomObject]@{
            FilePath     = $ResolvedPath
            SyntaxErrors = $ParserErrors.Count
            Passed       = $false
            Errors       = $ParserErrors
        }
    }
} # function Test-ScriptSyntax

#endregion #1 Syntax Validation Functions


#region #2 Function Definition Functions

function Get-FunctionDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Position = 1)]
        [string]$FunctionName,

        [switch]$Raw
    )

    $ResolvedPath = (Resolve-Path -Path $FilePath -ErrorAction Stop).Path
    $Lines = [System.IO.File]::ReadAllLines($ResolvedPath)

    if ($FunctionName) {
        $EscapedName = [regex]::Escape($FunctionName)
        $StartLineIndex = -1
        $EndLineIndex = -1

        for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
            if ($Lines[$Index] -match "^\s*function\s+$EscapedName\b") {
                $StartLineIndex = $Index
                break
            }
        }

        if ($StartLineIndex -eq -1) {
            Write-Warning "Function definition for '$FunctionName' was not found in: $ResolvedPath"
            return $null
        }

        for ($SearchIndex = $StartLineIndex; $SearchIndex -lt $Lines.Count; $SearchIndex++) {
            if ($Lines[$SearchIndex] -match "^\s*\}\s*#\s*function\s+$EscapedName\b") {
                $EndLineIndex = $SearchIndex
                break
            }
        }

        if ($EndLineIndex -eq -1) {
            Write-Warning "Matching closing tag '} # function $FunctionName' was not found in: $ResolvedPath"
            return $null
        }

        $LineCount = ($EndLineIndex - $StartLineIndex) + 1
        $DefinitionLines = $Lines[$StartLineIndex..$EndLineIndex]
        $DefinitionText = $DefinitionLines -join [System.Environment]::NewLine

        if ($Raw) {
            return $DefinitionText
        }

        return [PSCustomObject]@{
            FunctionName = $FunctionName
            FilePath     = $ResolvedPath
            StartLine    = ($StartLineIndex + 1)
            EndLine      = ($EndLineIndex + 1)
            LineCount    = $LineCount
            Definition   = $DefinitionText
        }
    }
    else {
        # Inventory all functions in the script file
        $FunctionResults = [System.Collections.ArrayList]@()
        for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
            if ($Lines[$Index] -match "^\s*function\s+([a-zA-Z0-9_\-]+)") {
                $FoundName = $Matches[1]
                $StartNumber = $Index + 1
                $EscapedFound = [regex]::Escape($FoundName)
                $FoundEndNumber = $null

                for ($SearchIndex = $Index; $SearchIndex -lt $Lines.Count; $SearchIndex++) {
                    if ($Lines[$SearchIndex] -match "^\s*\}\s*#\s*function\s+$EscapedFound\b") {
                        $FoundEndNumber = $SearchIndex + 1
                        break
                    }
                }

                $LineTotal = if ($FoundEndNumber) { ($FoundEndNumber - $StartNumber) + 1 } else { $null }

                [void]$FunctionResults.Add([PSCustomObject]@{
                    FunctionName    = $FoundName
                    StartLine       = $StartNumber
                    EndLine         = $FoundEndNumber
                    LineCount       = $LineTotal
                    HasClosingTag   = ($null -ne $FoundEndNumber)
                })
            }
        }

        return @($FunctionResults)
    }
} # function Get-FunctionDefinition

#endregion #2 Function Definition Functions


#region #3 Script Integrity Functions

function Test-ScriptIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [switch]$Quiet
    )

    $ResolvedPath = (Resolve-Path -Path $FilePath -ErrorAction Stop).Path
    $Lines = [System.IO.File]::ReadAllLines($ResolvedPath)

    $RegionDiscrepancies = 0
    $RegionsMatched = 0
    $RegionStack = [System.Collections.Generic.Stack[string]]::new()

    for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
        $Line = $Lines[$Index]
        if ($Line -match "^\s*#region\b(.*)") {
            $RegionStack.Push($Matches[1].Trim())
        }
        elseif ($Line -match "^\s*#endregion\b(.*)") {
            if ($RegionStack.Count -gt 0) {
                [void]$RegionStack.Pop()
                $RegionsMatched++
            }
            else {
                $RegionDiscrepancies++
            }
        }
    }
    $RegionDiscrepancies += $RegionStack.Count

    $TotalFunctions = 0
    $ClosingTagsMatched = 0
    $MissingClosingTags = 0

    for ($Index = 0; $Index -lt $Lines.Count; $Index++) {
        if ($Lines[$Index] -match "^\s*function\s+([a-zA-Z0-9_\-]+)") {
            $TotalFunctions++
            $FoundName = $Matches[1]
            $EscapedFound = [regex]::Escape($FoundName)
            $MatchedClosing = $false

            for ($SearchIndex = $Index; $SearchIndex -lt $Lines.Count; $SearchIndex++) {
                if ($Lines[$SearchIndex] -match "^\s*\}\s*#\s*function\s+$EscapedFound\b") {
                    $MatchedClosing = $true
                    break
                }
            }

            if ($MatchedClosing) {
                $ClosingTagsMatched++
            }
            else {
                $MissingClosingTags++
            }
        }
    }

    $IntegrityPassed = ($RegionDiscrepancies -eq 0 -and $MissingClosingTags -eq 0)

    if ($Quiet) {
        return $IntegrityPassed
    }

    $ResultObject = [PSCustomObject]@{
        FilePath            = $ResolvedPath
        RegionsMatched      = $RegionsMatched
        RegionDiscrepancies = $RegionDiscrepancies
        FunctionsTotal      = $TotalFunctions
        ClosingTagsMatched  = $ClosingTagsMatched
        MissingClosingTags  = $MissingClosingTags
        IntegrityPassed     = $IntegrityPassed
    }

    if ($IntegrityPassed) {
        Write-Host "INTEGRITY SUCCESS: All $RegionsMatched regions and all $ClosingTagsMatched function closing tags matched in: $ResolvedPath" -ForegroundColor Green
    }
    else {
        Write-Host "INTEGRITY FAILED: Discrepancies detected in: $ResolvedPath" -ForegroundColor Red
        if ($RegionDiscrepancies -gt 0) { Write-Host "  Region discrepancies: $RegionDiscrepancies" -ForegroundColor Yellow }
        if ($MissingClosingTags -gt 0) { Write-Host "  Missing function closing tags: $MissingClosingTags" -ForegroundColor Yellow }
    }

    return $ResultObject
} # function Test-ScriptIntegrity

#endregion #3 Script Integrity Functions


#region #4 Measurement Coverage Functions

function Test-FunctionMeasurementCoverage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [string[]]$ExcludedFunctions = @(
            'Start-FunctionMeasurement',
            'Stop-FunctionMeasurement',
            'Get-FunctionMeasurementSummary',
            'ViewUI'
        ),

        [switch]$Quiet
    )

    $ResolvedPath = (Resolve-Path -Path $FilePath -ErrorAction Stop).Path
    $ParserErrors = $null
    $AbstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseFile($ResolvedPath, [ref]$null, [ref]$ParserErrors)

    $AllFunctions = $AbstractSyntaxTree.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    $OperationalFunctions = [System.Collections.ArrayList]@()
    $InstrumentedFunctions = [System.Collections.ArrayList]@()
    $UninstrumentedFunctions = [System.Collections.ArrayList]@()
    $AsymmetricalFunctions = [System.Collections.ArrayList]@()

    foreach ($FunctionAst in $AllFunctions) {
        if ($ExcludedFunctions -contains $FunctionAst.Name) { continue }
        [void]$OperationalFunctions.Add($FunctionAst)

        $FunctionBodyText = $FunctionAst.Body.Extent.Text
        $HasStart = $FunctionBodyText -match 'Start-FunctionMeasurement'
        $HasStop = $FunctionBodyText -match 'Stop-FunctionMeasurement'

        if ($HasStart -and $HasStop) {
            [void]$InstrumentedFunctions.Add($FunctionAst.Name)
        }
        elseif (-not $HasStart -and -not $HasStop) {
            [void]$UninstrumentedFunctions.Add([PSCustomObject]@{
                Line = $FunctionAst.Extent.StartLineNumber
                Name = $FunctionAst.Name
                Verb = ($FunctionAst.Name -split '-')[0]
            })
        }
        else {
            [void]$AsymmetricalFunctions.Add([PSCustomObject]@{
                Line     = $FunctionAst.Extent.StartLineNumber
                Name     = $FunctionAst.Name
                HasStart = $HasStart
                HasStop  = $HasStop
            })
        }
    }

    $CoveragePercentage = if ($OperationalFunctions.Count -gt 0) {
        [Math]::Round(($InstrumentedFunctions.Count / $OperationalFunctions.Count) * 100, 2)
    }
    else {
        100.0
    }

    $Passed = ($UninstrumentedFunctions.Count -eq 0 -and $AsymmetricalFunctions.Count -eq 0)

    if ($Quiet) {
        return $Passed
    }

    $ResultObject = [PSCustomObject]@{
        FilePath                = $ResolvedPath
        TotalFunctions          = $AllFunctions.Count
        OperationalFunctions    = $OperationalFunctions.Count
        InstrumentedFunctions   = $InstrumentedFunctions.Count
        UninstrumentedFunctions = $UninstrumentedFunctions.Count
        AsymmetricalFunctions   = $AsymmetricalFunctions.Count
        CoveragePercentage      = $CoveragePercentage
        Passed                  = $Passed
    }

    if ($Passed) {
        Write-Host "COVERAGE SUCCESS: All $($OperationalFunctions.Count) operational functions are symmetrically instrumented ($CoveragePercentage%)." -ForegroundColor Green
    }
    else {
        Write-Host "COVERAGE WARNING: Coverage is at $CoveragePercentage% ($($InstrumentedFunctions.Count)/$($OperationalFunctions.Count))." -ForegroundColor Yellow
        if ($AsymmetricalFunctions.Count -gt 0) {
            Write-Host "  Asymmetrical functions ($($AsymmetricalFunctions.Count)):" -ForegroundColor Red
            $AsymmetricalFunctions | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Yellow
        }
        if ($UninstrumentedFunctions.Count -gt 0) {
            Write-Host "  Uninstrumented functions ($($UninstrumentedFunctions.Count)):" -ForegroundColor Red
            $UninstrumentedFunctions | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Yellow
        }
    }

    return $ResultObject
} # function Test-FunctionMeasurementCoverage

#endregion #4 Measurement Coverage Functions


#region #5 Unified Codebase Verification Functions

function Invoke-CodebaseVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    $ResolvedPath = (Resolve-Path -Path $FilePath -ErrorAction Stop).Path

    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "Codebase Verification Runner: $ResolvedPath" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan

    Write-Host "`n[1/3] Executing Syntax Verification..." -ForegroundColor Cyan
    $SyntaxResult = Test-ScriptSyntax -FilePath $ResolvedPath

    Write-Host "`n[2/3] Executing Script Integrity Verification..." -ForegroundColor Cyan
    $IntegrityResult = Test-ScriptIntegrity -FilePath $ResolvedPath

    Write-Host "`n[3/3] Executing Measurement Coverage Verification..." -ForegroundColor Cyan
    $CoverageResult = Test-FunctionMeasurementCoverage -FilePath $ResolvedPath

    $AllPassed = ($SyntaxResult.Passed -and $IntegrityResult.IntegrityPassed -and $CoverageResult.Passed)

    Write-Host "`n============================================================" -ForegroundColor Cyan
    if ($AllPassed) {
        Write-Host "OVERALL VERIFICATION: PASSED (Zero errors, intact integrity, full coverage)" -ForegroundColor Green
    }
    else {
        Write-Host "OVERALL VERIFICATION: FAILED (Review the warnings above)" -ForegroundColor Red
    }
    Write-Host "============================================================`n" -ForegroundColor Cyan

    return [PSCustomObject]@{
        FilePath        = $ResolvedPath
        SyntaxPassed    = $SyntaxResult.Passed
        IntegrityPassed = $IntegrityResult.IntegrityPassed
        CoveragePassed  = $CoverageResult.Passed
        OverallPassed   = $AllPassed
    }
} # function Invoke-CodebaseVerification

#endregion #5 Unified Codebase Verification Functions


#region #6 Module Export Configuration

Export-ModuleMember -Function @(
    'Test-ScriptSyntax',
    'Get-FunctionDefinition',
    'Test-ScriptIntegrity',
    'Test-FunctionMeasurementCoverage',
    'Invoke-CodebaseVerification'
)

#endregion #6 Module Export Configuration

