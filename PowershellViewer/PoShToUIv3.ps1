<# PoshToUI
    Project:
        - Dynamic PowerShell Object Viewer
        - UI is created using PowerShell
        - No hardcoded UI
        - No Abbrevations
        - Tag property should be used to store information that is used often or later.

    To Do
        6. Array - AsBlock (Delimiter*) - * Default is Comma; NewLine is always an additional delimiter (NewLine explanation in ToolTip); When AsBlock is clicked it changes to 'Default' and vice versa
        7. Dropdown - Sort, Search, Filter
        8. Construct Button - Indicators
            Turns Green when it's created
                Clears error, where ever that goes
            Turns Red when it errors
                Tooltip should show error, or somewhere
            Turns Yellow when something changes inside the form to indiciate the Object doesn't match the fields.
            Fields with values will be highlighted.
            Fields get marked as required (*) when the object requires additional fields with filled in fields.
        10. Password - How to save securely?

    Test Types:
        System.String[]
        System.Windows.Automation.DockPosition
        System.DirectoryServices.Protocols.LdapConnection
        System.DirectoryServices.DirectorySearcher
        System.Diagnostics.EventLog
#>
Clear-Host

#region #0 Variables

[string]$TypeToShow = 'System.DirectoryServices.DirectorySearcher[]'
[string]$Title = ($TypeToShow.Split('.')[-1] + $(if ($TypeToShow -like '*`[`]') { 's' })) -replace '\[\]', ''

[string]$SettingsRoot = "$env:APPDATA\PoshToUI"
[string]$QuickSetRootPath = "$SettingsRoot\QuickSet"
[string]$RandomValuesConfigurationFilePath = "$SettingsRoot\RandomValuesConfiguration.json"
$script:GlobalRandomValuesConfiguration = $null

[string[]]$PasswordFields = @(
    'password'
)

[hashtable]$FontSizes = @{
    Default     = 10
    Header      = 16
    MiniHeader  = 12
    Description = 10
    Button      = 14
}
$FontFamily = 'Cascadia Mono'
$ColorSequence = @(
    '#8879A1'
    '#A194BA'
    '#C1B8D1'
    '#EDEAFA'
)
$HeaderTitleMaximizedForeground = 'Black'
$HeaderDescriptionMaximizedForeground = '#0B132B'
$HeaderTitleMinimizedForeground = '#4E4660'
$HeaderDescriptionMinimizedForeground = '#635978'
[double]$SubMenuOverlapOffset = 0


# UI Element Names
$WindowName = 'Window'
$WindowScrollViewerName = 'Window_ScrollViewer'
$WindowScrollViewerStackPanelName = 'Window_ScrollViewer_StackPanel'

$ContentBorderName = 'Wrapper_Border'
$ContentBorderDockName = 'Content_Border_Dock'

$ContentHeaderBorderName = 'Wrapper_Header'
$ContentHeaderBorderStackName = 'Content_Header_Border_Stack'
$ContentHeaderTitleValueName = 'Content_Header_Title_Value'
$ContentHeaderDescriptionValueName = 'Content_Header_Description_Value'
$ContentHeaderTitleBorderName = 'Content_Header_Title_Border'
$ContentHeaderTitleBorderDockName = 'Content_Header_Title_Border_Dock'
$ContentHeaderTitleBorderDockStackName = 'Content_Header_Title_Border_Dock_Stack'

$ContentSlotElementName = 'ContentSlot'
$ContentElementName = 'Content'

$ArrayItemStackName = 'ArrayItemStack'
$ConstructName = 'Construct'

$MenuName = 'Menu'
$ButtonMenuName = 'ButtonMenu'
$UniversalMenuTriggerButtonName = 'UniversalMenuTriggerButton'
$UniversalMenuLockIndicatorButtonName = 'UniversalMenuLockIndicatorButton'
$UniversalMenuDisableIndicatorButtonName = 'UniversalMenuDisableIndicatorButton'
$script:UniversalSharedMenu = $null

$MinMaxButtonName = 'MinMaxButton'
$AddArrayItemButtonName = 'AddArrayItemButton'

$RandomValuesButtonNameSuffix = 'RandomValuesButton'
$RandomValuesSettingsButtonNameSuffix = 'RandomValuesSettingsButton'
$SortMenuNameSuffix = 'SortMenu'
$DragHandleNameSuffix = 'DragHandle'
$LockUnlockButtonName = 'LockUnlockButton'
$ClearButtonNameSuffix = 'ClearButton'
$DisableEnableButtonNameSuffix = 'DisableEnableButton'
$DeleteButtonNameSuffix = 'DeleteButton'

$ConstructButtonNameSuffix = 'ConstructButton'
$IndexBoxNameSuffix = 'IndexBox'

$CustomDateTimePickerName = 'CustomDateTimePicker'
$ContentDateTimeDisplayTextBoxName = 'DisplayTextBox'

$SearchButtonNameSuffix = 'SearchButton'
$SearchBarNameSuffix = 'SearchBar'
$SearchInputNameSuffix = 'SearchInput'
$SearchCountNameSuffix = 'SearchCount'
$SearchPrevButtonNameSuffix = 'SearchPrevButton'
$SearchNextButtonNameSuffix = 'SearchNextButton'
$SearchCloseButtonNameSuffix = 'SearchCloseButton'
$SearchRegexButtonNameSuffix = 'SearchRegexButton'
$SearchActionsButtonNameSuffix = 'SearchActionsButton'

$QuickSetMenuNameSuffix = 'QuickSetMenu'
$QuickSetBadgeNameSuffix = 'QuickSetBadge'
$QuickSetSetMenuNameSuffix = 'QuickSet_Set'
$QuickSetRefreshButtonNameSuffix = 'QuickSet_Refresh'
$QuickSetSaveButtonNameSuffix = 'QuickSet_Save'
$QuickSetRenameButtonNameSuffix = 'QuickSet_Rename'
$QuickSetSaveAsButtonNameSuffix = 'QuickSet_SaveAs'
$QuickSetClearButtonNameSuffix = 'QuickSet_Clear'
$QuickSetCloseButtonNameSuffix = 'QuickSet_Close'
$QuickSetDeleteButtonNameSuffix = 'QuickSet_Delete'

$CopyButtonNameSuffix = 'CopyButton'
$CopyAsMenuNameSuffix = 'CopyAsMenu'
$CopyAsJsonButtonNameSuffix = 'CopyAs_Json'
$CopyAsXmlButtonNameSuffix = 'CopyAs_Xml'
$CopyAsCsvButtonNameSuffix = 'CopyAs_Csv'
$PasteButtonNameSuffix = 'PasteButton'

# UI Element Headers, Icons, & ToolTips
$MinMaxButtonMaxedIcon = '🔽'
$MinMaxButtonMaxedToolTip = "Minimize`nSHIFT: Alternate Behavior"
$MinMaxButtonMinedIcon = '🔼'
$MinMaxButtonMinedToolTip = "Maximize`nSHIFT: Alternate Behavior"

$AddArrayItemButtonIcon = '➕'
$AddArrayItemButtonToolTip = "Add a new item to this array"
$ClearButtonHeader = 'Clear Value'
$ClearButtonIcon = '🧹'
$ClearButtonToolTip = "Clear this value"
$ClearButtonAllToolTip = "Clear the value of every item in this array"
$RandomValuesButtonHeader = 'Random Value'
$RandomValuesButtonIcon = '🎲'
$RandomValuesButtonToolTip = "Fill this value with a random value"
$RandomValuesButtonAllToolTip = "Fill every item in this array with random values"
$RandomValuesSettingsButtonIcon = '⚙'
$RandomValuesSettingsButtonToolTip = "Customize random value generation"
$SortMenuHeader = 'Sort'
$SortMenuIcon = '⇅'
$SortMenuToolTip = "Sort the items in this array"
$SortAscendingHeader = 'Ascending'
$SortAscendingIcon = '🔼'
$SortAscendingToolTip = "Sort items in ascending order (A to Z, lowest to highest)"
$SortDescendingHeader = 'Descending'
$SortDescendingIcon = '🔽'
$SortDescendingToolTip = "Sort items in descending order (Z to A, highest to lowest)"
$SortByTitleHeader = 'Title'
$SortByTitleIcon = '🏷️'
$SortByTitleToolTip = "Sort by item title (display name)"
$SortArrayValuesHeader = 'Values'
$SortArrayValuesIcon = '🔤'
$SortArrayValuesToolTip = "Sort by the combined values in this array"
$SortArrayCountHeader = 'Count'
$SortArrayCountIcon = '#️⃣'
$SortArrayCountToolTip = "Sort by the number of items in this array"
$SortMinItemsButtonToolTip = "Requires at least 2 items to sort"
$DisableEnableButtonHeaderDisabled = '❌'
$DisableEnableButtonIconDisabled = $null
$DisableEnableButtonHeaderEnabled = 'Disable'
$DisableEnableButtonIconEnabled = '❌'
$DisableEnableButtonToolTipEnabled = "Disable this item so it is not used when constructing the object"
$DisableEnableButtonToolTipDisabled = "Enable this item so it is used when constructing the object"
$DisableEnableButtonAllToolTipEnabled = "Disable every item in this array so they are not used when constructing the object"
$DisableEnableButtonAllToolTipDisabled = "Enable every item in this array so they are used when constructing the object"
$DeleteButtonHeader = 'Delete'
$DeleteButtonIcon = '🗑'
$DeleteButtonToolTip = "Remove this item from the array"
$DeleteButtonAllToolTip = "Remove every item from this array"
$LockUnlockButtonHeaderLocked = '🔒'
$LockUnlockButtonIconLocked = $null
$LockUnlockButtonHeaderUnlocked = 'Lock'
$LockUnlockButtonIconUnlocked = '🔓'
$LockUnlockButtonToolTipUnlocked = "Lock to protect from Paste, Random Value, and Clear"
$LockUnlockButtonToolTipLocked = "Unlock to allow Paste, Random Value, and Clear"
$LockUnlockButtonItemToolTipUnlocked = "Lock to protect from Paste, Random Value, Clear, Disable, and Delete"
$LockUnlockButtonItemToolTipLocked = "Unlock to allow Paste, Random Value, Clear, Disable, and Delete"
$LockUnlockButtonAllToolTipUnlocked = "Lock to protect from Add, Sort, Paste, Random Values, Clear, Disable, and Delete"
$LockUnlockButtonAllToolTipLocked = "Unlock to allow Add, Sort, Paste, Random Values, Clear, Disable, and Delete"
$LockedButtonToolTip = "Unlock to use"
$EmptyArrayButtonToolTip = "Add an item to this array first"
$EmptyClipboardButtonToolTip = "Copy an item of this type first"

$CopyButtonHeader = 'Copy'
$CopyButtonIcon = '📋'
$CopyButtonToolTip = "Copy this item to its type clipboard"
$CopyFullItemHeader = 'Full Item'
$CopyFullItemIcon = '📦'
$CopyFullItemToolTip = "Copy values, title, and UI states (minimized, locked, disabled)"
$CopyValuesOnlyHeader = 'Values Only'
$CopyValuesOnlyIcon = '🔤'
$CopyValuesOnlyToolTip = "Copy only the field values without UI states"
$CopyAsMenuHeader = 'Copy As'
$CopyAsMenuIcon = '📄'
$CopyAsMenuToolTip = "Copy this item to its type clipboard and as formatted text to the Windows Clipboard"
$CopyAsJsonHeader = 'JSON'
$CopyAsJsonIcon = '🧾'
$CopyAsJsonToolTip = "Copy as JSON to the Windows Clipboard and type clipboard"
$CopyAsXmlHeader = 'XML'
$CopyAsXmlIcon = '🏷️'
$CopyAsXmlToolTip = "Copy as XML to the Windows Clipboard and type clipboard"
$CopyAsCsvHeader = 'CSV'
$CopyAsCsvIcon = '📊'
$CopyAsCsvToolTip = "Copy as CSV to the Windows Clipboard and type clipboard"
$PasteButtonHeader = 'Paste'
$PasteButtonIcon = '📥'
$PasteButtonToolTip = "Paste the copied value for this type"
$PasteFullItemToolTip = "Paste values, title, and UI states (minimized, locked, disabled)"
$PasteValuesOnlyToolTip = "Paste only the field values and preserve existing UI states"

$ButtonMenuHeader = '⋮'
$ButtonMenuToolTip = "More actions"

$ConstructButtonHeader = 'Construct'
$ConstructButtonIcon = '🔨'
$ConstructButtonToolTip = "Construct Object"
$ConstructButtonAllToolTip = "Construct every object in this array"

$DragHandleIcon = '☰'
$DragHandleToolTip = "Drag to reorder`nSHIFT: Swap positions"

$SearchButtonHeader = 'Search'
$SearchButtonIcon = '🔍'
$SearchButtonToolTip = "Search (Ctrl+F)"
$SearchButtonToolTipActive = "Close Search (Ctrl+F)"
$SearchBarIcon = '🔍 '
$SearchCloseButtonHeader = '✖'
$SearchCloseButtonToolTip = "Close Search (Esc)"
$SearchNextButtonHeader = '▼'
$SearchNextButtonToolTip = "Next match (Enter)"
$SearchPrevButtonHeader = '▲'
$SearchPrevButtonToolTip = "Previous match (Shift+Enter)"
$SearchRegexButtonHeader = '.*'
$SearchRegexButtonToolTipEnabled = "Regex Mode: ON (Alt+R to toggle)"
$SearchRegexButtonToolTipDisabled = "Regex Mode: OFF (Literal String - Alt+R to toggle)"
$SearchActionsButtonHeader = '⚡ Actions ▾'
$SearchActionsButtonToolTip = "Actions on Matches"
$SearchActionShowMatchesHeader = '👁️  Show Matches'
$SearchActionShowMatchesToolTip = "Show matching items"
$SearchActionHideMatchesHeader = '🙈  Hide Matches'
$SearchActionHideMatchesToolTip = "Hide matching items"
$SearchActionShowAllHeader = '🔄  Show All'
$SearchActionShowAllToolTip = "Restore all items"
$SearchActionSortAscendingHeader = '🔼  Sort Matches Ascending'
$SearchActionSortAscendingToolTip = "Sort matching array items in ascending order"
$SearchActionSortDescendingHeader = '🔽  Sort Matches Descending'
$SearchActionSortDescendingToolTip = "Sort matching array items in descending order"
$SearchActionLockMatchesHeader = '🔒  Lock Matches'
$SearchActionLockMatchesToolTip = "Lock matching items"
$SearchActionUnlockMatchesHeader = '🔓  Unlock Matches'
$SearchActionUnlockMatchesToolTip = "Unlock matching items"
$SearchActionRandomizeMatchesHeader = '🎲  Randomize Matches'
$SearchActionRandomizeMatchesToolTip = "Randomize matching items"
$SearchActionClearMatchesHeader = '🧹  Clear Matches'
$SearchActionClearMatchesToolTip = "Clear matching items"
$SearchActionDisableMatchesHeader = '❌  Disable Matches'
$SearchActionDisableMatchesToolTip = "Disable matching items"
$SearchActionEnableMatchesHeader = '✔️  Enable Matches'
$SearchActionEnableMatchesToolTip = "Enable matching items"
$SearchActionDeleteMatchesHeader = '🗑️  Delete Matches'
$SearchActionDeleteMatchesToolTip = "Delete matching items"

$QuickSetHeader = 'QuickSet'
$QuickSetIcon = '⚡'
$QuickSetToolTip = "Save and load named sets of values for this item"
$QuickSetSetMenuHeader = 'Set'
$QuickSetSetMenuIcon = '📁'
$QuickSetSetMenuToolTip = "Load a saved QuickSet"
$QuickSetRefreshButtonHeader = 'Refresh'
$QuickSetRefreshButtonIcon = '🔄'
$QuickSetRefreshButtonToolTip = "Reload the list of saved QuickSets from disk"
$QuickSetSaveButtonHeader = 'Save'
$QuickSetSaveButtonIcon = '💾'
$QuickSetSaveButtonToolTip = "Save changes to the active QuickSet`nLoad a QuickSet first"
$QuickSetRenameButtonHeader = 'Rename'
$QuickSetRenameButtonIcon = '✏️'
$QuickSetRenameButtonToolTip = "Rename the active QuickSet`nLoad a QuickSet first"
$QuickSetSaveAsButtonHeader = 'Save As'
$QuickSetSaveAsButtonIcon = '📑'
$QuickSetSaveAsButtonToolTip = "Save the current values as a new QuickSet"
$QuickSetClearButtonHeader = 'Clear'
$QuickSetClearButtonIcon = '🧹'
$QuickSetClearButtonToolTip = "Save the current values to the active QuickSet, then clear the values`nLoad a QuickSet first"
$QuickSetCloseButtonHeader = 'Close'
$QuickSetCloseButtonIcon = '❌'
$QuickSetCloseButtonToolTip = "Close the active QuickSet and clear the values without saving`nLoad a QuickSet first"
$QuickSetDeleteButtonHeader = 'Delete'
$QuickSetDeleteButtonIcon = '🗑'
$QuickSetDeleteButtonToolTip = "Permanently delete the active QuickSet file`nLoad a QuickSet first"

$SearchOriginalStyles = @{}
$TypeClipboard = @{}
$script:TypeConstructorsCache = @{}
[bool]$script:EnableFunctionProfiling = $true
[double]$script:FunctionMeasurementConsoleMinimumMilliseconds = 10.0
$script:FunctionMeasurements = @{}

$script:FunctionMeasurementHistory = @{}
$script:FunctionMeasurementDurations = @{}
[int]$script:FunctionExecutionSequence = 0

#endregion #0 Variables


#region #0 Add Types

Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

#endregion #0 Add Types


#region #0 PowerShell Helper Functions

function Start-FunctionMeasurement {
    param([Parameter(Mandatory = $true)][string]$FunctionName)
    if (-not $script:EnableFunctionProfiling) { return }
    if (-not $script:FunctionMeasurements.ContainsKey($FunctionName)) {
        $script:FunctionMeasurements[$FunctionName] = [System.Collections.ArrayList]@()
    }
    [void]$script:FunctionMeasurements[$FunctionName].Add([System.Diagnostics.Stopwatch]::GetTimestamp())

} # function Start-FunctionMeasurement

function Stop-FunctionMeasurement {
    param([Parameter(Mandatory = $true)][string]$FunctionName)
    if (-not $script:EnableFunctionProfiling) { return }

    if (-not $script:FunctionMeasurements.ContainsKey($FunctionName)) { return }
    $Times = $script:FunctionMeasurements[$FunctionName]
    if ($null -eq $Times -or $Times.Count -eq 0) { return }

    $StartTime = $Times[-1]
    $Times.RemoveAt($Times.Count - 1)

    $ElapsedMilliseconds = (([System.Diagnostics.Stopwatch]::GetTimestamp() - $StartTime) / [System.Diagnostics.Stopwatch]::Frequency) * 1000

    # Aggregate measurement history for summary reporting
    if (-not $script:FunctionMeasurementDurations.ContainsKey($FunctionName)) {
        $script:FunctionMeasurementDurations[$FunctionName] = [System.Collections.Generic.List[double]]::new()
    }
    $script:FunctionMeasurementDurations[$FunctionName].Add($ElapsedMilliseconds)

    if (-not $script:FunctionMeasurementHistory.ContainsKey($FunctionName)) {
        $script:FunctionExecutionSequence++
        $script:FunctionMeasurementHistory[$FunctionName] = [PSCustomObject]@{
            Sequence            = [int]$script:FunctionExecutionSequence
            Function            = $FunctionName
            Calls               = [int]0
            TotalMilliseconds   = [double]0
            AverageMilliseconds = [double]0
            MedianMilliseconds  = [double][Math]::Round($ElapsedMilliseconds, 3)
            MinMilliseconds     = [double][Math]::Round($ElapsedMilliseconds, 3)
            MaxMilliseconds     = [double][Math]::Round($ElapsedMilliseconds, 3)
        }
    }
    $History = $script:FunctionMeasurementHistory[$FunctionName]
    $History.Calls++
    $History.TotalMilliseconds = [Math]::Round(($History.TotalMilliseconds + $ElapsedMilliseconds), 3)
    $History.AverageMilliseconds = [Math]::Round(($History.TotalMilliseconds / $History.Calls), 3)
    if ($History.Calls -eq 1) { $History.MedianMilliseconds = [Math]::Round($ElapsedMilliseconds, 3) }
    if ($ElapsedMilliseconds -lt $History.MinMilliseconds) { $History.MinMilliseconds = [Math]::Round($ElapsedMilliseconds, 3) }
    if ($ElapsedMilliseconds -gt $History.MaxMilliseconds) { $History.MaxMilliseconds = [Math]::Round($ElapsedMilliseconds, 3) }

    $TierColor = if ($ElapsedMilliseconds -gt 100) { 'Red' } elseif ($ElapsedMilliseconds -ge 15) { 'Yellow' } else { 'DarkGreen' }
    if ($ElapsedMilliseconds -ge $script:FunctionMeasurementConsoleMinimumMilliseconds) {
        Write-Host ("[{0,4}] [{1,-35}] Duration: {2,9:N3} milliseconds" -f $History.Sequence, $FunctionName, $ElapsedMilliseconds) -ForegroundColor $TierColor
    }
} # function Stop-FunctionMeasurement

function Get-FunctionMeasurementSummary {
    [CmdletBinding()]
    param(
        [string]$SortBy = 'TotalMilliseconds',
        [switch]$Descending = $true,
        [switch]$Clear
    )
    if ($Clear) {
        $script:FunctionMeasurementHistory.Clear()
        if ($script:FunctionMeasurementDurations) { $script:FunctionMeasurementDurations.Clear() }
        $script:FunctionExecutionSequence = 0
        Write-Host "Function measurement history cleared." -ForegroundColor Cyan
        return
    }
    if ($script:FunctionMeasurementHistory.Count -eq 0) {
        Write-Host "No function measurements recorded." -ForegroundColor Gray
        return
    }
    foreach ($Item in $script:FunctionMeasurementHistory.Values) {
        $FnName = $Item.Function
        if ($script:FunctionMeasurementDurations.ContainsKey($FnName)) {
            $Durations = $script:FunctionMeasurementDurations[$FnName]
            $Count = $Durations.Count
            if ($Count -gt 0) {
                $Sorted = [double[]]$Durations.ToArray()
                [System.Array]::Sort($Sorted)
                if ($Count % 2 -eq 1) {
                    $Mid = [int][Math]::Floor($Count / 2)
                    $Item.MedianMilliseconds = [Math]::Round($Sorted[$Mid], 3)
                }
                else {
                    $Mid = [int]($Count / 2)
                    $Item.MedianMilliseconds = [Math]::Round((($Sorted[$Mid - 1] + $Sorted[$Mid]) / 2.0), 3)
                }
            }
        }
    }
    $Results = @($script:FunctionMeasurementHistory.Values) | Sort-Object -Property $SortBy -Descending:$Descending
    return $Results
} # function Get-FunctionMeasurementSummary

function ViewUI {
    param(
        [Parameter(ValueFromPipeline = $true)][array]$UIElement,
        [string[]]$PropertiesToLookAt = @('Name', 'Tag', 'DataContext', 'Header', 'Child', 'Content', 'Children', 'Items', 'ToolBars', 'Text', 'SelectedItem', 'Password')
    )
    begin {
        $r = @()
    }
    process {
        Foreach ($Element in $UIElement) {
            $Hash = [Ordered]@{}
            $Hash.Parent = $Element.Parent.GetType().Name
            $Hash.Type = $Element.GetType().Name
            Foreach ($Property in $PropertiesToLookAt) {
                if ($null -ne $Element.$Property) {
                    $Hash.$Property = $Element.$Property
                }
            }
            $r += [PSCustomObject]$Hash
            Remove-Variable Hash -ErrorAction SilentlyContinue
        }
    }
    end {
        if ($r.count -gt 1) { $r | Format-Table -AutoSize }
        else { $r }
    }
} # function ViewUI

function Get-UniqueByProperty {
    param(
        $Property,
        [Parameter(ValueFromPipeline)]$HashArr
    )
    begin {
        Start-FunctionMeasurement -FunctionName "Get-UniqueByProperty"
        $PropertyArr = [System.Collections.ArrayList]@()
        $Return = @{
            List    = [System.Collections.ArrayList]@()
            Removed = [System.Collections.ArrayList]@()
        }
    }
    process {
        $Obj = $_

        if (!$PropertyArr.Contains($Obj.$Property)) {
            [Void]$PropertyArr.Add($Obj.$Property)
            [Void]$Return.List.Add($_)
        }
        else {
            [Void]$Return.Removed.Add($_)
        }
    }
    end {
        if ($Return.List.count -eq 0) { $Return.list.Clear() }
        if ($Return.Removed.count -eq 0) { $Return.Removed.clear() }
        Stop-FunctionMeasurement -FunctionName "Get-UniqueByProperty"
        return $Return
    }
} # function Get-UniqueByProperty

function Resolve-TargetElement {
    param($Element)
    Start-FunctionMeasurement -FunctionName "Resolve-TargetElement"
    $Target = if ($Element -is [System.Management.Automation.PSReference]) { $Element.Value } else { $Element }
    if ($Target -is [array]) { $Target = $Target[0] }
    Stop-FunctionMeasurement -FunctionName "Resolve-TargetElement"
    return $Target
} # function Resolve-TargetElement

function Get-ObjectPropertyEntryCaseInsensitive {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )
    Start-FunctionMeasurement -FunctionName "Get-ObjectPropertyEntryCaseInsensitive"
    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($Key in $InputObject.Keys) {
            if ($Key.ToString() -ieq $PropertyName) {
                return @{ Exists = $true; Value = $InputObject[$Key]; Name = $Key.ToString() }
            }
        }
        return $null
    }

    if ($InputObject -is [System.Management.Automation.PSObject] -or $InputObject -is [System.Management.Automation.PSCustomObject]) {
        foreach ($Property in $InputObject.PSObject.Properties) {
            if ($Property.Name -ieq $PropertyName) {
                return @{ Exists = $true; Value = $Property.Value; Name = $Property.Name }
            }
        }
    }

    Stop-FunctionMeasurement -FunctionName "Get-ObjectPropertyEntryCaseInsensitive"
    return $null
} # function Get-ObjectPropertyEntryCaseInsensitive

function Test-ObjectPropertyCaseInsensitive {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )
    Start-FunctionMeasurement -FunctionName "Test-ObjectPropertyCaseInsensitive"
    Stop-FunctionMeasurement -FunctionName "Test-ObjectPropertyCaseInsensitive"
    return ($null -ne (Get-ObjectPropertyEntryCaseInsensitive -InputObject $InputObject -PropertyName $PropertyName))
} # function Test-ObjectPropertyCaseInsensitive

function Get-ObjectPropertyCaseInsensitive {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )
    Start-FunctionMeasurement -FunctionName "Get-ObjectPropertyCaseInsensitive"
    $Entry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $InputObject -PropertyName $PropertyName
    if ($null -ne $Entry) { return $Entry.Value }
    Stop-FunctionMeasurement -FunctionName "Get-ObjectPropertyCaseInsensitive"
    return $null
} # function Get-ObjectPropertyCaseInsensitive

function Test-IsQuickSetWrapper {
    param($Element)
    Start-FunctionMeasurement -FunctionName "Test-IsQuickSetWrapper"
    # A wrapper is any element whose Tag was stamped with 'IsArray' by New-TypeContent
    Stop-FunctionMeasurement -FunctionName "Test-IsQuickSetWrapper"
    return ($null -ne $Element -and $Element.Tag -is [hashtable] -and $Element.Tag.ContainsKey('IsArray'))
} # function Test-IsQuickSetWrapper

function Resolve-QuickSetWrapper {
    param($Element)
    Start-FunctionMeasurement -FunctionName "Resolve-QuickSetWrapper"
    $Target = Resolve-TargetElement $Element
    if (-not $Target) { return $null }

    # 1. The element is the wrapper itself
    if (Test-IsQuickSetWrapper $Target) { return $Target }

    # 2. The element is inside a wrapper: walk up to the nearest one
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { Test-IsQuickSetWrapper $_ } -DigProperties 'Parent' -FindMax 1
    if ($Found) { return (Resolve-TargetElement $Found) }

    # 3. The element is above a wrapper: search down for the first one
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { Test-IsQuickSetWrapper $_ } -FindMax 1
    if ($Found) { return (Resolve-TargetElement $Found) }

    # 4. Nothing stamped was found; fall back to the element given
    Stop-FunctionMeasurement -FunctionName "Resolve-QuickSetWrapper"
    return $Target
} # function Resolve-QuickSetWrapper

#endregion #0 PowerShell Helper Functions


#region #0 UI Controls

#region #1 UI Helper Functions

function Find-ObjectWhere {
    param(
        [parameter(ValueFromPipeline, Mandatory)]
        [ref]$Object,
        [parameter(Mandatory)]
        [scriptblock]$FindWhere,
        [string[]]$DigProperties = @('Children', 'Content', 'Child', 'ToolBars', 'Items'),
        [int]$DepthMax = -1,
        [scriptblock]$DepthWhere,
        [int]$Depth = 0,
        [int]$FindMax = -1,
        [int]$AlreadyFound = 0
    )
    Start-FunctionMeasurement -FunctionName "Find-ObjectWhere: $FindWhere"
    $Found = @()
    $RecurseCount = 0
    :DigProperties foreach ($DigProperty in $DigProperties) {
        [array]$ObjectChildren = $Object.Value.$DigProperty
        if ($ObjectChildren.Count -eq 0) { continue DigProperties }

        :ObjectChildren foreach ($ObjectChild in $ObjectChildren) {
            $_ = $ObjectChild

            if ($FindWhere.Invoke()) {
                $Found += $ObjectChild
                $AlreadyFound ++
            }

            if ($FindMax -ne -1) {
                if ($AlreadyFound -ge $FindMax) { return $Found }
            }

            $ShouldRecurse = $true
            $NextDepth = $Depth
            if ($DepthMax -ne -1) {
                if ($null -eq $DepthWhere -or $DepthWhere.Invoke()) {
                    $NextDepth = $Depth + 1
                }
                if ($NextDepth -gt $DepthMax) {
                    $ShouldRecurse = $false
                }
            }

            if ($ShouldRecurse) {
                $ObjectGrandChild = Find-ObjectWhere -Object ([ref]$ObjectChild) `
                    -FindWhere $FindWhere -FindMax $FindMax -AlreadyFound $AlreadyFound `
                    -DigProperties $DigProperties -DepthWhere $DepthWhere -DepthMax $DepthMax -Depth $NextDepth
                $RecurseCount ++

                if ([bool]$ObjectGrandChild) {
                    $Found += $ObjectGrandChild
                    $AlreadyFound += $ObjectGrandChild.count
                }
            }
        } # ObjectChildren
    } # DigProperties
    if ($Found.count -gt 0) {
        Stop-FunctionMeasurement -FunctionName "Find-ObjectWhere: $FindWhere"
        return $Found
    }
    Stop-FunctionMeasurement -FunctionName "Find-ObjectWhere: $FindWhere"
} # function Find-ObjectWhere

function Find-Title {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        $Object
    )
    process {
        Start-FunctionMeasurement -FunctionName "Find-Title"
        if ($Object.Name -eq $ContentHeaderBorderName) { $ContentHeaderBorder = $Object }
        else {
            $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$Object) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
        }
        $ContentHeaderTitleBorderDock = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
        $ContentHeaderTitleValue = Find-ObjectWhere -Object ([ref]$ContentHeaderTitleBorderDock) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName } -FindMax 1
        $ContentHeaderDescriptionValue = Find-ObjectWhere -Object ([ref]$ContentHeaderTitleBorderDock) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName } -FindMax 1
        $TitleResult = "$($ContentHeaderTitleValue.Text) - $($ContentHeaderDescriptionValue.Text)"
        Stop-FunctionMeasurement -FunctionName "Find-Title"
        $TitleResult
    }
} # function Find-Title

function Get-ContentWrapperFromButton {
    param(
        [Parameter(Mandatory)]$Button,
        [Parameter(Mandatory)][string]$Suffix
    )
    Start-FunctionMeasurement -FunctionName "Get-ContentWrapperFromButton"
    $TargetButton = Resolve-TargetElement $Button
    if (-not $TargetButton) { return $null }
    if ($script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable] -and $script:UniversalSharedMenu.Tag.ContainsKey('ActiveWrapper') -and $script:UniversalSharedMenu.Tag.ActiveWrapper) {
        $IsSharedMenuButton = $false
        $CheckElement = $TargetButton
        while ($CheckElement) {
            if ($CheckElement -eq $script:UniversalSharedMenu) {
                $IsSharedMenuButton = $true
                break
            }
            $CheckElement = $CheckElement.Parent
        }
        if ($IsSharedMenuButton) {
            Stop-FunctionMeasurement -FunctionName "Get-ContentWrapperFromButton"
            return $script:UniversalSharedMenu.Tag.ActiveWrapper
        }
    }
    if (-not $TargetButton.Name) { return $null }
    $ExpectedWrapperName = $TargetButton.Name.Replace("_$Suffix", '')
    $ContentWrapper = Find-ObjectWhere -Object ([ref]$TargetButton) -FindWhere { $_.Name -eq $ExpectedWrapperName } -DigProperties 'Parent' -FindMax 1
    Stop-FunctionMeasurement -FunctionName "Get-ContentWrapperFromButton"
    return (Resolve-TargetElement $ContentWrapper)
} # function Get-ContentWrapperFromButton

function Get-ParentWrapperBorder {
    param(
        [Parameter(Mandatory)]$Element,
        [switch]$HeaderOnly
    )
    Start-FunctionMeasurement -FunctionName "Get-ParentWrapperBorder"
    $Target = Resolve-TargetElement $Element
    if (-not $Target) { return $null }
    $TargetNames = if ($HeaderOnly) { @($ContentHeaderBorderName) } else { @($ContentHeaderBorderName, $ContentBorderName) }

    $Current = $Target.Parent
    while ($null -ne $Current) {
        if ($TargetNames -contains $Current.Name) {
            Stop-FunctionMeasurement -FunctionName "Get-ParentWrapperBorder"
            return (Resolve-TargetElement $Current)
        }
        $Current = $Current.Parent
    }

    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $TargetNames -contains $_.Name } -DigProperties 'Parent' -FindMax 1
    Stop-FunctionMeasurement -FunctionName "Get-ParentWrapperBorder"
    return (Resolve-TargetElement $Found)
} # function Get-ParentWrapperBorder

function Get-WrapperMenu {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperMenu"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }
    if ($Target.Name -eq $MenuName) { return $Target }
    if ($Target.Name -eq $ButtonMenuName) { return $Target.Parent }
    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('Menu') -and $Target.Tag.Menu) {
        return (Resolve-TargetElement $Target.Tag.Menu)
    }
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $MenuName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
    $ResolvedMenu = Resolve-TargetElement $Found
    if ($ResolvedMenu -and ($Target.Tag -is [hashtable])) {
        $Target.Tag.Menu = $ResolvedMenu
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperMenu"
    return $ResolvedMenu
} # function Get-WrapperMenu

function Get-WrapperContentSlot {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperContentSlot"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }
    if ($Target.Name -eq $ContentSlotElementName) { return $Target }
    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('ContentSlot') -and $Target.Tag.ContentSlot) {
        return (Resolve-TargetElement $Target.Tag.ContentSlot)
    }
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
    $ResolvedSlot = Resolve-TargetElement $Found
    if ($ResolvedSlot -and ($Target.Tag -is [hashtable])) {
        $Target.Tag.ContentSlot = $ResolvedSlot
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperContentSlot"
    return $ResolvedSlot
} # function Get-WrapperContentSlot

function Get-WrapperLockIndicatorButton {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperLockIndicatorButton"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }
    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('LockIndicatorButton')) {
        Stop-FunctionMeasurement -FunctionName "Get-WrapperLockIndicatorButton"
        return $Target.Tag.LockIndicatorButton
    }
    $Button = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$UniversalMenuLockIndicatorButtonName*" } -DepthMax 2 -FindMax 1
    $ResolvedButton = Resolve-TargetElement $Button
    if ($Target.Tag -is [hashtable]) {
        $Target.Tag.LockIndicatorButton = $ResolvedButton
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperLockIndicatorButton"
    return $ResolvedButton
} # function Get-WrapperLockIndicatorButton

function Get-WrapperDisableIndicatorButton {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperDisableIndicatorButton"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }
    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('DisableIndicatorButton')) {
        Stop-FunctionMeasurement -FunctionName "Get-WrapperDisableIndicatorButton"
        return $Target.Tag.DisableIndicatorButton
    }
    $Button = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$UniversalMenuDisableIndicatorButtonName*" } -DepthMax 2 -FindMax 1
    $ResolvedButton = Resolve-TargetElement $Button
    if ($Target.Tag -is [hashtable]) {
        $Target.Tag.DisableIndicatorButton = $ResolvedButton
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperDisableIndicatorButton"
    return $ResolvedButton
} # function Get-WrapperDisableIndicatorButton

function Set-WrapperLockVisualState {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [Parameter(Mandatory)][bool]$IsLocked
    )
    Start-FunctionMeasurement -FunctionName 'Set-WrapperLockVisualState'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    $Dock = if ($Target.Name -eq $ContentHeaderBorderName) {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
    }
    else {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentBorderDockName } -FindMax 1
    }
    if (-not $Dock) { return }

    $ExistingButton = Get-WrapperLockIndicatorButton -Wrapper $Target
    if ($IsLocked) {
        if (-not $ExistingButton) {
            $Button = New-BaseButton @{
                Name                       = "$($Target.Name)_$UniversalMenuLockIndicatorButtonName"
                Content                    = '🔒'
                ToolTip                    = $LockUnlockButtonItemToolTipLocked
                Background                 = 'Transparent'
                BorderBrush                = 'Transparent'
                BorderThickness            = 0
                Cursor                     = 'Hand'
                VerticalAlignment          = 'Center'
                HorizontalAlignment        = 'Left'
                VerticalContentAlignment   = 'Center'
                HorizontalContentAlignment = 'Center'
                Width                      = 18
                Height                     = 18
                Padding                    = 0
                Margin                     = '2,0,2,0'
                FontSize                   = 11
                Foreground                 = 'Black'
                Focusable                  = $true
            }
            $Button.Add_Click({
                    param($s, $e)
                    $ParentTarget = Get-ParentWrapperBorder -Element $s
                    if ($ParentTarget) {
                        Set-TargetLockedState -Target $ParentTarget -IsLocked $false
                    }
                })

            # Lock is always placed on the far left (index 0)
            $Dock.Children.Insert(0, $Button)
            [System.Windows.Controls.DockPanel]::SetDock($Button, 'Left')
        }
    }
    else {
        if ($ExistingButton -and $ExistingButton.Parent) {
            $ExistingButton.Parent.Children.Remove($ExistingButton)
        }
    }
    Stop-FunctionMeasurement -FunctionName 'Set-WrapperLockVisualState'
} # function Set-WrapperLockVisualState

function Set-WrapperDisabledVisualState {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [Parameter(Mandatory)][bool]$IsDisabled
    )
    Start-FunctionMeasurement -FunctionName 'Set-WrapperDisabledVisualState'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    $Dock = if ($Target.Name -eq $ContentHeaderBorderName) {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
    }
    else {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentBorderDockName } -FindMax 1
    }
    if (-not $Dock) { return }

    $ExistingButton = Get-WrapperDisableIndicatorButton -Wrapper $Target
    if ($IsDisabled) {
        if (-not $ExistingButton) {
            $Button = New-BaseButton @{
                Name                       = "$($Target.Name)_$UniversalMenuDisableIndicatorButtonName"
                Content                    = '❌'
                ToolTip                    = $DisableEnableButtonToolTipDisabled
                Background                 = 'Transparent'
                BorderBrush                = 'Transparent'
                BorderThickness            = 0
                Cursor                     = 'Hand'
                VerticalAlignment          = 'Center'
                HorizontalAlignment        = 'Left'
                VerticalContentAlignment   = 'Center'
                HorizontalContentAlignment = 'Center'
                Width                      = 18
                Height                     = 18
                Padding                    = 0
                Margin                     = '2,0,2,0'
                FontSize                   = 11
                Foreground                 = 'Black'
                Focusable                  = $true
            }
            $Button.Add_Click({
                    param($s, $e)
                    $ParentTarget = Get-ParentWrapperBorder -Element $s
                    if ($ParentTarget) {
                        if (Get-IsLocked $ParentTarget) { return }
                        Set-TargetDisabledState -Target $ParentTarget -IsDisabled $false
                    }
                })

            # If Lock indicator exists, place Disable after it; otherwise at index 0
            $ExistingLock = Get-WrapperLockIndicatorButton -Wrapper $Target
            $InsertIndex = if ($ExistingLock -and $ExistingLock.Parent -eq $Dock) {
                $Dock.Children.IndexOf($ExistingLock) + 1
            }
            else {
                0
            }
            if ($InsertIndex -ge $Dock.Children.Count) {
                [void]$Dock.Children.Add($Button)
            }
            else {
                $Dock.Children.Insert($InsertIndex, $Button)
            }
            [System.Windows.Controls.DockPanel]::SetDock($Button, 'Left')
        }
    }
    else {
        if ($ExistingButton -and $ExistingButton.Parent) {
            $ExistingButton.Parent.Children.Remove($ExistingButton)
        }
    }
    Stop-FunctionMeasurement -FunctionName 'Set-WrapperDisabledVisualState'
} # function Set-WrapperDisabledVisualState

function Set-RichTextBoxText {
    param(
        [Parameter(Mandatory)]$RichTextBox,
        [string]$Text = $null
    )
    Start-FunctionMeasurement -FunctionName 'Set-RichTextBoxText'
    $Paragraph = New-Object System.Windows.Documents.Paragraph
    $Paragraph.Margin = '0'
    if (-not [string]::IsNullOrEmpty($Text)) {
        $Paragraph.Inlines.Add($Text) | Out-Null
    }
    $RichTextBox.Document.Blocks.Clear()
    $RichTextBox.Document.Blocks.Add($Paragraph)

    Stop-FunctionMeasurement -FunctionName 'Set-RichTextBoxText'
} # function Set-RichTextBoxText

function Get-CustomDateTimePickers {
    param(
        [Parameter(Mandatory)]$Wrapper
    )
    Start-FunctionMeasurement -FunctionName "Get-CustomDateTimePickers"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return @() }
    $Pickers = [System.Collections.ArrayList]@()
    if ($Target.Name -eq $CustomDateTimePickerName) {
        [void]$Pickers.Add($Target)
    }
    $ChildPickers = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName }
    if ($ChildPickers) {
        foreach ($Picker in @($ChildPickers)) {
            [void]$Pickers.Add($Picker)
        }
    }
    Stop-FunctionMeasurement -FunctionName "Get-CustomDateTimePickers"
    return @($Pickers)
} # function Get-CustomDateTimePickers

#endregion #1 UI Helper Functions

#region #1 Base UI Controls

#region #2 Base UI Control Actions

function Add-BaseStackPanelChild {
    param( [ref]$StackPanel, [ref]$Child )
    Start-FunctionMeasurement -FunctionName "Add-BaseStackPanelChild"
    try {
        $StackPanel.Value.AddChild($Child.Value)
    }
    catch {
        Write-Host "{Add-BaseStackPanelChild} $_" -ForegroundColor Red
    }
    Stop-FunctionMeasurement -FunctionName "Add-BaseStackPanelChild"
} # function Add-BaseStackPanelChild

function Add-BaseDockPanelChild {
    param( [ref]$DockPanel, [ref]$Child, [System.Windows.Controls.Dock]$DockTo )
    Start-FunctionMeasurement -FunctionName "Add-BaseDockPanelChild"
    try {
        $DockPanel.Value.AddChild($Child.Value)
        if ($DockTo) { [System.Windows.Controls.DockPanel]::SetDock($Child.Value, $DockTo) }
    }
    catch {
        Write-Host "{Add-BaseDockPanelChild} $_" -ForegroundColor Red
    }
    Stop-FunctionMeasurement -FunctionName "Add-BaseDockPanelChild"
} # function Add-BaseDockPanelChild

function Add-BaseMenuChild {
    param( [ref]$Menu, [ref]$Child, [int]$Index = 0 )
    Start-FunctionMeasurement -FunctionName "Add-BaseMenuChild"
    try {
        $Menu.Value.Items.Insert($Index, $Child.Value)
    }
    catch {
        Write-Host "{Add-BaseMenuChild} $_" -ForegroundColor Red
    }
    Stop-FunctionMeasurement -FunctionName "Add-BaseMenuChild"
} # function Add-BaseMenuChild

#endregion #2 Base UI Control Actions

#region #2 Base UI Control Elements

function New-BaseWindow {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseWindow'
    [System.Windows.Window]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseWindow'
} # function New-BaseWindow

function New-BaseBorder {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseBorder'
    [System.Windows.Controls.Border]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseBorder'
} # function New-BaseBorder

function New-BaseStackPanel {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseStackPanel'
    [System.Windows.Controls.StackPanel]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseStackPanel'
} # function New-BaseStackPanel

function New-BaseScrollViewer {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseScrollViewer'
    [System.Windows.Controls.ScrollViewer]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseScrollViewer'
} # function New-BaseScrollViewer

function New-BaseDockPanel {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseDockPanel'
    [System.Windows.Controls.DockPanel]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseDockPanel'
} # function New-BaseDockPanel

function New-BaseTextBox {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseTextBox'
    [System.Windows.Controls.TextBox]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseTextBox'
} # function New-BaseTextBox

function New-BaseTextBlock {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseTextBlock'
    try {
        [System.Windows.Controls.TextBlock]$Parameters
    }
    catch {
        Write-Host "{New-BaseTextBlock} $_" -ForegroundColor Red
    }

    Stop-FunctionMeasurement -FunctionName 'New-BaseTextBlock'
} # function New-BaseTextBlock

function New-BaseRichTextBox {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseRichTextBox'

    # 1. Intercept 'Text' so WPF doesn't break trying to convert it to blocks
    $InitialText = $null
    if ($Parameters.ContainsKey('Text')) {
        $InitialText = $Parameters['Text']
        $Parameters.Remove('Text')
    }

    # 2. Create the RichTextBox with the remaining parameters
    $RichTextBox = [System.Windows.Controls.RichTextBox]$Parameters

    # 3. Force it to behave like a single-line TextBox
    $RichTextBox.AcceptsReturn = $false
    $RichTextBox.AcceptsTab = $false
    $RichTextBox.VerticalScrollBarVisibility = 'Auto'
    $RichTextBox.HorizontalScrollBarVisibility = 'Disabled'
    $RichTextBox.MinWidth = 150

    # 4. Remove default RichTextBox padding and margins and insert initial text if any was provided
    $RichTextBox.Document.PagePadding = '0'
    Set-RichTextBoxText -RichTextBox $RichTextBox -Text $InitialText

    $ReturnValue = $RichTextBox
    Stop-FunctionMeasurement -FunctionName 'New-BaseRichTextBox'
    return $ReturnValue
} # function New-BaseRichTextBox

function New-BaseButton {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseButton'
    [System.Windows.Controls.Button]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseButton'
} # function New-BaseButton

function New-BaseCheckBox {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseCheckBox'
    $Parameters.FontFamily = $FontFamily
    $Parameters.Foreground = '#EDEAFA'
    $Parameters.Cursor = 'Hand'
    [System.Windows.Controls.CheckBox]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseCheckBox'
} # function New-BaseCheckBox

function New-BaseRadioButton {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseRadioButton'
    $Parameters.FontFamily = $FontFamily
    $Parameters.Foreground = '#EDEAFA'
    $Parameters.Cursor = 'Hand'
    [System.Windows.Controls.RadioButton]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseRadioButton'
} # function New-BaseRadioButton

function New-BaseSeparator {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseSeparator'
    [System.Windows.Controls.Separator]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseSeparator'
} # function New-BaseSeparator

function New-BaseComboBox {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseComboBox'
    [System.Windows.Controls.ComboBox]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseComboBox'
} # function New-BaseComboBox

function New-BaseMenu {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseMenu'
    [System.Windows.Controls.Menu]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BaseMenu'
} # function New-BaseMenu

function New-BaseMenuItem {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BaseMenuItem'
    $Parameters.FontFamily = $FontFamily
    $Parameters.Cursor = 'Hand'
    try {
        $MenuItem = [System.Windows.Controls.MenuItem]$Parameters
        $MenuItem.Add_SubmenuOpened({
                param($s, $e)
                if ($e.Source -ne $s) { return }
                $Popup = $s.Template.FindName('PART_Popup', $s)
                if ($Popup) {
                    $Popup.HorizontalOffset = $SubMenuOverlapOffset
                }
            })
        return $MenuItem
    }
    catch {
        Write-Host "{New-BaseMenuItem} $_" -ForegroundColor Red
    }

    Stop-FunctionMeasurement -FunctionName 'New-BaseMenuItem'
} # function New-BaseMenuItem

function New-BasePasswordBox {
    param( [hashtable]$Parameters = @{} )
    Start-FunctionMeasurement -FunctionName 'New-BasePasswordBox'
    [System.Windows.Controls.PasswordBox]$Parameters

    Stop-FunctionMeasurement -FunctionName 'New-BasePasswordBox'
} # function New-BasePasswordBox

#endregion #2 Base UI Control Elements

#endregion #1 Base UI Controls

#region #1 Content Controls

#region #2 Content Wrappers

#region #3 Content Wrapper Actions

function Reset-ArrayIndexes {
    param(
        [ref]$ItemInArray
    )
    Start-FunctionMeasurement -FunctionName "Reset-ArrayIndexes"
    $Array = $ItemInArray.Value
    if ($Array.Name -ne $ContentSlotElementName) {
        $Array = Find-ObjectWhere -Object $ItemInArray -FindWhere { $_.Name -eq $ContentSlotElementName } -DigProperties 'Parent' -FindMax 1
    }

    $IndexCounter = 1
    if ($Array -and $Array.Children.Count -gt 0) {
        foreach ($Child in @($Array.Children)) {
            if (-not ($Child.Tag -is [hashtable])) {
                $Child.Tag = @{}
            }
            $Box = if ($Child.Tag.ContainsKey('IndexBox') -and $Child.Tag.IndexBox) {
                $Child.Tag.IndexBox
            }
            else {
                $FoundBox = Find-ObjectWhere -Object ([ref]$Child) -FindWhere { $_.Name -like "*$IndexBoxNameSuffix" } -FindMax 1
                $Child.Tag.IndexBox = $FoundBox
                $FoundBox
            }
            if ($Box) {
                $Box.Text = "$IndexCounter"
                $IndexCounter++
            }
        }
    }
    Stop-FunctionMeasurement -FunctionName "Reset-ArrayIndexes"
} # function Reset-ArrayIndexes

function Build-Object {
    param(
        [ref]$Object,
        [Switch]$DoNotCreateIfNoParameters
    )
    Start-FunctionMeasurement -FunctionName "Build-Object"
    $ConstructTitle, $ConstructDescription = (Find-Title $Object.Value).Split('-').Trim()
    if ($ConstructDescription) {
        $ConstructDescription = [System.Text.RegularExpressions.Regex]::Replace($ConstructDescription, '\[.*?\]', '[]')
    }

    $ContentHeaderBorder = Find-ObjectWhere -Object $Object -FindWhere { $_.Name -eq $ContentHeaderBorderName }
    $Construct = Find-ObjectWhere -Object $ContentHeaderBorder -FindWhere { $_.Name -eq $ConstructName }

    #region Parameters

    $ParameterValues = [ordered]@{}
    [array]$ConstructRequiredParameters = Find-ObjectWhere -Object $Construct -FindWhere { $_.Name -eq $ConstructName }
    :ConstructRequiredParameters foreach ($ConstructParameter in $ConstructRequiredParameters) {
        $ParameterName, $ParameterType = (Find-Title $ConstructParameter).Split('-').Trim()
        $ParameterValue = Build-Object -Object ([ref]$ConstructParameter) -DoNotCreateIfNoParameters
        if ($null -ne $ParameterValue) {
            $ParameterValues[$ParameterName] = $ParameterValue
        }
    } # ConstructRequiredParameters

    [array]$OtherParameters = Find-ObjectWhere -Object $Construct -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 1 -DepthWhere { $_.Name -eq $ConstructName }
    :OtherParameters foreach ($Parameter in $OtherParameters) {
        $ParameterName, $ParameterType = (Find-Title $Parameter).Split('-').Trim()
        $CleanParameterType = if ($ParameterType) { [System.Text.RegularExpressions.Regex]::Replace($ParameterType, '\[.*?\]', '[]') } else { $ParameterType }
        $ParameterValue = Get-ContentValue -Object $Parameter
        if ($null -ne $ParameterValue) {
            if ($CleanParameterType -like '*`[]') {
                $ParameterValues[$ParameterName] += @($ParameterValue)
            }
            else {
                $ParameterValues[$ParameterName] = $ParameterValue
            }
        }
    } # OtherParameters

    if ($DoNotCreateIfNoParameters.IsPresent) {
        if ($ParameterValues.Keys.Count -eq 0) {
            return $null
        }
    }

    #endregion Parameters

    try {
        [array]$TypeConstructors = Get-TypeConstructors -Type $ConstructDescription
    }
    catch {
        Write-Host "[$(Get-Date)] {Build-Object} [$ConstructDescription] $ConstructTitle : Error getting type constructors" -Fore Red
    }

    if ($TypeConstructors.Constructor -notcontains 1) {
        if ($ParameterValues.Keys.count -eq 0) {
            Write-Host "[$(Get-Date)] {Build-Object} [$ConstructDescription] $ConstructTitle : No Parameters" -Fore Cyan
            return New-Object -TypeName $ConstructDescription
        }
    }

    [array]$TypeConstructorsGroups = $TypeConstructors | Group-Object Constructor | Where-Object {
        $_.Count -eq $ParameterValues.Count
    }

    :TypeConstructorsGroups foreach ($ConstructorGroup in $TypeConstructorsGroups) {
        # Compare what we have vs what constructors can use all provided parameters
        [array]$RequiredParameters = Compare-Object @($ConstructorGroup.Group.Name) @($ParameterValues.Keys) | Where-Object {
            $_.SideIndicator -ne '=='
        }

        if ($RequiredParameters.Count -eq 0) {
            Write-Host "[$(Get-Date)] {Build-Object} [$ConstructDescription] $ConstructTitle : $($ConstructorGroup.Group.Name)" -Fore Cyan
            return New-Object $ConstructDescription -ArgumentList @($ParameterValues.Values)
        }
    } # TypeConstructorsGroups

    Write-Host '[FIN] Build-Object'
    Stop-FunctionMeasurement -FunctionName "Build-Object"
} # function Build-Object

function Add-ContentToWrapper {
    param( [ref]$Wrapper, [ref]$Content )
    Start-FunctionMeasurement -FunctionName "Add-ContentToWrapper"

    $ContentSlot = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

    try {
        $ContentSlot.AddChild($Content.Value) | Out-Null
    }
    catch {
        Write-Host "[Add-ContentToWrapper] $($Wrapper.Name) $($Content.Value.Name) $($_)" -ForegroundColor Red
    }
    Stop-FunctionMeasurement -FunctionName "Add-ContentToWrapper"
} # function Add-ContentToWrapper

function Add-CustomMenuChild {
    param( [ref]$Wrapper, [ref]$Child, [int]$Index = 0 )
    Start-FunctionMeasurement -FunctionName "Add-CustomMenuChild"

    $Menu = Get-WrapperMenu -Wrapper $Wrapper

    try {
        $Menu.Items.Insert($Index, $Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Add-CustomMenuChild} $_" -ForegroundColor Red
    }
    Stop-FunctionMeasurement -FunctionName "Add-CustomMenuChild"
} # function Add-CustomMenuChild

function Remove-CustomMenuChild {
    param( [ref]$Wrapper, [ref]$Child )
    Start-FunctionMeasurement -FunctionName "Remove-CustomMenuChild"
    $Menu = Get-WrapperMenu -Wrapper $Wrapper
    try {
        $Menu.Items.Remove($Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Remove-CustomMenuChild} $_" -ForegroundColor Red
    }
    Stop-FunctionMeasurement -FunctionName "Remove-CustomMenuChild"
} # function Remove-CustomMenuChild

function Add-ChildToItemsButtonMenu {
    param( [ref]$Item, [ref]$Child, [int]$Index = -1 )
    Start-FunctionMeasurement -FunctionName "Add-ChildToItemsButtonMenu"

    $ResolvedItem = Resolve-TargetElement $Item.Value
    if (-not $ResolvedItem) {
        Stop-FunctionMeasurement -FunctionName "Add-ChildToItemsButtonMenu"
        return
    }

    $ButtonMenu = Find-ObjectWhere -Object ([ref]$ResolvedItem) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1

    if ($ButtonMenu) {
        if ($Index -lt 0 -or $Index -gt $ButtonMenu.Items.Count) { $Index = $ButtonMenu.Items.Count }
        try {
            $ButtonMenu.Items.Insert($Index, $Child.Value) | Out-Null
        }
        catch {
            Write-Host "{Add-ChildToItemsButtonMenu} $_" -ForegroundColor Red
        }
        $ButtonMenu.Visibility = 'Visible'
    }
    else {
        if (-not ($ResolvedItem.Tag -is [hashtable])) { $ResolvedItem.Tag = @{} }
        if (-not ($ResolvedItem.Tag.ContainsKey('ExtraMenuItems')) -or -not ($ResolvedItem.Tag.ExtraMenuItems -is [System.Collections.ArrayList])) {
            $ResolvedItem.Tag.ExtraMenuItems = [System.Collections.ArrayList]@()
        }
        if ($Index -lt 0 -or $Index -gt $ResolvedItem.Tag.ExtraMenuItems.Count) {
            $Index = $ResolvedItem.Tag.ExtraMenuItems.Count
        }
        $ResolvedItem.Tag.ExtraMenuItems.Insert($Index, $Child.Value) | Out-Null
    }
    Stop-FunctionMeasurement -FunctionName "Add-ChildToItemsButtonMenu"
    return

    try {
        $ButtonMenu.Items.Insert($Index, $Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Add-ChildToItemsButtonMenu} $_" -ForegroundColor Red
    }
    $ButtonMenu.Visibility = 'Visible'
    Stop-FunctionMeasurement -FunctionName "Add-ChildToItemsButtonMenu"
} # function Add-ChildToItemsButtonMenu

function Add-ChildrenToItemsButtonMenu {
    param(
        [Parameter(Mandatory)][ref]$Item,
        [Parameter(Mandatory)][array]$Children
    )
    Start-FunctionMeasurement -FunctionName "Add-ChildrenToItemsButtonMenu"
    foreach ($Child in $Children) {
        if ($Child) {
            Add-ChildToItemsButtonMenu $Item ([ref]$Child)
        }
    }
    Stop-FunctionMeasurement -FunctionName "Add-ChildrenToItemsButtonMenu"
} # function Add-ChildrenToItemsButtonMenu

function Remove-ChildToItemsButtonMenu {
    param( [ref]$Item, [ref]$Child )
    Start-FunctionMeasurement -FunctionName "Remove-ChildToItemsButtonMenu"
    if ($Item.Value.Name -eq $ButtonMenuName) { $ButtonMenu = $Item.Value }
    else {
        $ButtonMenu = Find-ObjectWhere -Object $Item -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
    }

    try {
        $ButtonMenu.Items.Remove($Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Remove-ChildToItemsButtonMenu} $_" -ForegroundColor Red
    }
    Stop-FunctionMeasurement -FunctionName "Remove-ChildToItemsButtonMenu"
} # function Remove-ChildToItemsButtonMenu

function Get-MenuItemRelativePriority {
    param(
        [Parameter(Mandatory)]$MenuItem,
        [Parameter(Mandatory)][ValidateSet('CustomMenu', 'ButtonMenu')][string]$MenuType
    )
    Start-FunctionMeasurement -FunctionName "Get-MenuItemRelativePriority"
    if ($MenuItem -is [System.Windows.Controls.Separator]) {
        if ($MenuItem.Tag -is [int]) { return $MenuItem.Tag }
        return 15
    }
    $ItemName = $MenuItem.Name

    if ($MenuType -eq 'CustomMenu') {
        if ($ItemName -like "*$QuickSetBadgeNameSuffix") { return 10 }
        if ($ItemName -like "*$SearchButtonNameSuffix") { return 20 }
        if ($ItemName -eq $LockUnlockButtonName) { return 30 }
        if ($ItemName -like "*$DisableEnableButtonNameSuffix") { return 40 }
        if ($ItemName -like "*$ConstructButtonNameSuffix" -or $ItemName -eq $AddArrayItemButtonName) { return 50 }
        if ($ItemName -eq $ButtonMenuName) { return 60 }
        if ($ItemName -eq $MinMaxButtonName) { return 70 }
        return 100
    }

    if ($ItemName -like "*$ConstructButtonNameSuffix") { return 10 }
    if ($ItemName -like "*$QuickSetMenuNameSuffix") { return 20 }
    if ($ItemName -like "*$SortMenuNameSuffix") { return 25 }
    if ($ItemName -like "*$SearchButtonNameSuffix") { return 30 }
    if ($ItemName -like "*$CopyButtonNameSuffix") { return 32 }
    if ($ItemName -like "*$CopyAsMenuNameSuffix") { return 34 }
    if ($ItemName -like "*$PasteButtonNameSuffix") { return 36 }
    if ($ItemName -eq $LockUnlockButtonName) { return 40 }
    if ($ItemName -like "*$RandomValuesButtonNameSuffix") { return 50 }
    if ($ItemName -like "*$ClearButtonNameSuffix") { return 60 }
    if ($ItemName -like "*$DisableEnableButtonNameSuffix") { return 70 }
    if ($ItemName -like "*$DeleteButtonNameSuffix") { return 80 }
    Stop-FunctionMeasurement -FunctionName "Get-MenuItemRelativePriority"
    return 100
} # function Get-MenuItemRelativePriority

function Get-MenuRelativeInsertIndex {
    param(
        [Parameter(Mandatory)]$MenuContainer,
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][ValidateSet('CustomMenu', 'ButtonMenu')][string]$MenuType
    )
    Start-FunctionMeasurement -FunctionName "Get-MenuRelativeInsertIndex"
    $TargetPriority = Get-MenuItemRelativePriority -MenuItem $Item -MenuType $MenuType
    for ($i = 0; $i -lt $MenuContainer.Items.Count; $i++) {
        $ExistingPriority = Get-MenuItemRelativePriority -MenuItem $MenuContainer.Items[$i] -MenuType $MenuType
        if ($ExistingPriority -gt $TargetPriority) {
            return $i
        }
    }
    Stop-FunctionMeasurement -FunctionName "Get-MenuRelativeInsertIndex"
    return $MenuContainer.Items.Count
} # function Get-MenuRelativeInsertIndex

function Move-MenuItemBetweenMenus {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][ValidateSet('ToCustomMenu', 'ToButtonMenu')][string]$Direction
    )
    Start-FunctionMeasurement -FunctionName "Move-MenuItemBetweenMenus"
    $Parent = $Item.Parent
    if (-not $Parent) { return }

    if ($Direction -eq 'ToCustomMenu') {
        $Menu = Get-WrapperMenu -Wrapper $Parent
        Remove-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$Item)
        $InsertIndex = if ($Menu) { Get-MenuRelativeInsertIndex -MenuContainer $Menu -Item $Item -MenuType 'CustomMenu' } else { 0 }
        Add-CustomMenuChild ([ref]$Parent) ([ref]$Item) $InsertIndex
    }
    else {
        $ButtonMenu = if ($Parent.Name -eq $ButtonMenuName) { $Parent } else {
            Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Parent) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1)
        }
        Remove-CustomMenuChild ([ref]$Parent) ([ref]$Item)
        $InsertIndex = if ($ButtonMenu) { Get-MenuRelativeInsertIndex -MenuContainer $ButtonMenu -Item $Item -MenuType 'ButtonMenu' } else { -1 }
        Add-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$Item) $InsertIndex
    }
    Stop-FunctionMeasurement -FunctionName "Move-MenuItemBetweenMenus"
} # function Move-MenuItemBetweenMenus

function Clear-SingleContentElement {
    param(
        [Parameter(Mandatory)]$Element,
        [switch]$UseEmptyString
    )
    Start-FunctionMeasurement -FunctionName "Clear-SingleContentElement"
    $EmptyVal = if ($UseEmptyString) { '' } else { $null }
    Restore-ElementSearchStyle -Element $Element

    switch ($Element.GetType().Name) {
        'TextBox' { $Element.Text = $EmptyVal }
        'ComboBox' {
            $Element.SelectedItem = $null
            if ($UseEmptyString) { $Element.Text = '' }
        }
        'PasswordBox' { $Element.Password = $EmptyVal }
        'RichTextBox' { Set-RichTextBoxText -RichTextBox $Element }
        default {
            Write-Host "What is this? ($($Element.GetType().Name))" -ForegroundColor Red -BackgroundColor Yellow
        }
    }
    Stop-FunctionMeasurement -FunctionName "Clear-SingleContentElement"
} # function Clear-SingleContentElement

function Clear-WrapperContent {
    param(
        [ref]$Wrapper
    )
    Start-FunctionMeasurement -FunctionName "Clear-WrapperContent"
    $Contents = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentElementName }
    :Contents foreach ($Content in $Contents) {
        if ((Get-IsLocked ([ref]$Content))) { continue Contents } # TODO: Flash lock
        Clear-SingleContentElement -Element $Content
    } # Contents

    $DateTimePickers = Get-CustomDateTimePickers -Wrapper $Wrapper
    :DateTimePickers foreach ($DTP in $DateTimePickers) {
        if ((Get-IsLocked ([ref]$DTP))) { continue DateTimePickers }
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox) {
            Clear-SingleContentElement -Element $DateBox
        }
    }
    Stop-FunctionMeasurement -FunctionName "Clear-WrapperContent"
} # function Clear-WrapperContent

function Get-RandomValuesConfiguration {
    param(
        $Wrapper = $null
    )
    Start-FunctionMeasurement -FunctionName 'Get-RandomValuesConfiguration'
    $TargetWrapper = if ($Wrapper) { Resolve-TargetElement $Wrapper } else { $null }
    if ($TargetWrapper -and $TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('RandomValuesConfiguration') -and $TargetWrapper.Tag.RandomValuesConfiguration) {
        Stop-FunctionMeasurement -FunctionName 'Get-RandomValuesConfiguration'
        return $TargetWrapper.Tag.RandomValuesConfiguration
    }

    if ($script:GlobalRandomValuesConfiguration -is [hashtable]) {
        Stop-FunctionMeasurement -FunctionName 'Get-RandomValuesConfiguration'
        return $script:GlobalRandomValuesConfiguration
    }

    if ($RandomValuesConfigurationFilePath -and (Test-Path -LiteralPath $RandomValuesConfigurationFilePath)) {
        try {
            $FileContent = Get-Content -LiteralPath $RandomValuesConfigurationFilePath -Raw -ErrorAction Stop
            $Parsed = ConvertFrom-Json -InputObject $FileContent -ErrorAction Stop
            $Configuration = @{
                GenerationMode             = if ($Parsed.GenerationMode) { [string]$Parsed.GenerationMode } else { 'CharacterSets' }
                RegularExpressionPattern   = if ($Parsed.RegularExpressionPattern) { [string]$Parsed.RegularExpressionPattern } else { '\(\d{3}\) \d{3}-\d{4}' }
                UnboundedRepetitionMaximum = if ($Parsed.UnboundedRepetitionMaximum -gt 0) { [int]$Parsed.UnboundedRepetitionMaximum } else { 5 }
                Length                     = if ($Parsed.Length -gt 0) { [int]$Parsed.Length } else { 10 }
                IncludeUppercase           = if ($null -ne $Parsed.IncludeUppercase) { [bool]$Parsed.IncludeUppercase } else { $true }
                UppercaseCharacters        = if ($null -ne $Parsed.UppercaseCharacters) { [string]$Parsed.UppercaseCharacters } else { 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' }
                IncludeLowercase           = if ($null -ne $Parsed.IncludeLowercase) { [bool]$Parsed.IncludeLowercase } else { $true }
                LowercaseCharacters        = if ($null -ne $Parsed.LowercaseCharacters) { [string]$Parsed.LowercaseCharacters } else { 'abcdefghijklmnopqrstuvwxyz' }
                IncludeNumbers             = if ($null -ne $Parsed.IncludeNumbers) { [bool]$Parsed.IncludeNumbers } else { $true }
                NumberCharacters           = if ($null -ne $Parsed.NumberCharacters) { [string]$Parsed.NumberCharacters } else { '0123456789' }
                IncludeSymbols             = if ($null -ne $Parsed.IncludeSymbols) { [bool]$Parsed.IncludeSymbols } else { $false }
                SymbolCharacters           = if ($null -ne $Parsed.SymbolCharacters) { [string]$Parsed.SymbolCharacters } else { '!@#$%^&*()_+-=[]{}|;:,.<>?' }
            }
            $script:GlobalRandomValuesConfiguration = $Configuration
            Stop-FunctionMeasurement -FunctionName 'Get-RandomValuesConfiguration'
            return $Configuration
        }
        catch {
            Write-Host "{Get-RandomValuesConfiguration} Error reading configuration file: $_" -ForegroundColor Yellow
        }
    }

    $DefaultConfiguration = @{
        GenerationMode             = 'CharacterSets'
        RegularExpressionPattern   = '\(\d{3}\) \d{3}-\d{4}'
        UnboundedRepetitionMaximum = 5
        Length                     = 10
        IncludeUppercase           = $true
        UppercaseCharacters        = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        IncludeLowercase           = $true
        LowercaseCharacters        = 'abcdefghijklmnopqrstuvwxyz'
        IncludeNumbers             = $true
        NumberCharacters           = '0123456789'
        IncludeSymbols             = $false
        SymbolCharacters           = '!@#$%^&*()_+-=[]{}|;:,.<>?'
    }
    Stop-FunctionMeasurement -FunctionName 'Get-RandomValuesConfiguration'
    return $DefaultConfiguration
} # function Get-RandomValuesConfiguration

function Get-RandomStringFromRegularExpression {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [int]$UnboundedRepetitionMaximum = 5
    )
    Start-FunctionMeasurement -FunctionName 'Get-RandomStringFromRegularExpression'

    $Digits = '0123456789'.ToCharArray()
    $Words = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'.ToCharArray()
    $Spaces = @([char]32)
    $Printable = (32..126 | ForEach-Object { [char]$_ })

    $Index = 0
    $Length = $Pattern.Length

    $ParseClass = {
        $Negated = $false
        if ($Index -lt $Length -and $Pattern[$Index] -eq '^') {
            $Negated = $true
            $Index++
        }
        $ClassCharacters = New-Object System.Collections.Generic.HashSet[char]
        while ($Index -lt $Length -and $Pattern[$Index] -ne ']') {
            $CurrentCharacter = $Pattern[$Index]
            $Index++
            if ($CurrentCharacter -eq '\' -and $Index -lt $Length) {
                $EscapedCharacter = $Pattern[$Index]
                $Index++
                switch ($EscapedCharacter) {
                    'd' { $Digits | ForEach-Object { [void]$ClassCharacters.Add($_) } }
                    'w' { $Words | ForEach-Object { [void]$ClassCharacters.Add($_) } }
                    's' { $Spaces | ForEach-Object { [void]$ClassCharacters.Add($_) } }
                    default { [void]$ClassCharacters.Add($EscapedCharacter) }
                }
            }
            elseif ($Index + 1 -lt $Length -and $Pattern[$Index] -eq '-' -and $Pattern[$Index + 1] -ne ']') {
                $Index++
                $EndCharacter = $Pattern[$Index]
                $Index++
                $StartAscii = [int][char]$CurrentCharacter
                $EndAscii = [int][char]$EndCharacter
                if ($StartAscii -le $EndAscii) {
                    for ($c = $StartAscii; $c -le $EndAscii; $c++) {
                        [void]$ClassCharacters.Add([char]$c)
                    }
                }
                else {
                    [void]$ClassCharacters.Add($CurrentCharacter)
                    [void]$ClassCharacters.Add($EndCharacter)
                }
            }
            else {
                [void]$ClassCharacters.Add($CurrentCharacter)
            }
        }
        if ($Index -lt $Length -and $Pattern[$Index] -eq ']') { $Index++ }

        if ($Negated) {
            $Remaining = New-Object System.Collections.Generic.List[char]
            foreach ($p in $Printable) {
                if (-not $ClassCharacters.Contains($p)) { $Remaining.Add($p) }
            }
            return $Remaining
        }
        return (New-Object System.Collections.Generic.List[char] $ClassCharacters)
    }

    $ParseQuantifier = {
        if ($Index -ge $Length) { return 1 }
        $Next = $Pattern[$Index]
        if ($Next -eq '?') {
            $Index++
            return (Get-Random -Minimum 0 -Maximum 2)
        }
        if ($Next -eq '*') {
            $Index++
            return (Get-Random -Minimum 0 -Maximum ($UnboundedRepetitionMaximum + 1))
        }
        if ($Next -eq '+') {
            $Index++
            return (Get-Random -Minimum 1 -Maximum ($UnboundedRepetitionMaximum + 1))
        }
        if ($Next -eq '{') {
            $EndBracket = $Pattern.IndexOf('}', $Index)
            if ($EndBracket -gt $Index) {
                $Specifier = $Pattern.Substring($Index + 1, $EndBracket - $Index - 1)
                $Index = $EndBracket + 1
                if ($Specifier.Contains(',')) {
                    $Parts = $Specifier.Split(',')
                    $Minimum = [int]$Parts[0]
                    $Maximum = if ($Parts[1].Trim().Length -gt 0) { [int]$Parts[1] } else { $Minimum + $UnboundedRepetitionMaximum }
                    return (Get-Random -Minimum $Minimum -Maximum ($Maximum + 1))
                }
                else {
                    return [int]$Specifier
                }
            }
        }
        return 1
    }

    $ParseSequence = $null
    $ParseSequence = {
        $Result = New-Object System.Text.StringBuilder
        while ($Index -lt $Length) {
            $Char = $Pattern[$Index]
            if ($Char -eq ')' -or $Char -eq '|') { break }
            if ($Char -eq '^' -or $Char -eq '$') { $Index++; continue }

            $Generator = $null
            if ($Char -eq '(') {
                $Index++
                $SubPatternIndex = $Index
                $NestingLevel = 1
                $GroupBranches = New-Object System.Collections.Generic.List[string]
                $CurrentBranchStart = $Index
                while ($Index -lt $Length -and $NestingLevel -gt 0) {
                    if ($Pattern[$Index] -eq '\' -and $Index + 1 -lt $Length) { $Index += 2; continue }
                    if ($Pattern[$Index] -eq '(') { $NestingLevel++ }
                    elseif ($Pattern[$Index] -eq ')') {
                        $NestingLevel--
                        if ($NestingLevel -eq 0) {
                            $GroupBranches.Add($Pattern.Substring($CurrentBranchStart, $Index - $CurrentBranchStart))
                            $Index++
                            break
                        }
                    }
                    elseif ($Pattern[$Index] -eq '|' -and $NestingLevel -eq 1) {
                        $GroupBranches.Add($Pattern.Substring($CurrentBranchStart, $Index - $CurrentBranchStart))
                        $CurrentBranchStart = $Index + 1
                    }
                    $Index++
                }
                $CapturedBranches = $GroupBranches.ToArray()
                $Generator = {
                    $Selected = $CapturedBranches[(Get-Random -Minimum 0 -Maximum $CapturedBranches.Length)]
                    Get-RandomStringFromRegularExpression -Pattern $Selected -UnboundedRepetitionMaximum $UnboundedRepetitionMaximum
                }
            }
            elseif ($Char -eq '[') {
                $Index++
                $ClassPool = . $ParseClass
                $Generator = {
                    if ($ClassPool.Count -gt 0) {
                        $ClassPool[(Get-Random -Minimum 0 -Maximum $ClassPool.Count)]
                    }
                    else { '' }
                }
            }
            elseif ($Char -eq '\') {
                $Index++
                if ($Index -lt $Length) {
                    $Escaped = $Pattern[$Index]
                    $Index++
                    switch ($Escaped) {
                        'd' { $Generator = { $Digits[(Get-Random -Minimum 0 -Maximum $Digits.Length)] } }
                        'w' { $Generator = { $Words[(Get-Random -Minimum 0 -Maximum $Words.Length)] } }
                        's' { $Generator = { ' ' } }
                        default { $LiteralEscaped = [string]$Escaped; $Generator = { $LiteralEscaped } }
                    }
                }
            }
            elseif ($Char -eq '.') {
                $Index++
                $Generator = { $Printable[(Get-Random -Minimum 0 -Maximum $Printable.Length)] }
            }
            else {
                $Index++
                $LiteralChar = [string]$Char
                $Generator = { $LiteralChar }
            }

            $Count = . $ParseQuantifier
            for ($k = 0; $k -lt $Count; $k++) {
                [void]$Result.Append((& $Generator))
            }
        }
        return $Result.ToString()
    }

    $BranchesTop = New-Object System.Collections.Generic.List[string]
    $TopStart = 0
    $Nesting = 0
    for ($i = 0; $i -lt $Length; $i++) {
        if ($Pattern[$i] -eq '\' -and $i + 1 -lt $Length) { $i++; continue }
        if ($Pattern[$i] -eq '(') { $Nesting++ }
        elseif ($Pattern[$i] -eq ')') { $Nesting-- }
        elseif ($Pattern[$i] -eq '|' -and $Nesting -eq 0) {
            $BranchesTop.Add($Pattern.Substring($TopStart, $i - $TopStart))
            $TopStart = $i + 1
        }
    }
    $BranchesTop.Add($Pattern.Substring($TopStart, $Length - $TopStart))

    $SelectedTop = if ($BranchesTop.Count -gt 1) {
        $BranchesTop[(Get-Random -Minimum 0 -Maximum $BranchesTop.Count)]
    }
    else {
        $Pattern
    }

    $Pattern = $SelectedTop
    $Length = $Pattern.Length
    $Index = 0
    $Output = . $ParseSequence

    Stop-FunctionMeasurement -FunctionName 'Get-RandomStringFromRegularExpression'
    return $Output
} # function Get-RandomStringFromRegularExpression

function Get-RandomCustomString {
    param(
        [hashtable]$Configuration,
        [int]$Length = 0
    )
    Start-FunctionMeasurement -FunctionName 'Get-RandomCustomString'
    if (-not $Configuration) {
        $Configuration = Get-RandomValuesConfiguration
    }

    if ($Configuration.ContainsKey('GenerationMode') -and $Configuration.GenerationMode -eq 'RegularExpression') {
        $Pattern = if ($Configuration.ContainsKey('RegularExpressionPattern') -and -not [string]::IsNullOrWhiteSpace($Configuration.RegularExpressionPattern)) {
            [string]$Configuration.RegularExpressionPattern
        }
        else {
            '\(\d{3}\) \d{3}-\d{4}'
        }
        $MaxRepetition = if ($Configuration.ContainsKey('UnboundedRepetitionMaximum') -and $Configuration.UnboundedRepetitionMaximum -gt 0) {
            [int]$Configuration.UnboundedRepetitionMaximum
        }
        else {
            5
        }
        $GeneratedRegexString = Get-RandomStringFromRegularExpression -Pattern $Pattern -UnboundedRepetitionMaximum $MaxRepetition
        Stop-FunctionMeasurement -FunctionName 'Get-RandomCustomString'
        return $GeneratedRegexString
    }

    $TargetLength = if ($Length -gt 0) {
        $Length
    }
    elseif ($Configuration.ContainsKey('Length') -and $Configuration.Length -gt 0) {
        [int]$Configuration.Length
    }
    else {
        10
    }

    $UniqueCharacterSet = New-Object System.Collections.Generic.HashSet[char]
    if ($Configuration.IncludeUppercase) {
        $Characters = if ($Configuration.ContainsKey('UppercaseCharacters') -and $null -ne $Configuration.UppercaseCharacters) { [string]$Configuration.UppercaseCharacters } else { 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' }
        $Characters.ToCharArray() | ForEach-Object { [void]$UniqueCharacterSet.Add($_) }
    }
    if ($Configuration.IncludeLowercase) {
        $Characters = if ($Configuration.ContainsKey('LowercaseCharacters') -and $null -ne $Configuration.LowercaseCharacters) { [string]$Configuration.LowercaseCharacters } else { 'abcdefghijklmnopqrstuvwxyz' }
        $Characters.ToCharArray() | ForEach-Object { [void]$UniqueCharacterSet.Add($_) }
    }
    if ($Configuration.IncludeNumbers) {
        $Characters = if ($Configuration.ContainsKey('NumberCharacters') -and $null -ne $Configuration.NumberCharacters) { [string]$Configuration.NumberCharacters } else { '0123456789' }
        $Characters.ToCharArray() | ForEach-Object { [void]$UniqueCharacterSet.Add($_) }
    }
    if ($Configuration.IncludeSymbols) {
        $Characters = if ($Configuration.ContainsKey('SymbolCharacters') -and $null -ne $Configuration.SymbolCharacters) { [string]$Configuration.SymbolCharacters } else { '!@#$%^&*()_+-=[]{}|;:,.<>?' }
        $Characters.ToCharArray() | ForEach-Object { [void]$UniqueCharacterSet.Add($_) }
    }

    if ($UniqueCharacterSet.Count -eq 0) {
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray() | ForEach-Object { [void]$UniqueCharacterSet.Add($_) }
    }

    $CharacterPool = New-Object System.Collections.Generic.List[char] $UniqueCharacterSet

    $RandomCharacters = [char[]](1..$TargetLength | ForEach-Object {
            $CharacterPool[(Get-Random -Minimum 0 -Maximum $CharacterPool.Count)]
        })
    $GeneratedString = -join $RandomCharacters

    Stop-FunctionMeasurement -FunctionName 'Get-RandomCustomString'
    return $GeneratedString
} # function Get-RandomCustomString

function Set-WrapperRandomContent {
    param(
        [ref]$Wrapper
    )
    Start-FunctionMeasurement -FunctionName 'Set-WrapperRandomContent'
    $Contents = @()
    if ($Wrapper.Value.Name -eq $ContentElementName) {
        $Contents += $Wrapper.Value
    }
    $ChildContents = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentElementName }
    if ($ChildContents) {
        $Contents += $ChildContents
    }

    $RandomConfiguration = Get-RandomValuesConfiguration -Wrapper $Wrapper.Value

    :Contents foreach ($Content in $Contents) {
        if ((Get-IsLocked ([ref]$Content))) { continue Contents }

        Restore-ElementSearchStyle -Element $Content

        switch ($Content.GetType().Name) {
            'TextBox' {
                if ($Content.MaxLength -eq 1) {
                    $Content.Text = Get-RandomCustomString -Configuration $RandomConfiguration -Length 1
                }
                elseif ($Content.Tag -is [hashtable] -and $Content.Tag.ContainsKey('TargetType') -and $Content.Tag.TargetType -and $Content.Tag.TargetType -ne [string]) {
                    $Content.Text = (Get-Random -Minimum 0 -Maximum 100).ToString()
                }
                else {
                    $Content.Text = Get-RandomCustomString -Configuration $RandomConfiguration
                }
            }
            'ComboBox' {
                if ($Content.ItemsSource -and @($Content.ItemsSource).Count -gt 0) {
                    $Content.SelectedItem = Get-Random -InputObject @($Content.ItemsSource)
                }
            }
            'PasswordBox' {
                $Content.Password = Get-RandomCustomString -Configuration $RandomConfiguration
            }
            'RichTextBox' {
                Set-RichTextBoxText -RichTextBox $Content -Text (Get-RandomCustomString -Configuration $RandomConfiguration)
            }
            default {
                Write-Host "What is this? ($($Content.GetType().Name))" -ForegroundColor Red -BackgroundColor Yellow
            }
        }
    } # Contents

    $DateTimePickers = Get-CustomDateTimePickers -Wrapper $Wrapper
    :DateTimePickers foreach ($DTP in $DateTimePickers) {
        if ((Get-IsLocked ([ref]$DTP))) { continue DateTimePickers }
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox) {
            Restore-ElementSearchStyle -Element $DateBox
            $DateBox.Text = (Get-Date).AddDays((Get-Random -Minimum -30 -Maximum 30)).ToString('yyyy-MM-dd HH:mm:ss')
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Set-WrapperRandomContent'
} # function Set-WrapperRandomContent

function Set-DisableEnableButtonVisualState {
    param(
        [Parameter(Mandatory)]$Button,
        [Parameter(Mandatory)][bool]$IsDisabled
    )
    Start-FunctionMeasurement -FunctionName 'Set-DisableEnableButtonVisualState'
    $IsAll = $Button.Header -like '* All' -or ($Button.Tag -is [hashtable] -and $Button.Tag.IsAll)
    if ($IsDisabled) {
        if ($Button.Icon -eq $DisableEnableButtonIconEnabled) {
            $Button.Tag = if ($IsAll) { @{ IsAll = $true } } else { $null }
            $Button.Header = if ($IsAll) { $DisableEnableButtonHeaderDisabled + ' All' } else { $DisableEnableButtonHeaderDisabled }
            $Button.Icon = $DisableEnableButtonIconDisabled
            Move-MenuItemBetweenMenus -Item $Button -Direction 'ToCustomMenu'
        }
    }
    else {
        if ($Button.Icon -eq $DisableEnableButtonIconDisabled) {
            $Button.Header = if ($IsAll) { $DisableEnableButtonHeaderEnabled + ' All' } else { $DisableEnableButtonHeaderEnabled }
            $Button.Icon = $DisableEnableButtonIconEnabled
            Move-MenuItemBetweenMenus -Item $Button -Direction 'ToButtonMenu'
            $Button.Tag = $null
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Set-DisableEnableButtonVisualState'
} # function Set-DisableEnableButtonVisualState

function Confirm-ArrayEnableButton {
    param( [ref]$Item )
    Start-FunctionMeasurement -FunctionName "Confirm-ArrayEnableButton"
    $Target = Resolve-TargetElement $Item
    if ($Target.Name -eq $ContentHeaderBorderName) {
        $ContentHeaderBorder = $Target
    }
    else {
        $ContentHeaderBorder = Get-ParentWrapperBorder -Element $Target -HeaderOnly
    }
    
    if (-not $ContentHeaderBorder) { return }

    $ContentHeaderBorderTitle = Find-Title $ContentHeaderBorder

    # If Wrapper is not an Array, Get GrandWrapper
    $CleanBorderTitle = if ($ContentHeaderBorderTitle) { [System.Text.RegularExpressions.Regex]::Replace($ContentHeaderBorderTitle, '\[.*?\]', '[]') } else { $ContentHeaderBorderTitle }
    if ($CleanBorderTitle -notlike '*`[]') {
        $GrandWrapper = Get-ParentWrapperBorder -Element $ContentHeaderBorder -HeaderOnly
        if ($GrandWrapper) { $ContentHeaderBorder = $GrandWrapper }
    }

    # If the resolved wrapper is known to not be an array, exit immediately
    if ($ContentHeaderBorder.Tag -is [hashtable] -and $ContentHeaderBorder.Tag.ContainsKey('IsArray') -and -not $ContentHeaderBorder.Tag.IsArray) {
        Stop-FunctionMeasurement -FunctionName "Confirm-ArrayEnableButton"
        return
    }

    $ArrayButton = if ($ContentHeaderBorder.Tag -is [hashtable] -and $ContentHeaderBorder.Tag.ContainsKey('DisableEnableButton')) {
        $ContentHeaderBorder.Tag.DisableEnableButton
    }
    else {
        $SearchRoot = Get-WrapperMenu -Wrapper $ContentHeaderBorder
        $FoundArrayButton = if ($SearchRoot) {
            Find-ObjectWhere -Object ([ref]$SearchRoot) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -FindMax 1
        }
        else {
            Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
        }
        if ($ContentHeaderBorder.Tag -is [hashtable]) {
            $ContentHeaderBorder.Tag.DisableEnableButton = $FoundArrayButton
        }
        $FoundArrayButton
    }
    if (-not $ArrayButton) {
        Stop-FunctionMeasurement -FunctionName "Confirm-ArrayEnableButton"
        return
    }

    $ContentSlot = Get-WrapperContentSlot -Wrapper $ContentHeaderBorder
    $HasCheckedChildrenViaTag = $false
    $ItemCount = 0
    $DisabledCount = 0

    if ($ContentSlot -and $ContentSlot.Children.Count -gt 0) {
        $ItemCount = $ContentSlot.Children.Count
        $AllChildrenHaveTags = $true
        foreach ($Child in @($ContentSlot.Children)) {
            if ($Child.Tag -is [hashtable] -and $Child.Tag.ContainsKey('IsDisabled')) {
                if ($Child.Tag.IsDisabled) { $DisabledCount++ }
            }
            elseif ($Child.Tag -is [hashtable] -and $Child.Tag.ContainsKey('DisableEnableButton') -and $Child.Tag.DisableEnableButton) {
                if ($null -eq $Child.Tag.DisableEnableButton.Icon) { $DisabledCount++ }
            }
            else {
                $AllChildrenHaveTags = $false
                break
            }
        }
        if ($AllChildrenHaveTags) {
            $HasCheckedChildrenViaTag = $true
        }
    }

    if (-not $HasCheckedChildrenViaTag) {
        $ItemButtons = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $ArrayButton }
        $ItemCount = if ($ItemButtons) { @($ItemButtons).Count } else { 0 }
        $DisabledButtons = $ItemButtons | Where-Object { $null -eq $_.Icon }
        $DisabledCount = if ($DisabledButtons) { @($DisabledButtons).Count } else { 0 }
    }

    if ($DisabledCount -gt 0) {
        Set-DisableEnableButtonVisualState -Button $ArrayButton -IsDisabled $true
    }
    else {
        Set-DisableEnableButtonVisualState -Button $ArrayButton -IsDisabled $false
    }
    Stop-FunctionMeasurement -FunctionName "Confirm-ArrayEnableButton"
} # function Confirm-ArrayEnableButton

function Update-ArrayHeaderDescription {
    param(
        [Parameter(Mandatory)]$Wrapper
    )
    Start-FunctionMeasurement -FunctionName 'Update-ArrayHeaderDescription'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    if ($Target.Name -eq $ContentSlotElementName) {
        $Target = Get-ParentWrapperBorder -Element $Target -HeaderOnly
    }
    if (-not $Target -or $Target.Name -ne $ContentHeaderBorderName) { return }

    $TitleDock = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
    if ($TitleDock -is [array]) { $TitleDock = $TitleDock[0] }
    $DescBlock = if ($TitleDock) {
        Find-ObjectWhere -Object ([ref]$TitleDock) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName } -FindMax 1
    }
    else {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName } -FindMax 1
    }
    if ($DescBlock -is [array]) { $DescBlock = $DescBlock[0] }
    if (-not $DescBlock) { return }

    $CurrentText = $DescBlock.Text
    if (-not ($CurrentText -match '\[.*?\]')) { return }

    if (-not ($Target.Tag -is [hashtable])) { $Target.Tag = @{} }
    if (-not $Target.Tag.ContainsKey('BaseDescription') -or [string]::IsNullOrWhiteSpace($Target.Tag.BaseDescription)) {
        $Target.Tag.BaseDescription = [System.Text.RegularExpressions.Regex]::Replace($CurrentText, '\[.*?\]', '')
    }
    $BaseDescription = $Target.Tag.BaseDescription

    $ContentSlot = Get-WrapperContentSlot -Wrapper $Target
    $TotalCount = if ($ContentSlot -and $ContentSlot.Children) { $ContentSlot.Children.Count } else { 0 }

    if ($TotalCount -eq 0) {
        $DescBlock.Text = "$BaseDescription`[]"
    }
    else {
        $DisabledCount = 0
        foreach ($Child in @($ContentSlot.Children)) {
            if ($Child.Tag -is [hashtable] -and $Child.Tag.ContainsKey('IsDisabled') -and $Child.Tag.IsDisabled) {
                $DisabledCount++
            }
        }
        $EnabledCount = $TotalCount - $DisabledCount
        $DescBlock.Text = "$BaseDescription`[$EnabledCount/$TotalCount]"
    }
    Stop-FunctionMeasurement -FunctionName 'Update-ArrayHeaderDescription'
} # function Update-ArrayHeaderDescription

function Update-ArrayButtonsState {
    param(
        [Parameter(Mandatory)]$Wrapper
    )
    Start-FunctionMeasurement -FunctionName 'Update-ArrayButtonsState'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    if ($Target.Name -eq $ContentSlotElementName) {
        $Target = Get-ParentWrapperBorder -Element $Target -HeaderOnly
    }
    if (-not $Target) { return }

    $IsArrayWrapper = ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('IsArray') -and $Target.Tag.IsArray)
    if (-not $IsArrayWrapper) {
        $TitleText = Find-Title $Target
        $CleanTitleText = if ($TitleText) { [System.Text.RegularExpressions.Regex]::Replace($TitleText, '\[.*?\]', '[]') } else { $TitleText }
        $IsArrayWrapper = ($CleanTitleText -like '*`[]')
    }
    if (-not $IsArrayWrapper) { return }

    $ContentSlot = Get-WrapperContentSlot -Wrapper $Target

    $ItemCount = if ($ContentSlot -and $ContentSlot.Children) { $ContentSlot.Children.Count } else { 0 }
    $HasItems = ($ItemCount -gt 0)
    $IsLocked = Get-IsElementLockedSelf $Target

    $Menu = Get-WrapperMenu -Wrapper $Target
    if (-not $Menu) { return }

    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes @($SearchButtonNameSuffix, $QuickSetSaveButtonNameSuffix, $CopyButtonNameSuffix, $CopyAsMenuNameSuffix, $ConstructButtonNameSuffix) -IsEnabled $HasItems

    $LockableBatchSuffixes = @(
        $ClearButtonNameSuffix
        $DisableEnableButtonNameSuffix
        $DeleteButtonNameSuffix
    )
    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes $LockableBatchSuffixes -IsEnabled ($HasItems -and (-not $IsLocked))
    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes @($RandomValuesButtonNameSuffix, $AddArrayItemButtonName) -IsEnabled (-not $IsLocked)
    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes @($SortMenuNameSuffix) -IsEnabled (($ItemCount -gt 1) -and (-not $IsLocked))
    Update-WrapperPasteButtonState -Wrapper $Target

    if (-not $HasItems) {
        $SearchBar = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1)
        if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
            Close-SearchBar -ChildElement $SearchBar
        }
    }

    Update-ArrayHeaderDescription -Wrapper $Target

    Stop-FunctionMeasurement -FunctionName 'Update-ArrayButtonsState'
} # function Update-ArrayButtonsState

function Sync-ArraySlotState {
    param(
        [Parameter(Mandatory)]$ContentSlot,
        $ContainerWrapper = $null
    )
    Start-FunctionMeasurement -FunctionName "Sync-ArraySlotState"
    $TargetSlot = Resolve-TargetElement $ContentSlot
    if (-not $TargetSlot) { return }
    Reset-ArrayIndexes ([ref]$TargetSlot)
    $SyncTarget = if ($ContainerWrapper) { $ContainerWrapper } else { $TargetSlot }
    Confirm-ArrayEnableButton -Item ([ref]$SyncTarget)
    Update-ArrayButtonsState -Wrapper $SyncTarget
    Stop-FunctionMeasurement -FunctionName "Sync-ArraySlotState"
} # function Sync-ArraySlotState

function Clear-ContentSlotArrayItems {
    param(
        [Parameter(Mandatory = $true)]
        $ContentSlot,
        $ContainerWrapper = $null
    )
    Start-FunctionMeasurement -FunctionName "Clear-ContentSlotArrayItems"
    $TargetSlot = Resolve-TargetElement $ContentSlot
    if (-not $TargetSlot) { return }

    :DeleteArrayItems foreach ($Child in @($TargetSlot.Children)) {
        if ((Get-IsLocked $Child)) { continue DeleteArrayItems }
        Detach-UniversalSharedMenu -TargetWrapper $Child
        $TargetSlot.Children.Remove($Child)
    }
    Sync-ArraySlotState -ContentSlot $TargetSlot -ContainerWrapper $ContainerWrapper
    Stop-FunctionMeasurement -FunctionName "Clear-ContentSlotArrayItems"
} # function Clear-ContentSlotArrayItems

#endregion #3 Content Wrapper Actions

#region #3 Content Wrapper Elements

function New-CustomMenu {
    Start-FunctionMeasurement -FunctionName 'New-CustomMenu'
    $Menu = New-BaseMenu @{
        Name                = $MenuName
        Background          = 'Transparent'
        VerticalAlignment   = 'Center'
        HorizontalAlignment = 'Right'
        Cursor              = 'Hand'
    }

    $MenuItem = New-BaseMenuItem @{
        Name       = $ButtonMenuName
        Header     = '⋮'
        ToolTip    = $ButtonMenuToolTip
        Visibility = 'Collapsed'
    }
    $MenuItem.Add_SubmenuOpened({
            param($s, $e)
            if ($e.Source -ne $s) { return }
            $ParentWrapper = Get-ParentWrapperBorder -Element $s
            if ($ParentWrapper) {
                Ensure-WrapperActionButtons -Element $s
                Update-WrapperPasteButtonState -Wrapper $ParentWrapper
            }
        })
    
    Add-BaseMenuChild ([ref]$Menu) ([ref]$MenuItem)

    $Menu

    Stop-FunctionMeasurement -FunctionName 'New-CustomMenu'
} # function New-CustomMenu

function New-MenuTriggerButton {
    param(
        [Parameter(Mandatory = $true)][string]$ActionFrom
    )
    Start-FunctionMeasurement -FunctionName 'New-MenuTriggerButton'
    $TriggerButton = New-BaseButton @{
        Name                       = "$ActionFrom_$UniversalMenuTriggerButtonName"
        Content                    = $ButtonMenuHeader
        ToolTip                    = $ButtonMenuToolTip
        Background                 = 'Transparent'
        BorderBrush                = 'Transparent'
        BorderThickness            = 0
        Cursor                     = 'Hand'
        VerticalAlignment          = 'Center'
        HorizontalAlignment        = 'Right'
        VerticalContentAlignment   = 'Center'
        HorizontalContentAlignment = 'Center'
        Width                      = 20
        Height                     = 18
        Padding                    = 0
        Margin                     = 0
        FontSize                   = 12
        Foreground                 = 'Black'
        Focusable                  = $true
    }
    $TriggerButton.Add_MouseEnter({
            param($s, $e)
            $s.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(0x3D, 0x7E, 0xBA, 0xED))
        })
    $TriggerButton.Add_MouseLeave({
            param($s, $e)
            $s.Background = [System.Windows.Media.Brushes]::Transparent
        })
    $TriggerButton.Add_Click({
            param($s, $e)
            Invoke-UniversalMenuTriggerClick -TriggerButton $s
        })
    $ReturnValue = $TriggerButton
    Stop-FunctionMeasurement -FunctionName 'New-MenuTriggerButton'
    return $ReturnValue
} # function New-MenuTriggerButton

function Get-UniversalSharedMenu {
    Start-FunctionMeasurement -FunctionName 'Get-UniversalSharedMenu'
    if ($script:UniversalSharedMenu) {
        Stop-FunctionMeasurement -FunctionName 'Get-UniversalSharedMenu'
        return $script:UniversalSharedMenu
    }

    $Menu = New-BaseMenu @{
        Name                = $MenuName
        Background          = 'Transparent'
        VerticalAlignment   = 'Center'
        HorizontalAlignment = 'Right'
        Cursor              = 'Hand'
        Width               = 20
        Height              = 18
        Padding             = 0
        Margin              = 0
        BorderThickness     = 0
    }

    $MenuItem = New-BaseMenuItem @{
        Name                       = $ButtonMenuName
        Header                     = $ButtonMenuHeader
        ToolTip                    = $ButtonMenuToolTip
        Visibility                 = 'Visible'
        VerticalAlignment          = 'Center'
        HorizontalAlignment        = 'Center'
        VerticalContentAlignment   = 'Center'
        HorizontalContentAlignment = 'Center'
        Width                      = 20
        Height                     = 18
        Padding                    = '7,0,7,0'
        Margin                     = 0
        FontSize                   = 12
    }

    $ActionFrom = 'Universal'
    $Buttons = Get-StandardActionButtons `
        -ActionFrom $ActionFrom `
        -IsBatch `
        -IsConstruct `
        -IncludeSearch `
        -IncludeArrayItemActions

    $ButtonsByName = @{}
    foreach ($Btn in $Buttons) {
        if ($Btn) {
            [void]$MenuItem.Items.Add($Btn)
            if ($Btn.Name) {
                $ButtonsByName[$Btn.Name] = $Btn
            }
        }
    }

    $MenuItem.Add_SubmenuOpened({
            param($s, $e)
            if ($e.Source -ne $s) { return }
            if ($script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable] -and $script:UniversalSharedMenu.Tag.ActiveWrapper) {
                $ActiveWrapper = $script:UniversalSharedMenu.Tag.ActiveWrapper
                Update-WrapperPasteButtonState -Wrapper $ActiveWrapper
            }
        })

    Add-BaseMenuChild ([ref]$Menu) ([ref]$MenuItem)
    $Menu.Tag = @{
        ActiveWrapper       = $null
        ActiveTriggerButton = $null
        ButtonsByName       = $ButtonsByName
    }

    $script:UniversalSharedMenu = $Menu
    Stop-FunctionMeasurement -FunctionName 'Get-UniversalSharedMenu'
    return $script:UniversalSharedMenu
} # function Get-UniversalSharedMenu

function Update-UniversalMenuActionsVisibility {
    param(
        [Parameter(Mandatory = $true)]$TargetWrapper
    )
    Start-FunctionMeasurement -FunctionName 'Update-UniversalMenuActionsVisibility'
    $SharedMenu = Get-UniversalSharedMenu
    $ButtonMenuItem = Find-ObjectWhere -Object ([ref]$SharedMenu) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
    if (-not $ButtonMenuItem) {
        Stop-FunctionMeasurement -FunctionName 'Update-UniversalMenuActionsVisibility'
        return
    }

    $ResolvedWrapper = Resolve-TargetElement $TargetWrapper
    $IsHeader = ($ResolvedWrapper.Name -eq $ContentHeaderBorderName)
    $IsArrayItem = ($ResolvedWrapper.Tag -is [hashtable] -and $ResolvedWrapper.Tag.ContainsKey('ArrayItem') -and $ResolvedWrapper.Tag.ArrayItem)
    $IsBatch = ($IsHeader -and $ResolvedWrapper.Tag -is [hashtable] -and $ResolvedWrapper.Tag.ContainsKey('TargetType') -and $ResolvedWrapper.Tag.TargetType)

    $QuickSetItem = Find-ObjectWhere -Object ([ref]$ButtonMenuItem) -FindWhere { $_.Name -like "*QuickSet*" } -FindMax 1
    if ($QuickSetItem) {
        Update-QuickSetSubMenu -QuickSetMenuItem $QuickSetItem -Wrapper $ResolvedWrapper
    }

    $PreviousExtraItems = @($ButtonMenuItem.Items | Where-Object { $_ -and ($_.Tag -is [hashtable] -and $_.Tag.ContainsKey('IsDynamicExtraItem')) })
    foreach ($OldExtra in $PreviousExtraItems) {
        [void]$ButtonMenuItem.Items.Remove($OldExtra)
    }

    if ($ResolvedWrapper.Tag -is [hashtable] -and $ResolvedWrapper.Tag.ContainsKey('ExtraMenuItems') -and $ResolvedWrapper.Tag.ExtraMenuItems) {
        $InsertIndex = 0
        foreach ($ExtraItem in $ResolvedWrapper.Tag.ExtraMenuItems) {
            if ($ExtraItem) {
                if (-not ($ExtraItem.Tag -is [hashtable])) { $ExtraItem.Tag = @{} }
                $ExtraItem.Tag.IsDynamicExtraItem = $true
                $ExtraItem.Visibility = 'Visible'
                $ButtonMenuItem.Items.Insert($InsertIndex, $ExtraItem) | Out-Null
                $InsertIndex++
            }
        }
    }

    $ContentSlot = Get-WrapperContentSlot -Wrapper $ResolvedWrapper
    $ItemCount = if ($ContentSlot -and $ContentSlot.Children) { $ContentSlot.Children.Count } else { 0 }
    $HasItems = ($ItemCount -gt 0)
    $IsLocked = Get-IsElementLockedSelf $ResolvedWrapper

    foreach ($Item in $ButtonMenuItem.Items) {
        if (-not $Item) { continue }
        $Name = $Item.Name

        if ($Name -like "*$DeleteButtonNameSuffix*") {
            $Item.Visibility = if ($IsArrayItem -or $IsBatch) { 'Visible' } else { 'Collapsed' }
            if ($IsBatch) {
                $Item.Header = "$DeleteButtonHeader All"
                $Item.ToolTip = $DeleteButtonAllToolTip
                $Item.IsEnabled = ($HasItems -and (-not $IsLocked))
            }
            else {
                $Item.Header = $DeleteButtonHeader
                $Item.ToolTip = $DeleteButtonToolTip
                $Item.IsEnabled = (-not $IsLocked)
            }
        }
        elseif ($Name -like "*$DisableEnableButtonNameSuffix*") {
            $Item.Visibility = if ($IsArrayItem -or $IsBatch) { 'Visible' } else { 'Collapsed' }
            $IsDisabled = ($ResolvedWrapper.Tag -is [hashtable] -and $ResolvedWrapper.Tag.ContainsKey('IsDisabled') -and $ResolvedWrapper.Tag.IsDisabled)
            if ($IsBatch) {
                $Item.Header = if ($IsDisabled) { 'Enable All' } else { 'Disable All' }
                $Item.Icon = '❌'
                $Item.IsEnabled = ($HasItems -and (-not $IsLocked))
                $BaseTip = if ($IsDisabled) { $DisableEnableButtonAllToolTipDisabled } else { $DisableEnableButtonAllToolTipEnabled }
                if ($ContentSlot -and $ContentSlot.Children.Count -gt 0) {
                    $TotalCount = $ContentSlot.Children.Count
                    $LockedCount = 0
                    $DisabledChildCount = 0
                    foreach ($Child in @($ContentSlot.Children)) {
                        if (Get-IsLocked $Child) { $LockedCount++ }
                        if ($Child.Tag -is [hashtable] -and $Child.Tag.ContainsKey('IsDisabled') -and $Child.Tag.IsDisabled) { $DisabledChildCount++ }
                    }
                    $EnabledChildCount = $TotalCount - $DisabledChildCount
                    $Item.ToolTip = "$BaseTip`nItems: $TotalCount total ($EnabledChildCount enabled, $DisabledChildCount disabled, $LockedCount locked)"
                }
                else {
                    $Item.ToolTip = $BaseTip
                }
            }
            else {
                $Item.Header = if ($IsDisabled) { 'Enable' } else { 'Disable' }
                $Item.Icon = '❌'
                $Item.ToolTip = if ($IsDisabled) { $DisableEnableButtonToolTipDisabled } else { $DisableEnableButtonToolTipEnabled }
                $Item.IsEnabled = (-not $IsLocked)
            }
        }
        elseif ($Name -like "*$SearchButtonNameSuffix*") {
            $Item.Visibility = if ($IsHeader) { 'Visible' } else { 'Collapsed' }
            $Item.IsEnabled = if ($IsBatch) { $HasItems } else { $true }
        }
        elseif ($Name -like "*$CopyButtonNameSuffix*" -or $Name -like "*$CopyAsMenuNameSuffix*") {
            if ($IsBatch) {
                $Item.IsEnabled = $HasItems
            }
        }
        elseif ($Name -like "*$ConstructButtonNameSuffix*") {
            if ($IsBatch) {
                $Item.IsEnabled = $HasItems
            }
        }
        elseif ($Name -like "*$SortMenuNameSuffix*") {
            $Item.Visibility = if ($IsBatch) { 'Visible' } else { 'Collapsed' }
            $Item.IsEnabled = (($ItemCount -gt 1) -and (-not $IsLocked))
        }
        elseif ($Name -like "*$RandomValuesButtonNameSuffix*") {
            $Item.Visibility = 'Visible'
            $TargetHeaderText = if ($IsBatch) { "$($RandomValuesButtonHeader + 's')" } else { $RandomValuesButtonHeader }
            $TargetToolTip = if ($IsBatch) { $RandomValuesButtonAllToolTip } else { $RandomValuesButtonToolTip }

            $Item.Header = $TargetHeaderText
            $Item.ToolTip = $TargetToolTip
            $Item.IsEnabled = (-not $IsLocked)
        }
        elseif ($Name -like "*$ClearButtonNameSuffix*") {
            $Item.Visibility = 'Visible'
            if ($IsBatch) {
                $Item.Header = "$($ClearButtonHeader + 's')"
                $Item.ToolTip = $ClearButtonAllToolTip
                $Item.IsEnabled = ($HasItems -and (-not $IsLocked))
            }
            else {
                $Item.Header = $ClearButtonHeader
                $Item.ToolTip = $ClearButtonToolTip
                $Item.IsEnabled = (-not $IsLocked)
            }
        }
        elseif ($Name -like "*$LockUnlockButtonName*") {
            $Item.Visibility = 'Visible'
            $IsLocked = ($ResolvedWrapper.Tag -is [hashtable] -and $ResolvedWrapper.Tag.ContainsKey('IsLocked') -and $ResolvedWrapper.Tag.IsLocked)
            $Item.Header = if ($IsLocked) { 'Unlock' } else { 'Lock' }
            $Item.Icon = if ($IsLocked) { '🔓' } else { '🔒' }
            $Item.ToolTip = if ($IsLocked) { $LockUnlockButtonItemToolTipLocked } else { $LockUnlockButtonItemToolTipUnlocked }
        }
    }

    Update-WrapperPasteButtonState -Wrapper $ResolvedWrapper

    Stop-FunctionMeasurement -FunctionName 'Update-UniversalMenuActionsVisibility'
} # function Update-UniversalMenuActionsVisibility

function Invoke-UniversalMenuTriggerClick {
    param(
        [Parameter(Mandatory = $true)]$TriggerButton
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-UniversalMenuTriggerClick'
    $TargetButton = Resolve-TargetElement $TriggerButton
    if (-not $TargetButton) {
        Stop-FunctionMeasurement -FunctionName 'Invoke-UniversalMenuTriggerClick'
        return
    }

    $TargetWrapper = Get-ParentWrapperBorder -Element $TargetButton
    if (-not $TargetWrapper) {
        Stop-FunctionMeasurement -FunctionName 'Invoke-UniversalMenuTriggerClick'
        return
    }

    $SharedMenu = Get-UniversalSharedMenu

    if ($SharedMenu.Tag -is [hashtable] -and $SharedMenu.Tag.ActiveWrapper -eq $TargetWrapper) {
        $ButtonMenuItem = Find-ObjectWhere -Object ([ref]$SharedMenu) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
        if ($ButtonMenuItem) {
            $ButtonMenuItem.IsSubmenuOpen = -not $ButtonMenuItem.IsSubmenuOpen
        }
        Stop-FunctionMeasurement -FunctionName 'Invoke-UniversalMenuTriggerClick'
        return
    }

    if ($SharedMenu.Parent) {
        $PreviousParent = $SharedMenu.Parent
        $PreviousParent.Children.Remove($SharedMenu)
        if ($SharedMenu.Tag -is [hashtable] -and $SharedMenu.Tag.ActiveTriggerButton) {
            $SharedMenu.Tag.ActiveTriggerButton.Visibility = 'Visible'
        }
    }

    $TargetDock = if ($TargetWrapper.Name -eq $ContentHeaderBorderName) {
        Find-ObjectWhere -Object ([ref]$TargetWrapper) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
    }
    else {
        Find-ObjectWhere -Object ([ref]$TargetWrapper) -FindWhere { $_.Name -eq $ContentBorderDockName } -FindMax 1
    }

    if ($TargetDock) {
        $ButtonIndex = $TargetDock.Children.IndexOf($TargetButton)
        if ($ButtonIndex -ge 0) {
            $TargetDock.Children.Insert($ButtonIndex, $SharedMenu)
        }
        else {
            $TargetDock.Children.Insert(0, $SharedMenu)
        }
        [System.Windows.Controls.DockPanel]::SetDock($SharedMenu, 'Right')
    }

    $TargetButton.Visibility = 'Collapsed'

    $SharedMenu.Tag.ActiveWrapper = $TargetWrapper
    $SharedMenu.Tag.ActiveTriggerButton = $TargetButton
    $SharedMenu.DataContext = $TargetWrapper

    Update-UniversalMenuActionsVisibility -TargetWrapper $TargetWrapper

    $ButtonMenuItem = Find-ObjectWhere -Object ([ref]$SharedMenu) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
    if ($ButtonMenuItem) {
        $ButtonMenuItem.IsSubmenuOpen = $true
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-UniversalMenuTriggerClick'
} # function Invoke-UniversalMenuTriggerClick

function Detach-UniversalSharedMenu {
    param(
        $TargetWrapper = $null
    )
    Start-FunctionMeasurement -FunctionName 'Detach-UniversalSharedMenu'
    if (-not $script:UniversalSharedMenu) {
        Stop-FunctionMeasurement -FunctionName 'Detach-UniversalSharedMenu'
        return
    }

    if ($TargetWrapper -and $script:UniversalSharedMenu.Tag -is [hashtable]) {
        if ($script:UniversalSharedMenu.Tag.ActiveWrapper -ne $TargetWrapper) {
            Stop-FunctionMeasurement -FunctionName 'Detach-UniversalSharedMenu'
            return
        }
    }

    if ($script:UniversalSharedMenu.Parent) {
        $Parent = $script:UniversalSharedMenu.Parent
        $Parent.Children.Remove($script:UniversalSharedMenu)
    }

    if ($script:UniversalSharedMenu.Tag -is [hashtable]) {
        if ($script:UniversalSharedMenu.Tag.ActiveTriggerButton) {
            $script:UniversalSharedMenu.Tag.ActiveTriggerButton.Visibility = 'Visible'
        }
        $script:UniversalSharedMenu.Tag.ActiveWrapper = $null
        $script:UniversalSharedMenu.Tag.ActiveTriggerButton = $null
    }

    Stop-FunctionMeasurement -FunctionName 'Detach-UniversalSharedMenu'
} # function Detach-UniversalSharedMenu

function New-ContentHeader {
    param(
        [ValidateSet('Header', 'MiniHeader')]
        [string]$TitleType,
        [string]$Title,
        [string]$Description,
        [Type]$Type,
        [bool]$ArrayItemHeader = $false,
        [int]$Depth = 0
    )
    Start-FunctionMeasurement -FunctionName 'New-ContentHeader'

    if (-not $WrapperType) { $WrapperType = $TitleType }

    $ContentHeaderBorder = New-BaseBorder @{
        Name            = $ContentHeaderBorderName
        Margin          = 2
        BorderThickness = 2
        BorderBrush     = 'Black'
        Background      = $ColorSequence[$Depth % $ColorSequence.Count]
    }
    $ContentHeaderBorder.Tag = @{
        Type           = $Type
        ActiveQuickSet = $null
        OriginalTitle  = if ($ArrayItemHeader) { $Title } else { $null }
        ArrayItem      = $ArrayItemHeader
        IsDisabled     = $false
        IsLocked       = $false
    }

    $ContentHeaderBorderStack = New-BaseStackPanel @{
        Name        = $ContentHeaderBorderStackName
        Orientation = 'Vertical'
    }
    $ContentHeaderBorder.AddChild($ContentHeaderBorderStack)

    #region Header

    $ContentHeaderTitleBorder = New-BaseBorder @{
        Name            = $ContentHeaderTitleBorderName
        Margin          = 1
        BorderThickness = '0,0,0,2'
        BorderBrush     = 'Black'
    }
    # Double-click title bar toggles minimize/maximize
    $ContentHeaderTitleBorder.Add_MouseLeftButtonDown({
            param($s, $e)
            if ($e.ClickCount -eq 2) {
                $ParentBorder = Get-ParentWrapperBorder -Element $s -HeaderOnly
                if ($ParentBorder) {
                    $MinMaxButton = Get-WrapperOwnActionButton -Element $ParentBorder -Name $MinMaxButtonName
                    if ($MinMaxButton) {
                        Invoke-MinMaxButtonClick $MinMaxButton $e
                        $e.Handled = $true
                    }
                }
            }
        })
    Add-BaseStackPanelChild ([ref]$ContentHeaderBorderStack) ([ref]$ContentHeaderTitleBorder)

    $ContentHeaderTitleBorderDock = New-BaseDockPanel @{
        Name       = $ContentHeaderTitleBorderDockName
        Background = $ColorSequence[$Depth % $ColorSequence.Count]
    }
    Add-BaseStackPanelChild ([ref]$ContentHeaderTitleBorder) ([ref]$ContentHeaderTitleBorderDock)

    $ContentHeaderTitleBorderDockStack = New-BaseStackPanel @{
        Name                = $ContentHeaderTitleBorderDockStackName
        HorizontalAlignment = 'Left'
        VerticalAlignment   = 'Center'
        Orientation         = 'Horizontal'
    }
    Add-BaseStackPanelChild ([ref]$ContentHeaderTitleBorderDock) ([ref]$ContentHeaderTitleBorderDockStack)

    $HeaderTitleValues = @{
        Margin              = 2
        Text                = $Title
        Name                = $ContentHeaderTitleValueName
        FontSize            = $FontSizes.$WrapperType
        Foreground          = $HeaderTitleMaximizedForeground
        HorizontalAlignment = 'Center'
        VerticalAlignment   = 'Center'
        FontWeight          = 'Bold'
    }

    if (-not $ArrayItemHeader) {
        $HeaderTitle = New-BaseTextBlock $HeaderTitleValues
    }
    else {
        $HeaderTitle = New-BaseTextBox $HeaderTitleValues
        $HeaderTitle.MinWidth = 50
        $HeaderTitle.Background = 'Transparent'
        $HeaderTitle.BorderBrush = 'Transparent'
    }
    Add-BaseStackPanelChild ([ref]$ContentHeaderTitleBorderDockStack) ([ref]$HeaderTitle)

    $HeaderDescription = New-BaseTextBlock @{
        Margin              = 2
        Text                = $Description
        Name                = $ContentHeaderDescriptionValueName
        FontSize            = $FontSizes.Description
        Foreground          = $HeaderDescriptionMaximizedForeground
        HorizontalAlignment = 'Center'
        VerticalAlignment   = 'Center'
    }
    Add-BaseStackPanelChild ([ref]$ContentHeaderTitleBorderDockStack) ([ref]$HeaderDescription)

    #endregion Header

    #region Buttons

    $ContentHeaderButtonMenu = New-BaseMenu @{
        Name                = $MenuName
        Background          = 'Transparent'
        VerticalAlignment   = 'Center'
        HorizontalAlignment = 'Right'
        Cursor              = 'Hand'
    }

    $MinMaxButton = New-MinMaxButton
    Add-BaseMenuChild ([ref]$ContentHeaderButtonMenu) ([ref]$MinMaxButton) 0
    $TriggerButton = New-MenuTriggerButton -ActionFrom $ContentHeaderBorderName
    Add-BaseDockPanelChild ([ref]$ContentHeaderTitleBorderDock) ([ref]$TriggerButton) 'Right'
    Add-BaseDockPanelChild ([ref]$ContentHeaderTitleBorderDock) ([ref]$ContentHeaderButtonMenu) 'Right'

    #endregion Buttons

    # Search Bar (Deferred/Lazy initialization via Get-OrCreateSearchBar)
    $ContentHeaderBorder.Tag.SearchBar = $null
    $ContentHeaderBorder.Tag.Menu = $ContentHeaderButtonMenu
    $ContentHeaderBorder.Tag.Depth = $Depth

    # Content Slot
    $ContentSlot = New-BaseStackPanel @{
        Name       = $ContentSlotElementName
        Background = $ColorSequence[ ($Depth + 1) % $ColorSequence.Count ]
    }
    $ContentHeaderBorderStack.AddChild($ContentSlot)
    $ContentHeaderBorder.Tag.ContentSlot = $ContentSlot

    # MiniHeader Setting Differences
    if ($WrapperType -eq 'MiniHeader') {
        $ContentHeaderBorder.Margin = 1.5
        $ContentHeaderBorder.BorderThickness = 1.5
        $ContentHeaderTitleBorder.BorderThickness = '0,0,0,1.5'
        $ContentHeaderTitleBorder.BorderBrush = 'White'
        $MinMaxButton.Header = $MinMaxButtonMaxedIcon
        $ContentSlot.Visibility = 'Collapsed'
    }

    $ReturnValue = $ContentHeaderBorder
    Stop-FunctionMeasurement -FunctionName 'New-ContentHeader'
    return $ReturnValue
} # function New-ContentHeader

#endregion #3 Content Wrapper Elements

#endregion #2 Content Wrappers

#region #2 Content Controls

#region #3 Content Controls Processes

function Invoke-ConstructButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-ConstructButtonClick'
    if ($s.Header -eq ($ConstructButtonHeader + ' All')) {
        $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
        $Constructs = Find-ObjectWhere -Object $ContentHeaderBorder -FindWhere { $_.Name -eq $ConstructName }
        :Constructs foreach ($Construct in $Constructs) {
            Build-Object -Object ([ref]$Construct)
        } # Constructs
    }
    else {
        Build-Object -Object ([ref]$s)
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-ConstructButtonClick'
} # function Invoke-ConstructButtonClick

function New-TypeContent {
    param(
        [ValidateSet('Header', 'MiniHeader', 'Border', 'None')]
        [string]$WrapperType = 'Header',
        [Type]$Type,
        [string]$Title = $Type.Name.TrimEnd('[]'),
        [string]$Description = $Type.Name,
        [ValidateSet('ArrayItem', 'Array', 'None')]
        [string]$ArrayType = 'None',
        [int]$Index = 0,
        [int]$Depth = 0
    )
    Start-FunctionMeasurement -FunctionName 'New-TypeContent'
    $ConstructArray = $False

    if ($Type.IsArray) {
        $TargetType = $Type.GetElementType()
        $ArrayType = 'Array'
    }
    else {
        $TargetType = $Type
    }

    $Content = :TypeSwitch switch ($Type.FullName.TrimEnd('[]')) {
        'System.Object' { return $null }
        { ($Type.IsArray -and $Type.GetElementType().IsEnum) -or $Type.IsEnum } {
            New-ContentEnum -EnumType $TargetType
        }
        'System.String' {
            if ($PasswordFields -contains $Title) { New-ContentPassword }
            else { New-ContentString }
        }
        { $_ -like 'System.Int*' -or $_ -like 'System.UInt*' -or @('System.Single', 'System.Double', 'System.Decimal') -contains $_ } {
            New-ContentNumber -TargetType $TargetType
        }
        'System.Boolean' { New-ContentBoolean }
        'System.DateTime' { New-ContentDateTime }
        'System.Char' { New-ContentChar }
        default {
            if ($Type.IsArray) {
                $WrapperType = 'Header'
                $ConstructArray = $True
            }
            else {
                $Parameters = Get-TypeConstructors -Type $TargetType
                $StackPanel = New-BaseStackPanel @{
                    Name                = $ConstructName
                    Orientation         = 'Vertical'
                    HorizontalAlignment = 'Stretch'
                }
                $UniqueParameters = $Parameters | Get-UniqueByProperty -Property 'Name'
                :UniqueParameters foreach ($Parameter in $UniqueParameters.List) {
                    $ParameterUIElement = New-TypeContent -WrapperType 'MiniHeader' -Type $Parameter.Type -Title $Parameter.Name -Description $Parameter.Type.split('.')[-1] -Depth ($Depth + 1)
                    if ($null -ne $ParameterUIElement) {
                        $StackPanel.AddChild($ParameterUIElement)
                    }
                } # UniqueParameters
                $StackPanel

                $WrapperType = 'Header'
            }
        }
    }

    $ContentWrapper = New-ContentWrapper -WrapperType $WrapperType -Type $Type -Title $Title -Description $Description -ArrayItem ($ArrayType -eq 'ArrayItem') -Depth $Depth

    if ($null -ne $ContentWrapper) { $Top = $ContentWrapper }
    elseif ($null -ne $Content) { $Top = $Content }

    if ($ArrayType -eq 'ArrayItem') {
        Add-ArrayFunctionality -ArrayItemType 'ArrayItem' -Wrapper ([ref]$Top) -Index $Index -WrapperType $WrapperType
        Add-DragDropLogic ([ref]$Top)
    }
    elseif ($Type.IsArray) {
        if (-not ($Top.Tag -is [hashtable])) { $Top.Tag = @{} }
        $Top.Tag.TargetType = $TargetType
        Add-ArrayFunctionality -ArrayItemType 'Array' -Wrapper ([ref]$Top) -WrapperType $WrapperType
    }

    # Must be placed after Add-ArrayFunctionality because we're using a DockPanel for Content with a 'Border' Wrapper. Last Item Fills the space and we want the Content to do that.
    if ($null -ne $ContentWrapper -and $null -ne $Content -and -not $Type.IsArray) {
        Add-ContentToWrapper ([ref]$ContentWrapper) ([ref]$Content)
    }

    $IsConstruct = ($null -ne $Content -and $Content.Name -eq $ConstructName) -or $ConstructArray
    $IsArrayType = $Type.IsArray -or ($ArrayType -eq 'Array')

    # Record the wrapper's kind and key elements so QuickSet code reads them instead of searching.
    # IsConstruct is only a real Construct panel; an array of constructable objects is an array.
    if ($null -ne $Top -and ($null -eq $Top.Tag -or $Top.Tag -is [hashtable])) {
        if ($null -eq $Top.Tag) { $Top.Tag = @{} }
        $Top.Tag.IsArray = [bool]$Type.IsArray
        $Top.Tag.IsConstruct = ($null -ne $Content -and $Content.Name -eq $ConstructName)
        $Top.Tag.Construct = if ($Top.Tag.IsConstruct) { $Content } else { $null }
        if (-not ($Top.Tag.ContainsKey('ContentSlot') -and $Top.Tag.ContentSlot)) {
            $Top.Tag.ContentSlot = Find-ObjectWhere -Object ([ref]$Top) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 0 -DepthWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -FindMax 1
        }
        if (-not $Top.Tag.ContainsKey('AddButton')) { $Top.Tag.AddButton = $null }
        $Top.Tag.Content = if ($null -ne $Content -and $Content.Name -eq $ContentElementName) { $Content } else { $null }
        $Top.Tag.CustomDateTimePicker = if ($null -ne $Content -and $Content.Name -eq $CustomDateTimePickerName) { $Content } else { $null }
        $Top.Tag.Depth = $Depth
    }

    if (-not $IsArrayType -and $ArrayType -ne 'ArrayItem') {
        Set-WrapperActionButtonsLazy -Wrapper ([ref]$Top) -ActionFrom $Top.Name -IncludeSearch -IsConstruct:$IsConstruct
    }

    if ($Content.Name -eq $ConstructName -or $ConstructArray) {
        $ConstructButton = New-BaseMenuItem @{
            Name    = $ContentWrapper.Value.Name + $ConstructButtonNameSuffix
            Header  = $(if ($ConstructArray) { $ConstructButtonHeader + ' All' } else { $ConstructButtonIcon })
            Icon    = $(if ($ConstructArray) { $ConstructButtonIcon } else { $null })
            ToolTip = $(if ($ConstructArray) { $ConstructButtonAllToolTip } else { $ConstructButtonToolTip })
        }

        $ConstructButton.Add_Click({ param($s, $e) Invoke-ConstructButtonClick $s $e })

        if ($ConstructArray) {
            Add-LockableButtonToolTip -Button $ConstructButton -ToolTip $ConstructButtonAllToolTip
            Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$(New-BaseSeparator)) 0
            Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$ConstructButton) 0
        }
        else {
            Add-CustomMenuChild ([ref]$Top) ([ref]$ConstructButton)
        }
    }

    if ($IsArrayType) {
        Update-ArrayButtonsState -Wrapper $Top
    }

    $ReturnValue = $Top
    Stop-FunctionMeasurement -FunctionName 'New-TypeContent'
    return $ReturnValue
} # function New-TypeContent

function New-ContentWrapper {
    param(
        [ValidateSet('Header', 'MiniHeader', 'Border', 'None')]
        [string]$WrapperType = 'Header',
        [Type]$Type,
        [string]$Title = $Type.Name.TrimEnd('[]'),
        [string]$Description = $Type.Name,
        [bool]$ArrayItem = $false,
        [int]$Depth = 0
    )
    Start-FunctionMeasurement -FunctionName 'New-ContentWrapper'

    if ($WrapperType -eq 'None') { return $null }

    if ($WrapperType -eq 'Border') {
        $Border = New-BaseBorder @{
            Name            = $ContentBorderName
            Margin          = 1
            BorderThickness = 1
            BorderBrush     = 'Black'
        }
        $Border.Tag = @{
            Type           = $Type
            ActiveQuickSet = $null
            ArrayItem      = $ArrayItem
            IsDisabled     = $false
            IsLocked       = $false
        }

        $BorderDock = New-BaseDockPanel @{
            Name       = $ContentBorderDockName
            Background = $ColorSequence[$Depth % $ColorSequence.Count]
        }
        $Border.AddChild($BorderDock) | Out-Null

        $BorderDockStack = New-BaseStackPanel @{
            Name                = $ContentSlotElementName
            Orientation         = 'Vertical'
            HorizontalAlignment = 'Stretch'
        }
        $BorderDock.AddChild($BorderDockStack) | Out-Null
        $Border.Tag.ContentSlot = $BorderDockStack
        $Border.Tag.Depth = $Depth

        Stop-FunctionMeasurement -FunctionName 'New-ContentWrapper'
        return $Border
    }

    $Wrapper = New-ContentHeader -TitleType $WrapperType -Title $Title -Description $Description -Type $Type -ArrayItemHeader $ArrayItem -Depth $Depth
    $ReturnValue = $Wrapper
    Stop-FunctionMeasurement -FunctionName 'New-ContentWrapper'
    return $ReturnValue

} # function New-ContentWrapper

function Add-ArrayFunctionality {
    param(
        [ValidateSet('Array', 'ArrayItem')]
        $ArrayItemType,
        [ValidateSet('Header', 'MiniHeader', 'Border', 'None')]
        $WrapperType,
        [ref]$Wrapper,
        $Index
    )
    Start-FunctionMeasurement -FunctionName "Add-ArrayFunctionality"
    if ($ArrayItemType -eq 'Array') {
        # Button: Add
        $TargetType = if ($Wrapper.Value.Tag -is [hashtable] -and $Wrapper.Value.Tag.ContainsKey('TargetType')) {
            $Wrapper.Value.Tag.TargetType
        }
        else {
            $Wrapper.Value.DataContext
        }
        $AddButton = New-AddArrayItemButton -Type $TargetType
        Add-CustomMenuChild $Wrapper ([ref]$AddButton)

        # Remember the Add button so QuickSet code can grow the array without searching for it
        if (-not ($Wrapper.Value.Tag -is [hashtable])) { $Wrapper.Value.Tag = @{} }
        $Wrapper.Value.Tag.AddButton = $AddButton

        # Buttons: QuickSet, Sort, Search, Lock, Random, Clear, Enable/Disable, Delete
        Set-WrapperActionButtonsLazy -Wrapper $Wrapper -ActionFrom $Wrapper.Value.Name -IsBatch -IncludeSearch -TargetType $TargetType
    }
    elseif ($ArrayItemType -eq 'ArrayItem') {
        if (@('Header', 'MiniHeader') -contains $WrapperType) {
            $ContentBorderDock = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
        }
        elseif ($WrapperType -eq 'Border') {
            $ContentBorderDock = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentBorderDockName } -FindMax 1
            $TriggerButton = New-MenuTriggerButton -ActionFrom $Wrapper.Value.Name
            $ContentBorderDock.Children.Insert(0, $TriggerButton)
            [System.Windows.Controls.DockPanel]::SetDock($TriggerButton, 'Right')
        }
        else {
            Write-Host '{Add-ArrayFunctionality} $_' -ForegroundColor Red
        }

        #region Array Item Controls

        $DragHandle = New-DragHandle -WrapperName $Wrapper.Value.Name
        $IndexBlock = New-IndexBox -WrapperName $Wrapper.Value.Name -Index ($Index + 1)
        if (-not ($Wrapper.Value.Tag -is [hashtable])) { $Wrapper.Value.Tag = @{} }
        $Wrapper.Value.Tag.IndexBox = $IndexBlock
        $ArrayItemStack = New-BaseStackPanel @{
            Name                = $ArrayItemStackName
            Orientation         = 'Horizontal'
            HorizontalAlignment = 'Stretch'
        }
        $ArrayItemStack.AddChild($DragHandle) | Out-Null
        $ArrayItemStack.AddChild($IndexBlock) | Out-Null

        $ContentBorderDock.Children.Insert(0, $ArrayItemStack)

        #endregion Array Item Controls

        #region Array Item Buttons

        # Header vs Border configuration
        if ($WrapperType -eq 'Border') {
            if (-not ($Wrapper.Value.Tag -is [hashtable])) { $Wrapper.Value.Tag = @{} }
            $Wrapper.Value.Tag.ActionButtonsConfiguration = @{
                ActionFrom              = $Wrapper.Value.Name
                IsBatch                 = $false
                IsConstruct             = $false
                IncludeSearch           = $false
                IncludeArrayItemActions = $true
                TargetType              = $null
            }
            $Wrapper.Value.Tag.ActionButtonsPopulated = $false
        }
        else {
            $HasHeaderMenu = ($WrapperType -ne 'None')
            Set-WrapperActionButtonsLazy -Wrapper $Wrapper -ActionFrom $Wrapper.Value.Name -IncludeArrayItemActions -IncludeSearch:$HasHeaderMenu -IsConstruct:$HasHeaderMenu
        }

        #endregion Array Item Buttons
    }
    else {
        Write-Host "[Add-ArrayFunctionality] Unknown ArrayItemType: $ArrayItemType" -ForegroundColor Red
    }

    Stop-FunctionMeasurement -FunctionName "Add-ArrayFunctionality"
} # function Add-ArrayFunctionality

#endregion #3 Content Controls Processes

#region #3 Content Controls Actions

#region #4 Content Value

function Get-ContentValue {
    param($Object)
    Start-FunctionMeasurement -FunctionName "Get-ContentValue"

    Try {
        $ObjectName = $Object.GetType().Name
    }
    Catch {
        Write-Host "{Get-ContentValue} $_" -ForegroundColor Red
    }

    $Value = switch ($Object.GetType().Name) {
        'PasswordBox' { $Object.Password }
        'TextBox' { $Object.Text }
        'ComboBox' { $Object.SelectedItem }
        'Button' { $Object.Content }
        'MenuItem' { $Object.Header }
        'TextBlock' { $Object.Text }
        'RichTextBox' {
            $Range = New-Object System.Windows.Documents.TextRange($Object.Document.ContentStart, $Object.Document.ContentEnd)
            $Range.Text.TrimEnd("`r`n")
        }
        'Grid' {
            if ($Object.Name -eq $CustomDateTimePickerName) {
                $DateBox = Find-ObjectWhere -Object ([ref]$Object) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
                if ($DateBox) { $DateBox.Text }
            }
        }
    }

    if ($null -ne $Value) {
        if ($Value.GetType().IsEnum) {
            Stop-FunctionMeasurement -FunctionName "Get-ContentValue"
            return $Value.ToString()
        }
        if ($Value -is [string] -and [string]::IsNullOrEmpty($Value)) {
            return $null
        }
        Stop-FunctionMeasurement -FunctionName "Get-ContentValue"
        return $Value
    }
    else { return $null }
} # function Get-ContentValue

#endregion #4 Content Value

#region #4 QuickSet

function New-QuickSetModalDialog {
    param(
        [string]$Title = 'QuickSet',
        [int]$Width = 380,
        [int]$Height = 160,
        [Parameter(Mandatory = $true)]
        [System.Windows.FrameworkElement[]]$ContentControls,
        [string]$AffirmativeButtonText = 'OK',
        [string]$AlternativeButtonText = $null,
        [string]$NegativeButtonText = 'Cancel',
        [string]$AuxiliaryButtonText = $null,
        [scriptblock]$AuxiliaryResultProvider = $null,
        [scriptblock]$ResultProvider,
        [scriptblock]$OnLoadedCallback
    )
    Start-FunctionMeasurement -FunctionName 'New-QuickSetModalDialog'

    $Dialog = New-Object System.Windows.Window
    $Dialog.Title = $Title
    $Dialog.Width = $Width
    $Dialog.Height = $Height
    $Dialog.ResizeMode = 'NoResize'
    $Dialog.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#2E273D')
    if ($FontFamily) {
        $Dialog.FontFamily = New-Object System.Windows.Media.FontFamily($FontFamily)
    }

    $OwnerWindow = $null
    if ($BaseWindow -and ($BaseWindow -is [System.Windows.Window]) -and $BaseWindow.IsVisible) {
        $OwnerWindow = $BaseWindow
    }
    elseif ([System.Windows.Application]::Current -and [System.Windows.Application]::Current.MainWindow) {
        $OwnerWindow = [System.Windows.Application]::Current.MainWindow
    }
    if ($OwnerWindow) {
        $Dialog.Owner = $OwnerWindow
        $Dialog.WindowStartupLocation = 'CenterOwner'
    }
    else {
        $Dialog.WindowStartupLocation = 'CenterScreen'
    }

    $Dock = New-Object System.Windows.Controls.DockPanel
    $Dock.Margin = New-Object System.Windows.Thickness(12)
    $Dialog.Content = $Dock

    $ButtonStack = New-Object System.Windows.Controls.StackPanel
    $ButtonStack.Orientation = 'Horizontal'
    $ButtonStack.HorizontalAlignment = 'Right'
    $ButtonStack.Margin = New-Object System.Windows.Thickness(0, 10, 0, 0)
    [System.Windows.Controls.DockPanel]::SetDock($ButtonStack, 'Bottom')
    $Dock.Children.Add($ButtonStack) | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($AuxiliaryButtonText)) {
        $AuxiliaryButtonWidth = if ($AuxiliaryButtonText.Length -gt 8) { 100 } else { 70 }
        $AuxiliaryButton = New-BaseButton @{
            Content         = $AuxiliaryButtonText
            Width           = $AuxiliaryButtonWidth
            Height          = 26
            Margin          = '0,0,8,0'
            Background      = '#504368'
            Foreground      = '#EDEAFA'
            BorderBrush     = '#8879A1'
            BorderThickness = 1
            Cursor          = 'Hand'
        }
        $ButtonStack.Children.Add($AuxiliaryButton) | Out-Null
    }

    $AffirmativeButtonWidth = if ($AffirmativeButtonText.Length -gt 8) { 90 } else { 70 }
    $AffirmativeButton = New-BaseButton @{
        Content         = $AffirmativeButtonText
        Width           = $AffirmativeButtonWidth
        Height          = 26
        Margin          = '0,0,8,0'
        Background      = '#504368'
        Foreground      = '#EDEAFA'
        BorderBrush     = '#8879A1'
        BorderThickness = 1
        Cursor          = 'Hand'
        IsDefault       = $true
    }
    $ButtonStack.Children.Add($AffirmativeButton) | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($AlternativeButtonText)) {
        $AlternativeButtonWidth = if ($AlternativeButtonText.Length -gt 8) { 90 } else { 70 }
        $AlternativeButton = New-BaseButton @{
            Content         = $AlternativeButtonText
            Width           = $AlternativeButtonWidth
            Height          = 26
            Margin          = '0,0,8,0'
            Background      = '#504368'
            Foreground      = '#EDEAFA'
            BorderBrush     = '#8879A1'
            BorderThickness = 1
            Cursor          = 'Hand'
        }
        $ButtonStack.Children.Add($AlternativeButton) | Out-Null
    }

    $NegativeButtonWidth = if ($NegativeButtonText.Length -gt 8) { 90 } else { 70 }
    $NegativeButton = New-BaseButton @{
        Content         = $NegativeButtonText
        Width           = $NegativeButtonWidth
        Height          = 26
        Background      = 'Transparent'
        Foreground      = '#EDEAFA'
        BorderBrush     = '#7A6E94'
        BorderThickness = 1
        Cursor          = 'Hand'
        IsCancel        = $true
    }
    $ButtonStack.Children.Add($NegativeButton) | Out-Null

    foreach ($Control in $ContentControls) {
        $Dock.Children.Add($Control) | Out-Null
    }

    $DialogResultContainer = [PSCustomObject]@{ Value = $null }

    if (-not [string]::IsNullOrWhiteSpace($AuxiliaryButtonText)) {
        $AuxiliaryButton.Add_Click({
                if ($AuxiliaryResultProvider) {
                    $ResultValue = & $AuxiliaryResultProvider
                    if ($null -eq $ResultValue) { return }
                    $DialogResultContainer.Value = $ResultValue
                }
                else {
                    $DialogResultContainer.Value = 'Auxiliary'
                }
                $Dialog.DialogResult = $true
                $Dialog.Close()
            })
    }

    $AffirmativeButton.Add_Click({
            if ($AlternativeButtonText) {
                $DialogResultContainer.Value = 'Save'
            }
            elseif ($ResultProvider) {
                $ResultValue = & $ResultProvider
                if ($null -eq $ResultValue) { return }
                $DialogResultContainer.Value = $ResultValue
            }
            else {
                $DialogResultContainer.Value = $true
            }
            $Dialog.DialogResult = $true
            $Dialog.Close()
        })

    if (-not [string]::IsNullOrWhiteSpace($AlternativeButtonText)) {
        $AlternativeButton.Add_Click({
                $DialogResultContainer.Value = 'Discard'
                $Dialog.DialogResult = $false
                $Dialog.Close()
            })
    }

    $NegativeButton.Add_Click({
            $DialogResultContainer.Value = if ($AlternativeButtonText) { 'Cancel' } elseif ($AffirmativeButtonText -eq 'Yes') { $false } else { $null }
            $Dialog.DialogResult = $false
            $Dialog.Close()
        })

    if ($OnLoadedCallback) {
        $Dialog.Add_Loaded($OnLoadedCallback)
    }

    $null = $Dialog.ShowDialog()
    $ReturnValue = $DialogResultContainer.Value
    Stop-FunctionMeasurement -FunctionName 'New-QuickSetModalDialog'
    return $ReturnValue
} # function New-QuickSetModalDialog


function Show-QuickSetInputDialog {
    param(
        [string]$Title = 'QuickSet',
        [string]$Prompt = 'Enter name:',
        [string]$DefaultValue = ''
    )
    Start-FunctionMeasurement -FunctionName "Show-QuickSetInputDialog"

    $PromptLabel = New-BaseTextBlock @{
        Text       = $Prompt
        Foreground = '#EDEAFA'
        FontSize   = 11
        Margin     = '0,0,0,6'
    }
    [System.Windows.Controls.DockPanel]::SetDock($PromptLabel, 'Top')

    $InputBox = New-BaseTextBox @{
        Text              = $DefaultValue
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontSize          = 11
        Padding           = '3'
        VerticalAlignment = 'Center'
    }

    return (New-QuickSetModalDialog `
            -Title $Title `
            -Width 380 `
            -Height 160 `
            -ContentControls @($PromptLabel, $InputBox) `
            -AffirmativeButtonText 'OK' `
            -NegativeButtonText 'Cancel' `
            -ResultProvider { $InputBox.Text } `
            -OnLoadedCallback {
            $InputBox.Focus() | Out-Null
            $InputBox.SelectAll()
        })
    Stop-FunctionMeasurement -FunctionName "Show-QuickSetInputDialog"
} # function Show-QuickSetInputDialog


function Show-QuickSetConfirmDialog {
    param(
        [string]$Title = 'Confirm',
        [string]$Message = 'Are you sure?'
    )
    Start-FunctionMeasurement -FunctionName "Show-QuickSetConfirmDialog"

    $MsgBlock = New-BaseTextBlock @{
        Text              = $Message
        Foreground        = '#EDEAFA'
        FontSize          = 11
        TextWrapping      = 'Wrap'
        VerticalAlignment = 'Center'
    }

    $Result = New-QuickSetModalDialog `
        -Title $Title `
        -Width 380 `
        -Height 150 `
        -ContentControls @($MsgBlock) `
        -AffirmativeButtonText 'Yes' `
        -NegativeButtonText 'No' `
        -ResultProvider { $true }

    if ($Result -eq $true) {
        return $true
    }
    Stop-FunctionMeasurement -FunctionName "Show-QuickSetConfirmDialog"
    return $false
} # function Show-QuickSetConfirmDialog

function Show-QuickSetSavePromptDialog {
    param(
        [string]$Title = 'QuickSet - Save Changes',
        [string]$Message = 'Do you want to save changes before closing?'
    )
    Start-FunctionMeasurement -FunctionName "Show-QuickSetSavePromptDialog"

    $MsgBlock = New-BaseTextBlock @{
        Text              = $Message
        Foreground        = '#EDEAFA'
        FontSize          = 11
        TextWrapping      = 'Wrap'
        VerticalAlignment = 'Center'
    }

    $Result = New-QuickSetModalDialog `
        -Title $Title `
        -Width 420 `
        -Height 150 `
        -ContentControls @($MsgBlock) `
        -AffirmativeButtonText 'Save' `
        -AlternativeButtonText 'Do Not Save' `
        -NegativeButtonText 'Cancel'

    if ($null -eq $Result) {
        $Result = 'Cancel'
    }

    Stop-FunctionMeasurement -FunctionName "Show-QuickSetSavePromptDialog"
    return $Result
} # function Show-QuickSetSavePromptDialog

function Show-RandomValuesConfigurationDialog {
    param(
        $Wrapper = $null
    )
    Start-FunctionMeasurement -FunctionName 'Show-RandomValuesConfigurationDialog'
    $TargetWrapper = if ($Wrapper) { Resolve-TargetElement $Wrapper } else { $null }
    $CurrentConfiguration = Get-RandomValuesConfiguration -Wrapper $TargetWrapper
    $CurrentMode = if ($CurrentConfiguration.ContainsKey('GenerationMode') -and $CurrentConfiguration.GenerationMode -eq 'RegularExpression') { 'RegularExpression' } else { 'CharacterSets' }
    $CurrentRegularExpressionPattern = if ($CurrentConfiguration.ContainsKey('RegularExpressionPattern') -and -not [string]::IsNullOrWhiteSpace($CurrentConfiguration.RegularExpressionPattern)) { [string]$CurrentConfiguration.RegularExpressionPattern } else { '\(\d{3}\) \d{3}-\d{4}' }

    $MainStackPanel = New-BaseStackPanel @{
        Orientation = 'Vertical'
        Margin      = 5
    }

    # Mode Selection (RadioButtons)
    $ModeDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,0,0,8'
    }
    $ModeLabel = New-BaseTextBlock @{
        Text              = 'Mode: '
        Foreground        = '#EDEAFA'
        FontSize          = 11
        FontWeight        = 'Bold'
        VerticalAlignment = 'Center'
        Width             = 50
    }
    [System.Windows.Controls.DockPanel]::SetDock($ModeLabel, 'Left')
    $ModeDock.Children.Add($ModeLabel) | Out-Null

    $ModeRadioStack = New-BaseStackPanel @{
        Orientation       = 'Horizontal'
        VerticalAlignment = 'Center'
    }
    $ModeCharacterSetsRadioButton = New-BaseRadioButton @{
        Content           = 'Character Sets'
        GroupName         = 'GenerationModeGroup'
        IsChecked         = ($CurrentMode -eq 'CharacterSets')
        FontSize          = 11
        Margin            = '0,0,20,0'
        VerticalAlignment = 'Center'
    }
    $ModeRadioStack.Children.Add($ModeCharacterSetsRadioButton) | Out-Null

    $ModeRegularExpressionRadioButton = New-BaseRadioButton @{
        Content           = 'Regular Expression'
        GroupName         = 'GenerationModeGroup'
        IsChecked         = ($CurrentMode -eq 'RegularExpression')
        FontSize          = 11
        VerticalAlignment = 'Center'
    }
    $ModeRadioStack.Children.Add($ModeRegularExpressionRadioButton) | Out-Null
    $ModeDock.Children.Add($ModeRadioStack) | Out-Null
    $MainStackPanel.Children.Add($ModeDock) | Out-Null

    # Character Sets Section Container
    $CharacterSetContainer = New-BaseStackPanel @{
        Orientation = 'Vertical'
        Visibility  = if ($CurrentMode -eq 'CharacterSets') { 'Visible' } else { 'Collapsed' }
    }

    # Length row
    $LengthDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,0,0,8'
    }
    $LengthLabel = New-BaseTextBlock @{
        Text              = 'Length (characters): '
        Foreground        = '#EDEAFA'
        FontSize          = 11
        VerticalAlignment = 'Center'
        Width             = 140
    }
    [System.Windows.Controls.DockPanel]::SetDock($LengthLabel, 'Left')
    $LengthDock.Children.Add($LengthLabel) | Out-Null

    $LengthTextBox = New-BaseTextBox @{
        Text              = $CurrentConfiguration.Length.ToString()
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontSize          = 11
        Padding           = '3'
        VerticalAlignment = 'Center'
    }
    $LengthDock.Children.Add($LengthTextBox) | Out-Null
    $CharacterSetContainer.Children.Add($LengthDock) | Out-Null

    # Character Types Header
    $TypesHeaderDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,4,0,4'
    }

    $TypesHeaderLabel = New-BaseTextBlock @{
        Text              = 'Character Types:'
        Foreground        = '#EDEAFA'
        FontSize          = 11
        FontWeight        = 'Bold'
        VerticalAlignment = 'Center'
    }
    $TypesHeaderDock.Children.Add($TypesHeaderLabel) | Out-Null
    $CharacterSetContainer.Children.Add($TypesHeaderDock) | Out-Null

    # Reset Button Factory Helper
    $NewResetButton = {
        param(
            [string]$ToolTipText,
            [scriptblock]$OnClickAction
        )
        $Button = New-BaseButton @{
            Content           = '↺'
            ToolTip           = $ToolTipText
            Background        = 'Transparent'
            Foreground        = '#C4B8DE'
            BorderBrush       = 'Transparent'
            BorderThickness   = 0
            Cursor            = 'Hand'
            Width             = 22
            Height            = 22
            Padding           = 0
            FontSize          = 14
            FontWeight        = 'Bold'
            VerticalAlignment = 'Center'
            Margin            = '4,0,0,0'
        }
        $Button.Add_MouseEnter({
                param($s, $e)
                $s.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#FFFFFF')
            })
        $Button.Add_MouseLeave({
                param($s, $e)
                $s.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#C4B8DE')
            })
        $Button.Add_Click($OnClickAction)
        return $Button
    }

    # Uppercase Row
    $UppercaseDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,2,0,2'
    }
    $UppercaseCheckBox = New-BaseCheckBox @{
        Content           = 'Uppercase:'
        IsChecked         = [bool]$CurrentConfiguration.IncludeUppercase
        Width             = 95
        FontSize          = 11
        VerticalAlignment = 'Center'
    }
    [System.Windows.Controls.DockPanel]::SetDock($UppercaseCheckBox, 'Left')
    $UppercaseDock.Children.Add($UppercaseCheckBox) | Out-Null

    $UppercaseResetButton = & $NewResetButton -ToolTipText 'Reset uppercase characters to default' -OnClickAction {
        $UppercaseTextBox.Text = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        & $UpdatePreview
    }
    [System.Windows.Controls.DockPanel]::SetDock($UppercaseResetButton, 'Right')
    $UppercaseDock.Children.Add($UppercaseResetButton) | Out-Null

    $UppercaseTextBox = New-BaseTextBox @{
        Text              = if ($null -ne $CurrentConfiguration.UppercaseCharacters) { [string]$CurrentConfiguration.UppercaseCharacters } else { 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' }
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontSize          = 11
        FontFamily        = $FontFamily
        Padding           = '3'
        Margin            = '4,0,0,0'
        VerticalAlignment = 'Center'
    }
    $UppercaseDock.Children.Add($UppercaseTextBox) | Out-Null
    $CharacterSetContainer.Children.Add($UppercaseDock) | Out-Null

    # Lowercase Row
    $LowercaseDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,2,0,2'
    }
    $LowercaseCheckBox = New-BaseCheckBox @{
        Content           = 'Lowercase:'
        IsChecked         = [bool]$CurrentConfiguration.IncludeLowercase
        Width             = 95
        FontSize          = 11
        VerticalAlignment = 'Center'
    }
    [System.Windows.Controls.DockPanel]::SetDock($LowercaseCheckBox, 'Left')
    $LowercaseDock.Children.Add($LowercaseCheckBox) | Out-Null

    $LowercaseResetButton = & $NewResetButton -ToolTipText 'Reset lowercase characters to default' -OnClickAction {
        $LowercaseTextBox.Text = 'abcdefghijklmnopqrstuvwxyz'
        & $UpdatePreview
    }
    [System.Windows.Controls.DockPanel]::SetDock($LowercaseResetButton, 'Right')
    $LowercaseDock.Children.Add($LowercaseResetButton) | Out-Null

    $LowercaseTextBox = New-BaseTextBox @{
        Text              = if ($null -ne $CurrentConfiguration.LowercaseCharacters) { [string]$CurrentConfiguration.LowercaseCharacters } else { 'abcdefghijklmnopqrstuvwxyz' }
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontSize          = 11
        FontFamily        = $FontFamily
        Padding           = '3'
        Margin            = '4,0,0,0'
        VerticalAlignment = 'Center'
    }
    $LowercaseDock.Children.Add($LowercaseTextBox) | Out-Null
    $CharacterSetContainer.Children.Add($LowercaseDock) | Out-Null

    # Numbers Row
    $NumbersDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,2,0,2'
    }
    $NumbersCheckBox = New-BaseCheckBox @{
        Content           = 'Numbers:'
        IsChecked         = [bool]$CurrentConfiguration.IncludeNumbers
        Width             = 95
        FontSize          = 11
        VerticalAlignment = 'Center'
    }
    [System.Windows.Controls.DockPanel]::SetDock($NumbersCheckBox, 'Left')
    $NumbersDock.Children.Add($NumbersCheckBox) | Out-Null

    $NumbersResetButton = & $NewResetButton -ToolTipText 'Reset number characters to default' -OnClickAction {
        $NumbersTextBox.Text = '0123456789'
        & $UpdatePreview
    }
    [System.Windows.Controls.DockPanel]::SetDock($NumbersResetButton, 'Right')
    $NumbersDock.Children.Add($NumbersResetButton) | Out-Null

    $NumbersTextBox = New-BaseTextBox @{
        Text              = if ($null -ne $CurrentConfiguration.NumberCharacters) { [string]$CurrentConfiguration.NumberCharacters } else { '0123456789' }
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontSize          = 11
        FontFamily        = $FontFamily
        Padding           = '3'
        Margin            = '4,0,0,0'
        VerticalAlignment = 'Center'
    }
    $NumbersDock.Children.Add($NumbersTextBox) | Out-Null
    $CharacterSetContainer.Children.Add($NumbersDock) | Out-Null

    # Symbols Row
    $SymbolsDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,2,0,2'
    }
    $SymbolsCheckBox = New-BaseCheckBox @{
        Content           = 'Symbols:'
        IsChecked         = [bool]$CurrentConfiguration.IncludeSymbols
        Width             = 95
        FontSize          = 11
        VerticalAlignment = 'Center'
    }
    [System.Windows.Controls.DockPanel]::SetDock($SymbolsCheckBox, 'Left')
    $SymbolsDock.Children.Add($SymbolsCheckBox) | Out-Null

    $SymbolsResetButton = & $NewResetButton -ToolTipText 'Reset symbol characters to default' -OnClickAction {
        $SymbolsTextBox.Text = '!@#$%^&*()_+-=[]{}|;:,.<>?'
        & $UpdatePreview
    }
    [System.Windows.Controls.DockPanel]::SetDock($SymbolsResetButton, 'Right')
    $SymbolsDock.Children.Add($SymbolsResetButton) | Out-Null

    $SymbolsTextBox = New-BaseTextBox @{
        Text              = if ($null -ne $CurrentConfiguration.SymbolCharacters) { [string]$CurrentConfiguration.SymbolCharacters } else { '!@#$%^&*()_+-=[]{}|;:,.<>?' }
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontSize          = 11
        FontFamily        = $FontFamily
        Padding           = '3'
        Margin            = '4,0,0,0'
        VerticalAlignment = 'Center'
    }
    $SymbolsDock.Children.Add($SymbolsTextBox) | Out-Null
    $CharacterSetContainer.Children.Add($SymbolsDock) | Out-Null

    $MainStackPanel.Children.Add($CharacterSetContainer) | Out-Null

    # Regular Expression Section Container
    $RegularExpressionContainer = New-BaseStackPanel @{
        Orientation = 'Vertical'
        Visibility  = if ($CurrentMode -eq 'RegularExpression') { 'Visible' } else { 'Collapsed' }
    }

    $RegexHeaderDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,4,0,4'
    }

    # Left: Label + Information Button
    $RegexTitleStack = New-BaseStackPanel @{
        Orientation       = 'Horizontal'
        VerticalAlignment = 'Center'
    }
    $RegexHeaderLabel = New-BaseTextBlock @{
        Text              = 'Regular Expression:'
        Foreground        = '#EDEAFA'
        FontSize          = 11
        FontWeight        = 'Bold'
        VerticalAlignment = 'Center'
    }
    $RegexTitleStack.Children.Add($RegexHeaderLabel) | Out-Null

    $RegexInfoButton = New-BaseButton @{
        Content           = 'ℹ'
        ToolTip           = "Supported Regular Expression Features:`n• Character classes: [a-z], [A-Z], [0-9], [aeiou]`n• Negated classes: [^0-9], [^a-z]`n• Shorthands: \d (digit), \w (word), \s (space), . (printable)`n• Quantifiers: {n}, {minimum,maximum}, ? (zero or one), * (zero or more), + (one or more)`n• Alternation: option1|option2|option3`n• Groups: (pattern)`n• Escaped characters: \., \-, \(, \), \[, \], \{, \}, \\, \|"
        Background        = 'Transparent'
        BorderBrush       = 'Transparent'
        BorderThickness   = 0
        Foreground        = '#87CEEB'
        Cursor            = 'Help'
        Width             = 20
        Height            = 20
        Padding           = 0
        FontSize          = 13
        FontWeight        = 'Bold'
        VerticalAlignment = 'Center'
        Margin            = '6,0,0,0'
    }
    $RegexTitleStack.Children.Add($RegexInfoButton) | Out-Null
    [System.Windows.Controls.DockPanel]::SetDock($RegexTitleStack, 'Left')
    $RegexHeaderDock.Children.Add($RegexTitleStack) | Out-Null

    # Right: Presets ComboBox
    $PresetDock = New-BaseDockPanel @{
        LastChildFill       = $true
        HorizontalAlignment = 'Right'
        VerticalAlignment   = 'Center'
    }
    $PresetLabel = New-BaseTextBlock @{
        Text              = 'Presets: '
        Foreground        = '#C4B8DE'
        FontSize          = 11
        VerticalAlignment = 'Center'
        Margin            = '0,0,4,0'
    }
    [System.Windows.Controls.DockPanel]::SetDock($PresetLabel, 'Left')
    $PresetDock.Children.Add($PresetLabel) | Out-Null

    $PresetComboBox = New-BaseComboBox @{
        Width             = 175
        Height            = 22
        FontSize          = 11
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        VerticalAlignment = 'Center'
    }

    $ComboBoxTemplateXaml = @"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                 xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                 TargetType="ComboBox">
    <Grid>
        <ToggleButton Name="ToggleButton"
                      Background="{TemplateBinding Background}"
                      Foreground="{TemplateBinding Foreground}"
                      BorderBrush="{TemplateBinding BorderBrush}"
                      BorderThickness="{TemplateBinding BorderThickness}"
                      Focusable="false"
                      IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                      ClickMode="Press">
            <ToggleButton.Template>
                <ControlTemplate TargetType="ToggleButton">
                    <Border Background="{TemplateBinding Background}"
                            BorderBrush="{TemplateBinding BorderBrush}"
                            BorderThickness="{TemplateBinding BorderThickness}"
                            CornerRadius="2">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition />
                                <ColumnDefinition Width="20" />
                            </Grid.ColumnDefinitions>
                            <Path Grid.Column="1"
                                  HorizontalAlignment="Center"
                                  VerticalAlignment="Center"
                                  Data="M 0 0 L 4 4 L 8 0 Z"
                                  Fill="#EDEAFA" />
                        </Grid>
                    </Border>
                </ControlTemplate>
            </ToggleButton.Template>
        </ToggleButton>
        <ContentPresenter Name="ContentSite"
                          IsHitTestVisible="False"
                          Content="{TemplateBinding SelectionBoxItem}"
                          ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                          ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                          Margin="6,3,23,3"
                          VerticalAlignment="Center"
                          HorizontalAlignment="Left" />
        <Popup Name="Popup"
               Placement="Bottom"
               IsOpen="{TemplateBinding IsDropDownOpen}"
               AllowsTransparency="True"
               Focusable="False"
               PopupAnimation="Slide">
            <Grid Name="DropDown"
                  SnapsToDevicePixels="True"
                  MinWidth="{TemplateBinding ActualWidth}"
                  MaxHeight="{TemplateBinding MaxDropDownHeight}">
                <Border x:Name="DropDownBorder"
                        Background="#2E273D"
                        BorderBrush="#7A6E94"
                        BorderThickness="1"
                        CornerRadius="2" />
                <ScrollViewer Margin="2" SnapsToDevicePixels="True">
                    <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained" />
                </ScrollViewer>
            </Grid>
        </Popup>
    </Grid>
</ControlTemplate>
"@

    $ComboBoxItemStyleXaml = @"
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="ComboBoxItem">
    <Setter Property="Background" Value="#2E273D" />
    <Setter Property="Foreground" Value="#EDEAFA" />
    <Setter Property="Padding" Value="6,4,6,4" />
    <Setter Property="Cursor" Value="Hand" />
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="ComboBoxItem">
                <Border x:Name="ItemBorder"
                        Background="{TemplateBinding Background}"
                        Padding="{TemplateBinding Padding}">
                    <ContentPresenter />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="ItemBorder" Property="Background" Value="#504368" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                    </Trigger>
                    <Trigger Property="IsSelected" Value="True">
                        <Setter TargetName="ItemBorder" Property="Background" Value="#655580" />
                        <Setter Property="Foreground" Value="#FFFFFF" />
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
"@

    $PresetComboBox.Template = [System.Windows.Markup.XamlReader]::Parse($ComboBoxTemplateXaml)
    $PresetComboBox.ItemContainerStyle = [System.Windows.Markup.XamlReader]::Parse($ComboBoxItemStyleXaml)

    $PresetPatterns = [ordered]@{
        'Telephone Number'              = '\(\d{3}\) \d{3}-\d{4}'
        'Electronic Mail Address'       = '[a-z]{4,8}@(gmail|yahoo|outlook)\.(com|org|net)'
        'Product Key'                   = '[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}'
        'Postal Code'                   = '[A-Z]\d[A-Z] \d[A-Z]\d'
        'Hexadecimal Color'             = '#[0-9A-Fa-f]{6}'
        'Universally Unique Identifier' = '[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}'
        'Internet Protocol Address'     = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
        'Date (YYYY-MM-DD)'             = '202[4-9]-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])'
    }

    $null = $PresetComboBox.Items.Add('(Select a preset...)')
    foreach ($PresetKey in $PresetPatterns.Keys) {
        $null = $PresetComboBox.Items.Add($PresetKey)
    }
    $PresetComboBox.SelectedIndex = 0
    $PresetDock.Children.Add($PresetComboBox) | Out-Null
    [System.Windows.Controls.DockPanel]::SetDock($PresetDock, 'Right')
    $RegexHeaderDock.Children.Add($PresetDock) | Out-Null
    $RegularExpressionContainer.Children.Add($RegexHeaderDock) | Out-Null

    # Pattern Row
    $PatternDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,4,0,4'
    }
    $PatternLabel = New-BaseTextBlock @{
        Text              = 'Pattern: '
        Foreground        = '#EDEAFA'
        FontSize          = 11
        VerticalAlignment = 'Center'
        Width             = 60
    }
    [System.Windows.Controls.DockPanel]::SetDock($PatternLabel, 'Left')
    $PatternDock.Children.Add($PatternLabel) | Out-Null

    $RegexTextBox = New-BaseTextBox @{
        Text              = $CurrentRegularExpressionPattern
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontSize          = 11
        FontFamily        = 'Consolas'
        Padding           = '3'
        VerticalAlignment = 'Center'
    }
    $PatternDock.Children.Add($RegexTextBox) | Out-Null
    $RegularExpressionContainer.Children.Add($PatternDock) | Out-Null

    $MainStackPanel.Children.Add($RegularExpressionContainer) | Out-Null

    # Mode switching handlers
    $ModeCharacterSetsRadioButton.Add_Checked({
            $CharacterSetContainer.Visibility = 'Visible'
            $RegularExpressionContainer.Visibility = 'Collapsed'
            & $UpdatePreview
        })
    $ModeRegularExpressionRadioButton.Add_Checked({
            $CharacterSetContainer.Visibility = 'Collapsed'
            $RegularExpressionContainer.Visibility = 'Visible'
            & $UpdatePreview
        })

    # Preset selection handler
    $PresetComboBox.Add_SelectionChanged({
            if ($PresetComboBox.SelectedIndex -gt 0) {
                $SelectedName = [string]$PresetComboBox.SelectedItem
                if ($PresetPatterns.Contains($SelectedName)) {
                    $RegexTextBox.Text = $PresetPatterns[$SelectedName]
                    & $UpdatePreview
                }
                $PresetComboBox.SelectedIndex = 0
            }
        })

    # Scope Option
    $GlobalCheckBox = New-BaseCheckBox @{
        Content    = 'Save as Global Default'
        IsChecked  = $false
        Margin     = '0,8,0,4'
        FontSize   = 11
        FontWeight = 'SemiBold'
    }
    $MainStackPanel.Children.Add($GlobalCheckBox) | Out-Null

    # Live Preview Section
    $PreviewDock = New-BaseDockPanel @{
        LastChildFill = $true
        Margin        = '0,6,0,0'
    }
    $PreviewLabel = New-BaseTextBlock @{
        Text              = 'Preview: '
        Foreground        = '#C4B8DE'
        FontSize          = 11
        VerticalAlignment = 'Center'
        Width             = 60
    }
    [System.Windows.Controls.DockPanel]::SetDock($PreviewLabel, 'Left')
    $PreviewDock.Children.Add($PreviewLabel) | Out-Null

    $PreviewTextBlock = New-BaseTextBlock @{
        Text              = ''
        Foreground        = '#98FB98'
        FontFamily        = 'Consolas'
        FontSize          = 11
        VerticalAlignment = 'Center'
        TextTrimming      = 'CharacterEllipsis'
        Cursor            = 'Hand'
        ToolTip           = 'Click to copy preview text'
    }
    $PreviewDock.Children.Add($PreviewTextBlock) | Out-Null

    $PreviewFeedbackTextBlock = New-BaseTextBlock @{
        Text              = ''
        Foreground        = '#FFD700'
        FontSize          = 10
        Margin            = '8,0,0,0'
        VerticalAlignment = 'Center'
    }
    $PreviewDock.Children.Add($PreviewFeedbackTextBlock) | Out-Null
    $MainStackPanel.Children.Add($PreviewDock) | Out-Null

    $PreviewTextBlock.Add_PreviewMouseLeftButtonDown({
            param($s, $e)
            if (-not [string]::IsNullOrEmpty($s.Text) -and $s.Text -ne '(empty pattern)' -and $s.Text -ne '(invalid pattern)') {
                [System.Windows.Clipboard]::SetText($s.Text)
                $PreviewFeedbackTextBlock.Text = 'Copied!'
            }
        })

    $ValidationWarningTextBlock = New-BaseTextBlock @{
        Text                = ''
        Foreground          = '#FF6B6B'
        FontSize            = 11
        Margin              = '0,6,0,0'
        HorizontalAlignment = 'Center'
    }
    $MainStackPanel.Children.Add($ValidationWarningTextBlock) | Out-Null

    $UpdatePreview = {
        $ValidationWarningTextBlock.Text = ''
        $PreviewFeedbackTextBlock.Text = ''
        if ($ModeRegularExpressionRadioButton.IsChecked) {
            $PatternValue = [string]$RegexTextBox.Text
            if ([string]::IsNullOrWhiteSpace($PatternValue)) {
                $PreviewTextBlock.Text = '(empty pattern)'
                return
            }
            try {
                $PreviewTextBlock.Text = Get-RandomStringFromRegularExpression -Pattern $PatternValue
            }
            catch {
                $PreviewTextBlock.Text = '(invalid pattern)'
            }
        }
        else {
            $ParsedLength = 10
            if (-not [int]::TryParse($LengthTextBox.Text, [ref]$ParsedLength) -or $ParsedLength -le 0) {
                $ParsedLength = 10
            }
            $TemporaryConfiguration = @{
                GenerationMode      = 'CharacterSets'
                Length              = $ParsedLength
                IncludeUppercase    = [bool]$UppercaseCheckBox.IsChecked
                UppercaseCharacters = [string]$UppercaseTextBox.Text
                IncludeLowercase    = [bool]$LowercaseCheckBox.IsChecked
                LowercaseCharacters = [string]$LowercaseTextBox.Text
                IncludeNumbers      = [bool]$NumbersCheckBox.IsChecked
                NumberCharacters    = [string]$NumbersTextBox.Text
                IncludeSymbols      = [bool]$SymbolsCheckBox.IsChecked
                SymbolCharacters    = [string]$SymbolsTextBox.Text
            }
            $PreviewTextBlock.Text = Get-RandomCustomString -Configuration $TemporaryConfiguration
        }
    }

    $LengthTextBox.Add_TextChanged({ & $UpdatePreview })
    $UppercaseCheckBox.Add_Click({ & $UpdatePreview })
    $UppercaseTextBox.Add_TextChanged({ & $UpdatePreview })
    $LowercaseCheckBox.Add_Click({ & $UpdatePreview })
    $LowercaseTextBox.Add_TextChanged({ & $UpdatePreview })
    $NumbersCheckBox.Add_Click({ & $UpdatePreview })
    $NumbersTextBox.Add_TextChanged({ & $UpdatePreview })
    $SymbolsCheckBox.Add_Click({ & $UpdatePreview })
    $SymbolsTextBox.Add_TextChanged({ & $UpdatePreview })
    $RegexTextBox.Add_TextChanged({ & $UpdatePreview })

    & $UpdatePreview

    $SaveAction = {
        param([bool]$SaveAndUse = $false)
        $IsRegularExpression = [bool]$ModeRegularExpressionRadioButton.IsChecked

        if ($IsRegularExpression) {
            $PatternValue = [string]$RegexTextBox.Text
            if ([string]::IsNullOrWhiteSpace($PatternValue)) {
                $ValidationWarningTextBlock.Text = 'Please provide a regular expression pattern.'
                return $null
            }
            try {
                [void][regex]::new($PatternValue)
                $null = Get-RandomStringFromRegularExpression -Pattern $PatternValue
            }
            catch {
                $ValidationWarningTextBlock.Text = 'The regular expression pattern contains syntax errors.'
                return $null
            }
        }
        else {
            $ActiveCharactersCount = 0
            if ($UppercaseCheckBox.IsChecked) { $ActiveCharactersCount += $UppercaseTextBox.Text.Length }
            if ($LowercaseCheckBox.IsChecked) { $ActiveCharactersCount += $LowercaseTextBox.Text.Length }
            if ($NumbersCheckBox.IsChecked) { $ActiveCharactersCount += $NumbersTextBox.Text.Length }
            if ($SymbolsCheckBox.IsChecked) { $ActiveCharactersCount += $SymbolsTextBox.Text.Length }

            if ($ActiveCharactersCount -eq 0) {
                $ValidationWarningTextBlock.Text = 'Please provide at least one character in an enabled character type.'
                return $null
            }
        }

        $ValidLength = 10
        if (-not [int]::TryParse($LengthTextBox.Text, [ref]$ValidLength) -or $ValidLength -le 0) {
            $ValidLength = 10
        }
        if ($ValidLength -gt 4096) { $ValidLength = 4096 }

        $HasAnyType = ($UppercaseCheckBox.IsChecked -or $LowercaseCheckBox.IsChecked -or $NumbersCheckBox.IsChecked -or $SymbolsCheckBox.IsChecked)
        $NewConfiguration = @{
            GenerationMode             = if ($IsRegularExpression) { 'RegularExpression' } else { 'CharacterSets' }
            RegularExpressionPattern   = [string]$RegexTextBox.Text
            UnboundedRepetitionMaximum = 5
            Length                     = $ValidLength
            IncludeUppercase           = if ($HasAnyType) { [bool]$UppercaseCheckBox.IsChecked } else { $true }
            UppercaseCharacters        = [string]$UppercaseTextBox.Text
            IncludeLowercase           = if ($HasAnyType) { [bool]$LowercaseCheckBox.IsChecked } else { $true }
            LowercaseCharacters        = [string]$LowercaseTextBox.Text
            IncludeNumbers             = if ($HasAnyType) { [bool]$NumbersCheckBox.IsChecked } else { $true }
            NumberCharacters           = [string]$NumbersTextBox.Text
            IncludeSymbols             = [bool]$SymbolsCheckBox.IsChecked
            SymbolCharacters           = [string]$SymbolsTextBox.Text
            SaveAndUse                 = $SaveAndUse
        }

        if ($TargetWrapper) {
            if (-not ($TargetWrapper.Tag -is [hashtable])) { $TargetWrapper.Tag = @{} }
            $TargetWrapper.Tag.RandomValuesConfiguration = $NewConfiguration
        }

        if ($GlobalCheckBox.IsChecked) {
            $script:GlobalRandomValuesConfiguration = $NewConfiguration
            try {
                $ConfigurationDirectory = [System.IO.Path]::GetDirectoryName($RandomValuesConfigurationFilePath)
                if ($ConfigurationDirectory -and (-not (Test-Path -LiteralPath $ConfigurationDirectory))) {
                    [void][System.IO.Directory]::CreateDirectory($ConfigurationDirectory)
                }
                $JsonData = ConvertTo-Json -InputObject $NewConfiguration
                [System.IO.File]::WriteAllText($RandomValuesConfigurationFilePath, $JsonData)
            }
            catch {
                Write-Host "{Show-RandomValuesConfigurationDialog} Error saving configuration: $_" -ForegroundColor Yellow
            }
        }

        return $NewConfiguration
    }

    $Result = New-QuickSetModalDialog `
        -Title 'Random Values Customization' `
        -Width 520 `
        -Height 430 `
        -ContentControls @($MainStackPanel) `
        -AffirmativeButtonText 'Save' `
        -NegativeButtonText 'Cancel' `
        -AuxiliaryButtonText 'Save and Use' `
        -AuxiliaryResultProvider { & $SaveAction -SaveAndUse $true } `
        -ResultProvider { & $SaveAction -SaveAndUse $false }

    Stop-FunctionMeasurement -FunctionName 'Show-RandomValuesConfigurationDialog'
    return $Result
} # function Show-RandomValuesConfigurationDialog

function Get-QuickSetTypeDirectory {
    param($Type)
    Start-FunctionMeasurement -FunctionName "Get-QuickSetTypeDirectory"
    if (-not (Test-Path -LiteralPath $QuickSetRootPath)) {
        [void][System.IO.Directory]::CreateDirectory($QuickSetRootPath)
    }

    $TypeName = if ($Type -is [type]) {
        $Type.FullName
    }
    elseif ($Type -is [string]) {
        $Type
    }
    elseif ($null -ne $Type) {
        $Type.ToString()
    }
    else {
        'System.Object'
    }

    if ([string]::IsNullOrWhiteSpace($TypeName)) { $TypeName = 'System.Object' }

    $CleanTypeName = $TypeName -replace '[\\/:*?"<>|]', '_'
    $TypeDir = Join-Path $QuickSetRootPath $CleanTypeName
    if (-not (Test-Path -LiteralPath $TypeDir)) {
        [void][System.IO.Directory]::CreateDirectory($TypeDir)
    }
    Stop-FunctionMeasurement -FunctionName "Get-QuickSetTypeDirectory"
    return $TypeDir
} # function Get-QuickSetTypeDirectory

function Get-WrapperTargetType {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperTargetType"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return [object] }

    if ($Target.Tag -is [hashtable]) {
        if ($Target.Tag.ContainsKey('TargetType') -and $null -ne $Target.Tag.TargetType) {
            return $Target.Tag.TargetType
        }
        if ($Target.Tag.ContainsKey('Type') -and $null -ne $Target.Tag.Type) {
            return $Target.Tag.Type
        }
    }
    if ($Target.DataContext) {
        if ($Target.DataContext -is [type]) { return $Target.DataContext }
        if ($Target.DataContext -is [string]) {
            try { return [type]$Target.DataContext } catch { return $Target.DataContext }
        }
    }
    $DescBlock = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName } -FindMax 1
    if ($DescBlock -and -not [string]::IsNullOrWhiteSpace($DescBlock.Text)) {
        $CleanText = [System.Text.RegularExpressions.Regex]::Replace($DescBlock.Text, '\[.*?\]', '[]')
        try { return [type]$CleanText } catch { return $CleanText }
    }
    $Content = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -FindMax 1
    if ($Content) {
        if ($Content.Tag -is [hashtable] -and $Content.Tag.ContainsKey('TargetType') -and $null -ne $Content.Tag.TargetType) {
            return $Content.Tag.TargetType
        }
        if ($Content.DataContext) {
            if ($Content.DataContext -is [type]) { return $Content.DataContext }
            try { return [type]$Content.DataContext } catch { return $Content.DataContext }
        }
        switch ($Content.GetType().Name) {
            'TextBox' { return [string] }
            'ComboBox' { return [string] }
            'PasswordBox' { return [string] }
            'RichTextBox' { return [string] }
            default { return [string] }
        }
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperTargetType"
    return [object]
} # function Get-WrapperTargetType

function Get-QuickSetMenuFromSender {
    param($s)
    Start-FunctionMeasurement -FunctionName "Get-QuickSetMenuFromSender"
    if (-not $s) { return $null }
    $Target = Resolve-TargetElement $s
    if ($Target -is [System.Windows.Controls.MenuItem] -and $Target.Name -like "*$QuickSetMenuNameSuffix") {
        return $Target
    }

    $Current = $Target.Parent
    while ($null -ne $Current) {
        if ($Current.Name -like "*$QuickSetMenuNameSuffix") {
            Stop-FunctionMeasurement -FunctionName "Get-QuickSetMenuFromSender"
            return $Current
        }
        $Current = $Current.Parent
    }

    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -DigProperties 'Parent' -FindMax 1
    if ($Found -is [array]) { return $Found[0] }
    Stop-FunctionMeasurement -FunctionName "Get-QuickSetMenuFromSender"
    return $Found
} # function Get-QuickSetMenuFromSender

function Get-QuickSetWrapper {
    param(
        [Parameter(Mandatory)]$s,
        [string]$ActionFrom
    )
    Start-FunctionMeasurement -FunctionName "Get-QuickSetWrapper"
    $TargetSender = Resolve-TargetElement $s

    if (-not $ActionFrom) {
        if ($TargetSender.Name -like "*$QuickSetBadgeNameSuffix") {
            $ActionFrom = $TargetSender.Name.Replace("_$QuickSetBadgeNameSuffix", '')
        }
        else {
            $QSMenu = Get-QuickSetMenuFromSender $TargetSender
            if ($QSMenu -and $QSMenu.Name) {
                $ActionFrom = $QSMenu.Name.Replace("_$QuickSetMenuNameSuffix", '')
            }
        }
    }

    $ContentWrapper = $null
    if ($ActionFrom) {
        $ContentWrapper = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1)
    }
    if (-not $ContentWrapper) {
        $ContentWrapper = Get-ParentWrapperBorder -Element $TargetSender
    }
    Stop-FunctionMeasurement -FunctionName "Get-QuickSetWrapper"
    return $ContentWrapper
} # function Get-QuickSetWrapper

function Get-WrapperHeaderTitleElement {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperHeaderTitleElement"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }

    $TitleDock = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
    if ($TitleDock -is [array]) { $TitleDock = $TitleDock[0] }
    if (-not $TitleDock) { return $null }

    $TitleElem = Find-ObjectWhere -Object ([ref]$TitleDock) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName } -FindMax 1
    if ($TitleElem -is [array]) { $TitleElem = $TitleElem[0] }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperHeaderTitleElement"
    return $TitleElem
} # function Get-WrapperHeaderTitleElement

function Get-IsArrayItem {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-IsArrayItem"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $false }

    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('ArrayItem') -and $Target.Tag.ArrayItem) {
        return $true
    }

    $ItemStack = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ArrayItemStackName } -DepthMax 2 -FindMax 1
    Stop-FunctionMeasurement -FunctionName "Get-IsArrayItem"
    return ($null -ne $ItemStack)
} # function Get-IsArrayItem

function Get-WrapperDisplayName {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperDisplayName"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }

    # 1. If Header has an editable Title TextBox that was modified
    $TitleElement = Get-WrapperHeaderTitleElement $Target
    if ($TitleElement -is [System.Windows.Controls.TextBox] -and -not [string]::IsNullOrWhiteSpace($TitleElement.Text)) {
        $DefaultTitle = if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('OriginalTitle') -and -not [string]::IsNullOrWhiteSpace($Target.Tag.OriginalTitle)) {
            $Target.Tag.OriginalTitle
        }
        else {
            $Type = Get-WrapperTargetType -Wrapper $Target
            if ($Type -is [type]) { $Type.Name.TrimEnd('[]') } else { $null }
        }

        if (-not $DefaultTitle -or $TitleElement.Text -ne $DefaultTitle) {
            return $TitleElement.Text
        }
    }

    # 2. Check ActiveQuickSet in Tag
    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('ActiveQuickSet') -and -not [string]::IsNullOrWhiteSpace($Target.Tag.ActiveQuickSet)) {
        return $Target.Tag.ActiveQuickSet
    }

    # 3. Check Badge tooltip if present
    $BadgeName = "$($Target.Name)_$QuickSetBadgeNameSuffix"
    $Menu = Get-WrapperMenu -Wrapper $Target
    if ($Menu) {
        $ExistingBadge = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $BadgeName } -FindMax 1)
        if ($ExistingBadge -and -not [string]::IsNullOrWhiteSpace($ExistingBadge.ToolTip)) {
            return $ExistingBadge.ToolTip
        }
    }

    Stop-FunctionMeasurement -FunctionName "Get-WrapperDisplayName"
    return $null
} # function Get-WrapperDisplayName

function Set-WrapperDisplayName {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [string]$DisplayName
    )
    Start-FunctionMeasurement -FunctionName 'Set-WrapperDisplayName'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    $TitleElement = Get-WrapperHeaderTitleElement $Target
    $CanUpdateTitle = ($TitleElement -is [System.Windows.Controls.TextBox] -and -not $TitleElement.IsReadOnly) -or ($TitleElement -is [System.Windows.Controls.TextBlock])

    if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
        if (-not ($Target.Tag -is [hashtable])) { $Target.Tag = @{} }
        $Target.Tag.ActiveQuickSet = $DisplayName

        if ($CanUpdateTitle) {
            if (-not $Target.Tag.ContainsKey('OriginalTitle')) {
                $Target.Tag.OriginalTitle = $TitleElement.Text
            }
            $TitleElement.Text = $DisplayName
        }

        Update-QuickSetBadge -Wrapper $Target -DisplayName $DisplayName

        $QSMenu = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -FindMax 1)
        if ($QSMenu) {
            Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $Target
        }
    }
    else {
        if ($CanUpdateTitle -and $Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('OriginalTitle') -and -not [string]::IsNullOrWhiteSpace($Target.Tag.OriginalTitle)) {
            $TitleElement.Text = $Target.Tag.OriginalTitle
        }
        if ($Target.Tag -is [hashtable]) {
            $Target.Tag.ActiveQuickSet = $null
        }
        Update-QuickSetBadge -Wrapper $Target -DisplayName $null
    }

    Stop-FunctionMeasurement -FunctionName 'Set-WrapperDisplayName'
} # function Set-WrapperDisplayName

function Save-QuickSetFile {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [Parameter(Mandatory)][string]$QuickSetName
    )
    Start-FunctionMeasurement -FunctionName "Save-QuickSetFile"
    $TargetWrapper = Resolve-QuickSetWrapper $Wrapper
    if (-not $TargetWrapper) { return $false }

    $SanitizedName = $QuickSetName.Trim() -replace '[\\/:*?"<>|]', '_'
    if ([string]::IsNullOrWhiteSpace($SanitizedName)) { return $false }

    $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type
    $FilePath = Join-Path $TypeDir "$SanitizedName.json"

    $CurrentValue = Get-WrapperQuickSetValue -Wrapper $TargetWrapper
    $JsonText = ConvertTo-Json -InputObject $CurrentValue -Depth 20
    Set-Content -LiteralPath $FilePath -Value $JsonText -Encoding UTF8

    if (-not ($TargetWrapper.Tag -is [hashtable])) { $TargetWrapper.Tag = @{} }
    $TargetWrapper.Tag.ActiveQuickSet = $SanitizedName
    $TargetWrapper.Tag.QuickSetSnapshot = $JsonText
    Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $SanitizedName

    Stop-FunctionMeasurement -FunctionName "Save-QuickSetFile"
    return $true
} # function Save-QuickSetFile

function Get-WrapperQuickSetValue {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [switch]$ValuesOnly
    )
    Start-FunctionMeasurement -FunctionName "Get-WrapperQuickSetValue"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $null }

    $Tag = if ($Target.Tag -is [hashtable]) { $Target.Tag } else { @{} }

    # -DepthMax 0 with this DepthWhere means a search never goes inside a child wrapper
    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

    $RawValue = $null

    if ($Tag.IsArray) {
        # Array wrapper: one value per item in its own ContentSlot
        $List = [System.Collections.ArrayList]@()
        if ($Tag.ContentSlot) {
            foreach ($Child in @($Tag.ContentSlot.Children)) {
                $ChildVal = Get-WrapperQuickSetValue -Wrapper $Child -ValuesOnly:$ValuesOnly
                [void]$List.Add($ChildVal)
            }
        }
        $RawValue = @($List)
    }
    elseif ($Tag.IsConstruct -and $Tag.Construct) {
        # Construct wrapper: one entry per parameter wrapper in the Construct panel
        $ObjMap = [ordered]@{}
        foreach ($Child in @($Tag.Construct.Children)) {
            $Title = Find-Title $Child
            $ParamName = if ($Title) { ($Title.Split('-')[0]).Trim() } else { $Child.Name }
            $ObjMap[$ParamName] = Get-WrapperQuickSetValue -Wrapper $Child -ValuesOnly:$ValuesOnly
        }
        $RawValue = $ObjMap
    }
    else {
        # Simple wrapper: read its own Content control (or the wrapper is the Content control)
        $Content = if ($Tag.ContainsKey('Content') -and $Tag.Content) { $Tag.Content } elseif ($Target.Name -eq $ContentElementName) { $Target } else {
            Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
        }
        if ($Content) {
            $RawValue = (Get-ContentValue -Object $Content)
        }
        else {
            $DTP = if ($Tag.ContainsKey('CustomDateTimePicker') -and $Tag.CustomDateTimePicker) { $Tag.CustomDateTimePicker } else { Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1 }
            if ($DTP) {
                $RawValue = (Get-ContentValue -Object $DTP)
            }
        }
    }

    if (-not $ValuesOnly) {
        $IsArrayItem = Get-IsArrayItem -Wrapper $Target
        $TitleElement = Get-WrapperHeaderTitleElement $Target
        $HasHeader = ($null -ne $TitleElement)
        $SelfLocked = Get-IsElementLockedSelf $Target
        $SelfDisabled = Get-IsElementDisabledSelf $Target
        $SelfMinMaxState = Get-WrapperMinMaxState $Target
        $SearchState = Get-WrapperSearchState -Wrapper $Target

        if (($IsArrayItem -and $HasHeader) -or $SelfLocked -or $SelfDisabled -or ($null -ne $SelfMinMaxState) -or ($null -ne $SearchState)) {
            $Envelope = [ordered]@{}
            if ($IsArrayItem -and $HasHeader) {
                $Envelope['displayName'] = Get-WrapperDisplayName -Wrapper $Target
            }
            if ($null -ne $SelfMinMaxState) { $Envelope['isMinimized'] = [bool]$SelfMinMaxState }
            if ($SelfLocked) { $Envelope['isLocked'] = $true }
            if ($SelfDisabled) { $Envelope['isDisabled'] = $true }
            if ($null -ne $SearchState) { $Envelope['search'] = $SearchState }
            $Envelope['value'] = $RawValue
            return $Envelope
        }
    }

    # The leading comma stops PowerShell from unrolling an array result
    if ($Tag.IsArray) { return , $RawValue }

    Stop-FunctionMeasurement -FunctionName "Get-WrapperQuickSetValue"
    return $RawValue
} # function Get-WrapperQuickSetValue

function Set-WrapperQuickSetValue {
    param(
        [Parameter(Mandatory)]$Wrapper,
        $Value,
        [switch]$ValuesOnly
    )
    Start-FunctionMeasurement -FunctionName 'Set-WrapperQuickSetValue'
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return }

    if ($ValuesOnly -and (Get-IsElementLockedSelf $Target)) { return }

    $Tag = if ($Target.Tag -is [hashtable]) { $Target.Tag } else { @{} }

    Restore-ElementSearchStyle -Element $Target

    # -DepthMax 0 with this DepthWhere means a search never goes inside a child wrapper
    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

    $SearchBar = if ($Tag.ContainsKey('SearchBar')) { $Tag.SearchBar } else { Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1 }
    if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
        Close-SearchBar -ChildElement $SearchBar
    }

    $ActualValue = $Value
    $DesiredLocked = $false
    $DesiredDisabled = $false
    $HasDesiredMinimized = $false
    $DesiredMinimized = $false
    $HasEnvelopeMetadata = $false
    $DesiredSearchData = $null
    $HasDesiredSearch = $false

    if (($Value -is [System.Collections.IDictionary] -or $Value -is [System.Management.Automation.PSObject] -or $Value -is [System.Management.Automation.PSCustomObject]) -and $Value -isnot [array]) {
        $ValueEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'Value'
        $DisplayNameEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'DisplayName'
        $MinimizedEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'IsMinimized'
        $LockedEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'IsLocked'
        $DisabledEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'IsDisabled'
        $SearchEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'Search'

        if ($null -ne $ValueEntry -and ($null -ne $DisplayNameEntry -or $null -ne $MinimizedEntry -or $null -ne $LockedEntry -or $null -ne $DisabledEntry -or $null -ne $SearchEntry)) {
            $HasEnvelopeMetadata = $true
            $ActualValue = $ValueEntry.Value

            if (-not $ValuesOnly) {
                if ($null -ne $DisplayNameEntry) {
                    Set-WrapperDisplayName -Wrapper $Target -DisplayName $DisplayNameEntry.Value
                }
                if ($null -ne $LockedEntry) {
                    $DesiredLocked = [bool]$LockedEntry.Value
                }
                if ($null -ne $DisabledEntry) {
                    $DesiredDisabled = [bool]$DisabledEntry.Value
                }
                if ($null -ne $SearchEntry) {
                    $HasDesiredSearch = $true
                    $DesiredSearchData = $SearchEntry.Value
                }
            }

            if ($null -ne $MinimizedEntry -and $null -ne $MinimizedEntry.Value) {
                $HasDesiredMinimized = $true
                $DesiredMinimized = [bool]$MinimizedEntry.Value
            }
        }
        elseif ($null -ne $DisplayNameEntry -and -not $ValuesOnly) {
            Set-WrapperDisplayName -Wrapper $Target -DisplayName $DisplayNameEntry.Value
        }
    }

    # Unlock control first to permit value updates when applying Full Item
    if (-not $ValuesOnly) {
        Set-TargetLockedState -Target $Target -IsLocked $false
    }

    $Value = $ActualValue

    # Array wrapper: grow/shrink the item list to match, then set each item
    if ($Tag.IsArray) {
        $ContentSlot = $Tag.ContentSlot
        $AddButton = $Tag.AddButton
        if ($ContentSlot -and $AddButton) {
            $List = if ($null -eq $Value) { @() } else { @($Value) }
            $TargetType = if ($Tag.ContainsKey('TargetType') -and $Tag.TargetType) { $Tag.TargetType } elseif ($AddButton.Tag) { [string]$AddButton.Tag.TrimEnd('[]') } else { $Target.DataContext }
            $BaseDepth = if ($Tag.ContainsKey('Depth')) { $Tag.Depth } else { 0 }
            while ($ContentSlot.Children.Count -lt $List.Count) {
                $CountBefore = $ContentSlot.Children.Count
                # Direct construction bypasses routed menu event overhead
                $NewItem = New-TypeContent -WrapperType 'Border' -Type $TargetType -ArrayType 'ArrayItem' -Index $ContentSlot.Children.Count -Depth ($BaseDepth + 1)
                $ContentSlot.AddChild($NewItem) | Out-Null

                # Stop if the Add button didn't add an item, instead of looping forever
                if ($ContentSlot.Children.Count -le $CountBefore) { break }
            }
            while ($ContentSlot.Children.Count -gt $List.Count) {
                $LastChild = $ContentSlot.Children[$ContentSlot.Children.Count - 1]
                $DelButton = Find-ObjectWhere -Object ([ref]$LastChild) -FindWhere { $_.Name -like "*$DeleteButtonNameSuffix" } -FindMax 1
                if ($DelButton) {
                    $ContentSlot.Children.Remove($LastChild)
                }
                else {
                    $ContentSlot.Children.RemoveAt($ContentSlot.Children.Count - 1)
                }
            }
            Reset-ArrayIndexes ([ref]$ContentSlot)

            $SetCount = [Math]::Min($List.Count, $ContentSlot.Children.Count)
            for ($i = 0; $i -lt $SetCount; $i++) {
                Set-WrapperQuickSetValue -Wrapper $ContentSlot.Children[$i] -Value $List[$i] -ValuesOnly:$ValuesOnly
            }

            # Dispatcher frame yielding: renders all items onto the screen once after batch population
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([System.Action] {}, [System.Windows.Threading.DispatcherPriority]::Background)

            # Batch array button states and enable confirmation once for the container after all child elements are populated
            Confirm-ArrayEnableButton -Item ([ref]$Target)
            Update-ArrayButtonsState -Wrapper $Target
        }
    }
    elseif ($Tag.IsConstruct -and $Tag.Construct) {
        # Object constructor: recurse on each parameter wrapper
        foreach ($Child in @($Tag.Construct.Children)) {
            $Title = Find-Title $Child
            $ParamName = if ($Title) { ($Title.Split('-')[0]).Trim() } else { $Child.Name }
            $MatchEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName $ParamName
            if ($null -ne $MatchEntry -and $MatchEntry.Exists) {
                Set-WrapperQuickSetValue -Wrapper $Child -Value $MatchEntry.Value -ValuesOnly:$ValuesOnly
            }
        }
    }
    else {
        # Direct content controls
        $Content = if ($Target.Name -eq $ContentElementName) { $Target }
        elseif ($Tag.ContainsKey('Content') -and $Tag.Content) { $Tag.Content }
        else {
            Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
        }
        if ($Content) {
            Restore-ElementSearchStyle -Element $Content

            switch ($Content.GetType().Name) {
                'TextBox' {
                    $Content.Text = if ($null -ne $Value) { [string]$Value } else { '' }
                }
                'ComboBox' {
                    if ($null -ne $Value -and $Value -ne '') {
                        $Content.SelectedItem = $Value
                        if ($null -eq $Content.SelectedItem -and $Content.ItemsSource) {
                            $MatchItem = @($Content.ItemsSource) | Where-Object { $_.ToString() -eq $Value.ToString() } | Select-Object -First 1
                            if ($MatchItem) { $Content.SelectedItem = $MatchItem }
                        }
                    }
                    else {
                        $Content.SelectedItem = $null
                        $Content.Text = ''
                    }
                }
                'PasswordBox' {
                    $Content.Password = if ($null -ne $Value) { [string]$Value } else { '' }
                }
                'RichTextBox' {
                    Set-RichTextBoxText -RichTextBox $Content -Text ([string]$Value)
                }
            }
        }
        else {
            $DTP = if ($Tag.ContainsKey('CustomDateTimePicker') -and $Tag.CustomDateTimePicker) { $Tag.CustomDateTimePicker }
            else {
                Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
            }
            if ($DTP) {
                $DateBox = if ($DTP.Tag -is [hashtable] -and $DTP.Tag.ContainsKey('DisplayTextBox') -and $DTP.Tag.DisplayTextBox) {
                    $DTP.Tag.DisplayTextBox
                }
                else {
                    Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
                }
                if ($DateBox) {
                    Restore-ElementSearchStyle -Element $DateBox
                    $DateBox.Text = if ($null -ne $Value) { [string]$Value } else { '' }
                }
            }
        }
    }

    if ($HasDesiredMinimized) {
        Set-TargetMinMaxState -Target $Target -IsMinimized $DesiredMinimized
    }
    if (-not $ValuesOnly) {
        Set-TargetDisabledState -Target $Target -IsDisabled $DesiredDisabled -SkipParentSync
        Set-TargetLockedState -Target $Target -IsLocked $DesiredLocked
        if ($HasDesiredSearch) {
            Set-WrapperSearchState -Wrapper $Target -SearchData $DesiredSearchData
        }
        else {
            Set-WrapperSearchState -Wrapper $Target -SearchData $null
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Set-WrapperQuickSetValue'
} # function Set-WrapperQuickSetValue

function Clear-WrapperQuickSetValue {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Clear-WrapperQuickSetValue"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return }

    $Tag = if ($Target.Tag -is [hashtable]) { $Target.Tag } else { @{} }

    if ((Get-IsLocked ([ref]$Target))) { return }

    Restore-ElementSearchStyle -Element $Target

    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

    $SearchBar = if ($Tag.ContainsKey('SearchBar')) { $Tag.SearchBar } else { Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1 }
    if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
        Close-SearchBar -ChildElement $SearchBar
    }

    # If Header has a change-able Title that was set by QuickSet, revert it
    $TitleElement = Get-WrapperHeaderTitleElement $Target
    if ($TitleElement -is [System.Windows.Controls.TextBox] -and -not $TitleElement.IsReadOnly) {
        if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('OriginalTitle') -and -not [string]::IsNullOrWhiteSpace($Target.Tag.OriginalTitle)) {
            $TitleElement.Text = $Target.Tag.OriginalTitle
        }
    }

    if ($Target.Tag -is [hashtable]) {
        $Target.Tag.ActiveQuickSet = $null
    }
    Update-QuickSetBadge -Wrapper $Target -DisplayName $null

    # 1. Array wrapper: remove all array item children from content slot
    $ContentSlot = $Tag.ContentSlot
    if ($Tag.IsArray -and $ContentSlot) {
        Clear-ContentSlotArrayItems -ContentSlot $ContentSlot -ContainerWrapper $Target
        return
    }

    # 2. Object constructor: recurse on each parameter wrapper
    $Construct = if ($Tag.IsConstruct) { $Tag.Construct } else { $null }
    if ($Construct) {
        foreach ($Child in @($Construct.Children)) {
            Clear-WrapperQuickSetValue -Wrapper $Child
        }
        return
    }

    # 3. Direct content controls
    $Content = if ($Target.Name -eq $ContentElementName) { $Target } else {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
    }
    if ($Content) {
        if ((Get-IsLocked ([ref]$Content))) { return }
        Clear-SingleContentElement -Element $Content -UseEmptyString
        return
    }

    $DTP = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
    if ($DTP) {
        if ((Get-IsLocked ([ref]$DTP))) { return }
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox) {
            Clear-SingleContentElement -Element $DateBox -UseEmptyString
        }
        return
    }
    Stop-FunctionMeasurement -FunctionName "Clear-WrapperQuickSetValue"
} # function Clear-WrapperQuickSetValue

function Set-QuickSetActiveButtonsState {
    param(
        [Parameter(Mandatory)]$QuickSetMenuItem,
        [Parameter(Mandatory)][bool]$IsEnabled
    )
    Start-FunctionMeasurement -FunctionName 'Set-QuickSetActiveButtonsState'
    $QSMenu = Resolve-TargetElement $QuickSetMenuItem
    if (-not $QSMenu) { return }

    $ActiveOnlyButtonSuffixes = @(
        $QuickSetSaveButtonNameSuffix

        $QuickSetRenameButtonNameSuffix
        $QuickSetClearButtonNameSuffix
        $QuickSetCloseButtonNameSuffix
        $QuickSetDeleteButtonNameSuffix
    )

    Set-MenuButtonsEnabledState -Menu $QSMenu -Suffixes $ActiveOnlyButtonSuffixes -IsEnabled $IsEnabled

    Stop-FunctionMeasurement -FunctionName 'Set-QuickSetActiveButtonsState'
} # function Set-QuickSetActiveButtonsState

function Reset-WrapperQuickSet {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [switch]$SaveCurrentValues,
        $QuickSetMenuItem = $null
    )
    Start-FunctionMeasurement -FunctionName "Reset-WrapperQuickSet"
    $TargetWrapper = Resolve-TargetElement $Wrapper
    if (-not $TargetWrapper) { return }

    if ($SaveCurrentValues) {
        $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet') -and -not [string]::IsNullOrWhiteSpace($TargetWrapper.Tag.ActiveQuickSet)) {
            $TargetWrapper.Tag.ActiveQuickSet
        }
        else { $null }

        if (-not [string]::IsNullOrWhiteSpace($ActiveName)) {
            $null = Save-QuickSetFile -Wrapper $TargetWrapper -QuickSetName $ActiveName
        }
    }

    Clear-WrapperQuickSetValue -Wrapper $TargetWrapper

    if ($TargetWrapper.Tag -is [hashtable] -and $null -ne $TargetWrapper.Tag.ActiveQuickSet) {
        $TargetWrapper.Tag.ActiveQuickSet = $null
        $TargetWrapper.Tag.QuickSetSnapshot = $null
        Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $null
    }

    $QSMenu = if ($QuickSetMenuItem) { Resolve-TargetElement $QuickSetMenuItem } else {
        $Menu = Get-WrapperMenu -Wrapper $TargetWrapper
        if ($Menu -and $Menu.Tag -is [hashtable] -and $Menu.Tag.ButtonsByName) {
            $FoundQS = $null
            foreach ($Key in $Menu.Tag.ButtonsByName.Keys) {
                if ($Key -like "*$QuickSetMenuNameSuffix") { $FoundQS = $Menu.Tag.ButtonsByName[$Key]; break }
            }
            if ($FoundQS) { $FoundQS } else { Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetWrapper) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -FindMax 1) }
        }
        else {
            Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetWrapper) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -FindMax 1)
        }
    }
    if ($QSMenu) {
        Set-QuickSetActiveButtonsState -QuickSetMenuItem $QSMenu -IsEnabled $false
        Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
    }
    Stop-FunctionMeasurement -FunctionName "Reset-WrapperQuickSet"
} # function Reset-WrapperQuickSet

function Get-WrapperQuickSetSnapshot {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperQuickSetSnapshot"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $null }
    $CurrentVal = Get-WrapperQuickSetValue -Wrapper $Target
    $Snapshot = ConvertTo-Json -InputObject $CurrentVal -Depth 20
    Stop-FunctionMeasurement -FunctionName "Get-WrapperQuickSetSnapshot"
    return $Snapshot
} # function Get-WrapperQuickSetSnapshot

function Test-QuickSetValueNotEmpty {
    param($Value)
    if ($null -eq $Value) { return $false }
    if ($Value -is [string]) {
        return (-not [string]::IsNullOrWhiteSpace($Value))
    }
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($Key in $Value.Keys) {
            if (Test-QuickSetValueNotEmpty -Value $Value[$Key]) { return $true }
        }
        return $false
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $Items = @($Value)
        if ($Items.Count -eq 0) { return $false }
        foreach ($Item in $Items) {
            if (Test-QuickSetValueNotEmpty -Value $Item) { return $true }
        }
        return $false
    }
    return $true
} # function Test-QuickSetValueNotEmpty

function Test-WrapperHasQuickSetValue {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Test-WrapperHasQuickSetValue"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $false }
    $Val = Get-WrapperQuickSetValue -Wrapper $Target -ValuesOnly
    $HasValue = Test-QuickSetValueNotEmpty -Value $Val
    Stop-FunctionMeasurement -FunctionName "Test-WrapperHasQuickSetValue"
    return $HasValue
} # function Test-WrapperHasQuickSetValue

function Test-IsActiveQuickSetWrapper {
    param($Element)
    Start-FunctionMeasurement -FunctionName "Test-IsActiveQuickSetWrapper"
    if ($null -eq $Element) {
        Stop-FunctionMeasurement -FunctionName "Test-IsActiveQuickSetWrapper"
        return $false
    }
    $Tag = $Element.Tag
    if (-not ($Tag -is [hashtable])) {
        Stop-FunctionMeasurement -FunctionName "Test-IsActiveQuickSetWrapper"
        return $false
    }
    if (-not $Tag.ContainsKey('IsArray')) {
        Stop-FunctionMeasurement -FunctionName "Test-IsActiveQuickSetWrapper"
        return $false
    }
    $ActiveName = $Tag['ActiveQuickSet']
    if ([string]::IsNullOrWhiteSpace($ActiveName)) {
        Stop-FunctionMeasurement -FunctionName "Test-IsActiveQuickSetWrapper"
        return $false
    }

    if (-not [string]::IsNullOrWhiteSpace($Tag['QuickSetSnapshot'])) {
        Stop-FunctionMeasurement -FunctionName "Test-IsActiveQuickSetWrapper"
        return $true
    }

    $Type = Get-WrapperTargetType -Wrapper $Element
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type
    $FilePath = Join-Path $TypeDir "$ActiveName.json"
    $IsActive = (Test-Path -LiteralPath $FilePath)
    Stop-FunctionMeasurement -FunctionName "Test-IsActiveQuickSetWrapper"
    return $IsActive
} # function Test-IsActiveQuickSetWrapper

function Test-IsWrapperQuickSetModified {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Test-IsWrapperQuickSetModified"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $false }

    $Tag = $Target.Tag
    if (-not ($Tag -is [hashtable])) { return $false }

    $ActiveName = $Tag['ActiveQuickSet']
    if ([string]::IsNullOrWhiteSpace($ActiveName)) {
        Stop-FunctionMeasurement -FunctionName "Test-IsWrapperQuickSetModified"
        return $false
    }

    $CurrentSnapshot = Get-WrapperQuickSetSnapshot -Wrapper $Target

    if (-not [string]::IsNullOrWhiteSpace($Tag['QuickSetSnapshot'])) {
        $IsModified = ($CurrentSnapshot -ne $Tag['QuickSetSnapshot'])
        Stop-FunctionMeasurement -FunctionName "Test-IsWrapperQuickSetModified"
        return $IsModified
    }

    $Type = Get-WrapperTargetType -Wrapper $Target
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type
    $FilePath = Join-Path $TypeDir "$ActiveName.json"
    if (Test-Path -LiteralPath $FilePath) {
        $DiskRaw = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8
        $DiskNormalized = try { ConvertTo-Json -InputObject ($DiskRaw | ConvertFrom-Json) -Depth 20 } catch { $DiskRaw }
        $IsModified = ($CurrentSnapshot -ne $DiskNormalized)
        Stop-FunctionMeasurement -FunctionName "Test-IsWrapperQuickSetModified"
        return $IsModified
    }

    Stop-FunctionMeasurement -FunctionName "Test-IsWrapperQuickSetModified"
    return $false
} # function Test-IsWrapperQuickSetModified

function Get-ActiveQuickSetWrappers {
    param([Parameter(Mandatory)]$Window)
    Start-FunctionMeasurement -FunctionName "Get-ActiveQuickSetWrappers"
    $FoundWrappers = [System.Collections.ArrayList]@()
    $AllWrappers = Find-ObjectWhere -Object ([ref]$Window) -FindWhere {
        Test-IsActiveQuickSetWrapper $_
    }
    if ($AllWrappers) {
        foreach ($Wrapper in @($AllWrappers)) {
            $Resolved = Resolve-TargetElement $Wrapper
            if ($Resolved -and -not $FoundWrappers.Contains($Resolved)) {
                [void]$FoundWrappers.Add($Resolved)
            }
        }
    }
    Stop-FunctionMeasurement -FunctionName "Get-ActiveQuickSetWrappers"
    return @($FoundWrappers)
} # function Get-ActiveQuickSetWrappers

function Get-ModifiedQuickSetWrappers {
    param([Parameter(Mandatory)]$Window)
    Start-FunctionMeasurement -FunctionName "Get-ModifiedQuickSetWrappers"
    $FoundWrappers = [System.Collections.ArrayList]@()
    $ActiveWrappers = Get-ActiveQuickSetWrappers -Window $Window
    if ($ActiveWrappers) {
        foreach ($Wrapper in $ActiveWrappers) {
            if (Test-IsWrapperQuickSetModified -Wrapper $Wrapper) {
                [void]$FoundWrappers.Add($Wrapper)
            }
        }
    }
    Stop-FunctionMeasurement -FunctionName "Get-ModifiedQuickSetWrappers"
    return @($FoundWrappers)
} # function Get-ModifiedQuickSetWrappers

function Invoke-ExistingBadgeClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-ExistingBadgeClick'
    if ($e) { $e.Handled = $true }
    try {
        $TargetWrapper = if ($s.Tag) { $s.Tag } else { Get-QuickSetWrapper $s }
        if (-not $TargetWrapper) { return }
        Reset-WrapperQuickSet -Wrapper $TargetWrapper -SaveCurrentValues
    }
    catch {
        [System.Windows.MessageBox]::Show("Error saving QuickSet: $_", "QuickSet Error") | Out-Null
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-ExistingBadgeClick'
} # function Invoke-ExistingBadgeClick

function Update-QuickSetBadge {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [string]$DisplayName
    )
    Start-FunctionMeasurement -FunctionName 'Update-QuickSetBadge'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    $Menu = Get-WrapperMenu -Wrapper $Target
    if (-not $Menu) { return }

    $BadgeName = "$($Target.Name)_$QuickSetBadgeNameSuffix"
    $ExistingBadge = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $BadgeName } -FindMax 1)

    if ([string]::IsNullOrWhiteSpace($DisplayName)) {
        if ($ExistingBadge) {
            $Menu.Items.Remove($ExistingBadge) | Out-Null
        }
        return
    }

    if (-not $ExistingBadge) {
        $ExistingBadge = New-BaseMenuItem @{
            Name            = $BadgeName
            Header          = $QuickSetIcon
            ToolTip         = $DisplayName
            Foreground      = '#EDEAFA'
            Background      = '#504368'
            BorderBrush     = '#8879A1'
            BorderThickness = 1
            FontWeight      = 'Bold'
            FontSize        = 10
            Padding         = '4,1,4,1'
            Margin          = '2,0,2,0'
            Cursor          = 'Hand'
        }
        $ExistingBadge.Tag = $Target

        $ExistingBadge.Add_Click({ param($s, $e) Invoke-ExistingBadgeClick $s $e })

        $Menu.Items.Insert(0, $ExistingBadge) | Out-Null
    }
    else {
        $ExistingBadge.Header = $QuickSetIcon
        $ExistingBadge.ToolTip = $DisplayName
        $ExistingBadge.Tag = $Target
        $ExistingBadge.Visibility = 'Visible'
        if ($Menu.Items.IndexOf($ExistingBadge) -ne 0) {
            $Menu.Items.Remove($ExistingBadge) | Out-Null
            $Menu.Items.Insert(0, $ExistingBadge) | Out-Null
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Update-QuickSetBadge'
} # function Update-QuickSetBadge

function Invoke-QuickSetSetItemClick {
    param($s, $e, $TargetWrapper, $TargetFile, $TargetName, $CurrentQSMenu)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetSetItemClick'
    try {
        $MenuToUpdate = if ($CurrentQSMenu) { $CurrentQSMenu } else { Get-QuickSetMenuFromSender $s }
        $WrapperToUpdate = if ($TargetWrapper) { $TargetWrapper } else { Get-QuickSetWrapper $s }
        if (-not $WrapperToUpdate) { return }

        $RawJson = Get-Content -LiteralPath $TargetFile -Raw -Encoding UTF8
        $LoadedVal = try { $RawJson | ConvertFrom-Json } catch { $RawJson }
        Set-WrapperQuickSetValue -Wrapper $WrapperToUpdate -Value $LoadedVal

        if (-not ($WrapperToUpdate.Tag -is [hashtable])) { $WrapperToUpdate.Tag = @{} }
        $WrapperToUpdate.Tag.ActiveQuickSet = $TargetName
        $CurrentVal = Get-WrapperQuickSetValue -Wrapper $WrapperToUpdate
        $WrapperToUpdate.Tag.QuickSetSnapshot = (ConvertTo-Json -InputObject $CurrentVal -Depth 20)
        Update-QuickSetBadge -Wrapper $WrapperToUpdate -DisplayName $TargetName

        if ($MenuToUpdate) {
            Set-QuickSetActiveButtonsState -QuickSetMenuItem $MenuToUpdate -IsEnabled $true
            Update-QuickSetSubMenu -QuickSetMenuItem $MenuToUpdate -Wrapper $WrapperToUpdate
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error loading QuickSet: $_", "QuickSet Error") | Out-Null
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetSetItemClick'
} # function Invoke-QuickSetSetItemClick

function Update-QuickSetSubMenu {
    param(
        [Parameter(Mandatory)]$QuickSetMenuItem,
        [Parameter(Mandatory)]$Wrapper
    )
    Start-FunctionMeasurement -FunctionName 'Update-QuickSetSubMenu'
    $TargetWrapper = Resolve-TargetElement $Wrapper
    if (-not $TargetWrapper) { return }

    $QSMenu = Resolve-TargetElement $QuickSetMenuItem
    if (-not $QSMenu) { return }

    $SetMenu = Find-ObjectWhere -Object ([ref]$QSMenu) -FindWhere { $_.Name -like "*_$QuickSetSetMenuNameSuffix" } -FindMax 1
    if ($SetMenu -is [array]) { $SetMenu = $SetMenu[0] }
    if (-not $SetMenu -or $SetMenu.IsSubmenuOpen) { return }

    $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type

    $Files = @(Get-ChildItem -LiteralPath $TypeDir -Filter "*.json" -File -ErrorAction SilentlyContinue | Sort-Object Name)
    $SetMenu.Items.Clear()

    if ($Files.Count -eq 0) {
        $NoItems = New-BaseMenuItem @{
            Header        = '(No sets found)'
            IsEnabled     = $false
            FlowDirection = 'LeftToRight'
        }
        $SetMenu.Items.Add($NoItems) | Out-Null
        return
    }

    $ActiveSet = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet')) {
        $TargetWrapper.Tag.ActiveQuickSet
    }
    else { $null }

    :files foreach ($File in $Files) {
        $DisplayName = $File.BaseName
        $IsActive = ($DisplayName -eq $ActiveSet)

        $SetItem = New-BaseMenuItem @{
            Header        = $DisplayName
            Icon          = if ($IsActive) { '✓' } else { $null }
            ToolTip       = $File.FullName
            FlowDirection = 'LeftToRight'
        }
        if ($IsActive) {
            $SetItem.FontWeight = 'Bold'
            $SetItem.Foreground = '#A29BFE'
        }

        $TargetFile = $File.FullName
        $TargetName = $DisplayName
        $CurrentQSMenu = $QSMenu
        $SetItem.Add_Click(({ param($s, $e) Invoke-QuickSetSetItemClick $s $e $TargetWrapper $TargetFile $TargetName $CurrentQSMenu }).GetNewClosure())

        $SetMenu.Items.Add($SetItem) | Out-Null
    } # files foreach

    Stop-FunctionMeasurement -FunctionName 'Update-QuickSetSubMenu'
} # function Update-QuickSetSubMenu

#endregion #4 QuickSet

#region #4 Search

function Restore-ElementSearchStyle {
    param(
        [Parameter(Mandatory)]$Element
    )
    Start-FunctionMeasurement -FunctionName "Restore-ElementSearchStyle"
    $Target = Resolve-TargetElement $Element
    if (-not $Target -or [string]::IsNullOrEmpty($Target.Uid)) { return }
    if (-not $SearchOriginalStyles.ContainsKey($Target.Uid)) { return }

    $Entry = $SearchOriginalStyles[$Target.Uid]
    if ($Entry.Type -eq 'TextBlock') {
        $Target.Background = $Entry.Background
        $Target.Foreground = $Entry.Foreground
        $Target.FontWeight = $Entry.FontWeight
    }
    elseif ($Entry.Type -eq 'RichTextBox') {
        $Target.BorderBrush = $Entry.BorderBrush
        $Target.BorderThickness = $Entry.BorderThickness
        if ($null -ne $Entry.OriginalText) {
            Set-RichTextBoxText -RichTextBox $Target -Text $Entry.OriginalText
        }
    }
    else {
        $Target.BorderBrush = $Entry.BorderBrush
        $Target.BorderThickness = $Entry.BorderThickness
    }
    $SearchOriginalStyles.Remove($Target.Uid)
    Stop-FunctionMeasurement -FunctionName "Restore-ElementSearchStyle"
} # function Restore-ElementSearchStyle

function Resolve-SearchBar {
    param(
        [Parameter(Mandatory)]$ChildElement
    )
    Start-FunctionMeasurement -FunctionName "Resolve-SearchBar"
    $Target = Resolve-TargetElement $ChildElement
    if (-not $Target) { return $null }
    if ($Target.Name -like "*$SearchBarNameSuffix") { return $Target }

    $Current = $Target.Parent
    while ($null -ne $Current) {
        if ($Current.Name -like "*$SearchBarNameSuffix") {
            Stop-FunctionMeasurement -FunctionName "Resolve-SearchBar"
            return $Current
        }
        $Current = $Current.Parent
    }

    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
    if ($Found -is [array]) { return $Found[0] }
    Stop-FunctionMeasurement -FunctionName "Resolve-SearchBar"
    return $Found
} # function Resolve-SearchBar

function Expand-ElementParents {
    param([Parameter(Mandatory)]$Element)
    Start-FunctionMeasurement -FunctionName "Expand-ElementParents"
    $Curr = $Element
    while ($Curr -and $Curr -ne $BaseWindow) {
        $Parent = $Curr.Parent
        if (-not $Parent) { break }

        if ($Parent.Name -eq $ContentSlotElementName -and $Parent.Visibility -ne 'Visible') {
            $HeaderBorder = Get-ParentWrapperBorder -Element $Parent
            $MinMaxButton = if ($HeaderBorder) { Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$HeaderBorder) -FindWhere { $_.Name -eq $MinMaxButtonName } -FindMax 1) } else { $null }
            if ($MinMaxButton) {
                Set-ContentSlotCollapseState -ContentSlotElement $Parent -MinMaxButton $MinMaxButton -ContentHeaderBorder $HeaderBorder -Collapse $false
            }
            else {
                $Parent.Visibility = 'Visible'
            }
        }
        $Curr = $Parent
    }
    Stop-FunctionMeasurement -FunctionName "Expand-ElementParents"
} # function Expand-ElementParents

function Set-BorderHighlight {
    param(
        [Parameter(Mandatory)]$Target,
        [ValidateSet('Match', 'Active')][string]$HighlightType = 'Match'
    )
    Start-FunctionMeasurement -FunctionName 'Set-BorderHighlight'
    if (-not $Target) { return }

    if ([string]::IsNullOrEmpty($Target.Uid)) {
        $Target.Uid = [guid]::NewGuid().ToString()
    }

    if (-not $SearchOriginalStyles.ContainsKey($Target.Uid)) {
        $SearchOriginalStyles[$Target.Uid] = @{
            Element         = $Target
            Type            = 'Control'
            BorderBrush     = $Target.BorderBrush
            BorderThickness = $Target.BorderThickness
        }
    }

    $BrushConverter = [System.Windows.Media.BrushConverter]::new()
    if ($HighlightType -eq 'Active') {
        $Target.BorderBrush = $BrushConverter.ConvertFromString('#E67E22')
        $Target.BorderThickness = [System.Windows.Thickness]::new(3.5)
    }
    else {
        $Target.BorderBrush = $BrushConverter.ConvertFromString('#F1C40F')
        $Target.BorderThickness = [System.Windows.Thickness]::new(2.5)
    }

    Stop-FunctionMeasurement -FunctionName 'Set-BorderHighlight'
} # function Set-BorderHighlight

function Set-ElementHighlight {
    param(
        [Parameter(Mandatory)][ref]$Element,
        [ValidateSet('Match', 'Active')][string]$HighlightType = 'Match',
        [string]$Query = '',
        [regex]$CompiledRegex = $null
    )
    Start-FunctionMeasurement -FunctionName 'Set-ElementHighlight'
    $Target = Resolve-TargetElement $Element
    if (-not $Target) { return }

    if ([string]::IsNullOrEmpty($Target.Uid)) {
        $Target.Uid = [guid]::NewGuid().ToString()
    }

    # Expand any collapsed parent container so this item is visible
    Expand-ElementParents -Element $Target

    $BrushConverter = [System.Windows.Media.BrushConverter]::new()
    $ShouldHighlightParentBorder = $false

    if ($Target -is [System.Windows.Controls.TextBlock]) {
        if (-not $SearchOriginalStyles.ContainsKey($Target.Uid)) {
            $SearchOriginalStyles[$Target.Uid] = @{
                Element    = $Target
                Type       = 'TextBlock'
                Background = $Target.Background
                Foreground = $Target.Foreground
                FontWeight = $Target.FontWeight
            }
        }

        if ($HighlightType -eq 'Active') {
            $Target.Background = $BrushConverter.ConvertFromString('#E67E22')
            $Target.Foreground = $BrushConverter.ConvertFromString('#FFFFFF')
            $Target.FontWeight = [System.Windows.FontWeights]::Bold
        }
        else {
            $Target.Background = $BrushConverter.ConvertFromString('#F1C40F')
            $Target.Foreground = $BrushConverter.ConvertFromString('#1E1E1E')
            $Target.FontWeight = [System.Windows.FontWeights]::Bold
        }

        $ShouldHighlightParentBorder = $true
    }
    elseif ($Target -is [System.Windows.Controls.RichTextBox]) {
        # RichTextBox: Highlight control border AND matching text in document
        if (-not $SearchOriginalStyles.ContainsKey($Target.Uid)) {
            $Range = New-Object System.Windows.Documents.TextRange($Target.Document.ContentStart, $Target.Document.ContentEnd)
            $SearchOriginalStyles[$Target.Uid] = @{
                Element         = $Target
                Type            = 'RichTextBox'
                BorderBrush     = $Target.BorderBrush
                BorderThickness = $Target.BorderThickness
                OriginalText    = $Range.Text.TrimEnd("`r`n")
            }
        }

        Set-BorderHighlight -Target $Target -HighlightType $HighlightType

        $OrigText = $SearchOriginalStyles[$Target.Uid].OriginalText
        if ((-not [string]::IsNullOrEmpty($Query) -or $CompiledRegex) -and -not [string]::IsNullOrEmpty($OrigText)) {
            $BgBrush = if ($HighlightType -eq 'Active') { $BrushConverter.ConvertFromString('#E67E22') } else { $BrushConverter.ConvertFromString('#F1C40F') }
            $FgBrush = if ($HighlightType -eq 'Active') { $BrushConverter.ConvertFromString('#FFFFFF') } else { $BrushConverter.ConvertFromString('#1E1E1E') }

            $Paragraph = New-Object System.Windows.Documents.Paragraph
            $Paragraph.Margin = [System.Windows.Thickness]::new(0)

            $CurrentIdx = 0
            if ($CompiledRegex) {
                $RMatches = $CompiledRegex.Matches($OrigText)
                foreach ($RMatch in $RMatches) {
                    if ($RMatch.Length -eq 0) { continue }
                    if ($RMatch.Index -ge $CurrentIdx) {
                        if ($RMatch.Index -gt $CurrentIdx) {
                            $Before = $OrigText.Substring($CurrentIdx, $RMatch.Index - $CurrentIdx)
                            $Paragraph.Inlines.Add((New-Object System.Windows.Documents.Run($Before))) | Out-Null
                        }
                        $MatchedText = $RMatch.Value
                        $MatchedRun = New-Object System.Windows.Documents.Run($MatchedText)
                        $MatchedRun.Background = $BgBrush
                        $MatchedRun.Foreground = $FgBrush
                        $MatchedRun.FontWeight = [System.Windows.FontWeights]::Bold
                        $Paragraph.Inlines.Add($MatchedRun) | Out-Null
                        $CurrentIdx = $RMatch.Index + $RMatch.Length
                    }
                }
                if ($CurrentIdx -lt $OrigText.Length) {
                    $Remaining = $OrigText.Substring($CurrentIdx)
                    $Paragraph.Inlines.Add((New-Object System.Windows.Documents.Run($Remaining))) | Out-Null
                }
            }
            else {
                $QueryLen = $Query.Length
                while ($CurrentIdx -lt $OrigText.Length) {
                    $MatchIdx = $OrigText.IndexOf($Query, $CurrentIdx, [System.StringComparison]::CurrentCultureIgnoreCase)
                    if ($MatchIdx -eq -1) {
                        $Remaining = $OrigText.Substring($CurrentIdx)
                        $Paragraph.Inlines.Add((New-Object System.Windows.Documents.Run($Remaining))) | Out-Null
                        break
                    }

                    if ($MatchIdx -gt $CurrentIdx) {
                        $Before = $OrigText.Substring($CurrentIdx, $MatchIdx - $CurrentIdx)
                        $Paragraph.Inlines.Add((New-Object System.Windows.Documents.Run($Before))) | Out-Null
                    }

                    $MatchedText = $OrigText.Substring($MatchIdx, $QueryLen)
                    $MatchedRun = New-Object System.Windows.Documents.Run($MatchedText)
                    $MatchedRun.Background = $BgBrush
                    $MatchedRun.Foreground = $FgBrush
                    $MatchedRun.FontWeight = [System.Windows.FontWeights]::Bold
                    $Paragraph.Inlines.Add($MatchedRun) | Out-Null

                    $CurrentIdx = $MatchIdx + $QueryLen
                }
            }

            $Target.Document.Blocks.Clear()
            $Target.Document.Blocks.Add($Paragraph)
        }

        $ShouldHighlightParentBorder = $true
    }
    else {
        Set-BorderHighlight -Target $Target -HighlightType $HighlightType
        if ($Target.Name -eq $ContentElementName -or $Target.Name -eq $ContentDateTimeDisplayTextBoxName) {
            $ShouldHighlightParentBorder = $true
        }
    }

    if ($ShouldHighlightParentBorder) {
        $ParentFieldBorder = Get-ParentWrapperBorder -Element $Target
        if ($ParentFieldBorder) {
            Set-BorderHighlight -Target $ParentFieldBorder -HighlightType $HighlightType
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Set-ElementHighlight'
} # function Set-ElementHighlight

function Reset-ElementHighlight {
    param([Parameter(Mandatory)][ref]$Element)
    Start-FunctionMeasurement -FunctionName "Reset-ElementHighlight"
    $Target = Resolve-TargetElement $Element
    if (-not $Target) { return }

    Restore-ElementSearchStyle -Element $Target

    # Reset parent field border if it was highlighted
    $ParentFieldBorder = Get-ParentWrapperBorder -Element $Target
    if ($ParentFieldBorder) {
        Restore-ElementSearchStyle -Element $ParentFieldBorder
    }
    Stop-FunctionMeasurement -FunctionName "Reset-ElementHighlight"
} # function Reset-ElementHighlight

function Test-ElementMatchesQuery {
    param(
        [Parameter(Mandatory)]$Element,
        [Parameter(Mandatory)][string]$Query,
        [regex]$CompiledRegex = $null
    )
    Start-FunctionMeasurement -FunctionName "Test-ElementMatchesQuery"
    if ([string]::IsNullOrWhiteSpace($Query) -and $null -eq $CompiledRegex) { return $false }

    $TestString = {
        param($Text)
        if ([string]::IsNullOrEmpty($Text)) { return $false }
        if ($CompiledRegex) {
            return $CompiledRegex.IsMatch($Text)
        }
        else {
            return ($Text.IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0)
        }
    }

    $MatchedParts = [System.Collections.ArrayList]@()

    # Unified single-pass match across all search candidates inside element
    $AllItemsToTest = [System.Collections.ArrayList]@()
    [void]$AllItemsToTest.Add($Element)
    $CandidateElements = Find-ObjectWhere -Object ([ref]$Element) -FindWhere {
        $_.Name -eq $ContentHeaderTitleValueName -or
        $_.Name -eq $ContentHeaderDescriptionValueName -or
        $_.Name -eq $ContentElementName -or
        $_.Name -eq $CustomDateTimePickerName -or
        $_.Name -like "*$IndexBoxNameSuffix"
    }
    if ($CandidateElements) {
        foreach ($Cand in $CandidateElements) {
            [void]$AllItemsToTest.Add($Cand)
        }
    }

    foreach ($Item in $AllItemsToTest) {
        $ItemName = $Item.Name
        if ($ItemName -eq $ContentHeaderTitleValueName) {
            if (& $TestString $Item.Text) {
                [void]$MatchedParts.Add($Item)
            }
        }
        elseif ($ItemName -eq $ContentHeaderDescriptionValueName) {
            if (& $TestString $Item.Text) {
                [void]$MatchedParts.Add($Item)
            }
        }
        elseif ($ItemName -eq $ContentElementName) {
            $Val = Get-ContentValue $Item
            if ($null -ne $Val) {
                $StrVal = "$Val"
                if (& $TestString $StrVal) {
                    [void]$MatchedParts.Add($Item)
                }
            }
            if ($Item -is [System.Windows.Controls.ComboBox] -and $Item.ItemsSource) {
                foreach ($Opt in $Item.ItemsSource) {
                    if ($Opt -and (& $TestString "$Opt")) {
                        if (-not $MatchedParts.Contains($Item)) {
                            [void]$MatchedParts.Add($Item)
                        }
                        break
                    }
                }
            }
        }
        elseif ($ItemName -eq $CustomDateTimePickerName) {
            $DateBox = if ($Item.Tag -is [hashtable] -and $Item.Tag.ContainsKey('DisplayTextBox') -and $Item.Tag.DisplayTextBox) {
                $Item.Tag.DisplayTextBox
            }
            else {
                Find-ObjectWhere -Object ([ref]$Item) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
            }
            if ($DateBox -and (& $TestString $DateBox.Text)) {
                [void]$MatchedParts.Add($DateBox)
            }
        }
        elseif ($ItemName -like "*$IndexBoxNameSuffix") {
            if ($Item.Text) {
                $IVal = $Item.Text.Trim()
                if ($CompiledRegex) {
                    if ($CompiledRegex.IsMatch($IVal)) {
                        [void]$MatchedParts.Add($Item)
                    }
                }
                elseif ($IVal -eq $Query.Trim()) {
                    [void]$MatchedParts.Add($Item)
                }
            }
        }
    }

    if ($MatchedParts.Count -gt 0) {
        return $MatchedParts
    }
    Stop-FunctionMeasurement -FunctionName "Test-ElementMatchesQuery"
    return $null
} # function Test-ElementMatchesQuery

function Clear-SearchHighlights {
    param([Parameter(Mandatory)][ref]$SearchBar)
    Start-FunctionMeasurement -FunctionName "Clear-SearchHighlights"

    # Clean up all highlighted elements in $SearchOriginalStyles
    if ($SearchOriginalStyles.Count -gt 0) {
        $Uids = @($SearchOriginalStyles.Keys)
        foreach ($Uid in $Uids) {
            $Entry = $SearchOriginalStyles[$Uid]
            if ($Entry -and $Entry.Element) {
                Restore-ElementSearchStyle -Element $Entry.Element
            }
        }
        $SearchOriginalStyles.Clear()
    }

    if ($SearchBar.Value.Tag) {
        if ($SearchBar.Value.Tag.Matches) {
            $SearchBar.Value.Tag.Matches.Clear()
        }
        $SearchBar.Value.Tag.CurrentIndex = -1
        $SearchBar.Value.Tag.Query = ''
        $SearchBar.Value.Tag.CompiledRegex = $null
    }

    $CountBlock = Find-ObjectWhere -Object $SearchBar -FindWhere { $_.Name -like "*$SearchCountNameSuffix" } -FindMax 1
    if ($CountBlock) { $CountBlock.Text = '' }
    Stop-FunctionMeasurement -FunctionName "Clear-SearchHighlights"
} # function Clear-SearchHighlights

function Close-SearchBar {
    param([Parameter(Mandatory)]$ChildElement)
    Start-FunctionMeasurement -FunctionName "Close-SearchBar"
    $SearchBar = Resolve-SearchBar $ChildElement
    if (-not $SearchBar) { return }

    $ActionsButton = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchActionsButtonNameSuffix" } -FindMax 1
    if ($ActionsButton -and $ActionsButton.Tag) {
        $ActionsButton.Tag.IsOpen = $false
    }

    # Restore visibility on any filtered items
    $SlotInfo = Get-MatchedSlotItems -ChildElement $SearchBar
    if ($SlotInfo -and $SlotInfo.ContentSlot) {
        foreach ($Child in $SlotInfo.ContentSlot.Children) {
            $Child.Visibility = 'Visible'
        }
    }

    Clear-SearchHighlights -SearchBar ([ref]$SearchBar)
    $SearchBar.Visibility = 'Collapsed'

    $ContentHeaderBorder = Get-ParentWrapperBorder -Element $SearchBar -HeaderOnly
    if ($ContentHeaderBorder) {
        $Menu = Get-WrapperMenu -Wrapper $ContentHeaderBorder
        if ($Menu) {
            Ensure-WrapperActionButtons -Element $Target
            $SearchButton = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" } -FindMax 1)
            if ($SearchButton -and $SearchButton.Parent -and $SearchButton.Parent.Name -eq $MenuName) {
                $SearchButton.Header = $SearchButtonHeader
                $SearchButton.Icon = $SearchButtonIcon
                $SearchButton.ToolTip = $SearchButtonToolTip
                Move-MenuItemBetweenMenus -Item $SearchButton -Direction 'ToButtonMenu'
                $SearchButton.Tag = $null
            }
        }
    }
    Stop-FunctionMeasurement -FunctionName "Close-SearchBar"
} # function Close-SearchBar

function Invoke-SearchExecution {
    param([Parameter(Mandatory)]$SearchBox)
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchExecution'

    $SearchBar = Resolve-SearchBar $SearchBox
    if (-not $SearchBar) { return }

    $ContentHeaderBorder = Get-ParentWrapperBorder -Element $SearchBar -HeaderOnly
    if (-not $ContentHeaderBorder) { return }

    $ContentSlot = Get-WrapperContentSlot -Wrapper $ContentHeaderBorder
    if (-not $ContentSlot) { return }

    Clear-SearchHighlights -SearchBar ([ref]$SearchBar)

    $Query = $SearchBox.Text
    $CountBlock = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchCountNameSuffix" } -FindMax 1

    if ([string]::IsNullOrWhiteSpace($Query)) {
        if ($CountBlock) { $CountBlock.Text = '' }
        return
    }

    $UseRegex = if ($SearchBar.Tag -and $SearchBar.Tag.ContainsKey('UseRegex')) { [bool]$SearchBar.Tag.UseRegex } else { $true }
    $CompiledRegex = $null

    try {
        $RegexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        if ($UseRegex) {
            $CompiledRegex = [regex]::new($Query, $RegexOptions)
        }
        else {
            $CompiledRegex = [regex]::new([regex]::Escape($Query), $RegexOptions)
        }
    }
    catch {
        if ($CountBlock) {
            $CountBlock.Text = 'Invalid regex'
            $CountBlock.Foreground = '#FF7675'
        }
        return
    }

    $MatchedElements = [System.Collections.ArrayList]@()
    :Children foreach ($Child in @($ContentSlot.Children)) {
        $Matches = Test-ElementMatchesQuery -Element $Child -Query $Query -CompiledRegex $CompiledRegex
        if ($Matches) {
            :Matches foreach ($MatchItem in $Matches) {
                if (-not $MatchedElements.Contains($MatchItem)) {
                    [void]$MatchedElements.Add($MatchItem)
                }
            }
        }
    }

    if ($MatchedElements.Count -eq 0) {
        if ($CountBlock) {
            $CountBlock.Text = '0 / 0'
            $CountBlock.Foreground = '#FF7675'
        }
        return
    }

    $SearchBar.Tag.Query = $Query
    $SearchBar.Tag.CompiledRegex = $CompiledRegex
    $IsSearchBarVisible = ($SearchBar.Visibility -eq 'Visible')
    if ($IsSearchBarVisible) {
        :Matches foreach ($Match in $MatchedElements) {
            Set-ElementHighlight -Element ([ref]$Match) -HighlightType 'Match' -Query $Query -CompiledRegex $CompiledRegex
        }

    }

    $SearchBar.Tag.Matches = $MatchedElements
    $SearchBar.Tag.CurrentIndex = 0
    if ($IsSearchBarVisible) {
        Set-ElementHighlight -Element ([ref]$MatchedElements[0]) -HighlightType 'Active' -Query $Query -CompiledRegex $CompiledRegex
        $MatchedElements[0].BringIntoView()
    
    }


    if ($CountBlock) {
        $CountBlock.Text = "1 / $($MatchedElements.Count)"
        $CountBlock.Foreground = '#C1B8D1'
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchExecution'
} # function Invoke-SearchExecution

function Step-SearchMatch {
    param(
        [Parameter(Mandatory)]$ChildElement,
        [ValidateSet('Next', 'Prev')][string]$Direction = 'Next'
    )
    Start-FunctionMeasurement -FunctionName "Step-SearchMatch"

    $SearchBar = Resolve-SearchBar $ChildElement
    if (-not $SearchBar -or -not $SearchBar.Tag -or $SearchBar.Tag.Matches.Count -eq 0) { return }

    $ValidMatches = [System.Collections.ArrayList]@($SearchBar.Tag.Matches | Where-Object { $null -ne $_.Parent })
    if ($ValidMatches.Count -eq 0) {
        Clear-SearchHighlights -SearchBar ([ref]$SearchBar)
        return
    }
    $SearchBar.Tag.Matches = $ValidMatches

    $Matches = $SearchBar.Tag.Matches
    $CurrentIdx = $SearchBar.Tag.CurrentIndex
    $Query = if ($SearchBar.Tag -and $SearchBar.Tag.Query) { $SearchBar.Tag.Query } else { '' }
    $CompiledRegex = if ($SearchBar.Tag -and $SearchBar.Tag.ContainsKey('CompiledRegex')) { $SearchBar.Tag.CompiledRegex } else { $null }

    if ($CurrentIdx -ge 0 -and $CurrentIdx -lt $Matches.Count) {
        Set-ElementHighlight -Element ([ref]$Matches[$CurrentIdx]) -HighlightType 'Match' -Query $Query -CompiledRegex $CompiledRegex
    }

    if ($Direction -eq 'Next') {
        $NewIdx = ($CurrentIdx + 1) % $Matches.Count
    }
    else {
        $NewIdx = ($CurrentIdx - 1 + $Matches.Count) % $Matches.Count
    }

    $SearchBar.Tag.CurrentIndex = $NewIdx
    Set-ElementHighlight -Element ([ref]$Matches[$NewIdx]) -HighlightType 'Active' -Query $Query -CompiledRegex $CompiledRegex
    $Matches[$NewIdx].BringIntoView()

    $CountBlock = if ($SearchBar.Tag -is [hashtable] -and $SearchBar.Tag.ContainsKey('SearchCount') -and $SearchBar.Tag.SearchCount) {
        $SearchBar.Tag.SearchCount
    }
    else {
        Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchCountNameSuffix" } -FindMax 1
    }
    if ($CountBlock) {
        $CountBlock.Text = "$($NewIdx + 1) / $($Matches.Count)"
        $CountBlock.Foreground = '#C1B8D1'
    }
    Stop-FunctionMeasurement -FunctionName "Step-SearchMatch"
} # function Step-SearchMatch

function Get-WrapperSearchState {
    param(
        [Parameter(Mandatory)]$Wrapper
    )
    Start-FunctionMeasurement -FunctionName "Get-WrapperSearchState"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }

    # Stop at child wrappers so we only inspect the search bar of this wrapper
    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }
    $SearchBar = if ($Tag.ContainsKey('SearchBar')) { $Tag.SearchBar } else { Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1 }
    if ($SearchBar -is [array]) { $SearchBar = $SearchBar[0] }
    if (-not $SearchBar) { return $null }

    $SearchInput = if ($SearchBar.Tag -is [hashtable] -and $SearchBar.Tag.ContainsKey('SearchInput') -and $SearchBar.Tag.SearchInput) {
        $SearchBar.Tag.SearchInput
    }
    else {
        Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchInputNameSuffix" } -FindMax 1
    }
    if ($SearchInput -is [array]) { $SearchInput = $SearchInput[0] }
    if (-not $SearchInput) { return $null }

    $QueryText = if ($SearchInput.Text) { $SearchInput.Text } else { '' }
    if ([string]::IsNullOrWhiteSpace($QueryText)) { return $null }

    $UseRegex = if ($SearchBar.Tag -is [hashtable] -and $SearchBar.Tag.ContainsKey('UseRegex')) {
        [bool]$SearchBar.Tag.UseRegex
    }
    else {
        $true
    }

    $IsOpen = ($SearchBar.Visibility -eq 'Visible')
    $CurrentIndex = if ($SearchBar.Tag -is [hashtable] -and $SearchBar.Tag.ContainsKey('CurrentIndex') -and $null -ne $SearchBar.Tag.CurrentIndex) {
        [int]$SearchBar.Tag.CurrentIndex
    }
    else {
        -1
    }

    $SearchData = [ordered]@{
        query        = $QueryText
        useRegex     = $UseRegex
        isOpen       = $IsOpen
        currentIndex = $CurrentIndex
    }

    Stop-FunctionMeasurement -FunctionName "Get-WrapperSearchState"
    return $SearchData
} # function Get-WrapperSearchState

function Set-WrapperSearchState {
    param(
        [Parameter(Mandatory)]$Wrapper,
        $SearchData
    )
    Start-FunctionMeasurement -FunctionName 'Set-WrapperSearchState'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    if ($null -eq $SearchData) {
        if ($Tag.ContainsKey('SearchBar') -and $Tag.SearchBar -and $Tag.SearchBar.Visibility -eq 'Visible') {
            Close-SearchBar -ChildElement $Tag.SearchBar
        }
        return
    }

    $SearchBar = if ($Tag.ContainsKey('SearchBar') -and $Tag.SearchBar) { $Tag.SearchBar } else { Get-OrCreateSearchBar -ContentHeaderBorder $Target }
    if (-not $SearchBar) { return }

    $QueryEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $SearchData -PropertyName 'Query'
    $UseRegexEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $SearchData -PropertyName 'UseRegex'
    $IsOpenEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $SearchData -PropertyName 'IsOpen'
    $CurrentIndexEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $SearchData -PropertyName 'CurrentIndex'

    $Query = if ($null -ne $QueryEntry -and $null -ne $QueryEntry.Value) { [string]$QueryEntry.Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($Query)) {
        if ($SearchBar.Visibility -eq 'Visible') {
            Close-SearchBar -ChildElement $SearchBar
        }
        return
    }

    $UseRegex = if ($null -ne $UseRegexEntry -and $null -ne $UseRegexEntry.Value) { [bool]$UseRegexEntry.Value } else { $true }
    $IsOpen = if ($null -ne $IsOpenEntry -and $null -ne $IsOpenEntry.Value) { [bool]$IsOpenEntry.Value } else { $true }
    $TargetCurrentIndex = if ($null -ne $CurrentIndexEntry -and $null -ne $CurrentIndexEntry.Value) { [int]$CurrentIndexEntry.Value } else { 0 }

    # Validate regular expression pattern; if invalid, fall back to literal matching
    if ($UseRegex) {
        try {
            $null = [regex]::new($Query, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
        catch {
            $UseRegex = $false
        }
    }

    # Update regex button visual state
    if (-not ($SearchBar.Tag -is [hashtable])) {
        $SearchBar.Tag = @{}
    }
    $SearchBar.Tag.UseRegex = $UseRegex

    $RegexButton = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchRegexButtonNameSuffix" } -FindMax 1
    if ($RegexButton -is [array]) { $RegexButton = $RegexButton[0] }
    if ($RegexButton) {
        if ($UseRegex) {
            $RegexButton.Background = '#504368'
            $RegexButton.BorderBrush = '#8879A1'
            $RegexButton.ToolTip = $SearchRegexButtonToolTipEnabled
        }
        else {
            $RegexButton.Background = 'Transparent'
            $RegexButton.BorderBrush = 'Transparent'
            $RegexButton.ToolTip = $SearchRegexButtonToolTipDisabled
        }
    }

    # Open search bar if desired
    if ($IsOpen) {
        $ContentSlot = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
        if ($ContentSlot -and $ContentSlot.Visibility -ne 'Visible') {
            $MinMaxButton = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $MinMaxButtonName } -FindMax 1)
            if ($MinMaxButton) {
                Set-ContentSlotCollapseState -ContentSlotElement $ContentSlot -MinMaxButton $MinMaxButton -ContentHeaderBorder $Target -Collapse $false
            }
            else {
                $ContentSlot.Visibility = 'Visible'
            }
        }

        $Menu = Get-WrapperMenu -Wrapper $Target
        if ($Menu) {
            Ensure-WrapperActionButtons -Element $Target
            $SearchButton = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" } -FindMax 1)
            if ($SearchButton -and $SearchButton.Parent -and $SearchButton.Parent.Name -eq $ButtonMenuName) {
                $SearchButton.Header = $SearchButtonIcon
                $SearchButton.Icon = $null
                $SearchButton.ToolTip = $SearchButtonToolTipActive
                Move-MenuItemBetweenMenus -Item $SearchButton -Direction 'ToCustomMenu'
            }
        }

        $SearchBar.Visibility = 'Visible'
        if ($script:UniversalSharedMenu) {
            $SharedMenuItem = Find-ObjectWhere -Object ([ref]$script:UniversalSharedMenu) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
            if ($SharedMenuItem) { $SharedMenuItem.IsSubmenuOpen = $false }
        }
    }
    else {
        $SearchBar.Visibility = 'Collapsed'
    }

    # Update query text and execute search
    $SearchInput = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchInputNameSuffix" } -FindMax 1
    if ($SearchInput -is [array]) { $SearchInput = $SearchInput[0] }
    if ($SearchInput) {
        $SearchInput.Text = $Query

        # Defer execution to background dispatcher frame so UI renders immediately
        $DeferredSearchAction = ({
                if (-not $SearchInput) { return }
                Invoke-SearchExecution -SearchBox $SearchInput

                # If a specific match index was saved and matches exist, navigate to that index
                if ($IsOpen -and $SearchBar.Tag -and $SearchBar.Tag.Matches -and $SearchBar.Tag.Matches.Count -gt 0) {
                    $MatchCount = $SearchBar.Tag.Matches.Count
                    if ($TargetCurrentIndex -lt 0) { $TargetCurrentIndex = 0 }
                    if ($TargetCurrentIndex -ge $MatchCount) { $TargetCurrentIndex = $MatchCount - 1 }

                    if ($TargetCurrentIndex -ne $SearchBar.Tag.CurrentIndex) {
                        $OldIdx = $SearchBar.Tag.CurrentIndex
                        $CompiledRegex = if ($SearchBar.Tag.ContainsKey('CompiledRegex')) { $SearchBar.Tag.CompiledRegex } else { $null }

                        if ($OldIdx -ge 0 -and $OldIdx -lt $MatchCount) {
                            Set-ElementHighlight -Element ([ref]$SearchBar.Tag.Matches[$OldIdx]) -HighlightType 'Match' -Query $Query -CompiledRegex $CompiledRegex
                        }

                        $SearchBar.Tag.CurrentIndex = $TargetCurrentIndex
                        Set-ElementHighlight -Element ([ref]$SearchBar.Tag.Matches[$TargetCurrentIndex]) -HighlightType 'Active' -Query $Query -CompiledRegex $CompiledRegex
                        $SearchBar.Tag.Matches[$TargetCurrentIndex].BringIntoView()

                        $CountBlock = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchCountNameSuffix" } -FindMax 1
                        if ($CountBlock) {
                            $CountBlock.Text = "$($TargetCurrentIndex + 1) / $MatchCount"
                            $CountBlock.Foreground = '#C1B8D1'
                        }
                    }
                }
            }).GetNewClosure()

        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [System.Action]$DeferredSearchAction
        ) | Out-Null
    }

    Stop-FunctionMeasurement -FunctionName 'Set-WrapperSearchState'
} # function Set-WrapperSearchState

#endregion #4 Search

#region #4 Filter

function Get-MatchedSlotItems {
    param(
        [Parameter(Mandatory)]$ChildElement
    )
    Start-FunctionMeasurement -FunctionName "Get-MatchedSlotItems"
    $SearchBar = Resolve-SearchBar $ChildElement
    if (-not $SearchBar) { return $null }

    $ContentHeaderBorder = Get-ParentWrapperBorder -Element $SearchBar -HeaderOnly
    if (-not $ContentHeaderBorder) { return $null }

    $ContentSlot = Get-WrapperContentSlot -Wrapper $ContentHeaderBorder
    if (-not $ContentSlot -or $ContentSlot.Children.Count -eq 0) { return $null }

    $MatchedElements = if ($SearchBar.Tag -and $SearchBar.Tag.Matches) { $SearchBar.Tag.Matches } else { @() }

    $MatchedItems = [System.Collections.ArrayList]@()
    $NonMatchedItems = [System.Collections.ArrayList]@()

    foreach ($ChildItem in @($ContentSlot.Children)) {
        $HasMatch = $false
        foreach ($MatchEl in $MatchedElements) {
            $Curr = $MatchEl
            while ($Curr -and $Curr -ne $ContentSlot) {
                if ($Curr -eq $ChildItem) {
                    $HasMatch = $true
                    break
                }
                $Curr = $Curr.Parent
            }
            if ($HasMatch) { break }
        }

        if ($HasMatch) {
            [void]$MatchedItems.Add($ChildItem)
        }
        else {
            [void]$NonMatchedItems.Add($ChildItem)
        }
    }

    return @{
        SearchBar   = $SearchBar
        ContentSlot = $ContentSlot
        Matched     = $MatchedItems
        NonMatched  = $NonMatchedItems
    }
    Stop-FunctionMeasurement -FunctionName "Get-MatchedSlotItems"
} # function Get-MatchedSlotItems

function Invoke-SearchFilterAction {
    param(
        [Parameter(Mandatory)]$ChildElement,
        [ValidateSet('ShowOnly', 'Hide', 'ShowAll')][string]$Action = 'ShowOnly'
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchFilterAction'
    $SlotInfo = Get-MatchedSlotItems -ChildElement $ChildElement
    if (-not $SlotInfo) { return }

    $SearchBar = $SlotInfo.SearchBar
    $CountBlock = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchCountNameSuffix" } -FindMax 1

    switch ($Action) {
        'ShowOnly' {
            foreach ($Item in $SlotInfo.NonMatched) { $Item.Visibility = 'Collapsed' }
            foreach ($Item in $SlotInfo.Matched) { $Item.Visibility = 'Visible' }
            $Total = $SlotInfo.ContentSlot.Children.Count
            $VisibleCount = $SlotInfo.Matched.Count
            if ($CountBlock) {
                $CountBlock.Text = "Filtered: $VisibleCount / $Total"
                $CountBlock.Foreground = '#F1C40F'
            }
        }
        'Hide' {
            foreach ($Item in $SlotInfo.Matched) { $Item.Visibility = 'Collapsed' }
            foreach ($Item in $SlotInfo.NonMatched) { $Item.Visibility = 'Visible' }
            $Total = $SlotInfo.ContentSlot.Children.Count
            $VisibleCount = $SlotInfo.NonMatched.Count
            if ($CountBlock) {
                $CountBlock.Text = "Filtered: $VisibleCount / $Total"
                $CountBlock.Foreground = '#F1C40F'
            }
        }
        'ShowAll' {
            foreach ($Item in $SlotInfo.ContentSlot.Children) { $Item.Visibility = 'Visible' }
            if ($CountBlock -and $SearchBar.Tag -and $SearchBar.Tag.Matches) {
                $MatchCount = $SearchBar.Tag.Matches.Count
                $CurrIdx = $SearchBar.Tag.CurrentIndex
                if ($MatchCount -gt 0) {
                    $CountBlock.Text = "$($CurrIdx + 1) / $MatchCount"
                    $CountBlock.Foreground = '#C1B8D1'
                }
                else {
                    $CountBlock.Text = ''
                }
            }
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchFilterAction'
} # function Invoke-SearchFilterAction

#endregion #4 Filter

#region #4 Batch

function Get-MatchedWrappers {
    param(
        [Parameter(Mandatory)]$ChildElement
    )
    Start-FunctionMeasurement -FunctionName "Get-MatchedWrappers"
    $SearchBar = Resolve-SearchBar $ChildElement
    if (-not $SearchBar) { return $null }

    $MatchedElements = if ($SearchBar.Tag -and $SearchBar.Tag.Matches) { @($SearchBar.Tag.Matches) } else { @() }
    $MatchedWrappers = [System.Collections.ArrayList]@()

    foreach ($MatchEl in $MatchedElements) {
        if (-not $MatchEl) { continue }
        $Wrapper = Get-ParentWrapperBorder -Element $MatchEl
        if ($Wrapper -and -not $MatchedWrappers.Contains($Wrapper)) {
            [void]$MatchedWrappers.Add($Wrapper)
        }
    }

    return @{
        SearchBar = $SearchBar
        Matched   = $MatchedWrappers
    }
    Stop-FunctionMeasurement -FunctionName "Get-MatchedWrappers"
} # function Get-MatchedWrappers

function Invoke-SearchMatchesSort {
    param(
        [Parameter(Mandatory)]$SearchBar,
        [ValidateSet('Ascending', 'Descending')][string]$Direction = 'Ascending'
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchMatchesSort'
    $MatchedElements = if ($SearchBar.Tag -and $SearchBar.Tag.Matches) { @($SearchBar.Tag.Matches) } else { @() }
    if ($MatchedElements.Count -eq 0) { return }

    $SearchContainer = Get-ParentWrapperBorder -Element $SearchBar -HeaderOnly
    $PrimarySlot = if ($SearchContainer -and $SearchContainer.Tag -is [hashtable] -and $SearchContainer.Tag.IsArray) {
        Get-WrapperContentSlot -Wrapper $SearchContainer
    }
    else { $null }

    $SlotGroups = [ordered]@{}

    foreach ($MatchEl in $MatchedElements) {
        if (-not $MatchEl) { continue }

        $ArrayItemWrapper = $null
        $Curr = $MatchEl
        while ($Curr -and $Curr -ne $BaseWindow) {
            $Parent = $Curr.Parent
            if ($PrimarySlot) {
                if ($Parent -eq $PrimarySlot) {
                    $ArrayItemWrapper = $Curr
                    break
                }
            }
            elseif ($Parent -and $Parent.Name -eq $ContentSlotElementName -and (Get-IsArrayItem -Wrapper $Curr)) {
                $ArrayItemWrapper = $Curr
                break
            }
            $Curr = $Parent
        }

        if (-not $ArrayItemWrapper -or -not $ArrayItemWrapper.Parent) { continue }
        $ParentSlot = $ArrayItemWrapper.Parent
        $SlotKey = if (-not [string]::IsNullOrEmpty($ParentSlot.Uid)) { $ParentSlot.Uid } else { $ParentSlot.GetHashCode().ToString() }

        if (-not $SlotGroups.Contains($SlotKey)) {
            $SlotGroups[$SlotKey] = @{
                Slot  = $ParentSlot
                Items = [ordered]@{}
            }
        }

        $ItemKey = if (-not [string]::IsNullOrEmpty($ArrayItemWrapper.Uid)) { $ArrayItemWrapper.Uid } else { $ArrayItemWrapper.GetHashCode().ToString() }
        $CandidateKey = $null
        if ($MatchEl.Name -eq $ContentHeaderTitleValueName -and -not [string]::IsNullOrWhiteSpace($MatchEl.Text)) {
            $CandidateKey = $MatchEl.Text.Trim()
        }
        else {
            $ImmediateWrapper = Get-ParentWrapperBorder -Element $MatchEl
            if ($ImmediateWrapper -and -not ($ImmediateWrapper.Tag -is [hashtable] -and $ImmediateWrapper.Tag.IsConstruct)) {
                $CandidateKey = Get-WrapperSortableScalarValue -Wrapper $ImmediateWrapper
            }
            if ($null -eq $CandidateKey) {
                $CandidateKey = Get-WrapperSortableScalarValue -Wrapper $ArrayItemWrapper
            }
            if ($null -eq $CandidateKey) {
                $CandidateKey = Get-WrapperDisplayName -Wrapper $ArrayItemWrapper
            }
            if ($null -eq $CandidateKey) {
                $CandidateKey = Get-ArrayItemSortKey -ItemWrapper $ArrayItemWrapper
            }
        }

        if (-not $SlotGroups[$SlotKey].Items.Contains($ItemKey)) {
            $SlotGroups[$SlotKey].Items[$ItemKey] = [PSCustomObject]@{
                Wrapper       = $ArrayItemWrapper
                SortKey       = $CandidateKey
                OriginalIndex = $ParentSlot.Children.IndexOf($ArrayItemWrapper)
            }
        }
        elseif ($null -eq $SlotGroups[$SlotKey].Items[$ItemKey].SortKey -and $null -ne $CandidateKey) {
            $SlotGroups[$SlotKey].Items[$ItemKey].SortKey = $CandidateKey
        }
    }

    $IsDescending = ($Direction -eq 'Descending')

    foreach ($GroupEntry in $SlotGroups.Values) {
        $ContentSlot = $GroupEntry.Slot
        $MatchedEntries = @($GroupEntry.Items.Values)
        if ($MatchedEntries.Count -eq 0) { continue }
        if (-not $ContentSlot.Children -or $ContentSlot.Children.Count -le 1) { continue }

        $ArrayBorder = Get-ParentWrapperBorder -Element $ContentSlot -HeaderOnly
        if ($ArrayBorder -and (Get-IsElementLockedSelf $ArrayBorder)) { continue }

        $MatchedWrappersList = [System.Collections.ArrayList]@()
        $NonEmptyEntries = [System.Collections.ArrayList]@()
        $EmptyEntries = [System.Collections.ArrayList]@()

        foreach ($Entry in $MatchedEntries) {
            [void]$MatchedWrappersList.Add($Entry.Wrapper)
            $IsEmpty = ($null -eq $Entry.SortKey) -or ($Entry.SortKey -is [string] -and [string]::IsNullOrWhiteSpace($Entry.SortKey))
            if ($IsEmpty) {
                [void]$EmptyEntries.Add($Entry)
            }
            else {
                [void]$NonEmptyEntries.Add($Entry)
            }
        }

        $SortedNonEmpty = if ($NonEmptyEntries.Count -gt 1) {
            @($NonEmptyEntries | Sort-Object -Property @{ Expression = { $_.SortKey }; Descending = $IsDescending }, @{ Expression = { $_.OriginalIndex }; Descending = $false })
        }
        else {
            @($NonEmptyEntries)
        }

        $FinalMatchedWrappers = @(($SortedNonEmpty + $EmptyEntries) | ForEach-Object { $_.Wrapper })
        $UnmatchedWrappers = [System.Collections.ArrayList]@()
        foreach ($ExistingChild in @($ContentSlot.Children)) {
            if (-not $MatchedWrappersList.Contains($ExistingChild)) {
                [void]$UnmatchedWrappers.Add($ExistingChild)
            }
        }

        $UpdatedChildren = @($FinalMatchedWrappers) + @($UnmatchedWrappers)

        $ContentSlot.Children.Clear()
        foreach ($ChildElem in $UpdatedChildren) {
            [void]$ContentSlot.Children.Add($ChildElem)
        }

        Reset-ArrayIndexes ([ref]$ContentSlot)
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchMatchesSort'
} # function Invoke-SearchMatchesSort

function Invoke-SearchBatchAction {
    param(
        [Parameter(Mandatory)]$ChildElement,
        [ValidateSet('SortAscending', 'SortDescending', 'Random', 'Clear', 'Disable', 'Enable', 'Delete', 'Lock', 'Unlock')][string]$Action = 'Random'
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchBatchAction'
    $MatchInfo = Get-MatchedWrappers -ChildElement $ChildElement
    if (-not $MatchInfo -or $MatchInfo.Matched.Count -eq 0) { return }

    $SearchBar = $MatchInfo.SearchBar
    $SearchInput = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchInputNameSuffix" } -FindMax 1

    switch ($Action) {
        'SortAscending' {
            Invoke-SearchMatchesSort -SearchBar $SearchBar -Direction 'Ascending'
        }
        'SortDescending' {
            Invoke-SearchMatchesSort -SearchBar $SearchBar -Direction 'Descending'
        }
        'Lock' {
            foreach ($Item in $MatchInfo.Matched) {
                Set-TargetLockedState -Target $Item -IsLocked $true
            }
        }
        'Unlock' {
            foreach ($Item in $MatchInfo.Matched) {
                Set-TargetLockedState -Target $Item -IsLocked $false
            }
        }
        'Random' {
            foreach ($Item in $MatchInfo.Matched) {
                if ($Item.Tag -is [hashtable] -and ($Item.Tag.IsArray -or $Item.Tag.IsConstruct)) { continue }
                Set-WrapperRandomContent -Wrapper ([ref]$Item)
            }
        }
        'Clear' {
            foreach ($Item in $MatchInfo.Matched) {
                if ($Item.Tag -is [hashtable] -and ($Item.Tag.IsArray -or $Item.Tag.IsConstruct)) { continue }
                Clear-WrapperContent -Wrapper ([ref]$Item)
            }
        }
        'Disable' {
            foreach ($Item in $MatchInfo.Matched) {
                if (Get-IsLocked $Item) { continue }
                if ($Item.Tag -is [hashtable] -and $Item.Tag.IsArray) { continue }
                Set-TargetDisabledState -Target $Item -IsDisabled $true
            }
        }
        'Enable' {
            foreach ($Item in $MatchInfo.Matched) {
                if (Get-IsLocked $Item) { continue }
                if ($Item.Tag -is [hashtable] -and $Item.Tag.IsArray) { continue }
                Set-TargetDisabledState -Target $Item -IsDisabled $false
            }
        }
        'Delete' {
            $AffectedSlots = [System.Collections.ArrayList]@()
            foreach ($Item in @($MatchInfo.Matched)) {
                if (Get-IsLocked $Item) { continue }
                $DelButton = Get-WrapperOwnActionButton -Element $Item -Suffix $DeleteButtonNameSuffix
                if ($DelButton -and $DelButton.Header -notlike '* All' -and $Item.Parent -and $Item.Parent.Name -eq $ContentSlotElementName) {
                    $ParentSlot = $Item.Parent
                    $ParentSlot.Children.Remove($Item)
                    if (-not $AffectedSlots.Contains($ParentSlot)) {
                        [void]$AffectedSlots.Add($ParentSlot)
                    }
                }
            }
            foreach ($Slot in $AffectedSlots) {
                Sync-ArraySlotState -ContentSlot $Slot
            }
            if ($SearchBar.Visibility -ne 'Visible') {
                return
            }
        }
    }

    if ($SearchInput) {
        Invoke-SearchExecution -SearchBox $SearchInput
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchBatchAction'
} # function Invoke-SearchBatchAction

#endregion #4 Batch

#endregion #3 Content Controls Actions

#region #3 Content Controls Elements

function Invoke-DateTimeNowButtonClick {
    param($Calendar, $HourCombo, $MinuteCombo, $SecondCombo)
    Start-FunctionMeasurement -FunctionName 'Invoke-DateTimeNowButtonClick'
    $now = Get-Date
    $Calendar.SelectedDate = $now.Date
    $Calendar.DisplayDate = $now.Date
    $HourCombo.SelectedItem = $now.ToString('HH')
    $MinuteCombo.SelectedItem = $now.ToString('mm')
    $SecondCombo.SelectedItem = $now.ToString('ss')

    Stop-FunctionMeasurement -FunctionName 'Invoke-DateTimeNowButtonClick'
} # function Invoke-DateTimeNowButtonClick

function Invoke-DateTimeOkButtonClick {
    param($Calendar, $HourCombo, $MinuteCombo, $SecondCombo, $PickButton, $Dialog)
    Start-FunctionMeasurement -FunctionName 'Invoke-DateTimeOkButtonClick'
    $selDate = if ($Calendar.SelectedDate) { $Calendar.SelectedDate } else { (Get-Date).Date }
    $h = [int]($HourCombo.SelectedItem -as [int])
    $m = [int]($MinuteCombo.SelectedItem -as [int])
    $s = [int]($SecondCombo.SelectedItem -as [int])

    $finalDateTime = [DateTime]::new($selDate.Year, $selDate.Month, $selDate.Day, $h, $m, $s)
    $CustomDateTimePicker = Find-ObjectWhere -Object ([ref]$PickButton) -FindWhere { $_.Name -eq $CustomDateTimePickerName }
    $ContentDateTimeDisplayTextBox = Find-ObjectWhere -Object ([ref]$CustomDateTimePicker) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName }
    $ContentDateTimeDisplayTextBox.Text = $finalDateTime.ToString('yyyy-MM-dd HH:mm:ss')
    $Dialog.Close()

    Stop-FunctionMeasurement -FunctionName 'Invoke-DateTimeOkButtonClick'
} # function Invoke-DateTimeOkButtonClick

function Invoke-DateTimeCancelButtonClick {
    param($Dialog)
    Start-FunctionMeasurement -FunctionName 'Invoke-DateTimeCancelButtonClick'
    $Dialog.Close()

    Stop-FunctionMeasurement -FunctionName 'Invoke-DateTimeCancelButtonClick'
} # function Invoke-DateTimeCancelButtonClick

function Invoke-SearchItemButtonClick {
    param($s, $e, $TargetButton, $ActionType, $ActionName)
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchItemButtonClick'
    if ($TargetButton.Tag) {
        $TargetButton.Tag.IsOpen = $false
    }
    if ($ActionType -eq 'Filter') {
        Invoke-SearchFilterAction -ChildElement $TargetButton -Action $ActionName
    }
    else {
        Invoke-SearchBatchAction -ChildElement $TargetButton -Action $ActionName
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchItemButtonClick'
} # function Invoke-SearchItemButtonClick

function Invoke-SearchActionsButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchActionsButtonClick'
    if ($s.Tag) {
        $s.Tag.IsOpen = -not $s.Tag.IsOpen
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchActionsButtonClick'
} # function Invoke-SearchActionsButtonClick

function New-ContentEnum {
    param([type]$EnumType)
    Start-FunctionMeasurement -FunctionName 'New-ContentEnum'
    New-BaseComboBox @{
        Name        = $ContentElementName
        ItemsSource = $EnumType.GetEnumNames()
        Margin      = 2
    }

    Stop-FunctionMeasurement -FunctionName 'New-ContentEnum'
} # function New-ContentEnum

function New-ContentPassword {
    Start-FunctionMeasurement -FunctionName 'New-ContentPassword'
    New-BasePasswordBox @{
        Name   = $ContentElementName
        Margin = 2
    }

    Stop-FunctionMeasurement -FunctionName 'New-ContentPassword'
} # function New-ContentPassword

function New-ContentString {
    Start-FunctionMeasurement -FunctionName 'New-ContentString'
    New-BaseRichTextBox @{
        Name      = $ContentElementName
        Margin    = 2
        AllowDrop = $false
    }

    Stop-FunctionMeasurement -FunctionName 'New-ContentString'
} # function New-ContentString

function New-ContentNumber {
    param( [type]$TargetType )
    Start-FunctionMeasurement -FunctionName 'New-ContentNumber'
    $TextBox = New-BaseTextBox @{
        Name   = $ContentElementName
        Tag    = @{ TargetType = $TargetType }
        Margin = 2
    }

    $TextBox.Add_PreviewTextInput({
            param($s, $e)
            $type = $s.Tag.TargetType
            $isSigned = -not $type.Name.StartsWith('U')
            $isFloatingPoint = @('System.Single', 'System.Double', 'System.Decimal') -contains $type.FullName
            $currentText = $s.Text
            $caretIndex = $s.CaretIndex
            $selectionLength = $s.SelectionLength

            $predictedText = $currentText.Remove($caretIndex, $selectionLength).Insert($caretIndex, $e.Text)

            # ^ means "start of string"
            $regex = '^'
            # Allow optional negative sign for signed types
            if ($isSigned) { $regex += '-?' }
            # Allow digits for integer types
            $regex += '\d*'
            # Allow optional decimal point and digits for floating point types
            if ($isFloatingPoint) { $regex += '\.?\d*' }
            # $ means "end of string"
            $regex += '$'
            $e.Handled = -not ($predictedText -match $regex)
        })

    $TextBox.Add_TextChanged({
            param($s, $e)
            $val = $s.Text
            if ([string]::IsNullOrWhiteSpace($val) -or $val -eq '-') {
                return
            }

            try {
                $type = $s.Tag.TargetType
                $null = $type::Parse($val)
                $s.ToolTip = $null
            }
            catch {
                $type = $s.Tag.TargetType
                $s.ToolTip = "Invalid value for $($type.FullName)"
            }
        })

    $TextBox

    Stop-FunctionMeasurement -FunctionName 'New-ContentNumber'
} # function New-ContentNumber

function New-ContentBoolean {
    Start-FunctionMeasurement -FunctionName 'New-ContentBoolean'
    New-BaseComboBox @{
        Name        = $ContentElementName
        ItemsSource = @(
            $true,
            $false
        )
    }

    Stop-FunctionMeasurement -FunctionName 'New-ContentBoolean'
} # function New-ContentBoolean

function New-ContentDateTime {
    param(
        [hashtable]$Parameters = @{},
        $SelectedDateTime = (Get-Date)
    )
    Start-FunctionMeasurement -FunctionName 'New-ContentDateTime'

    $Grid = [System.Windows.Controls.Grid]@{
        Name                = $CustomDateTimePickerName
        HorizontalAlignment = if ($Parameters.HorizontalAlignment) { $Parameters.HorizontalAlignment } else { 'Stretch' }
        VerticalAlignment   = if ($Parameters.VerticalAlignment) { $Parameters.VerticalAlignment } else { 'Center' }
        Margin              = if ($Parameters.Margin) { $Parameters.Margin } else { '0' }
    }

    $col1 = [System.Windows.Controls.ColumnDefinition]@{ Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star) }
    $col2 = [System.Windows.Controls.ColumnDefinition]@{ Width = [System.Windows.GridLength]::Auto }
    $Grid.ColumnDefinitions.Add($col1) | Out-Null
    $Grid.ColumnDefinitions.Add($col2) | Out-Null

    $formattedInitialDate = ''
    if ($SelectedDateTime) {
        try {
            $formattedInitialDate = ([DateTime]$SelectedDateTime).ToString('yyyy-MM-dd HH:mm:ss')
        }
        catch {
            $formattedInitialDate = "$SelectedDateTime"
        }
    }

    $TextBox = New-BaseTextBox @{
        Text                = $formattedInitialDate
        Name                = $ContentDateTimeDisplayTextBoxName
        VerticalAlignment   = 'Stretch'
        HorizontalAlignment = 'Stretch'
    }
    [System.Windows.Controls.Grid]::SetColumn($TextBox, 0)
    $Grid.Children.Add($TextBox) | Out-Null
    $Grid.Tag = @{ DateBox = $TextBox; DisplayTextBox = $TextBox }

    $PickButton = New-BaseButton @{
        Content           = ' 📅 '
        Margin            = '2,0,0,0'
        Padding           = '5,2,5,2'
        VerticalAlignment = 'Stretch'
        FocusAble         = $false
    }
    [System.Windows.Controls.Grid]::SetColumn($PickButton, 1)
    $Grid.Children.Add($PickButton) | Out-Null

    $PickButton.Add_Click({
            $PickButton = $this
            $currentDate = Get-Date
            if (-not [DateTime]::TryParse($TextBox.Text, [ref]$currentDate)) {
                $currentDate = Get-Date
            }

            $Dialog = New-BaseWindow @{
                Title                 = 'Select Date & Time'
                SizeToContent         = 'WidthAndHeight'
                WindowStartupLocation = 'CenterScreen'
                ResizeMode            = 'NoResize'
                WindowStyle           = 'ToolWindow'
                ShowInTaskbar         = $false
            }

            $MainStack = New-BaseStackPanel @{
                Margin      = 10
                Orientation = 'Vertical'
            }

            $Calendar = [System.Windows.Controls.Calendar]@{
                SelectedDate       = $currentDate.Date
                DisplayDate        = $currentDate.Date
                Margin             = '0,0,0,10'
                IsTodayHighlighted = $true
            }
            $MainStack.Children.Add($Calendar) | Out-Null

            $TimeHeader = New-BaseTextBlock @{
                Text       = 'Time (HH : MM : SS):'
                FontWeight = 'SemiBold'
                Margin     = '0,0,0,4'
            }
            $MainStack.Children.Add($TimeHeader) | Out-Null

            $TimeStack = New-BaseStackPanel @{
                Orientation = 'Horizontal'
                Margin      = '0,0,0,10'
            }

            $HourCombo = [System.Windows.Controls.ComboBox]@{ Width = 50 }
            0..23 | ForEach-Object { [void]$HourCombo.Items.Add($_.ToString('D2')) }
            $HourCombo.SelectedItem = $currentDate.ToString('HH')

            $MinuteCombo = [System.Windows.Controls.ComboBox]@{ Width = 50 }
            0..59 | ForEach-Object { [void]$MinuteCombo.Items.Add($_.ToString('D2')) }
            $MinuteCombo.SelectedItem = $currentDate.ToString('mm')

            $SecondCombo = [System.Windows.Controls.ComboBox]@{ Width = 50 }
            0..59 | ForEach-Object { [void]$SecondCombo.Items.Add($_.ToString('D2')) }
            $SecondCombo.SelectedItem = $currentDate.ToString('ss')

            $colon1 = New-BaseTextBlock @{ Text = ' : '; VerticalAlignment = 'Center' }
            $colon2 = New-BaseTextBlock @{ Text = ' : '; VerticalAlignment = 'Center' }

            $TimeStack.Children.Add($HourCombo)
            $TimeStack.Children.Add($colon1)
            $TimeStack.Children.Add($MinuteCombo)
            $TimeStack.Children.Add($colon2)
            $TimeStack.Children.Add($SecondCombo)
            $MainStack.Children.Add($TimeStack)

            $ButtonStack = New-BaseStackPanel @{
                Orientation         = 'Horizontal'
                HorizontalAlignment = 'Right'
            }

            $NowButton = New-BaseButton @{
                Content = 'Now'
                Width   = 55
                Margin  = '0,0,6,0'
            }
            $NowButton.Add_Click({ Invoke-DateTimeNowButtonClick $Calendar $HourCombo $MinuteCombo $SecondCombo })

            $OkButton = New-BaseButton @{
                Content   = 'OK'
                Width     = 55
                Margin    = '0,0,6,0'
                IsDefault = $true
            }
            $OkButton.Add_Click({ Invoke-DateTimeOkButtonClick $Calendar $HourCombo $MinuteCombo $SecondCombo $PickButton $Dialog })

            $CancelButton = New-BaseButton @{
                Content  = 'Cancel'
                Width    = 55
                IsCancel = $true
            }
            $CancelButton.Add_Click({ Invoke-DateTimeCancelButtonClick $Dialog })

            $ButtonStack.Children.Add($NowButton)
            $ButtonStack.Children.Add($OkButton)
            $ButtonStack.Children.Add($CancelButton)
            $MainStack.Children.Add($ButtonStack)

            $Dialog.Content = $MainStack
            [void]$Dialog.ShowDialog()
        })

    $ReturnValue = $Grid
    Stop-FunctionMeasurement -FunctionName 'New-ContentDateTime'
    return $ReturnValue
} # function New-ContentDateTime

function New-ContentChar {
    Start-FunctionMeasurement -FunctionName 'New-ContentChar'
    $CharBox = New-BaseTextBox @{
        Name      = $ContentElementName
        Tag       = @{ TargetType = [char] }
        Margin    = 2
        MaxLength = 1
    }
    $CharBox.Add_TextChanged({
            param($s, $e)
            $val = $s.Text
            if ([string]::IsNullOrWhiteSpace($val)) {
                return
            }

            try {
                $null = [char]::Parse($val)
                $s.ToolTip = $null
            }
            catch {
                $type = $s.Tag.TargetType
                $s.ToolTip = "Invalid value for $($type.FullName)"
            }
        }
    )
    $CharBox

    Stop-FunctionMeasurement -FunctionName 'New-ContentChar'
} # function New-ContentChar

function New-DragHandle {
    param($WrapperName)
    Start-FunctionMeasurement -FunctionName 'New-DragHandle'

    $DragHandle = New-BaseTextBlock @{
        Text              = $DragHandleIcon
        Foreground        = 'Black'
        VerticalAlignment = 'Center'
        Cursor            = 'SizeNS'
        Name              = "$WrapperName`_$DragHandleNameSuffix"
        ToolTip           = $DragHandleToolTip
    }
    $DragHandle.Add_PreviewMouseLeftButtonDown({
            param($s, $e)
            $DraggingItem = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$DragHandleNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
            [System.Windows.DragDrop]::DoDragDrop($DraggingItem, $DraggingItem.uid, [System.Windows.DragDropEffects]::Move) | Out-Null
        }
    )
    $DragHandle

    Stop-FunctionMeasurement -FunctionName 'New-DragHandle'
} # function New-DragHandle

function Add-DragDropLogic {
    param([ref]$DragDropTarget)
    Start-FunctionMeasurement -FunctionName "Add-DragDropLogic"

    $DragDropTarget.Value.AllowDrop = $true
    $DragDropTarget.Value.Uid = [guid]::NewGuid().ToString()

    $DragDropTarget.Value.Add_DragEnter({
            param($s, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true

            #Write-Host "DragEnter: $($s.Name) - $(find-title $s)"

            $SourceUid = $e.Data.GetData([String])
            if (($SourceUid -and $SourceUid -eq $s.Uid)) { return }

            $Array = $s.Parent
            $DraggingItemIndex = $Array.Children.IndexOf($DraggingItem)
            if ($DraggingItemIndex -eq -1) { return }

            $SourceIndex = $Array.Children.IndexOf($s)
            $s.BorderBrush = 'DodgerBlue'

            $Thickness = $s.BorderThickness.ToString()[0]
            if ($SourceIndex -gt $DraggingItemIndex) {
                $s.BorderThickness = "0,0,0,$Thickness"
            }
            else {
                $s.BorderThickness = "0,$Thickness,0,0"
            }
        })
    $DragDropTarget.Value.Add_DragLeave({
            param($s, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true

            $SourceUid = $e.Data.GetData([String])
            if (($SourceUid -and $SourceUid -eq $s.Uid)) { return }

            $Array = $s.Parent
            $DraggingItemIndex = $Array.Children.IndexOf($DraggingItem)
            if ($DraggingItemIndex -eq -1) { return }

            $s.BorderBrush = 'Black'
            $Thickness = $s.BorderThickness.ToString().Split(',') | Where-Object { $_ -ne 0 }
            $s.BorderThickness = $Thickness
        })
    $DragDropTarget.Value.Add_DragOver({
            param($s, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true
        })
    $DragDropTarget.Value.Add_Drop({
            param($s, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true

            $SourceUid = $e.Data.GetData([String])
            if (($SourceUid -and $SourceUid -eq $s.Uid)) { return }

            $Array = $s.Parent
            $DraggingItemIndex = $Array.Children.IndexOf($DraggingItem)
            if ($DraggingItemIndex -eq -1) { return }

            $s.BorderBrush = 'Black'
            $Thickness = $s.BorderThickness.ToString().Split(',') | Where-Object { $_ -ne 0 }
            if ($s.Count -gt 1) {
                Write-Host '{Add_Drop} pause, why more than 1 object here??' -ForegroundColor Red -BackgroundColor Yellow #0 Issue last seen, 10-3-2026.
            }
            $s.BorderThickness = $Thickness

            $TargetIndex = $Array.Children.IndexOf($s)

            $Array.Children.Remove($DraggingItem)
            $Array.Children.Insert($TargetIndex, $DraggingItem)

            if ([System.Windows.Forms.Control]::ModifierKeys -match 'Shift') {
                $Array.Children.Remove($s)
                $Array.Children.Insert($DraggingItemIndex, $s)
            }

            Reset-ArrayIndexes ([ref]$Array)
        })
    Stop-FunctionMeasurement -FunctionName "Add-DragDropLogic"
} # function Add-DragDropLogic

function New-IndexBox {
    param(
        $WrapperName,
        [int]$Index = $Index + 1
    )
    Start-FunctionMeasurement -FunctionName 'New-IndexBox'
    $IndexBlock = New-BaseTextBox @{
        Text              = "$Index"
        Margin            = '1,0,1,0'
        Foreground        = 'Black'
        VerticalAlignment = 'Center'
        Name              = "$WrapperName`_$IndexBoxNameSuffix"
        Background        = 'Transparent'
        BorderBrush       = 'Transparent'
        MinWidth          = 12
        AllowDrop         = $false
    }
    $IndexBlock.Add_KeyDown({
            param($s, $e)
            if ($e.Key -eq 'Enter' -or $e.Key -eq 'Return') {
                $ExpectedName = $s.Name.Replace("_$IndexBoxNameSuffix", '')
                $IndexBlockParent = $null
                $Curr = $s.Parent
                while ($null -ne $Curr) {
                    if ($Curr.Name -eq $ExpectedName) { $IndexBlockParent = $Curr; break }
                    $Curr = $Curr.Parent
                }
                if (-not $IndexBlockParent) {
                    $IndexBlockParent = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ExpectedName } -DigProperties 'Parent' -FindMax 1
                }
                $Content = if ($IndexBlockParent -and $IndexBlockParent.Tag -is [hashtable] -and $IndexBlockParent.Tag.ContainsKey('Content') -and $IndexBlockParent.Tag.Content) {
                    $IndexBlockParent.Tag.Content
                }
                else {
                    Find-ObjectWhere -Object ([ref]$IndexBlockParent) -FindWhere { $_.Name -eq $ContentElementName } -FindMax 1
                }
                if ($Content) { $Content.Focus() }
            }
        }
    )
    $IndexBlock.Add_LostFocus({
            param($s, $e)

            # This section moves the item to the new index if the user has changed it.
            $ExpectedName = $s.Name.Replace("_$IndexBoxNameSuffix", '')
            $ArrayItem = $null
            $Curr = $s.Parent
            while ($null -ne $Curr) {
                if ($Curr.Name -eq $ExpectedName) { $ArrayItem = $Curr; break }
                $Curr = $Curr.Parent
            }
            if (-not $ArrayItem) {
                $ArrayItem = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ExpectedName } -DigProperties 'Parent' -FindMax 1
            }
            $Array = $ArrayItem.Parent
            $CurrentIndex = $Array.Children.IndexOf($ArrayItem)
            $NewIndexText = $s.Text
            if ($ArrayItem -and $Array) {
                if ([int]::TryParse($NewIndexText, [ref]$null)) {
                    $NewIndex = [int]$NewIndexText

                    $TargetIndex = $NewIndex - 1
                    if ($TargetIndex -lt 0) { $TargetIndex = 0 }
                    if ($TargetIndex -ge $Array.Children.Count) { $TargetIndex = $Array.Children.Count - 1 }
                    $s.Text = "$($TargetIndex + 1)"

                    if ($TargetIndex -ne $CurrentIndex -and $TargetIndex -ge 0) {
                        $Array.Children.Remove($ArrayItem)
                        $Array.Children.Insert($TargetIndex, $ArrayItem)
                    }
                }

                Reset-ArrayIndexes ([ref]$Array)
            }
        }
    )
    $IndexBlock

    Stop-FunctionMeasurement -FunctionName 'New-IndexBox'
} # function New-IndexBox

function New-SearchBar {
    param(
        [string]$WrapperName = $ContentHeaderBorderName
    )
    Start-FunctionMeasurement -FunctionName 'New-SearchBar'

    $SearchBarBorder = New-BaseBorder @{
        Name            = "$WrapperName`_$SearchBarNameSuffix"
        Margin          = '2,1,2,3'
        Padding         = '3'
        BorderThickness = 1
        BorderBrush     = '#6C6288'
        Background      = '#2E273D'
        Visibility      = 'Collapsed'
    }

    $SearchDock = New-BaseDockPanel @{
        LastChildFill = $true
    }
    $SearchBarBorder.AddChild($SearchDock) | Out-Null

    # Close button (Dock Right)
    $CloseButton = New-BaseButton @{
        Content           = $SearchCloseButtonHeader
        Name              = "$WrapperName`_$SearchCloseButtonNameSuffix"
        Width             = 22
        Height            = 20
        Margin            = '2,0,0,0'
        Padding           = '0'
        Background        = 'Transparent'
        Foreground        = '#EDEAFA'
        BorderThickness   = 0
        Cursor            = 'Hand'
        ToolTip           = $SearchCloseButtonToolTip
        VerticalAlignment = 'Center'
        Focusable         = $false
    }
    [System.Windows.Controls.DockPanel]::SetDock($CloseButton, 'Right')
    $SearchDock.Children.Add($CloseButton) | Out-Null

    # Actions Menu Button & Dark-Themed Dropdown Popup (Dock Right)
    $ActionsButton = New-BaseButton @{
        Content           = $SearchActionsButtonHeader
        Name              = "$WrapperName`_$SearchActionsButtonNameSuffix"
        ToolTip           = $SearchActionsButtonToolTip
        Foreground        = '#EDEAFA'
        Background        = '#504368'
        BorderBrush       = '#8879A1'
        BorderThickness   = 1
        Padding           = '4,1,4,1'
        Margin            = '2,0,2,0'
        FontSize          = 10
        FontFamily        = $FontFamily
        Cursor            = 'Hand'
        VerticalAlignment = 'Center'
        Focusable         = $false
    }
    [System.Windows.Controls.DockPanel]::SetDock($ActionsButton, 'Right')
    $SearchDock.Children.Add($ActionsButton) | Out-Null

    $ActionsPopup = New-Object System.Windows.Controls.Primitives.Popup
    $ActionsPopup.PlacementTarget = $ActionsButton
    $ActionsPopup.Placement = [System.Windows.Controls.Primitives.PlacementMode]::Bottom
    $ActionsPopup.StaysOpen = $false
    $ActionsPopup.AllowsTransparency = $true
    $ActionsButton.Tag = $ActionsPopup

    $PopupBorder = New-BaseBorder @{
        Background      = '#251F33'
        BorderBrush     = '#7A6E94'
        BorderThickness = 1
        CornerRadius    = 4
        Padding         = 2
    }
    $ActionsPopup.Child = $PopupBorder

    $PopupStack = New-BaseStackPanel @{
        Orientation = 'Vertical'
    }
    $PopupBorder.Child = $PopupStack

    $MenuItems = @(
        @{ Header = $SearchActionShowMatchesHeader; ToolTip = $SearchActionShowMatchesToolTip; Action = 'ShowOnly'; Type = 'Filter' },
        @{ Header = $SearchActionHideMatchesHeader; ToolTip = $SearchActionHideMatchesToolTip; Action = 'Hide'; Type = 'Filter' },
        @{ Header = $SearchActionShowAllHeader; ToolTip = $SearchActionShowAllToolTip; Action = 'ShowAll'; Type = 'Filter' },
        @{ Separator = $true },
        @{ Header = $SearchActionSortAscendingHeader; ToolTip = $SearchActionSortAscendingToolTip; Action = 'SortAscending'; Type = 'Batch' },
        @{ Header = $SearchActionSortDescendingHeader; ToolTip = $SearchActionSortDescendingToolTip; Action = 'SortDescending'; Type = 'Batch' },
        @{ Separator = $true },
        @{ Header = $SearchActionLockMatchesHeader; ToolTip = $SearchActionLockMatchesToolTip; Action = 'Lock'; Type = 'Batch' },
        @{ Header = $SearchActionUnlockMatchesHeader; ToolTip = $SearchActionUnlockMatchesToolTip; Action = 'Unlock'; Type = 'Batch' },
        @{ Separator = $true },
        @{ Header = $SearchActionRandomizeMatchesHeader; ToolTip = $SearchActionRandomizeMatchesToolTip; Action = 'Random'; Type = 'Batch' },
        @{ Header = $SearchActionClearMatchesHeader; ToolTip = $SearchActionClearMatchesToolTip; Action = 'Clear'; Type = 'Batch' },
        @{ Separator = $true },
        @{ Header = $SearchActionDisableMatchesHeader; ToolTip = $SearchActionDisableMatchesToolTip; Action = 'Disable'; Type = 'Batch' },
        @{ Header = $SearchActionEnableMatchesHeader; ToolTip = $SearchActionEnableMatchesToolTip; Action = 'Enable'; Type = 'Batch' },
        @{ Header = $SearchActionDeleteMatchesHeader; ToolTip = $SearchActionDeleteMatchesToolTip; Action = 'Delete'; Type = 'Batch' }
    )

    :MenuItems foreach ($Item in $MenuItems) {
        if ($Item.ContainsKey('Separator') -and $Item.Separator) {
            $Sep = New-BaseBorder @{
                Height     = 1
                Background = '#4C435E'
                Margin     = '2,3,2,3'
            }
            $PopupStack.Children.Add($Sep) | Out-Null
            continue
        }

        $ItemButton = New-BaseButton @{
            Content                    = $Item.Header
            ToolTip                    = $Item.ToolTip
            Foreground                 = '#EDEAFA'
            Background                 = 'Transparent'
            BorderThickness            = 0
            HorizontalContentAlignment = 'Left'
            Padding                    = '10,5,10,5'
            FontFamily                 = $FontFamily
            FontSize                   = 11
            Cursor                     = 'Hand'
        }

        $ItemButton.Add_MouseEnter({
                param($s, $e)
                $s.Background = '#504368'
                $s.Foreground = '#FFFFFF'
            })
        $ItemButton.Add_MouseLeave({
                param($s, $e)
                $s.Background = 'Transparent'
                $s.Foreground = '#EDEAFA'
            })

        $ActionName = $Item.Action
        $ActionType = $Item.Type
        $TargetButton = $ActionsButton
        $ItemButton.Add_Click(({ param($s, $e) Invoke-SearchItemButtonClick $s $e $TargetButton $ActionType $ActionName }).GetNewClosure())

        $PopupStack.Children.Add($ItemButton) | Out-Null
    } # MenuItems foreach

    $ActionsButton.Add_Click({ param($s, $e) Invoke-SearchActionsButtonClick $s $e })

    # Next button (Dock Right)
    $NextButton = New-BaseButton @{
        Content           = $SearchNextButtonHeader
        Name              = "$WrapperName`_$SearchNextButtonNameSuffix"
        Width             = 20
        Height            = 20
        Margin            = '1,0,1,0'
        Padding           = '0'
        Background        = 'Transparent'
        Foreground        = '#EDEAFA'
        BorderThickness   = 0
        Cursor            = 'Hand'
        ToolTip           = $SearchNextButtonToolTip
        VerticalAlignment = 'Center'
        Focusable         = $false
    }
    [System.Windows.Controls.DockPanel]::SetDock($NextButton, 'Right')
    $SearchDock.Children.Add($NextButton) | Out-Null

    # Prev button (Dock Right)
    $PrevButton = New-BaseButton @{
        Content           = $SearchPrevButtonHeader
        Name              = "$WrapperName`_$SearchPrevButtonNameSuffix"
        Width             = 20
        Height            = 20
        Margin            = '1,0,1,0'
        Padding           = '0'
        Background        = 'Transparent'
        Foreground        = '#EDEAFA'
        BorderThickness   = 0
        Cursor            = 'Hand'
        ToolTip           = $SearchPrevButtonToolTip
        VerticalAlignment = 'Center'
        Focusable         = $false
    }
    [System.Windows.Controls.DockPanel]::SetDock($PrevButton, 'Right')
    $SearchDock.Children.Add($PrevButton) | Out-Null

    # Regex toggle button (Dock Right)
    $RegexButton = New-BaseButton @{
        Content           = $SearchRegexButtonHeader
        Name              = "$WrapperName`_$SearchRegexButtonNameSuffix"
        Width             = 24
        Height            = 20
        Margin            = '2,0,2,0'
        Padding           = '0'
        Background        = '#504368'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#8879A1'
        BorderThickness   = 1
        Cursor            = 'Hand'
        ToolTip           = $SearchRegexButtonToolTipEnabled
        VerticalAlignment = 'Center'
        Focusable         = $false
        FontWeight        = 'Bold'
        FontSize          = 11
    }
    [System.Windows.Controls.DockPanel]::SetDock($RegexButton, 'Right')
    $SearchDock.Children.Add($RegexButton) | Out-Null

    # Match Counter (Dock Right)
    $MatchCount = New-BaseTextBlock @{
        Name              = "$WrapperName`_$SearchCountNameSuffix"
        Text              = ''
        Foreground        = '#C1B8D1'
        FontSize          = 10
        FontFamily        = $FontFamily
        Margin            = '4,0,6,0'
        VerticalAlignment = 'Center'
    }
    [System.Windows.Controls.DockPanel]::SetDock($MatchCount, 'Right')
    $SearchDock.Children.Add($MatchCount) | Out-Null

    # Search Icon (Dock Left)
    $SearchIcon = New-BaseTextBlock @{
        Text              = $SearchBarIcon
        Foreground        = '#EDEAFA'
        VerticalAlignment = 'Center'
        Margin            = '4,0,2,0'
        FontSize          = 11
    }
    [System.Windows.Controls.DockPanel]::SetDock($SearchIcon, 'Left')
    $SearchDock.Children.Add($SearchIcon) | Out-Null

    # Search Input TextBox (Fill Center)
    $SearchInput = New-BaseTextBox @{
        Name              = "$WrapperName`_$SearchInputNameSuffix"
        Background        = '#3D3452'
        Foreground        = '#EDEAFA'
        BorderBrush       = '#7A6E94'
        BorderThickness   = 1
        FontFamily        = $FontFamily
        FontSize          = 11
        VerticalAlignment = 'Center'
        Padding           = '2'
    }
    $SearchDock.Children.Add($SearchInput) | Out-Null

    # State tracking on Border Tag
    $SearchBarBorder.Tag = @{
        Matches       = [System.Collections.ArrayList]@()
        CurrentIndex  = -1
        UseRegex      = $true
        CompiledRegex = $null
        Query         = ''
        SearchInput   = $SearchInput
        SearchCount   = $MatchCount
        RegexButton   = $RegexButton
    }

    $SearchInput.Add_TextChanged({
            param($s, $e)
            Invoke-SearchExecution -SearchBox $s
        })

    $SearchInput.Add_KeyDown({
            param($s, $e)
            if ($e.Key -eq 'Escape') {
                Close-SearchBar -ChildElement $s
                $e.Handled = $true
            }
            elseif ($e.Key -eq 'Enter' -or $e.Key -eq 'Return') {
                $SearchBar = Resolve-SearchBar $s
                if (-not $SearchBar) { $SearchBar = $SearchBarBorder }
                $IsShift = ([System.Windows.Forms.Control]::ModifierKeys -match 'Shift') -or ([System.Windows.Input.Keyboard]::Modifiers -match 'Shift')
                $HasMatches = $SearchBar -and $SearchBar.Tag -and $SearchBar.Tag.Matches -and ($SearchBar.Tag.Matches.Count -gt 0)
                $HasSearchedCurrent = $HasMatches -and ($SearchBar.Tag.Query -eq $s.Text) -and ($SearchBar.Tag.CurrentIndex -ge 0)

                if (-not $HasSearchedCurrent) {
                    Invoke-SearchExecution -SearchBox $s
                    if ($IsShift) {
                        Step-SearchMatch -ChildElement $s -Direction 'Prev'
                    }
                }
                else {
                    if ($IsShift) {
                        Step-SearchMatch -ChildElement $s -Direction 'Prev'
                    }
                    else {
                        Step-SearchMatch -ChildElement $s -Direction 'Next'
                    }
                }
                $e.Handled = $true
            }
            elseif ($e.Key -eq 'R' -and ([System.Windows.Forms.Control]::ModifierKeys -match 'Alt' -or [System.Windows.Input.Keyboard]::Modifiers -match 'Alt')) {
                $RButton = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -like "*$SearchRegexButtonNameSuffix" } -DigProperties 'Parent' -FindMax 1
                if ($RButton) {
                    $RButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
                    $e.Handled = $true
                }
            }
        })

    $RegexButton.Add_Click({ param($s, $e) Invoke-SearchRegexButtonClick $s $e })
    $NextButton.Add_Click({ param($s, $e) Invoke-SearchStepButtonClick $s $e -Direction 'Next' })
    $PrevButton.Add_Click({ param($s, $e) Invoke-SearchStepButtonClick $s $e -Direction 'Prev' })
    $CloseButton.Add_Click({ param($s, $e) Invoke-SearchCloseButtonClick $s $e })

    $ReturnValue = $SearchBarBorder
    Stop-FunctionMeasurement -FunctionName 'New-SearchBar'
    return $ReturnValue
} # function New-SearchBar

function Get-OrCreateSearchBar {
    param([Parameter(Mandatory = $true)]$ContentHeaderBorder)
    Start-FunctionMeasurement -FunctionName "Get-OrCreateSearchBar"
    $TargetBorder = Resolve-TargetElement $ContentHeaderBorder
    if (-not $TargetBorder) { return $null }
    if ($TargetBorder.Tag -is [hashtable] -and $TargetBorder.Tag.ContainsKey('SearchBar') -and $TargetBorder.Tag.SearchBar) {
        return $TargetBorder.Tag.SearchBar
    }

    $ContentHeaderBorderStack = Find-ObjectWhere -Object ([ref]$TargetBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderStackName } -FindMax 1
    if (-not $ContentHeaderBorderStack) { return $null }

    $SearchBar = $ContentHeaderBorderStack.Children | Where-Object { $_.Name -like "*$SearchBarNameSuffix" }
    if ($SearchBar) {
        if ($TargetBorder.Tag -is [hashtable]) { $TargetBorder.Tag.SearchBar = $SearchBar }
        return $SearchBar
    }

    $SearchBar = New-SearchBar -WrapperName $TargetBorder.Name
    $SlotIndex = -1
    for ($i = 0; $i -lt $ContentHeaderBorderStack.Children.Count; $i++) {
        if ($ContentHeaderBorderStack.Children[$i].Name -eq $ContentSlotElementName) {
            $SlotIndex = $i
            break
        }
    }
    if ($SlotIndex -ge 0) {
        $ContentHeaderBorderStack.Children.Insert($SlotIndex, $SearchBar)
    }
    else {
        $ContentHeaderBorderStack.Children.Add($SearchBar) | Out-Null
    }

    if (-not ($TargetBorder.Tag -is [hashtable])) { $TargetBorder.Tag = @{} }
    $TargetBorder.Tag.SearchBar = $SearchBar
    Stop-FunctionMeasurement -FunctionName "Get-OrCreateSearchBar"
    return $SearchBar
} # function Get-OrCreateSearchBar

#endregion #3 Content Controls Elements

#region #3 Button Elements

function Invoke-SearchRegexButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchRegexButtonClick'
    $SearchBarBorder = Resolve-SearchBar $s
    if (-not $SearchBarBorder) { return }

    $CurrentUseRegex = if ($SearchBarBorder.Tag.ContainsKey('UseRegex')) { $SearchBarBorder.Tag.UseRegex } else { $true }
    $NewUseRegex = -not $CurrentUseRegex
    $SearchBarBorder.Tag.UseRegex = $NewUseRegex

    if ($NewUseRegex) {
        $s.Background = '#504368'
        $s.BorderBrush = '#8879A1'
        $s.ToolTip = $SearchRegexButtonToolTipEnabled
    }
    else {
        $s.Background = 'Transparent'
        $s.BorderBrush = 'Transparent'
        $s.ToolTip = $SearchRegexButtonToolTipDisabled
    }

    $SearchInput = Find-ObjectWhere -Object ([ref]$SearchBarBorder) -FindWhere { $_.Name -like "*$SearchInputNameSuffix" } -FindMax 1
    if ($SearchInput) {
        Invoke-SearchExecution -SearchBox $SearchInput
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchRegexButtonClick'
} # function Invoke-SearchRegexButtonClick

function Invoke-SearchStepButtonClick {
    param(
        $s,
        $e,
        [ValidateSet('Next', 'Prev')][string]$Direction = 'Next'
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchStepButtonClick'
    Step-SearchMatch -ChildElement $s -Direction $Direction

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchStepButtonClick'
} # function Invoke-SearchStepButtonClick

function Invoke-SearchCloseButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchCloseButtonClick'
    Close-SearchBar -ChildElement $s

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchCloseButtonClick'
} # function Invoke-SearchCloseButtonClick

function Set-ContentSlotCollapseState {
    param(
        [Parameter(Mandatory = $true)]$ContentSlotElement,
        [Parameter(Mandatory = $true)]$MinMaxButton,
        $ContentHeaderBorder,
        [Parameter(Mandatory = $true)][bool]$Collapse
    )
    Start-FunctionMeasurement -FunctionName 'Set-ContentSlotCollapseState'
    if (-not $ContentHeaderBorder -and $MinMaxButton) {
        $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$MinMaxButton) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    }

    if ($Collapse) {
        $ContentSlotElement.Visibility = 'Collapsed'
        $MinMaxButton.Header = $MinMaxButtonMaxedIcon
        $MinMaxButton.ToolTip = $MinMaxButtonMaxedToolTip
        if ($ContentHeaderBorder) {
            $SearchBar = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -FindMax 1
            if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
                Close-SearchBar -ChildElement $SearchBar
            }
        }
    }
    else {
        $ContentSlotElement.Visibility = 'Visible'
        $MinMaxButton.Header = $MinMaxButtonMinedIcon
        $MinMaxButton.ToolTip = $MinMaxButtonMinedToolTip
    }

    if ($ContentHeaderBorder) {
        $TitleDock = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
        if ($TitleDock -is [array]) { $TitleDock = $TitleDock[0] }
        if ($TitleDock) {
            $HeaderTitle = Find-ObjectWhere -Object ([ref]$TitleDock) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName } -FindMax 1
            if ($HeaderTitle -is [array]) { $HeaderTitle = $HeaderTitle[0] }
            $HeaderDesc = Find-ObjectWhere -Object ([ref]$TitleDock) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName } -FindMax 1
            if ($HeaderDesc -is [array]) { $HeaderDesc = $HeaderDesc[0] }

            $TargetTitleFg = if ($Collapse) { $HeaderTitleMinimizedForeground } else { $HeaderTitleMaximizedForeground }
            $TargetDescFg = if ($Collapse) { $HeaderDescriptionMinimizedForeground } else { $HeaderDescriptionMaximizedForeground }

            if ($HeaderTitle) {
                if (-not [string]::IsNullOrEmpty($HeaderTitle.Uid) -and $SearchOriginalStyles.ContainsKey($HeaderTitle.Uid) -and $SearchOriginalStyles[$HeaderTitle.Uid].Type -eq 'TextBlock') {
                    $SearchOriginalStyles[$HeaderTitle.Uid].Foreground = $TargetTitleFg
                }
                else {
                    $HeaderTitle.Foreground = $TargetTitleFg
                }
            }
            if ($HeaderDesc) {
                if (-not [string]::IsNullOrEmpty($HeaderDesc.Uid) -and $SearchOriginalStyles.ContainsKey($HeaderDesc.Uid) -and $SearchOriginalStyles[$HeaderDesc.Uid].Type -eq 'TextBlock') {
                    $SearchOriginalStyles[$HeaderDesc.Uid].Foreground = $TargetDescFg
                }
                else {
                    $HeaderDesc.Foreground = $TargetDescFg
                }
            }
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Set-ContentSlotCollapseState'
} # function Set-ContentSlotCollapseState

function Invoke-MinMaxButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-MinMaxButtonClick'
    if ([System.Windows.Forms.Control]::ModifierKeys -match 'Shift') {
        $AlternateBehavior = $true
    }
    $ChangedChild = $false

    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
    if ($AlternateBehavior) {
        [array]$MinMaxButtons = Find-ObjectWhere -Object ([ref]$ContentSlotElement) -FindWhere { $_.Name -eq $MinMaxButtonName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
        :MinMaxButtons foreach ($MinMaxButton in $MinMaxButtons) {
            if ($MinMaxButton.Header -eq $s.Header) { $ChangedChild = $true }

            $ButtonsContentHeaderBorder = Find-ObjectWhere -Object ([ref]$MinMaxButton) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
            $ButtonsContentSlotElement = Find-ObjectWhere -Object ([ref]$ButtonsContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

            Set-ContentSlotCollapseState -ContentSlotElement $ButtonsContentSlotElement `
                -MinMaxButton $MinMaxButton `
                -ContentHeaderBorder $ButtonsContentHeaderBorder `
                -Collapse ($s.Header -eq $MinMaxButtonMinedIcon)
        } # MinMaxButtons
    }

    if (!$AlternateBehavior -or ($AlternateBehavior -and (-not $ChangedChild -or $s.Header -eq $MinMaxButtonMaxedIcon))) {
        Set-ContentSlotCollapseState -ContentSlotElement $ContentSlotElement `
            -MinMaxButton $s `
            -ContentHeaderBorder $ContentHeaderBorder `
            -Collapse ($s.Header -eq $MinMaxButtonMinedIcon)
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-MinMaxButtonClick'
} # function Invoke-MinMaxButtonClick

function Invoke-AddArrayItemButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-AddArrayItemButtonClick'
    if ($s -and -not $s.IsEnabled) { return }
    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    if ($ContentHeaderBorder) {
        $Color = '#' + $ContentHeaderBorder.Background.Color.ToString().Substring(3)
        $IndexOfColorSequence = $ColorSequence.IndexOf($Color)

        $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

        $NewItem = New-TypeContent -WrapperType 'Border' -Type $s.Tag.TrimEnd('[]') -ArrayType 'ArrayItem' -Index $ContentSlotElement.Children.Count -Depth ($IndexOfColorSequence + 1)
        Add-ContentToWrapper ([ref]$ContentHeaderBorder) ([ref]$NewItem)
        Update-ArrayButtonsState -Wrapper $ContentHeaderBorder
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-AddArrayItemButtonClick'
} # function Invoke-AddArrayItemButtonClick

function Get-QuickSetActionContext {
    param(
        [Parameter(Mandatory)]$Sender,
        [string]$RequireActiveForAction,
        [switch]$IncludeTypeDirectory,
        [switch]$FallbackToDisplayName
    )
    Start-FunctionMeasurement -FunctionName "Get-QuickSetActionContext"
    $TargetWrapper = Get-QuickSetWrapper $Sender
    if (-not $TargetWrapper) { return $null }
    $QSMenu = Get-QuickSetMenuFromSender $Sender

    $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet') -and -not [string]::IsNullOrWhiteSpace($TargetWrapper.Tag.ActiveQuickSet)) {
        $TargetWrapper.Tag.ActiveQuickSet
    }
    elseif ($FallbackToDisplayName) {
        Get-WrapperDisplayName -Wrapper $TargetWrapper
    }
    else {
        $null
    }

    if (-not [string]::IsNullOrWhiteSpace($RequireActiveForAction) -and [string]::IsNullOrWhiteSpace($ActiveName)) {
        $ActionTitle = $RequireActiveForAction.Substring(0, 1).ToUpper() + $RequireActiveForAction.Substring(1)
        [System.Windows.MessageBox]::Show("Please select a QuickSet first to $RequireActiveForAction.", "QuickSet - $ActionTitle", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        return $null
    }

    $Type = $null
    $TypeDir = $null
    $ActiveFilePath = $null
    if ($IncludeTypeDirectory) {
        $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
        $TypeDir = Get-QuickSetTypeDirectory -Type $Type
        if (-not [string]::IsNullOrWhiteSpace($ActiveName)) {
            $ActiveFilePath = Join-Path $TypeDir "$ActiveName.json"
        }
    }

    return [pscustomobject]@{
        QSMenu         = $QSMenu
        TargetWrapper  = $TargetWrapper
        ActiveName     = $ActiveName
        Type           = $Type
        TypeDir        = $TypeDir
        ActiveFilePath = $ActiveFilePath
    }
    Stop-FunctionMeasurement -FunctionName "Get-QuickSetActionContext"
} # function Get-QuickSetActionContext

function Request-ValidatedQuickSetTarget {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Prompt,
        [string]$DefaultValue,
        [Parameter(Mandatory)][string]$TypeDir,
        [string]$RejectIfSameAs,
        [string]$SkipConfirmForName
    )
    Start-FunctionMeasurement -FunctionName "Request-ValidatedQuickSetTarget"
    $RawName = Show-QuickSetInputDialog -Title $Title -Prompt $Prompt -DefaultValue $DefaultValue
    if ([string]::IsNullOrWhiteSpace($RawName)) { return $null }

    $SanitizedName = ($RawName.Trim() -replace '[\\/:*?"<>|]', '_')
    if ([string]::IsNullOrWhiteSpace($SanitizedName)) { return $null }
    if (-not [string]::IsNullOrWhiteSpace($RejectIfSameAs) -and $SanitizedName -eq $RejectIfSameAs) { return $null }

    $TargetFilePath = Join-Path $TypeDir "$SanitizedName.json"
    if (Test-Path -LiteralPath $TargetFilePath) {
        $Confirm = if ($SkipConfirmForName -and $SanitizedName -ieq $SkipConfirmForName) { $true } else { Show-QuickSetConfirmDialog -Title "Overwrite QuickSet" -Message "A QuickSet named '$SanitizedName' already exists. Overwrite it?" }
        if (-not $Confirm) { return $null }
    }

    return [pscustomobject]@{
        Name     = $SanitizedName
        FilePath = $TargetFilePath
    }
    Stop-FunctionMeasurement -FunctionName "Request-ValidatedQuickSetTarget"
} # function Request-ValidatedQuickSetTarget

function Invoke-QuickSetRefreshButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetRefreshButtonClick'
    $Ctx = Get-QuickSetActionContext -Sender $s
    if ($Ctx -and $Ctx.QSMenu) {
        Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetRefreshButtonClick'
} # function Invoke-QuickSetRefreshButtonClick

function Invoke-QuickSetSaveButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetSaveButtonClick'
    $Ctx = Get-QuickSetActionContext -Sender $s -RequireActiveForAction 'save'
    if (-not $Ctx) { return }

    if (-not [string]::IsNullOrWhiteSpace($Ctx.ActiveName)) {
        $null = Save-QuickSetFile -Wrapper $Ctx.TargetWrapper -QuickSetName $Ctx.ActiveName
        if ($Ctx.QSMenu) {
            Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetSaveButtonClick'
} # function Invoke-QuickSetSaveButtonClick

function Invoke-QuickSetRenameButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetRenameButtonClick'
    $Ctx = Get-QuickSetActionContext -Sender $s -RequireActiveForAction 'rename' -IncludeTypeDirectory
    if (-not $Ctx) { return }

    if (-not (Test-Path -LiteralPath $Ctx.ActiveFilePath)) {
        [System.Windows.MessageBox]::Show("QuickSet file not found on disk: $($Ctx.ActiveName).json", "QuickSet", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    $Target = Request-ValidatedQuickSetTarget -Title "Rename QuickSet" -Prompt "Enter new name for '$($Ctx.ActiveName)':" -DefaultValue $Ctx.ActiveName -TypeDir $Ctx.TypeDir -RejectIfSameAs $Ctx.ActiveName
    if (-not $Target) { return }

    Move-Item -LiteralPath $Ctx.ActiveFilePath -Destination $Target.FilePath -Force
    $null = Save-QuickSetFile -Wrapper $Ctx.TargetWrapper -QuickSetName $Target.Name


    if ($Ctx.QSMenu) {
        Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetRenameButtonClick'
} # function Invoke-QuickSetRenameButtonClick

function Invoke-QuickSetSaveAsButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetSaveAsButtonClick'
    $Ctx = Get-QuickSetActionContext -Sender $s -IncludeTypeDirectory -FallbackToDisplayName
    if (-not $Ctx) { return }

    $TypeNameDisplay = if ($Ctx.Type -is [type]) { $Ctx.Type.Name } else { $Ctx.Type.ToString().Split('.')[-1] }
    $Target = Request-ValidatedQuickSetTarget -Title "Save QuickSet As" -Prompt "Enter QuickSet name for $($TypeNameDisplay):" -DefaultValue $Ctx.ActiveName -TypeDir $Ctx.TypeDir -SkipConfirmForName $Ctx.ActiveName
    if (-not $Target) { return }

    $null = Save-QuickSetFile -Wrapper $Ctx.TargetWrapper -QuickSetName $Target.Name

    if ($Ctx.QSMenu) {
        Set-QuickSetActiveButtonsState -QuickSetMenuItem $Ctx.QSMenu -IsEnabled $true
        Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetSaveAsButtonClick'
} # function Invoke-QuickSetSaveAsButtonClick

function Invoke-QuickSetDeleteButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetDeleteButtonClick'
    $Ctx = Get-QuickSetActionContext -Sender $s -RequireActiveForAction 'delete' -IncludeTypeDirectory
    if (-not $Ctx) { return }

    $Confirm = Show-QuickSetConfirmDialog -Title "Delete QuickSet" -Message "Are you sure you want to delete QuickSet '$($Ctx.ActiveName)'?"
    if (-not $Confirm) { return }

    if (Test-Path -LiteralPath $Ctx.ActiveFilePath) {
        Remove-Item -LiteralPath $Ctx.ActiveFilePath -Force -ErrorAction SilentlyContinue
    }

    $Ctx.TargetWrapper.Tag.ActiveQuickSet = $null
    Update-QuickSetBadge -Wrapper $Ctx.TargetWrapper -DisplayName $null
    if ($Ctx.QSMenu) {
        Set-QuickSetActiveButtonsState -QuickSetMenuItem $Ctx.QSMenu -IsEnabled $false
        Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetDeleteButtonClick'
} # function Invoke-QuickSetDeleteButtonClick

function Invoke-QuickSetClearButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetClearButtonClick'
    try {
        $Ctx = Get-QuickSetActionContext -Sender $s
        if (-not $Ctx) { return }
        Reset-WrapperQuickSet -Wrapper $Ctx.TargetWrapper -SaveCurrentValues -QuickSetMenuItem $Ctx.QSMenu
    }
    catch {
        [System.Windows.MessageBox]::Show("Error saving QuickSet: $_", "QuickSet Error") | Out-Null
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetClearButtonClick'
} # function Invoke-QuickSetClearButtonClick

function Invoke-QuickSetCloseButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-QuickSetCloseButtonClick'
    try {
        $Ctx = Get-QuickSetActionContext -Sender $s
        if (-not $Ctx) { return }
        Reset-WrapperQuickSet -Wrapper $Ctx.TargetWrapper -QuickSetMenuItem $Ctx.QSMenu
    }
    catch {
        [System.Windows.MessageBox]::Show("Error closing QuickSet: $_", "QuickSet Error") | Out-Null
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-QuickSetCloseButtonClick'
} # function Invoke-QuickSetCloseButtonClick

function Invoke-ClearButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-ClearButtonClick'
    $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $ClearButtonNameSuffix
    if ($ContentWrapper) { Clear-WrapperContent ([ref]$ContentWrapper) }

    Stop-FunctionMeasurement -FunctionName 'Invoke-ClearButtonClick'
} # function Invoke-ClearButtonClick

function Invoke-RandomValuesButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-RandomValuesButtonClick'
    $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $RandomValuesButtonNameSuffix
    if ($ContentWrapper) { Set-WrapperRandomContent ([ref]$ContentWrapper) }

    Stop-FunctionMeasurement -FunctionName 'Invoke-RandomValuesButtonClick'
} # function Invoke-RandomValuesButtonClick

function Invoke-RandomValuesSettingsButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-RandomValuesSettingsButtonClick'
    $TargetElement = if ($s -and $s.TemplatedParent) { $s.TemplatedParent } else { $s }
    $ContentWrapper = Get-ContentWrapperFromButton -Button $TargetElement -Suffix $RandomValuesButtonNameSuffix
    if (-not $ContentWrapper -and $script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable]) {
        $ContentWrapper = $script:UniversalSharedMenu.Tag.ActiveWrapper
    }

    if ($script:UniversalSharedMenu) {
        $ButtonMenuItem = Find-ObjectWhere -Object ([ref]$script:UniversalSharedMenu) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
        if ($ButtonMenuItem) { $ButtonMenuItem.IsSubmenuOpen = $false }
    }

    $ConfigurationResult = Show-RandomValuesConfigurationDialog -Wrapper $ContentWrapper
    if ($ConfigurationResult -and $ConfigurationResult.SaveAndUse -and $ContentWrapper) {
        Set-WrapperRandomContent -Wrapper ([ref]$ContentWrapper)
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-RandomValuesSettingsButtonClick'
} # function Invoke-RandomValuesSettingsButtonClick

function Invoke-DisableEnableButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-DisableEnableButtonClick'
    $TargetWrapper = if ($script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable] -and $script:UniversalSharedMenu.Tag.ActiveWrapper) {
        $script:UniversalSharedMenu.Tag.ActiveWrapper
    }
    else {
        Get-ParentWrapperBorder -Element $s
    }
    if (-not $TargetWrapper) {
        Stop-FunctionMeasurement -FunctionName 'Invoke-DisableEnableButtonClick'
        return
    }

    if ((Get-IsLocked $TargetWrapper)) {
        Stop-FunctionMeasurement -FunctionName 'Invoke-DisableEnableButtonClick'
        return
    }

    $CurrentlyDisabled = ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('IsDisabled') -and $TargetWrapper.Tag.IsDisabled)
    $NewDisabledState = -not $CurrentlyDisabled

    $IsAll = ($s.Header -like '* All') -or ($s.Tag -is [hashtable] -and $s.Tag.IsAll)
    if ($IsAll) {
        $ContentSlot = Get-WrapperContentSlot -Wrapper $TargetWrapper
        if ($ContentSlot) {
            foreach ($Child in @($ContentSlot.Children)) {
                if (Get-IsLocked $Child) { continue }
                Set-TargetDisabledState -Target $Child -IsDisabled $NewDisabledState
            }
        }
    }
    else {
        Set-TargetDisabledState -Target $TargetWrapper -IsDisabled $NewDisabledState
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-DisableEnableButtonClick'
} # function Invoke-DisableEnableButtonClick

function Invoke-DeleteButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-DeleteButtonClick'
    if ((Get-IsLocked $s)) { return }
    $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $DeleteButtonNameSuffix
    if (-not $ContentWrapper) { return }

    $IsAll = $s.Header -like '* All'
    if ($IsAll) {
        $ContentSlotElement = Get-WrapperContentSlot -Wrapper $ContentWrapper
        if ($ContentSlotElement) {
            Clear-ContentSlotArrayItems -ContentSlot $ContentSlotElement -ContainerWrapper $ContentWrapper
        }
    }
    else {
        if ((Get-IsLocked $ContentWrapper)) { return }
        Detach-UniversalSharedMenu -TargetWrapper $ContentWrapper
        $Array = $ContentWrapper.Parent
        if ($Array) {
            $Array.Children.Remove($ContentWrapper)
            Sync-ArraySlotState -ContentSlot $Array
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-DeleteButtonClick'
} # function Invoke-DeleteButtonClick

function Invoke-SearchButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-SearchButtonClick'
    if ($s -and -not $s.IsEnabled) { return }
    $ContentHeaderBorder = Get-ParentWrapperBorder -Element $s -HeaderOnly
    if (-not $ContentHeaderBorder) { return }

    $ContentHeaderBorderStack = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderStackName } -FindMax 1
    if (-not $ContentHeaderBorderStack) { return }

    $SearchBar = if ($ContentHeaderBorder.Tag -is [hashtable] -and $ContentHeaderBorder.Tag.SearchBar) { $ContentHeaderBorder.Tag.SearchBar } else { Get-OrCreateSearchBar -ContentHeaderBorder $ContentHeaderBorder }
    if (-not $SearchBar) { return }

    if ($SearchBar.Visibility -eq 'Visible') {
        Close-SearchBar -ChildElement $SearchBar
    }
    else {
        $ContentSlot = $ContentHeaderBorderStack.Children | Where-Object { $_.Name -eq $ContentSlotElementName }
        if ($ContentSlot -and $ContentSlot.Visibility -ne 'Visible') {
            $MinMaxButton = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $MinMaxButtonName } -FindMax 1)
            if ($MinMaxButton) {
                Set-ContentSlotCollapseState -ContentSlotElement $ContentSlot -MinMaxButton $MinMaxButton -ContentHeaderBorder $ContentHeaderBorder -Collapse $false
            }
            else {
                $ContentSlot.Visibility = 'Visible'
            }
        }

        if ($s.Parent -and $s.Parent.Name -eq $ButtonMenuName) {
            $s.Header = $SearchButtonIcon
            $s.Icon = $null
            $s.ToolTip = $SearchButtonToolTipActive
            Move-MenuItemBetweenMenus -Item $s -Direction 'ToCustomMenu'
        }

        $SearchBar.Visibility = 'Visible'
        $SearchInput = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchInputNameSuffix" } -FindMax 1
        if ($SearchInput) {
            if (-not [string]::IsNullOrWhiteSpace($SearchInput.Text)) { Invoke-SearchExecution -SearchBox $SearchInput }
            $SearchInput.Focus()
            $SearchInput.SelectAll()
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Invoke-SearchButtonClick'
} # function Invoke-SearchButtonClick

function Invoke-LockUnlockButtonClick {
    param($s, $e)
    Start-FunctionMeasurement -FunctionName 'Invoke-LockUnlockButtonClick'
    $TargetWrapper = if ($script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable] -and $script:UniversalSharedMenu.Tag.ActiveWrapper) {
        $script:UniversalSharedMenu.Tag.ActiveWrapper
    }
    else {
        Get-ParentWrapperBorder -Element $s
    }
    if (-not $TargetWrapper) {
        Stop-FunctionMeasurement -FunctionName 'Invoke-LockUnlockButtonClick'
        return
    }

    $CurrentlyLocked = ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('IsLocked') -and $TargetWrapper.Tag.IsLocked)
    $NewLockedState = -not $CurrentlyLocked

    Set-TargetLockedState -Target $TargetWrapper -IsLocked $NewLockedState

    Stop-FunctionMeasurement -FunctionName 'Invoke-LockUnlockButtonClick'
} # function Invoke-LockUnlockButtonClick

function New-MinMaxButton {
    Start-FunctionMeasurement -FunctionName 'New-MinMaxButton'
    $MinMaxButton = New-BaseMenuItem @{
        Name    = $MinMaxButtonName
        Header  = $MinMaxButtonMinedIcon
        ToolTip = $MinMaxButtonMinedToolTip
    }
    $MinMaxButton.Add_Click({ param($s, $e) Invoke-MinMaxButtonClick $s $e })
    $ReturnValue = $MinMaxButton
    Stop-FunctionMeasurement -FunctionName 'New-MinMaxButton'
    return $ReturnValue
} # function New-MinMaxButton

function New-AddArrayItemButton {
    param( [type]$Type )
    Start-FunctionMeasurement -FunctionName 'New-AddArrayItemButton'
    $AddArrayItemButton = New-BaseMenuItem @{
        Name    = $AddArrayItemButtonName
        Tag     = $Type.FullName
        Header  = $AddArrayItemButtonIcon
        ToolTip = $AddArrayItemButtonToolTip
    }
    $AddArrayItemButton.Add_Click({ param($s, $e) Invoke-AddArrayItemButtonClick $s $e })
    Add-LockableButtonToolTip -Button $AddArrayItemButton -ToolTip $AddArrayItemButtonToolTip

    $ReturnValue = $AddArrayItemButton
    Stop-FunctionMeasurement -FunctionName 'New-AddArrayItemButton'
    return $ReturnValue
} # function New-AddArrayItemButton

function New-QuickSetMenuItem {
    param(
        [string]$ActionFrom = $ContentHeaderBorderName,
        [bool]$IsConstruct = $false
    )
    Start-FunctionMeasurement -FunctionName 'New-QuickSetMenuItem'

    $QuickSetMenu = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$QuickSetMenuNameSuffix"
        Header  = $QuickSetHeader
        Icon    = $QuickSetIcon
        ToolTip = $QuickSetToolTip
    }

    $SetMenu = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$QuickSetSetMenuNameSuffix"
        Header  = $QuickSetSetMenuHeader
        Icon    = $QuickSetSetMenuIcon
        ToolTip = $QuickSetSetMenuToolTip
    }
    $QuickSetMenu.Items.Add($SetMenu) | Out-Null

    $RefreshButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$QuickSetRefreshButtonNameSuffix"
        Header  = $QuickSetRefreshButtonHeader
        Icon    = $QuickSetRefreshButtonIcon
        ToolTip = $QuickSetRefreshButtonToolTip
    }
    $QuickSetMenu.Items.Add($RefreshButton) | Out-Null
    $QuickSetMenu.Items.Add((New-BaseSeparator)) | Out-Null

    $SaveButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$QuickSetSaveButtonNameSuffix"
        Header    = $QuickSetSaveButtonHeader
        Icon      = $QuickSetSaveButtonIcon
        ToolTip   = $QuickSetSaveButtonToolTip
        IsEnabled = $false
    }
    $QuickSetMenu.Items.Add($SaveButton) | Out-Null

    $SaveAsButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$QuickSetSaveAsButtonNameSuffix"
        Header    = $QuickSetSaveAsButtonHeader
        Icon      = $QuickSetSaveAsButtonIcon
        ToolTip   = $QuickSetSaveAsButtonToolTip
        IsEnabled = $IsConstruct
    }
    $QuickSetMenu.Items.Add($SaveAsButton) | Out-Null

    $RenameButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$QuickSetRenameButtonNameSuffix"
        Header    = $QuickSetRenameButtonHeader
        Icon      = $QuickSetRenameButtonIcon
        ToolTip   = $QuickSetRenameButtonToolTip
        IsEnabled = $false
    }
    $QuickSetMenu.Items.Add($RenameButton) | Out-Null
    $QuickSetMenu.Items.Add((New-BaseSeparator)) | Out-Null

    $ClearButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$QuickSetClearButtonNameSuffix"
        Header    = $QuickSetClearButtonHeader
        Icon      = $QuickSetClearButtonIcon
        ToolTip   = $QuickSetClearButtonToolTip
        IsEnabled = $false
    }
    $QuickSetMenu.Items.Add($ClearButton) | Out-Null

    $CloseButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$QuickSetCloseButtonNameSuffix"
        Header    = $QuickSetCloseButtonHeader
        Icon      = $QuickSetCloseButtonIcon
        ToolTip   = $QuickSetCloseButtonToolTip
        IsEnabled = $false
    }
    $QuickSetMenu.Items.Add($CloseButton) | Out-Null

    $DeleteButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$QuickSetDeleteButtonNameSuffix"
        Header    = $QuickSetDeleteButtonHeader
        Icon      = $QuickSetDeleteButtonIcon
        ToolTip   = $QuickSetDeleteButtonToolTip
        IsEnabled = $false
    }
    $QuickSetMenu.Items.Add($DeleteButton) | Out-Null

    # Show tooltips even while a QuickSet button is disabled, so the user knows what it needs
    :items foreach ($Item in $QuickSetMenu.Items) {
        [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($Item, $true)
    } # items foreach

    # QuickSet Button Functionality
    $RefreshButton.Add_Click({ param($s, $e) Invoke-QuickSetRefreshButtonClick $s $e })
    $SaveButton.Add_Click({ param($s, $e) Invoke-QuickSetSaveButtonClick $s $e })
    $SaveAsButton.Add_Click({ param($s, $e) Invoke-QuickSetSaveAsButtonClick $s $e })
    $RenameButton.Add_Click({ param($s, $e) Invoke-QuickSetRenameButtonClick $s $e })
    $ClearButton.Add_Click({ param($s, $e) Invoke-QuickSetClearButtonClick $s $e })
    $CloseButton.Add_Click({ param($s, $e) Invoke-QuickSetCloseButtonClick $s $e })
    $DeleteButton.Add_Click({ param($s, $e) Invoke-QuickSetDeleteButtonClick $s $e })

    # Populate the Set submenu once, the first time the QuickSet menu is opened
    $LoadedState = @{ HasRefreshed = $false }
    $QuickSetMenu.Add_SubmenuOpened(({
                param($s, $e)
                if ($e.Source -ne $s) { return }
                if ($LoadedState.HasRefreshed) { return }
                $LoadedState.HasRefreshed = $true
                Invoke-QuickSetRefreshButtonClick $s $e
            }).GetNewClosure())

    $ReturnValue = $QuickSetMenu
    Stop-FunctionMeasurement -FunctionName 'New-QuickSetMenuItem'
    return $ReturnValue
} # function New-QuickSetMenuItem

function Test-IsSimpleContentType {
    param($Type)
    Start-FunctionMeasurement -FunctionName "Test-IsSimpleContentType"
    if (-not $Type) { return $true }
    $ResolvedType = if ($Type -is [type]) { $Type } else { $Type -as [type] }
    if (-not $ResolvedType) { return $true }
    if ($ResolvedType.IsArray) {
        $ResolvedType = $ResolvedType.GetElementType()
    }
    if ($ResolvedType.IsEnum) { return $true }
    $FullName = $ResolvedType.FullName.TrimEnd('[]')
    if (@('System.String', 'System.Boolean', 'System.DateTime', 'System.Char', 'System.Single', 'System.Double', 'System.Decimal') -contains $FullName) {
        return $true
    }
    if ($FullName -like 'System.Int*' -or $FullName -like 'System.UInt*') {
        return $true
    }
    Stop-FunctionMeasurement -FunctionName "Test-IsSimpleContentType"
    return $false
} # function Test-IsSimpleContentType

function Get-WrapperSortableScalarValue {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [switch]$SortByArrayCount
    )
    Start-FunctionMeasurement -FunctionName "Get-WrapperSortableScalarValue"
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }

    $Tag = if ($Target.Tag -is [hashtable]) { $Target.Tag } else { @{} }
    if ($Tag.IsArray -and $Tag.ContentSlot) {
        if ($SortByArrayCount) {
            $NestedCount = if ($Tag.ContentSlot.Children) { [int]$Tag.ContentSlot.Children.Count } else { 0 }
            if ($NestedCount -le 0) { return $null }
            return $NestedCount
        }
        $Parts = [System.Collections.ArrayList]@()
        foreach ($Child in @($Tag.ContentSlot.Children)) {
            $ChildVal = Get-WrapperSortableScalarValue -Wrapper $Child
            if ($null -ne $ChildVal -and -not ($ChildVal -is [string] -and [string]::IsNullOrWhiteSpace($ChildVal))) {
                [void]$Parts.Add($ChildVal.ToString())
            }
        }
        if ($Parts.Count -eq 0) { return $null }
        return ($Parts -join ', ')
    }

    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }
    $Content = if ($Target.Name -eq $ContentElementName) { $Target } else {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
    }
    if ($Content -is [array]) { $Content = $Content[0] }

    if ($Content) {
        $RawValue = Get-ContentValue -Object $Content
        if ($null -eq $RawValue -or ($RawValue -is [string] -and [string]::IsNullOrWhiteSpace($RawValue))) {
            return $null
        }
        if ($RawValue -is [bool]) {
            return [int]$RawValue
        }
        if ($Content.Tag -is [hashtable] -and $Content.Tag.ContainsKey('TargetType') -and $Content.Tag.TargetType) {
            $TargetTypeName = $Content.Tag.TargetType.FullName
            if ($TargetTypeName -like 'System.Int*' -or $TargetTypeName -like 'System.UInt*' -or @('System.Single', 'System.Double', 'System.Decimal') -contains $TargetTypeName) {
                $ParsedNumber = [decimal]0
                if ([decimal]::TryParse($RawValue.ToString().Trim(), [ref]$ParsedNumber)) {
                    return $ParsedNumber
                }
            }
        }
        return $RawValue.ToString()
    }

    $DTP = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
    if ($DTP -is [array]) { $DTP = $DTP[0] }
    if ($DTP) {
        $RawDate = Get-ContentValue -Object $DTP
        if ($null -eq $RawDate -or ($RawDate -is [string] -and [string]::IsNullOrWhiteSpace($RawDate))) {
            return $null
        }
        $ParsedDate = [DateTime]::MinValue
        if ([DateTime]::TryParse($RawDate.ToString().Trim(), [ref]$ParsedDate)) {
            return $ParsedDate
        }
        return $RawDate.ToString()
    }

    Stop-FunctionMeasurement -FunctionName "Get-WrapperSortableScalarValue"
    return $null
} # function Get-WrapperSortableScalarValue

function Get-ArrayItemSortKey {
    param(
        [Parameter(Mandatory)]$ItemWrapper,
        [string[]]$PropertyPath = @(),
        [switch]$SortByTitle,
        [switch]$SortByArrayCount
    )
    Start-FunctionMeasurement -FunctionName "Get-ArrayItemSortKey"
    $TargetItem = Resolve-TargetElement $ItemWrapper
    if (-not $TargetItem) { return $null }

    $CurrentWrapper = $TargetItem
    if ($PropertyPath -and $PropertyPath.Count -gt 0) {
        foreach ($StepName in $PropertyPath) {
            if (-not $CurrentWrapper) { return $null }
            $CurrTag = if ($CurrentWrapper.Tag -is [hashtable]) { $CurrentWrapper.Tag } else { @{} }
            $ConstructPanel = if ($CurrTag.IsConstruct -and $CurrTag.Construct) {
                $CurrTag.Construct
            }
            else {
                Find-ObjectWhere -Object ([ref]$CurrentWrapper) -FindWhere { $_.Name -eq $ConstructName } -DepthMax 1 -DepthWhere { $_.Name -eq $ConstructName } -FindMax 1
            }
            if ($ConstructPanel -is [array]) { $ConstructPanel = $ConstructPanel[0] }
            if (-not $ConstructPanel -or -not $ConstructPanel.Children) { return $null }

            $MatchedChild = $null
            foreach ($Child in @($ConstructPanel.Children)) {
                $ChildTitle = Find-Title $Child
                $ParamName = if ($ChildTitle) { ($ChildTitle.Split('-')[0]).Trim() } else { $Child.Name }
                if ($ParamName -eq $StepName) {
                    $MatchedChild = $Child
                    break
                }
            }
            $CurrentWrapper = $MatchedChild
        }
        if (-not $CurrentWrapper) { return $null }
        Stop-FunctionMeasurement -FunctionName "Get-ArrayItemSortKey"
        return (Get-WrapperSortableScalarValue -Wrapper $CurrentWrapper -SortByArrayCount:$SortByArrayCount)
    }

    $TitleElement = Get-WrapperHeaderTitleElement -Wrapper $TargetItem
    if (-not $TitleElement -and $TargetItem.Name -eq $ContentHeaderBorderName) {
        $FoundTitleElement = Find-ObjectWhere -Object ([ref]$TargetItem) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName } -FindMax 1
        if ($FoundTitleElement -is [array]) { $FoundTitleElement = $FoundTitleElement[0] }
        $TitleElement = $FoundTitleElement
    }
    $HasHeader = ($null -ne $TitleElement) -or ($TargetItem.Name -eq $ContentHeaderBorderName)

    if ($SortByTitle -or $HasHeader) {
        $TitleValue = if ($TitleElement -and -not [string]::IsNullOrWhiteSpace($TitleElement.Text)) {
            $TitleElement.Text
        }
        elseif ($TargetItem.Tag -is [hashtable] -and $TargetItem.Tag.ContainsKey('OriginalTitle') -and -not [string]::IsNullOrWhiteSpace($TargetItem.Tag.OriginalTitle)) {
            $TargetItem.Tag.OriginalTitle
        }
        else {
            $DisplayName = Get-WrapperDisplayName -Wrapper $TargetItem
            if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
                $DisplayName
            }
            else {
                $FoundTitle = Find-Title $TargetItem
                if ($FoundTitle) { ($FoundTitle.Split('-')[0]).Trim() } else { $null }
            }
        }

        if ([string]::IsNullOrWhiteSpace($TitleValue)) {
            Stop-FunctionMeasurement -FunctionName "Get-ArrayItemSortKey"
            return $null
        }

        $TrimmedTitle = $TitleValue.Trim()
        $ParsedNumber = [decimal]0
        if ([decimal]::TryParse($TrimmedTitle, [ref]$ParsedNumber)) {
            Stop-FunctionMeasurement -FunctionName "Get-ArrayItemSortKey"
            return $ParsedNumber
        }

        Stop-FunctionMeasurement -FunctionName "Get-ArrayItemSortKey"
        return $TrimmedTitle
    }

    Stop-FunctionMeasurement -FunctionName "Get-ArrayItemSortKey"
    return (Get-WrapperSortableScalarValue -Wrapper $TargetItem -SortByArrayCount:$SortByArrayCount)
} # function Get-ArrayItemSortKey

function Invoke-ArraySort {
    param(
        [Parameter(Mandatory)]$Sender,
        [Parameter(Mandatory)][string]$ActionFrom,
        [ValidateSet('Ascending', 'Descending')][string]$Direction = 'Ascending',
        [string[]]$PropertyPath = @(),
        [switch]$SortByTitle,
        [switch]$SortByArrayCount
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-ArraySort'
    $TargetSender = Resolve-TargetElement $Sender
    if (-not $TargetSender) { return }

    $ArrayWrapper = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1)
    if (-not $ArrayWrapper) {
        $ArrayWrapper = Get-ParentWrapperBorder -Element $TargetSender -HeaderOnly
    }
    if (-not $ArrayWrapper -and $script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable]) {
        $ArrayWrapper = $script:UniversalSharedMenu.Tag.ActiveWrapper
    }
    if (-not $ArrayWrapper) { return }
    if (Get-IsElementLockedSelf $ArrayWrapper) { return }

    $ContentSlot = Get-WrapperContentSlot -Wrapper $ArrayWrapper
    if (-not $ContentSlot -or -not $ContentSlot.Children -or $ContentSlot.Children.Count -le 1) { return }

    $NonEmptyEntries = [System.Collections.ArrayList]@()
    $EmptyEntries = [System.Collections.ArrayList]@()
    $Idx = 0

    foreach ($ChildWrapper in @($ContentSlot.Children)) {
        $SortKey = Get-ArrayItemSortKey -ItemWrapper $ChildWrapper -PropertyPath $PropertyPath -SortByTitle:$SortByTitle -SortByArrayCount:$SortByArrayCount
        $IsEmpty = ($null -eq $SortKey) -or ($SortKey -is [string] -and [string]::IsNullOrWhiteSpace($SortKey))
        $Entry = [PSCustomObject]@{
            Wrapper       = $ChildWrapper
            SortKey       = $SortKey
            OriginalIndex = $Idx
        }
        if ($IsEmpty) {
            [void]$EmptyEntries.Add($Entry)
        }
        else {
            [void]$NonEmptyEntries.Add($Entry)
        }
        $Idx++
    }

    $IsDescending = ($Direction -eq 'Descending')
    $SortedNonEmpty = if ($NonEmptyEntries.Count -gt 1) {
        @($NonEmptyEntries | Sort-Object -Property @{ Expression = { $_.SortKey }; Descending = $IsDescending }, @{ Expression = { $_.OriginalIndex }; Descending = $false })
    }
    else {
        @($NonEmptyEntries)
    }

    $FinalOrder = @($SortedNonEmpty) + @($EmptyEntries)

    $ContentSlot.Children.Clear()
    foreach ($Entry in $FinalOrder) {
        [void]$ContentSlot.Children.Add($Entry.Wrapper)
    }

    Reset-ArrayIndexes ([ref]$ContentSlot)

    Stop-FunctionMeasurement -FunctionName 'Invoke-ArraySort'
} # function Invoke-ArraySort

function Add-SortDirectionMenuItems {
    param(
        [Parameter(Mandatory)]$ParentMenuItem,
        [Parameter(Mandatory)][string]$ActionFrom,
        [string[]]$PropertyPath = @(),
        [switch]$SortByTitle,
        [switch]$SortByArrayCount
    )
    Start-FunctionMeasurement -FunctionName "Add-SortDirectionMenuItems"
    $AscItem = New-BaseMenuItem @{
        Header        = $SortAscendingHeader
        Icon          = $SortAscendingIcon
        ToolTip       = $SortAscendingToolTip
        FlowDirection = 'LeftToRight'
    }
    $DescItem = New-BaseMenuItem @{
        Header        = $SortDescendingHeader
        Icon          = $SortDescendingIcon
        ToolTip       = $SortDescendingToolTip
        FlowDirection = 'LeftToRight'
    }

    $BoundActionFrom = $ActionFrom
    $BoundPath = @($PropertyPath)
    $BoundByTitle = [bool]$SortByTitle
    $BoundByArrayCount = [bool]$SortByArrayCount

    $AscItem.Add_Click(({
                param($s, $e)
                Invoke-ArraySort -Sender $s -ActionFrom $BoundActionFrom -Direction 'Ascending' -PropertyPath $BoundPath -SortByTitle:$BoundByTitle -SortByArrayCount:$BoundByArrayCount
            }).GetNewClosure())

    $DescItem.Add_Click(({
                param($s, $e)
                Invoke-ArraySort -Sender $s -ActionFrom $BoundActionFrom -Direction 'Descending' -PropertyPath $BoundPath -SortByTitle:$BoundByTitle -SortByArrayCount:$BoundByArrayCount
            }).GetNewClosure())

    $ParentMenuItem.Items.Add($AscItem) | Out-Null
    $ParentMenuItem.Items.Add($DescItem) | Out-Null
    Stop-FunctionMeasurement -FunctionName "Add-SortDirectionMenuItems"
} # function Add-SortDirectionMenuItems

function Add-ConstructSortPropertyMenuItems {
    param(
        [Parameter(Mandatory)]$ParentMenuItem,
        [Parameter(Mandatory)][string]$ActionFrom,
        [Parameter(Mandatory)]$ConstructType,
        [string[]]$ParentPath = @(),
        [int]$Depth = 0
    )
    Start-FunctionMeasurement -FunctionName "Add-ConstructSortPropertyMenuItems"
    if ($Depth -gt 3) { return }
    $ResolvedType = if ($ConstructType -is [type]) { $ConstructType } else { $ConstructType -as [type] }
    if (-not $ResolvedType) { return }

    $Parameters = Get-TypeConstructors -Type $ResolvedType
    if (-not $Parameters) { return }

    $UniqueParameters = $Parameters | Get-UniqueByProperty -Property 'Name'
    foreach ($Parameter in $UniqueParameters.List) {
        if (-not $Parameter -or [string]::IsNullOrWhiteSpace($Parameter.Name)) { continue }
        if ($Parameter.Type -eq 'System.Object') { continue }

        $ParamType = $Parameter.Type -as [type]
        $TypeShortName = $Parameter.Type.ToString().Split('.')[-1]
        $CurrentPath = @($ParentPath) + @($Parameter.Name)
        $IsArrayProperty = ($ParamType -and $ParamType.IsArray) -or ($Parameter.Type.ToString() -like '*`[]')

        $PropMenuItem = New-BaseMenuItem @{
            Header        = $Parameter.Name
            ToolTip       = "Sort by $($Parameter.Name) ($TypeShortName)"
            FlowDirection = 'LeftToRight'
        }

        if ($IsArrayProperty) {
            $ValuesMenuItem = New-BaseMenuItem @{
                Header        = $SortArrayValuesHeader
                Icon          = $SortArrayValuesIcon
                ToolTip       = $SortArrayValuesToolTip
                FlowDirection = 'LeftToRight'
            }
            Add-SortDirectionMenuItems -ParentMenuItem $ValuesMenuItem -ActionFrom $ActionFrom -PropertyPath $CurrentPath
            $PropMenuItem.Items.Add($ValuesMenuItem) | Out-Null

            $CountMenuItem = New-BaseMenuItem @{
                Header        = $SortArrayCountHeader
                Icon          = $SortArrayCountIcon
                ToolTip       = $SortArrayCountToolTip
                FlowDirection = 'LeftToRight'
            }
            Add-SortDirectionMenuItems -ParentMenuItem $CountMenuItem -ActionFrom $ActionFrom -PropertyPath $CurrentPath -SortByArrayCount
            $PropMenuItem.Items.Add($CountMenuItem) | Out-Null
        }
        elseif ($ParamType -and -not (Test-IsSimpleContentType -Type $ParamType)) {
            Add-ConstructSortPropertyMenuItems -ParentMenuItem $PropMenuItem -ActionFrom $ActionFrom -ConstructType $ParamType -ParentPath $CurrentPath -Depth ($Depth + 1)
        }
        else {
            Add-SortDirectionMenuItems -ParentMenuItem $PropMenuItem -ActionFrom $ActionFrom -PropertyPath $CurrentPath
        }

        if ($PropMenuItem.Items.Count -gt 0) {
            $ParentMenuItem.Items.Add($PropMenuItem) | Out-Null
        }
    }
    Stop-FunctionMeasurement -FunctionName "Add-ConstructSortPropertyMenuItems"
} # function Add-ConstructSortPropertyMenuItems

function New-SortMenuItem {
    param(
        [string]$ActionFrom = $ContentHeaderBorderName,
        $TargetType = $null
    )
    Start-FunctionMeasurement -FunctionName 'New-SortMenuItem'
    $SortMenu = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$SortMenuNameSuffix"
        Header  = $SortMenuHeader
        Icon    = $SortMenuIcon
        ToolTip = $SortMenuToolTip
    }
    Add-LockableButtonToolTip -Button $SortMenu -ToolTip $SortMenuToolTip

    $ResolvedElementType = if ($TargetType -is [type]) { $TargetType } elseif ($TargetType) { $TargetType -as [type] } else { $null }
    if ($ResolvedElementType -and $ResolvedElementType.IsArray) {
        $ResolvedElementType = $ResolvedElementType.GetElementType()
    }

    if ($ResolvedElementType -and -not (Test-IsSimpleContentType -Type $ResolvedElementType)) {
        $TitleMenuItem = New-BaseMenuItem @{
            Header        = $SortByTitleHeader
            Icon          = $SortByTitleIcon
            ToolTip       = $SortByTitleToolTip
            FlowDirection = 'LeftToRight'
        }
        Add-SortDirectionMenuItems -ParentMenuItem $TitleMenuItem -ActionFrom $ActionFrom -SortByTitle
        $SortMenu.Items.Add($TitleMenuItem) | Out-Null

        $SortMenu.Items.Add((New-BaseSeparator)) | Out-Null
        Add-ConstructSortPropertyMenuItems -ParentMenuItem $SortMenu -ActionFrom $ActionFrom -ConstructType $ResolvedElementType
    }
    else {
        Add-SortDirectionMenuItems -ParentMenuItem $SortMenu -ActionFrom $ActionFrom
    }

    $ReturnValue = $SortMenu
    Stop-FunctionMeasurement -FunctionName 'New-SortMenuItem'
    return $ReturnValue
} # function New-SortMenuItem

function Get-WrapperTypeClipboardKey {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Get-WrapperTypeClipboardKey"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return 'System.Object' }

    $Type = Get-WrapperTargetType -Wrapper $Target
    $TypeName = if ($Type -is [type]) {
        $Type.FullName.TrimEnd('[]')
    }
    elseif ($Type -is [string] -and -not [string]::IsNullOrWhiteSpace($Type)) {
        $Type.TrimEnd('[]')
    }
    else {
        'System.Object'
    }

    $IsArray = ($Target.Tag -is [hashtable] -and $Target.Tag.IsArray)
    if (-not $IsArray) {
        $TitleText = Find-Title $Target
        $CleanTitleText = if ($TitleText) { [System.Text.RegularExpressions.Regex]::Replace($TitleText, '\[.*?\]', '[]') } else { $TitleText }
        $IsArray = ($CleanTitleText -like '*`[]')
    }

    if ($IsArray) {
        return "$TypeName`[]"
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperTypeClipboardKey"
    return $TypeName
} # function Get-WrapperTypeClipboardKey

function Test-HasClipboardForWrapper {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName "Test-HasClipboardForWrapper"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $false }
    $TypeKey = Get-WrapperTypeClipboardKey -Wrapper $Target
    Stop-FunctionMeasurement -FunctionName "Test-HasClipboardForWrapper"
    return ($TypeClipboard -is [hashtable] -and $TypeClipboard.ContainsKey($TypeKey))
} # function Test-HasClipboardForWrapper

function Update-WrapperPasteButtonState {
    param([Parameter(Mandatory)]$Wrapper)
    Start-FunctionMeasurement -FunctionName 'Update-WrapperPasteButtonState'
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    $Menu = Get-WrapperMenu -Wrapper $Target
    if (-not $Menu) { return }

    $IsLocked = Get-IsElementLockedSelf $Target
    $HasClipboard = Test-HasClipboardForWrapper -Wrapper $Target
    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes @($PasteButtonNameSuffix) -IsEnabled ($HasClipboard -and (-not $IsLocked))

    Stop-FunctionMeasurement -FunctionName 'Update-WrapperPasteButtonState'
} # function Update-WrapperPasteButtonState

function Save-WrapperToTypeClipboard {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [switch]$ValuesOnly
    )
    Start-FunctionMeasurement -FunctionName "Save-WrapperToTypeClipboard"
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $null }

    $TypeKey = Get-WrapperTypeClipboardKey -Wrapper $Target
    $CurrentValue = Get-WrapperQuickSetValue -Wrapper $Target -ValuesOnly:$ValuesOnly
    $JsonSnapshot = ConvertTo-Json -InputObject $CurrentValue -Depth 20
    $TypeClipboard[$TypeKey] = @{
        Json       = $JsonSnapshot
        ValuesOnly = [bool]$ValuesOnly
    }

    if ($BaseWindow) {
        $AllPasteButtons = Find-ObjectWhere -Object ([ref]$BaseWindow) -FindWhere { $_.Name -like "*_$PasteButtonNameSuffix" }
        foreach ($PBtn in @($AllPasteButtons)) {
            if ($PBtn) {
                $OwnerWrapper = Get-ParentWrapperBorder -Element $PBtn
                if ($OwnerWrapper) {
                    Update-WrapperPasteButtonState -Wrapper $OwnerWrapper
                }
            }
        }
    }

    Stop-FunctionMeasurement -FunctionName "Save-WrapperToTypeClipboard"
    return $CurrentValue
} # function Save-WrapperToTypeClipboard

function Convert-QuickSetNodeToCsvRowObject {
    param($Node)
    Start-FunctionMeasurement -FunctionName "Convert-QuickSetNodeToCsvRowObject"
    $Row = [ordered]@{}
    if ($null -eq $Node) {
        $Row['value'] = ''
        return [PSCustomObject]$Row
    }

    if (($Node -is [System.Collections.IDictionary] -or $Node -is [System.Management.Automation.PSCustomObject]) -and $Node -isnot [array]) {
        $PropNames = if ($Node -is [System.Collections.IDictionary]) { @($Node.Keys) } else { @($Node.PSObject.Properties.Name) }
        $HasValueEnvelope = ($PropNames -contains 'value') -and (($PropNames -contains 'displayName') -or ($PropNames -contains 'isMinimized') -or ($PropNames -contains 'isLocked') -or ($PropNames -contains 'isDisabled'))

        if ($HasValueEnvelope) {
            foreach ($MetaKey in @('displayName', 'isMinimized', 'isLocked', 'isDisabled')) {
                if ($PropNames -contains $MetaKey) {
                    $Row[$MetaKey] = if ($Node -is [System.Collections.IDictionary]) { $Node[$MetaKey] } else { $Node.$MetaKey }
                }
            }
            $Inner = if ($Node -is [System.Collections.IDictionary]) { $Node['value'] } else { $Node.value }
            if (($Inner -is [System.Collections.IDictionary] -or $Inner -is [System.Management.Automation.PSCustomObject]) -and $Inner -isnot [array]) {
                $InnerProps = if ($Inner -is [System.Collections.IDictionary]) { @($Inner.Keys) } else { @($Inner.PSObject.Properties.Name) }
                foreach ($K in $InnerProps) {
                    $V = if ($Inner -is [System.Collections.IDictionary]) { $Inner[$K] } else { $Inner.$K }
                    $Row[$K] = if ($V -is [array] -or $V -is [System.Collections.IDictionary] -or $V -is [System.Management.Automation.PSCustomObject]) {
                        ConvertTo-Json -InputObject $V -Compress -Depth 10
                    }
                    else { $V }
                }
            }
            else {
                $Row['value'] = if ($Inner -is [array] -or $Inner -is [System.Collections.IDictionary] -or $Inner -is [System.Management.Automation.PSCustomObject]) {
                    ConvertTo-Json -InputObject $Inner -Compress -Depth 10
                }
                else { $Inner }
            }
        }
        else {
            foreach ($K in $PropNames) {
                $V = if ($Node -is [System.Collections.IDictionary]) { $Node[$K] } else { $Node.$K }
                $Row[$K] = if ($V -is [array] -or $V -is [System.Collections.IDictionary] -or $V -is [System.Management.Automation.PSCustomObject]) {
                    ConvertTo-Json -InputObject $V -Compress -Depth 10
                }
                else { $V }
            }
        }
        return [PSCustomObject]$Row
    }

    $Row['value'] = $Node
    Stop-FunctionMeasurement -FunctionName "Convert-QuickSetNodeToCsvRowObject"
    return [PSCustomObject]$Row
} # function Convert-QuickSetNodeToCsvRowObject

function Convert-WrapperValueToTextFormat {
    param(
        $Value,
        [Parameter(Mandatory)][ValidateSet('JSON', 'XML', 'CSV')][string]$Format
    )
    Start-FunctionMeasurement -FunctionName "Convert-WrapperValueToTextFormat"
    switch ($Format) {
        'JSON' {
            return (ConvertTo-Json -InputObject $Value -Depth 20)
        }
        'XML' {
            $XmlDoc = ConvertTo-Xml -InputObject $Value -Depth 20 -NoTypeInformation
            $StringWriter = New-Object System.IO.StringWriter
            $XmlWriter = New-Object System.Xml.XmlTextWriter($StringWriter)
            $XmlWriter.Formatting = [System.Xml.Formatting]::Indented
            $XmlDoc.WriteContentTo($XmlWriter)
            $XmlWriter.Flush()
            return $StringWriter.ToString()
        }
        'CSV' {
            $TargetItems = $null
            if ($Value -is [array] -or $Value -is [System.Collections.IList]) {
                $TargetItems = @($Value)
            }
            elseif (($Value -is [System.Collections.IDictionary]) -and $Value.Contains('value') -and ($Value['value'] -is [array] -or $Value['value'] -is [System.Collections.IList])) {
                $TargetItems = @($Value['value'])
            }

            if ($null -ne $TargetItems) {
                $RowObjects = [System.Collections.ArrayList]@()
                foreach ($Elem in $TargetItems) {
                    [void]$RowObjects.Add((Convert-QuickSetNodeToCsvRowObject -Node $Elem))
                }
                if ($RowObjects.Count -eq 0) { return '' }
                return ((@($RowObjects) | ConvertTo-Csv -NoTypeInformation) -join [Environment]::NewLine)
            }

            $SingleRow = Convert-QuickSetNodeToCsvRowObject -Node $Value
            return ((@($SingleRow) | ConvertTo-Csv -NoTypeInformation) -join [Environment]::NewLine)
        }
    }
    Stop-FunctionMeasurement -FunctionName "Convert-WrapperValueToTextFormat"
} # function Convert-WrapperValueToTextFormat

function Invoke-CopyButtonClick {
    param($s, $e, [string]$ActionFrom)
    Start-FunctionMeasurement -FunctionName 'Invoke-CopyButtonClick'
    $TargetSender = Resolve-TargetElement $s
    if (-not $TargetSender) { return }

    $ContentWrapper = if ($ActionFrom) {
        Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1)
    }
    else {
        Get-ContentWrapperFromButton -Button $TargetSender -Suffix $CopyButtonNameSuffix
    }
    if (-not $ContentWrapper) {
        $ContentWrapper = Get-ParentWrapperBorder -Element $TargetSender
    }
    if (-not $ContentWrapper) { return }
    $null = Save-WrapperToTypeClipboard -Wrapper $ContentWrapper

    Stop-FunctionMeasurement -FunctionName 'Invoke-CopyButtonClick'
} # function Invoke-CopyButtonClick

function Invoke-CopyAsButtonClick {
    param(
        $s,
        $e,
        [Parameter(Mandatory)][string]$ActionFrom,
        [Parameter(Mandatory)][ValidateSet('JSON', 'XML', 'CSV')][string]$Format,
        [switch]$ValuesOnly
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-CopyAsButtonClick'
    $TargetSender = Resolve-TargetElement $s
    if (-not $TargetSender) { return }

    $ContentWrapper = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1)
    if (-not $ContentWrapper) {
        $ContentWrapper = Get-ParentWrapperBorder -Element $TargetSender
    }
    if (-not $ContentWrapper) { return }

    $CapturedValue = Save-WrapperToTypeClipboard -Wrapper $ContentWrapper -ValuesOnly:$ValuesOnly
    $FormattedText = Convert-WrapperValueToTextFormat -Value $CapturedValue -Format $Format
    if ($null -eq $FormattedText) { $FormattedText = '' }
    [System.Windows.Clipboard]::SetText([string]$FormattedText)

    Stop-FunctionMeasurement -FunctionName 'Invoke-CopyAsButtonClick'
} # function Invoke-CopyAsButtonClick

function Invoke-PasteButtonClick {
    param(
        $s,
        $e,
        [string]$ActionFrom,
        [switch]$ValuesOnly
    )
    Start-FunctionMeasurement -FunctionName 'Invoke-PasteButtonClick'
    $TargetSender = Resolve-TargetElement $s
    if (-not $TargetSender) { return }

    $ContentWrapper = if ($ActionFrom) {
        Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1)
    }
    else {
        Get-ContentWrapperFromButton -Button $TargetSender -Suffix $PasteButtonNameSuffix
    }
    if (-not $ContentWrapper) {
        $ContentWrapper = Get-ParentWrapperBorder -Element $TargetSender
    }
    if (-not $ContentWrapper) { return }
    if (Get-IsElementLockedSelf $ContentWrapper) { return }

    $TypeKey = Get-WrapperTypeClipboardKey -Wrapper $ContentWrapper
    if (-not ($TypeClipboard -is [hashtable]) -or -not $TypeClipboard.ContainsKey($TypeKey)) { return }

    $Entry = $TypeClipboard[$TypeKey]
    $JsonSnapshot = if ($Entry -is [hashtable] -and $Entry.ContainsKey('Json')) { $Entry.Json } else { [string]$Entry }
    $IsSnapshotValuesOnly = if ($Entry -is [hashtable] -and $Entry.ContainsKey('ValuesOnly')) { [bool]$Entry.ValuesOnly } else { $false }
    $EffectiveValuesOnly = ([bool]$ValuesOnly) -or $IsSnapshotValuesOnly

    $ClonedValue = if ([string]::IsNullOrEmpty($JsonSnapshot)) { $null } else { ConvertFrom-Json -InputObject $JsonSnapshot }
    Set-WrapperQuickSetValue -Wrapper $ContentWrapper -Value $ClonedValue -ValuesOnly:$EffectiveValuesOnly

    Stop-FunctionMeasurement -FunctionName 'Invoke-PasteButtonClick'
} # function Invoke-PasteButtonClick

function Get-PasteButtonToolTip {
    param([Parameter(Mandatory)]$Button)
    Start-FunctionMeasurement -FunctionName "Get-PasteButtonToolTip"
    if ($Button.IsEnabled) { return $PasteButtonToolTip }
    $ParentBorder = Get-ParentWrapperBorder -Element $Button
    if ($ParentBorder -and (Get-IsElementLockedSelf $ParentBorder)) {
        return "$PasteButtonToolTip`n$LockedButtonToolTip"
    }
    Stop-FunctionMeasurement -FunctionName "Get-PasteButtonToolTip"
    return "$PasteButtonToolTip`n$EmptyClipboardButtonToolTip"
} # function Get-PasteButtonToolTip

function Add-CopyScopeMenuItems {
    param(
        [Parameter(Mandatory)]$ParentMenuItem,
        [Parameter(Mandatory)][string]$ActionFrom,
        [string]$Format = $null
    )
    Start-FunctionMeasurement -FunctionName "Add-CopyScopeMenuItems"
    $FullItem = New-BaseMenuItem @{
        Header        = $CopyFullItemHeader
        Icon          = $CopyFullItemIcon
        ToolTip       = $CopyFullItemToolTip
        FlowDirection = 'LeftToRight'
    }
    $ValuesItem = New-BaseMenuItem @{
        Header        = $CopyValuesOnlyHeader
        Icon          = $CopyValuesOnlyIcon
        ToolTip       = $CopyValuesOnlyToolTip
        FlowDirection = 'LeftToRight'
    }

    $BoundActionFrom = $ActionFrom
    $BoundFormat = $Format

    $FullItem.Add_Click(({
                param($s, $e)
                if ([string]::IsNullOrEmpty($BoundFormat)) {
                    Invoke-CopyButtonClick -s $s -e $e -ActionFrom $BoundActionFrom
                }
                else {
                    Invoke-CopyAsButtonClick -s $s -e $e -ActionFrom $BoundActionFrom -Format $BoundFormat
                }
            }).GetNewClosure())

    $ValuesItem.Add_Click(({
                param($s, $e)
                if ([string]::IsNullOrEmpty($BoundFormat)) {
                    Invoke-CopyButtonClick -s $s -e $e -ActionFrom $BoundActionFrom -ValuesOnly
                }
                else {
                    Invoke-CopyAsButtonClick -s $s -e $e -ActionFrom $BoundActionFrom -Format $BoundFormat -ValuesOnly
                }
            }).GetNewClosure())

    $ParentMenuItem.Items.Add($FullItem) | Out-Null
    $ParentMenuItem.Items.Add($ValuesItem) | Out-Null
    Stop-FunctionMeasurement -FunctionName "Add-CopyScopeMenuItems"
} # function Add-CopyScopeMenuItems

function New-CopyButton {
    param([string]$ActionFrom = $ContentHeaderBorderName)
    Start-FunctionMeasurement -FunctionName 'New-CopyButton'
    $CopyButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$CopyButtonNameSuffix"
        Header  = $CopyButtonHeader
        Icon    = $CopyButtonIcon
        ToolTip = $CopyButtonToolTip
    }
    $CopyButton.Add_Click({ param($s, $e) Invoke-CopyButtonClick $s $e })
    Add-LockableButtonToolTip -Button $CopyButton -ToolTip $CopyButtonToolTip
    $ReturnValue = $CopyButton
    Stop-FunctionMeasurement -FunctionName 'New-CopyButton'
    return $ReturnValue
} # function New-CopyButton

function New-CopyAsMenuItem {
    param([string]$ActionFrom = $ContentHeaderBorderName)
    Start-FunctionMeasurement -FunctionName 'New-CopyAsMenuItem'
    $CopyAsMenu = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$CopyAsMenuNameSuffix"
        Header  = $CopyAsMenuHeader
        Icon    = $CopyAsMenuIcon
        ToolTip = $CopyAsMenuToolTip
    }
    Add-LockableButtonToolTip -Button $CopyAsMenu -ToolTip $CopyAsMenuToolTip

    # Placeholder child to enable WPF submenu expansion arrow
    $DummyItem = New-BaseMenuItem @{ Header = 'Loading...' }
    $CopyAsMenu.Items.Add($DummyItem) | Out-Null

    $PopulatedState = @{ IsPopulated = $false }
    $CopyAsMenu.Add_SubmenuOpened(({
                param($s, $e)
                if ($e.Source -ne $s) { return }
                if ($PopulatedState.IsPopulated) { return }
                $PopulatedState.IsPopulated = $true
                $s.Items.Clear()

                $Formats = @(
                    @{ Format = 'JSON'; NameSuffix = $CopyAsJsonButtonNameSuffix; Header = $CopyAsJsonHeader; Icon = $CopyAsJsonIcon; ToolTip = $CopyAsJsonToolTip },
                    @{ Format = 'XML'; NameSuffix = $CopyAsXmlButtonNameSuffix; Header = $CopyAsXmlHeader; Icon = $CopyAsXmlIcon; ToolTip = $CopyAsXmlToolTip },
                    @{ Format = 'CSV'; NameSuffix = $CopyAsCsvButtonNameSuffix; Header = $CopyAsCsvHeader; Icon = $CopyAsCsvIcon; ToolTip = $CopyAsCsvToolTip }
                )

                foreach ($Fmt in $Formats) {
                    $FmtItem = New-BaseMenuItem @{
                        Name          = "$ActionFrom`_$($Fmt.NameSuffix)"
                        Header        = $Fmt.Header
                        Icon          = $Fmt.Icon
                        ToolTip       = $Fmt.ToolTip
                        FlowDirection = 'LeftToRight'
                    }
                    Add-CopyScopeMenuItems -ParentMenuItem $FmtItem -ActionFrom $ActionFrom -Format $Fmt.Format
                    $s.Items.Add($FmtItem) | Out-Null
                }
            }).GetNewClosure())

    $ReturnValue = $CopyAsMenu
    Stop-FunctionMeasurement -FunctionName 'New-CopyAsMenuItem'
    return $ReturnValue
} # function New-CopyAsMenuItem

function New-PasteButton {
    param([string]$ActionFrom = $ContentHeaderBorderName)
    Start-FunctionMeasurement -FunctionName 'New-PasteButton'
    $PasteButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$PasteButtonNameSuffix"
        Header    = $PasteButtonHeader
        Icon      = $PasteButtonIcon
        ToolTip   = $PasteButtonToolTip
        IsEnabled = $false
    }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($PasteButton, $true)
    $PasteButton.Add_ToolTipOpening({
            param($s, $e)
            $s.ToolTip = Get-PasteButtonToolTip -Button $s
        })

    $FullItem = New-BaseMenuItem @{
        Header        = $CopyFullItemHeader
        Icon          = $CopyFullItemIcon
        ToolTip       = $PasteFullItemToolTip
        FlowDirection = 'LeftToRight'
    }
    $ValuesItem = New-BaseMenuItem @{
        Header        = $CopyValuesOnlyHeader
        Icon          = $CopyValuesOnlyIcon
        ToolTip       = $PasteValuesOnlyToolTip
        FlowDirection = 'LeftToRight'
    }

    $BoundActionFrom = $ActionFrom
    $FullItem.Add_Click(({
                param($s, $e)
                Invoke-PasteButtonClick -s $s -e $e -ActionFrom $BoundActionFrom
            }).GetNewClosure())
    $ValuesItem.Add_Click(({
                param($s, $e)
                Invoke-PasteButtonClick -s $s -e $e -ActionFrom $BoundActionFrom -ValuesOnly
            }).GetNewClosure())

    $PasteButton.Items.Add($FullItem) | Out-Null
    $PasteButton.Items.Add($ValuesItem) | Out-Null

    $ReturnValue = $PasteButton
    Stop-FunctionMeasurement -FunctionName 'New-PasteButton'
    return $ReturnValue
} # function New-PasteButton

function Get-StandardActionButtons {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActionFrom,
        [switch]$IsBatch,
        [switch]$IsConstruct,
        [switch]$IncludeSearch,
        [switch]$IncludeArrayItemActions,
        $TargetType = $null
    )
    Start-FunctionMeasurement -FunctionName "Get-StandardActionButtons"

    $Buttons = [System.Collections.ArrayList]@()
    [void]$Buttons.Add((New-QuickSetMenuItem -ActionFrom $ActionFrom -IsConstruct $IsConstruct))
    if ($IsBatch) {
        [void]$Buttons.Add((New-SortMenuItem -ActionFrom $ActionFrom -TargetType $TargetType))
    }
    if ($IncludeSearch) {
        [void]$Buttons.Add((New-SearchButton -ActionFrom $ActionFrom))
    }

    [void]$Buttons.Add((New-BaseSeparator @{ Tag = 31 }))
    [void]$Buttons.Add((New-CopyButton -ActionFrom $ActionFrom))
    [void]$Buttons.Add((New-CopyAsMenuItem -ActionFrom $ActionFrom))
    [void]$Buttons.Add((New-PasteButton -ActionFrom $ActionFrom))
    [void]$Buttons.Add((New-BaseSeparator @{ Tag = 38 }))

    [void]$Buttons.Add((New-LockButton -ActionFrom $ActionFrom))

    if ($IsBatch) {
        [void]$Buttons.Add((New-RandomValuesButton -Header "$($RandomValuesButtonHeader + 's')" -ToolTip $RandomValuesButtonAllToolTip -ActionFrom $ActionFrom))
        [void]$Buttons.Add((New-ClearButton -Header "$($ClearButtonHeader + 's')" -ToolTip $ClearButtonAllToolTip -ActionFrom $ActionFrom))
        [void]$Buttons.Add((New-BaseSeparator @{ Tag = 65 }))
        [void]$Buttons.Add((New-DisableEnableButton -Header ($DisableEnableButtonHeaderEnabled + ' All') -ActionFrom $ActionFrom))
        [void]$Buttons.Add((New-DeleteButton -Header ($DeleteButtonHeader + ' All') -ToolTip $DeleteButtonAllToolTip -ActionFrom $ActionFrom))
    }
    else {
        [void]$Buttons.Add((New-RandomValuesButton -ActionFrom $ActionFrom))
        [void]$Buttons.Add((New-ClearButton -ActionFrom $ActionFrom))
        if ($IncludeArrayItemActions) {
            [void]$Buttons.Add((New-BaseSeparator @{ Tag = 65 }))
            [void]$Buttons.Add((New-DisableEnableButton -ActionFrom $ActionFrom))
            [void]$Buttons.Add((New-DeleteButton -ActionFrom $ActionFrom))
        }
    }

    Stop-FunctionMeasurement -FunctionName "Get-StandardActionButtons"
    return @($Buttons)
} # function Get-StandardActionButtons

function Set-WrapperActionButtonsLazy {
    param(
        [Parameter(Mandatory = $true)][ref]$Wrapper,
        [Parameter(Mandatory = $true)][string]$ActionFrom,
        [switch]$IsBatch,
        [switch]$IsConstruct,
        [switch]$IncludeSearch,
        [switch]$IncludeArrayItemActions,
        $TargetType = $null
    )
    Start-FunctionMeasurement -FunctionName "Set-WrapperActionButtonsLazy"
    $TargetElement = Resolve-TargetElement $Wrapper.Value
    if (-not $TargetElement) {
        Stop-FunctionMeasurement -FunctionName "Set-WrapperActionButtonsLazy"
        return
    }

    if (-not ($TargetElement.Tag -is [hashtable])) { $TargetElement.Tag = @{} }
    $TargetElement.Tag.ActionButtonsConfiguration = @{
        ActionFrom              = $ActionFrom
        IsBatch                 = [bool]$IsBatch
        IsConstruct             = [bool]$IsConstruct
        IncludeSearch           = [bool]$IncludeSearch
        IncludeArrayItemActions = [bool]$IncludeArrayItemActions
        TargetType              = $TargetType
    }
    $TargetElement.Tag.ActionButtonsPopulated = $false

    $Menu = Get-WrapperMenu -Wrapper $TargetElement
    if (-not $Menu) {
        Stop-FunctionMeasurement -FunctionName "Set-WrapperActionButtonsLazy"
        return
    }

    $ButtonMenu = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
    if (-not $ButtonMenu) {
        Stop-FunctionMeasurement -FunctionName "Set-WrapperActionButtonsLazy"
        return
    }

    if (-not ($ButtonMenu.Tag -is [hashtable])) { $ButtonMenu.Tag = @{} }
    $ButtonMenu.Tag.ActionButtonsConfiguration = @{
        ActionFrom              = $ActionFrom
        IsBatch                 = [bool]$IsBatch
        IsConstruct             = [bool]$IsConstruct
        IncludeSearch           = [bool]$IncludeSearch
        IncludeArrayItemActions = [bool]$IncludeArrayItemActions
        TargetType              = $TargetType
    }
    $ButtonMenu.Tag.ActionButtonsPopulated = $false
    $ButtonMenu.Visibility = 'Visible'

    Stop-FunctionMeasurement -FunctionName "Set-WrapperActionButtonsLazy"
} # function Set-WrapperActionButtonsLazy

function Ensure-WrapperActionButtons {
    param(
        [Parameter(Mandatory = $true)]$Element
    )
    Start-FunctionMeasurement -FunctionName "Ensure-WrapperActionButtons"
    $TargetElement = Resolve-TargetElement $Element
    if (-not $TargetElement) {
        Stop-FunctionMeasurement -FunctionName "Ensure-WrapperActionButtons"
        return
    }

    $Wrapper = if ($TargetElement.Name -eq $ContentHeaderBorderName -or $TargetElement.Name -eq $ContentBorderName) {
        $TargetElement
    }
    else {
        $Parent = Get-ParentWrapperBorder -Element $TargetElement
        if ($Parent) { $Parent } else { $TargetElement }
    }

    $Menu = Get-WrapperMenu -Wrapper $Wrapper
    if (-not $Menu) {
        Stop-FunctionMeasurement -FunctionName "Ensure-WrapperActionButtons"
        return
    }

    $ButtonMenu = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1
    if (-not $ButtonMenu) {
        Stop-FunctionMeasurement -FunctionName "Ensure-WrapperActionButtons"
        return
    }

    if ($ButtonMenu.Tag -is [hashtable] -and $ButtonMenu.Tag.ActionButtonsPopulated) {
        Stop-FunctionMeasurement -FunctionName "Ensure-WrapperActionButtons"
        return
    }

    if ($ButtonMenu.Tag -is [hashtable] -and $ButtonMenu.Tag.ActionButtonsConfiguration) {
        $Configuration = $ButtonMenu.Tag.ActionButtonsConfiguration
        $Buttons = Get-StandardActionButtons `
            -ActionFrom $Configuration.ActionFrom `
            -IsBatch:$Configuration.IsBatch `
            -IsConstruct:$Configuration.IsConstruct `
            -IncludeSearch:$Configuration.IncludeSearch `
            -IncludeArrayItemActions:$Configuration.IncludeArrayItemActions `
            -TargetType $Configuration.TargetType

        Add-ChildrenToItemsButtonMenu ([ref]$Wrapper) $Buttons
        $ButtonMenu.Tag.ActionButtonsPopulated = $true
        if (-not $ButtonMenu.Tag.ButtonsByName) { $ButtonMenu.Tag.ButtonsByName = @{} }
        foreach ($Btn in $Buttons) {
            if ($Btn -and $Btn.Name) {
                $ButtonMenu.Tag.ButtonsByName[$Btn.Name] = $Btn
            }
        }

        if ($Configuration.IsBatch) {
            Update-ArrayButtonsState -Wrapper $Wrapper
        }
    }

    Stop-FunctionMeasurement -FunctionName "Ensure-WrapperActionButtons"
} # function Ensure-WrapperActionButtons

function New-ClearButton {
    param(
        [string]$Header = $ClearButtonHeader,
        [string]$ToolTip = $ClearButtonToolTip,
        [string]$ActionFrom = $ContentHeaderBorderName
    )
    Start-FunctionMeasurement -FunctionName 'New-ClearButton'

    $ClearButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$ClearButtonNameSuffix"
        Header  = $Header
        Icon    = $ClearButtonIcon
        ToolTip = $ToolTip
    }
    $ClearButton.Add_Click({ param($s, $e) Invoke-ClearButtonClick $s $e })
    Add-LockableButtonToolTip -Button $ClearButton -ToolTip $ToolTip
    $ReturnValue = $ClearButton
    Stop-FunctionMeasurement -FunctionName 'New-ClearButton'
    return $ReturnValue
} # function New-ClearButton

function Attach-RandomValuesGearHandler {
    param($TargetItem)
    Start-FunctionMeasurement -FunctionName 'Attach-RandomValuesGearHandler'
    if (-not $TargetItem -or -not $TargetItem.Template) {
        Stop-FunctionMeasurement -FunctionName 'Attach-RandomValuesGearHandler'
        return
    }
    $Gear = $TargetItem.Template.FindName('PART_GearButton', $TargetItem)
    if ($Gear -and -not $Gear.Tag) {
        $Gear.Tag = $true
        $Gear.Add_PreviewMouseLeftButtonDown({
                param($s, $e)
                $e.Handled = $true
                Invoke-RandomValuesSettingsButtonClick $s $e
            })
        $Gear.Add_Click({
                param($s, $e)
                $e.Handled = $true
                Invoke-RandomValuesSettingsButtonClick $s $e
            })
    }
    Stop-FunctionMeasurement -FunctionName 'Attach-RandomValuesGearHandler'
} # function Attach-RandomValuesGearHandler

function New-RandomValuesButton {
    param(
        [string]$Header = $RandomValuesButtonHeader,
        [string]$ToolTip = $RandomValuesButtonToolTip,
        [string]$ActionFrom = $ContentHeaderBorderName
    )
    Start-FunctionMeasurement -FunctionName 'New-RandomValuesButton'

    $RandomValuesMenuItemTemplateXaml = @"
<ControlTemplate TargetType="MenuItem" xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
    <Border Name="templateRoot" BorderThickness="1" BorderBrush="Transparent" Background="Transparent" SnapsToDevicePixels="True">
        <Grid Margin="-1,-1,-1,-1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto" MinWidth="22" SharedSizeGroup="MenuItemIconColumnGroup" />
                <ColumnDefinition Width="13" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="30" />
                <ColumnDefinition Width="Auto" SharedSizeGroup="MenuItemIGTColumnGroup" />
                <ColumnDefinition Width="20" />
            </Grid.ColumnDefinitions>
            <ContentPresenter ContentSource="Icon" Margin="3" HorizontalAlignment="Center" VerticalAlignment="Center" SnapsToDevicePixels="True" />
            <ContentPresenter ContentSource="Header" Grid.Column="2" HorizontalAlignment="Left" VerticalAlignment="Center" SnapsToDevicePixels="True" />
            <Button Name="PART_GearButton" Content="$RandomValuesSettingsButtonIcon" ToolTip="$RandomValuesSettingsButtonToolTip" Grid.Column="4" Grid.ColumnSpan="2" HorizontalAlignment="Right" VerticalAlignment="Center" Width="20" Height="20" Background="Transparent" BorderThickness="0" Margin="0,0,4,0" Cursor="Hand" FontSize="12" FontFamily="$FontFamily" Foreground="{Binding RelativeSource={RelativeSource AncestorType=MenuItem}, Path=Foreground}" />
        </Grid>
    </Border>
    <ControlTemplate.Triggers>
        <Trigger Property="IsHighlighted" Value="True">
            <Setter TargetName="templateRoot" Property="Background" Value="#3D26A0DA" />
            <Setter TargetName="templateRoot" Property="BorderBrush" Value="#FF26A0DA" />
        </Trigger>
        <Trigger Property="IsEnabled" Value="False">
            <Setter TargetName="templateRoot" Property="TextElement.Foreground" Value="#FF707070" />
        </Trigger>
    </ControlTemplate.Triggers>
</ControlTemplate>
"@

    $Template = [System.Windows.Markup.XamlReader]::Parse($RandomValuesMenuItemTemplateXaml)

    $RandomValuesButton = New-BaseMenuItem @{
        Name     = "$ActionFrom`_$RandomValuesButtonNameSuffix"
        Header   = $Header
        Icon     = $RandomValuesButtonIcon
        ToolTip  = $ToolTip
        Template = $Template
    }

    $RandomValuesButton.ApplyTemplate() | Out-Null
    Attach-RandomValuesGearHandler -TargetItem $RandomValuesButton

    $RandomValuesButton.Add_Loaded({
            param($s, $e)
            Attach-RandomValuesGearHandler -TargetItem $s
        })

    $RandomValuesButton.Add_Click({ param($s, $e) Invoke-RandomValuesButtonClick $s $e })
    Add-LockableButtonToolTip -Button $RandomValuesButton -ToolTip $ToolTip
    $ReturnValue = $RandomValuesButton
    Stop-FunctionMeasurement -FunctionName 'New-RandomValuesButton'
    return $ReturnValue
} # function New-RandomValuesButton

function New-DisableEnableButton {
    param(
        [string]$Header = $DisableEnableButtonHeaderEnabled,
        [string]$ActionFrom = $ContentHeaderBorderName
    )
    Start-FunctionMeasurement -FunctionName 'New-DisableEnableButton'

    $DisableEnableButton = New-BaseMenuItem @{
        Name   = "$ActionFrom`_$DisableEnableButtonNameSuffix"
        Header = $Header
        Icon   = $DisableEnableButtonIconEnabled
    }
    $DisableEnableButton.ToolTip = Get-DisableEnableButtonToolTip -Button $DisableEnableButton
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($DisableEnableButton, $true)

    $DisableEnableButton.Add_Click({ param($s, $e) Invoke-DisableEnableButtonClick $s $e })
    # Tooltip follows the current Disable/Enable state and adds the locked note when disabled
    $DisableEnableButton.Add_ToolTipOpening({
            param($s, $e)
            $s.ToolTip = Get-LockableToolTip -Button $s -ToolTip (Get-DisableEnableButtonToolTip -Button $s)
        })

    $ReturnValue = $DisableEnableButton
    Stop-FunctionMeasurement -FunctionName 'New-DisableEnableButton'
    return $ReturnValue
} # function New-DisableEnableButton

function New-DeleteButton {
    param(
        [string]$Header = $DeleteButtonHeader,
        [string]$ToolTip = $DeleteButtonToolTip,
        [string]$ActionFrom = $ContentHeaderBorderName
    )
    Start-FunctionMeasurement -FunctionName 'New-DeleteButton'

    $DeleteButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$DeleteButtonNameSuffix"
        Header  = $Header
        Icon    = $DeleteButtonIcon
        ToolTip = $ToolTip
    }

    $DeleteButton.Add_Click({ param($s, $e) Invoke-DeleteButtonClick $s $e })
    Add-LockableButtonToolTip -Button $DeleteButton -ToolTip $ToolTip

    $ReturnValue = $DeleteButton
    Stop-FunctionMeasurement -FunctionName 'New-DeleteButton'
    return $ReturnValue
} # function New-DeleteButton

function New-SearchButton {
    param(
        [string]$Header = $SearchButtonHeader,
        $Icon = $SearchButtonIcon,
        [string]$ActionFrom = $ContentHeaderBorderName,
        [bool]$IsEnabled = $true
    )
    Start-FunctionMeasurement -FunctionName 'New-SearchButton'

    $SearchButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$SearchButtonNameSuffix"
        Header    = $Header
        Icon      = $Icon
        ToolTip   = $SearchButtonToolTip
        IsEnabled = $IsEnabled
    }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($SearchButton, $true)

    $SearchButton.Add_Click({ param($s, $e) Invoke-SearchButtonClick $s $e })
    $SearchButton.Add_ToolTipOpening({
            param($s, $e)
            $s.ToolTip = Get-SearchButtonToolTip -Button $s
        })

    $ReturnValue = $SearchButton
    Stop-FunctionMeasurement -FunctionName 'New-SearchButton'
    return $ReturnValue
} # function New-SearchButton

function New-LockButton {
    param($ActionFrom)
    Start-FunctionMeasurement -FunctionName 'New-LockButton'

    $LockUnlockButton = New-BaseMenuItem @{
        Name    = $LockUnlockButtonName
        Header  = $LockUnlockButtonHeaderUnlocked
        Icon    = $LockUnlockButtonIconUnlocked
        ToolTip = $LockUnlockButtonToolTipUnlocked
    }

    $LockUnlockButton.Add_Click({ param($s, $e) Invoke-LockUnlockButtonClick $s $e })
    # Tooltip follows the current Lock/Unlock state
    $LockUnlockButton.Add_ToolTipOpening({
            param($s, $e)
            $s.ToolTip = Get-LockUnlockButtonToolTip -Button $s
        })

    $ReturnValue = $LockUnlockButton
    Stop-FunctionMeasurement -FunctionName 'New-LockButton'
    return $ReturnValue
} # function New-LockButton

function Add-LockableButtonToolTip {
    param(
        [Parameter(Mandatory)]$Button,
        [Parameter(Mandatory)][string]$ToolTip
    )
    Start-FunctionMeasurement -FunctionName "Add-LockableButtonToolTip"
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($Button, $true)
    $BaseToolTip = $ToolTip
    $Button.Add_ToolTipOpening(({
                param($s, $e)
                $s.ToolTip = Get-LockableToolTip -Button $s -ToolTip $BaseToolTip
            }).GetNewClosure())
    Stop-FunctionMeasurement -FunctionName "Add-LockableButtonToolTip"
} # function Add-LockableButtonToolTip

function Get-LockableToolTip {
    param(
        [Parameter(Mandatory)]$Button,
        [string]$ToolTip
    )
    Start-FunctionMeasurement -FunctionName "Get-LockableToolTip"
    if ($Button.IsEnabled) { return $ToolTip }
    if ($Button.Name -like "*$ConstructButtonNameSuffix") {
        return "$ToolTip`n$EmptyArrayButtonToolTip"
    }
    $ParentBorder = Get-ParentWrapperBorder -Element $Button
    if ($ParentBorder -and (Get-IsElementLockedSelf $ParentBorder)) {
        return "$ToolTip`n$LockedButtonToolTip"
    }
    if ($ParentBorder -and $ParentBorder.Tag -is [hashtable] -and $ParentBorder.Tag.IsArray) {
        $Slot = $ParentBorder.Tag.ContentSlot
        if (-not $Slot -or $Slot.Children.Count -eq 0) {
            return "$ToolTip`n$EmptyArrayButtonToolTip"
        }
        if ($Button.Name -like "*$SortMenuNameSuffix" -and $Slot.Children.Count -lt 2) {
            return "$ToolTip`n$SortMinItemsButtonToolTip"
        }
    }
    Stop-FunctionMeasurement -FunctionName "Get-LockableToolTip"
    return "$ToolTip`n$LockedButtonToolTip"
} # function Get-LockableToolTip

function Get-DisableEnableButtonToolTip {
    param([Parameter(Mandatory)]$Button)
    Start-FunctionMeasurement -FunctionName "Get-DisableEnableButtonToolTip"
    $IsAll = $Button.Header -like '* All' -or ($Button.Tag -is [hashtable] -and $Button.Tag.IsAll)
    $IsDisabled = $Button.Icon -eq $DisableEnableButtonIconDisabled
    if ($IsAll) {
        $BaseToolTip = if ($IsDisabled) { $DisableEnableButtonAllToolTipDisabled } else { $DisableEnableButtonAllToolTipEnabled }
        $ParentWrapper = Get-ParentWrapperBorder -Element $Button -HeaderOnly
        if ($ParentWrapper) {
            $ContentSlot = Get-WrapperContentSlot -Wrapper $ParentWrapper
            if ($ContentSlot -and $ContentSlot.Children.Count -gt 0) {
                $TotalCount = $ContentSlot.Children.Count
                $LockedCount = 0
                $DisabledCount = 0
                foreach ($Child in @($ContentSlot.Children)) {
                    if (Get-IsLocked $Child) { $LockedCount++ }
                    if ($Child.Tag -is [hashtable] -and $Child.Tag.ContainsKey('IsDisabled') -and $Child.Tag.IsDisabled) { $DisabledCount++ }
                }
                $EnabledCount = $TotalCount - $DisabledCount
                $CountsNote = "Items: $TotalCount total ($EnabledCount enabled, $DisabledCount disabled, $LockedCount locked)"
                Stop-FunctionMeasurement -FunctionName "Get-DisableEnableButtonToolTip"
                return "$BaseToolTip`n$CountsNote"
            }
        }
        Stop-FunctionMeasurement -FunctionName "Get-DisableEnableButtonToolTip"
        return $BaseToolTip
    }
    if ($IsDisabled) { return $DisableEnableButtonToolTipDisabled }
    Stop-FunctionMeasurement -FunctionName "Get-DisableEnableButtonToolTip"
    return $DisableEnableButtonToolTipEnabled
} # function Get-DisableEnableButtonToolTip

function Get-LockUnlockButtonToolTip {
    param([Parameter(Mandatory)]$Button)
    Start-FunctionMeasurement -FunctionName "Get-LockUnlockButtonToolTip"
    $ParentBorder = Get-ParentWrapperBorder -Element $Button
    $IsArrayWrapper = ($ParentBorder -and $ParentBorder.Tag -is [hashtable] -and $ParentBorder.Tag.IsArray)
    $IsArrayItemWrapper = ($ParentBorder -and (Get-IsArrayItem -Wrapper $ParentBorder))
    if ($Button.Icon -eq $LockUnlockButtonIconLocked) {
        if ($IsArrayWrapper) { return $LockUnlockButtonAllToolTipLocked }
        if ($IsArrayItemWrapper) { return $LockUnlockButtonItemToolTipLocked }
        return $LockUnlockButtonToolTipLocked
    }
    if ($IsArrayWrapper) { return $LockUnlockButtonAllToolTipUnlocked }
    if ($IsArrayItemWrapper) { return $LockUnlockButtonItemToolTipUnlocked }
    Stop-FunctionMeasurement -FunctionName "Get-LockUnlockButtonToolTip"
    return $LockUnlockButtonToolTipUnlocked
} # function Get-LockUnlockButtonToolTip

function Get-SearchButtonToolTip {
    param([Parameter(Mandatory)]$Button)
    Start-FunctionMeasurement -FunctionName "Get-SearchButtonToolTip"
    if (-not $Button.IsEnabled) { return "$SearchButtonToolTip`n$EmptyArrayButtonToolTip" }
    if ($null -eq $Button.Icon) { return $SearchButtonToolTipActive }
    Stop-FunctionMeasurement -FunctionName "Get-SearchButtonToolTip"
    return $SearchButtonToolTip
} # function Get-SearchButtonToolTip

function Set-MenuButtonsEnabledState {
    param(
        [Parameter(Mandatory = $true)]$Menu,
        [Parameter(Mandatory = $true)][string[]]$Suffixes,
        [Parameter(Mandatory = $true)][bool]$IsEnabled
    )
    Start-FunctionMeasurement -FunctionName 'Set-MenuButtonsEnabledState'
    $TargetMenu = Resolve-TargetElement $Menu
    if (-not $TargetMenu) { return }

    if ($TargetMenu.Tag -is [hashtable] -and $TargetMenu.Tag.ButtonsByName) {
        $BtnMap = $TargetMenu.Tag.ButtonsByName
        foreach ($Suffix in $Suffixes) {
            foreach ($Key in $BtnMap.Keys) {
                if ($Key -like "*_$Suffix" -or $Key -eq $Suffix) {
                    $Btn = $BtnMap[$Key]
                    if ($Btn) { $Btn.IsEnabled = $IsEnabled }
                }
            }
        }
    }
    else {
        :Suffixes foreach ($Suffix in $Suffixes) {
            $Buttons = Find-ObjectWhere -Object ([ref]$TargetMenu) -FindWhere { $_.Name -like "*_$Suffix" -or $_.Name -eq $Suffix }
            :Buttons foreach ($Button in @($Buttons)) {
                if ($Button) { $Button.IsEnabled = $IsEnabled }
            }
        }
    }

    Stop-FunctionMeasurement -FunctionName 'Set-MenuButtonsEnabledState'
} # function Set-MenuButtonsEnabledState

function Set-LockableButtonsState {
    param(
        [Parameter(Mandatory)]$LockButton,
        [Parameter(Mandatory)][bool]$IsEnabled
    )
    Start-FunctionMeasurement -FunctionName 'Set-LockableButtonsState'
    # Only search this item's own menu, so nested child items keep their own state
    $Menu = Find-ObjectWhere -Object ([ref]$LockButton) -FindWhere { $_.Name -eq $MenuName } -DigProperties 'Parent' -FindMax 1
    if (-not $Menu) { return }

    $ParentBorder = Get-ParentWrapperBorder -Element $Menu
    if ($ParentBorder -and $ParentBorder.Tag -is [hashtable] -and $ParentBorder.Tag.IsArray) {
        Update-ArrayButtonsState -Wrapper $ParentBorder
        return
    }

    $LockableButtonSuffixes = @(
        $AddArrayItemButtonName
        $SortMenuNameSuffix
        $RandomValuesButtonNameSuffix
        $ClearButtonNameSuffix
        $DisableEnableButtonNameSuffix
        $DeleteButtonNameSuffix
    )

    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes $LockableButtonSuffixes -IsEnabled $IsEnabled
    if ($ParentBorder) {
        Update-WrapperPasteButtonState -Wrapper $ParentBorder
    }

    Stop-FunctionMeasurement -FunctionName 'Set-LockableButtonsState'
} # function Set-LockableButtonsState

function Test-AncestorBorderButtonState {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][scriptblock]$ButtonSelector,
        [Parameter(Mandatory)][scriptblock]$ValueCondition
    )
    Start-FunctionMeasurement -FunctionName "Test-AncestorBorderButtonState"
    $Target = Resolve-TargetElement $Object
    if (-not $Target) { return $false }

    $ContentBorders = @()
    if (@($ContentHeaderBorderName, $ContentBorderName) -contains $Target.Name) {
        $ContentBorders += $Target
    }
    $ParentBorders = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent'
    if ($ParentBorders) {
        $ContentBorders += $ParentBorders
    }

    :Borders foreach ($ContentBorder in $ContentBorders) {
        if ($ContentBorder.Tag -is [hashtable]) {
            if ($ButtonSelector.ToString() -like "*Lock*" -and $ContentBorder.Tag.ContainsKey('IsLocked')) {
                if ($ContentBorder.Tag.IsLocked) {
                    return $true
                }
                continue Borders
            }
            if ($ButtonSelector.ToString() -like "*Disable*" -and $ContentBorder.Tag.ContainsKey('IsDisabled')) {
                if ($ContentBorder.Tag.IsDisabled) {
                    return $true
                }
                continue Borders
            }
        }
        $Button = & $ButtonSelector $ContentBorder
        if ($Button) {
            $Value = Get-ContentValue $Button
            if (& $ValueCondition $Value) {
                return $true
            }
        }
    }

    Stop-FunctionMeasurement -FunctionName "Test-AncestorBorderButtonState"
    return $false
} # function Test-AncestorBorderButtonState

function Get-IsLocked {
    param($Object)
    Start-FunctionMeasurement -FunctionName "Get-IsLocked"
    return Test-AncestorBorderButtonState -Object $Object `
        -ButtonSelector { param($Border) Find-ObjectWhere -Object ([ref]$Border) -FindWhere { $_.Name -eq $LockUnlockButtonName } -FindMax 1 } `
        -ValueCondition { param($Value) $Value -eq $LockUnlockButtonHeaderLocked }
    Stop-FunctionMeasurement -FunctionName "Get-IsLocked"
} # function Get-IsLocked

function Get-IsDisabled {
    param($Object)
    Start-FunctionMeasurement -FunctionName "Get-IsDisabled"
    return Test-AncestorBorderButtonState -Object $Object `
        -ButtonSelector { param($Border) Find-ObjectWhere -Object ([ref]$Border) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -FindMax 1 } `
        -ValueCondition { param($Value) $Value -like "$DisableEnableButtonHeaderDisabled*" }
    Stop-FunctionMeasurement -FunctionName "Get-IsDisabled"
} # function Get-IsDisabled

function Get-WrapperOwnActionButton {
    param(
        [Parameter(Position = 0)]
        [Alias('Wrapper')]
        $Element,
        [switch]$IsDisableButton,
        [string]$Name,
        [string]$Suffix
    )
    Start-FunctionMeasurement -FunctionName "Get-WrapperOwnActionButton"
    $TargetElem = Resolve-TargetElement $Element
    if (-not $TargetElem) { return $null }
    Ensure-WrapperActionButtons -Element $TargetElem
    $SearchRoot = if ($script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable] -and $script:UniversalSharedMenu.Tag.ActiveWrapper -eq $TargetElem) { $script:UniversalSharedMenu } else { Get-WrapperMenu -Wrapper $TargetElem }
    if (-not $SearchRoot) { $SearchRoot = $TargetElem }

    $Found = $null
    if ($SearchRoot.Tag -is [hashtable] -and $SearchRoot.Tag.ButtonsByName) {
        $BtnMap = $SearchRoot.Tag.ButtonsByName
        if (-not [string]::IsNullOrWhiteSpace($Name) -and $BtnMap.ContainsKey($Name)) {
            $Found = $BtnMap[$Name]
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Suffix)) {
            foreach ($Key in $BtnMap.Keys) {
                if ($Key -like "*$Suffix") {
                    $Found = $BtnMap[$Key]
                    break
                }
            }
        }
        elseif ($IsDisableButton) {
            foreach ($Key in $BtnMap.Keys) {
                if ($Key -like "*$DisableEnableButtonNameSuffix" -and $Key -notlike "*All*") {
                    $Found = $BtnMap[$Key]
                    break
                }
            }
        }
        else {
            if ($BtnMap.ContainsKey($LockUnlockButtonName)) {
                $Found = $BtnMap[$LockUnlockButtonName]
            }
        }
    }

    if (-not $Found) {
        if (-not [string]::IsNullOrWhiteSpace($Name)) {
            $Found = Find-ObjectWhere -Object ([ref]$SearchRoot) -FindWhere { $_.Name -eq $Name } -FindMax 1
        }
        elseif (-not [string]::IsNullOrWhiteSpace($Suffix)) {
            $Found = Find-ObjectWhere -Object ([ref]$SearchRoot) -FindWhere { $_.Name -like "*$Suffix" } -FindMax 1
        }
        elseif ($IsDisableButton) {
            $Found = Find-ObjectWhere -Object ([ref]$SearchRoot) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_.Name -notlike "*All*" } -FindMax 1
        }
        else {
            $Found = Find-ObjectWhere -Object ([ref]$SearchRoot) -FindWhere { $_.Name -eq $LockUnlockButtonName } -FindMax 1
        }
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperOwnActionButton"
    return (Resolve-TargetElement $Found)
} # function Get-WrapperOwnActionButton

function Get-IsElementLockedSelf {
    param($Element)
    Start-FunctionMeasurement -FunctionName "Get-IsElementLockedSelf"
    $Target = Resolve-TargetElement $Element
    if ($Target -and $Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('IsLocked') -and $Target.Tag.IsLocked) {
        return $true
    }
    $Indicator = Get-WrapperLockIndicatorButton -Wrapper $Element
    if ($Indicator) { return $true }
    $LockButton = Get-WrapperOwnActionButton -Element $Element
    if ($LockButton) {
        return ($LockButton.Icon -eq $LockUnlockButtonIconLocked)
    }
    Stop-FunctionMeasurement -FunctionName "Get-IsElementLockedSelf"
    return $false
} # function Get-IsElementLockedSelf

function Get-IsElementDisabledSelf {
    param($Element)
    Start-FunctionMeasurement -FunctionName "Get-IsElementDisabledSelf"
    $Target = Resolve-TargetElement $Element
    if ($Target -and $Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('IsDisabled') -and $Target.Tag.IsDisabled) {
        return $true
    }
    $Indicator = Get-WrapperDisableIndicatorButton -Wrapper $Element
    if ($Indicator) { return $true }
    $DisableButton = Get-WrapperOwnActionButton -Element $Element -IsDisableButton
    if ($DisableButton) {
        return ($DisableButton.Icon -eq $DisableEnableButtonIconDisabled)
    }
    Stop-FunctionMeasurement -FunctionName "Get-IsElementDisabledSelf"
    return $false
} # function Get-IsElementDisabledSelf

function Set-TargetLockedState {
    param(
        $Target,
        [bool]$IsLocked
    )
    Start-FunctionMeasurement -FunctionName 'Set-TargetLockedState'
    $TargetElem = Resolve-TargetElement $Target
    if (-not $TargetElem) {
        Stop-FunctionMeasurement -FunctionName 'Set-TargetLockedState'
        return
    }

    if (-not ($TargetElem.Tag -is [hashtable])) { $TargetElem.Tag = @{} }
    $TargetElem.Tag.IsLocked = $IsLocked

    Set-WrapperLockVisualState -Wrapper $TargetElem -IsLocked $IsLocked

    $OwnMenu = Get-WrapperMenu -Wrapper $TargetElem
    if ($OwnMenu) {
        Set-MenuButtonsEnabledState -Menu $OwnMenu -Suffixes @($RandomValuesButtonNameSuffix, $ClearButtonNameSuffix, $DisableEnableButtonNameSuffix, $DeleteButtonNameSuffix) -IsEnabled (-not $IsLocked)
    }

    if ($script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable] -and $script:UniversalSharedMenu.Tag.ActiveWrapper -eq $TargetElem) {
        Update-UniversalMenuActionsVisibility -TargetWrapper $TargetElem
    }

    Stop-FunctionMeasurement -FunctionName 'Set-TargetLockedState'
} # function Set-TargetLockedState

function Get-WrapperMinMaxState {
    param($Element)
    Start-FunctionMeasurement -FunctionName "Get-WrapperMinMaxState"
    $TargetElem = Resolve-TargetElement $Element
    if (-not $TargetElem -or $TargetElem.Name -ne $ContentHeaderBorderName) { return $null }
    $MinMaxButton = Get-WrapperOwnActionButton -Element $TargetElem -Name $MinMaxButtonName
    if (-not $MinMaxButton) { return $null }
    $ContentSlot = Get-WrapperContentSlot -Wrapper $TargetElem
    if ($ContentSlot) {
        return ($ContentSlot.Visibility -eq 'Collapsed')
    }
    Stop-FunctionMeasurement -FunctionName "Get-WrapperMinMaxState"
    return ($MinMaxButton.Header -eq $MinMaxButtonMaxedIcon)
} # function Get-WrapperMinMaxState

function Set-TargetMinMaxState {
    param(
        $Target,
        [bool]$IsMinimized
    )
    Start-FunctionMeasurement -FunctionName 'Set-TargetMinMaxState'
    $TargetElem = Resolve-TargetElement $Target
    if (-not $TargetElem -or $TargetElem.Name -ne $ContentHeaderBorderName) { return }
    $MinMaxButton = Get-WrapperOwnActionButton -Element $TargetElem -Name $MinMaxButtonName
    $ContentSlot = Get-WrapperContentSlot -Wrapper $TargetElem
    if (-not $MinMaxButton -or -not $ContentSlot) { return }

    Set-ContentSlotCollapseState -ContentSlotElement $ContentSlot -MinMaxButton $MinMaxButton -ContentHeaderBorder $TargetElem -Collapse $IsMinimized

    Stop-FunctionMeasurement -FunctionName 'Set-TargetMinMaxState'
} # function Set-TargetMinMaxState

function Set-TargetDisabledState {
    param(
        $Target,
        [bool]$IsDisabled,
        [switch]$SkipParentSync
    )
    Start-FunctionMeasurement -FunctionName 'Set-TargetDisabledState'
    $TargetElem = Resolve-TargetElement $Target
    if (-not $TargetElem) {
        Stop-FunctionMeasurement -FunctionName 'Set-TargetDisabledState'
        return
    }

    if (-not ($TargetElem.Tag -is [hashtable])) { $TargetElem.Tag = @{} }
    $TargetElem.Tag.IsDisabled = $IsDisabled

    Set-WrapperDisabledVisualState -Wrapper $TargetElem -IsDisabled $IsDisabled

    $ContentSlot = Get-WrapperContentSlot -Wrapper $TargetElem
    if ($ContentSlot) {
        $ContentSlot.IsEnabled = (-not $IsDisabled)
    }
    $OwnContent = if ($TargetElem.Tag -is [hashtable] -and $TargetElem.Tag.ContainsKey('Content') -and $TargetElem.Tag.Content) {
        $TargetElem.Tag.Content
    }
    else {
        Find-ObjectWhere -Object ([ref]$TargetElem) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 2 -FindMax 1
    }
    if ($OwnContent) {
        $OwnContent.IsEnabled = (-not $IsDisabled)
    }
    $DTP = if ($TargetElem.Tag -is [hashtable] -and $TargetElem.Tag.ContainsKey('CustomDateTimePicker') -and $TargetElem.Tag.CustomDateTimePicker) {
        $TargetElem.Tag.CustomDateTimePicker
    }
    else {
        Find-ObjectWhere -Object ([ref]$TargetElem) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 2 -FindMax 1
    }
    if ($DTP) {
        $DTP.IsEnabled = (-not $IsDisabled)
    }

    if (-not $SkipParentSync) {
        Confirm-ArrayEnableButton -Item ([ref]$TargetElem)
        $ParentBorder = Get-ParentWrapperBorder -Element $TargetElem -HeaderOnly
        if ($ParentBorder) {
            $ParentSlot = Get-WrapperContentSlot -Wrapper $ParentBorder
            if ($ParentSlot) {
                Sync-ArraySlotState -ContentSlot $ParentSlot -ContainerWrapper $ParentBorder
            }
        }
    }

    if ($script:UniversalSharedMenu -and $script:UniversalSharedMenu.Tag -is [hashtable] -and $script:UniversalSharedMenu.Tag.ActiveWrapper -eq $TargetElem) {
        Update-UniversalMenuActionsVisibility -TargetWrapper $TargetElem
    }

    Stop-FunctionMeasurement -FunctionName 'Set-TargetDisabledState'
} # function Set-TargetDisabledState

#endregion #3 Button Elements

#endregion #2 Content Controls

#endregion #1 Content Controls

#endregion #0 UI Controls


#region #0 Functions

function Get-TypeConstructors {
    param($Type)
    Start-FunctionMeasurement -FunctionName "Get-TypeConstructors"
    if (-not $Type) { return $null }
    $ResolvedType = if ($Type -is [type]) { $Type } else { try { [type]$Type } catch { return $null } }
    if (-not $ResolvedType) { return $null }
    $TypeName = $ResolvedType.FullName
    if ($script:TypeConstructorsCache.ContainsKey($TypeName)) {
        return $script:TypeConstructorsCache[$TypeName]
    }
    $i = 0
    try {
        $Constructors = $ResolvedType.GetConstructors()
        $Results = [System.Collections.ArrayList]@()
    }
    catch {
        Write-Host "{Get-TypeConstructors} Error: $_"
        return $null
    }
    :Constructors foreach ($Constructor in $Constructors) {
        $i ++
        $Parameters = $Constructor.GetParameters()
        :Parameters foreach ($Parameter in $Parameters) {
            [void]$Results.Add([PSCustomObject]@{
                    Constructor  = $i
                    Name         = $Parameter.Name
                    Type         = $Parameter.ParameterType.FullName
                    DefaultValue = $Parameter.DefaultValue
                })
            if ($Parameter.HasDefaultValue) {
                Write-Host "HasDefaultValue: $($Parameter.DefaultValue)" -ForegroundColor Yellow
            }
        } # Parameters
    } # Constructors
    $script:TypeConstructorsCache[$TypeName] = @($Results)
    Stop-FunctionMeasurement -FunctionName "Get-TypeConstructors"
    return @($Results)
} # function Get-TypeConstructors

#endregion #0 Functions


#region #9 WindowBase

$BaseWindow = New-BaseWindow -Parameters @{
    Margin     = 3
    Height     = 500
    MinHeight  = 200
    Width      = 500
    MinWidth   = 500
    Title      = $Title
    Name       = $WindowName
    FontFamily = $FontFamily
    Background = '#4C435E'
    Content    = $(
        New-BaseScrollViewer @{
            Name                          = $WindowScrollViewerName
            VerticalScrollBarVisibility   = 'Auto'
            HorizontalScrollBarVisibility = 'Disabled'
            Content                       = $(
                New-BaseStackPanel @{
                    Orientation = 'Vertical'
                    Name        = $WindowScrollViewerStackPanelName
                }
            )
        }
    )
}

Add-BaseStackPanelChild -StackPanel ([ref]$BaseWindow.Content.Content) -Child ([ref](
        New-TypeContent -Type $TypeToShow -Title $Title
    )
)

$BaseWindow.Add_KeyDown({
        param($s, $e)
        if ($e.Key -eq 'F' -and [System.Windows.Input.Keyboard]::Modifiers -match 'Control') {
            $Focused = [System.Windows.Input.FocusManager]::GetFocusedElement($BaseWindow)
            $TargetButton = $null
            if ($Focused) {
                $ParentBorder = Find-ObjectWhere -Object ([ref]$Focused) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
                if ($ParentBorder) {
                    $CandidateButton = Find-ObjectWhere -Object ([ref]$ParentBorder) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
                    if ($CandidateButton -is [array]) { $CandidateButton = $CandidateButton[0] }
                    if ($CandidateButton -and $CandidateButton.IsEnabled) {
                        $TargetButton = $CandidateButton
                    }
                }
            }
            if (-not $TargetButton) {
                $SearchButtons = Find-ObjectWhere -Object ([ref]$BaseWindow) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" -and $_.IsEnabled }
                if ($SearchButtons -and @($SearchButtons).Count -gt 0) {
                    $TargetButton = @($SearchButtons)[0]
                }
            }
            if ($TargetButton -and $TargetButton.IsEnabled) {
                $TargetButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
                $e.Handled = $true
            }
        }
        if ($e.Key -eq 'P' -and [System.Windows.Input.Keyboard]::Modifiers -match 'Control' -and [System.Windows.Input.Keyboard]::Modifiers -match 'Shift') {
            Write-Host "`n============================================================" -ForegroundColor Cyan
            Write-Host "Function Measurement Summary" -ForegroundColor Cyan
            Write-Host "============================================================" -ForegroundColor Cyan
            $SummaryData = Get-FunctionMeasurementSummary
            $SummaryData | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Yellow
            Write-Host "============================================================`n" -ForegroundColor Cyan
            if ($SummaryData) {
                $SummaryData | Out-GridView -Title 'Function Measurement Summary'
            }
            $e.Handled = $true
        }
    })

$BaseWindow.Add_Closing({
        param($s, $e)

        # 1. Check for any active QuickSets in the window
        $ActiveWrappers = Get-ActiveQuickSetWrappers -Window $BaseWindow
        if ($ActiveWrappers -and $ActiveWrappers.Count -gt 0) {
            $ModifiedWrappers = $ActiveWrappers | Where-Object { Test-IsWrapperQuickSetModified -Wrapper $_ }
            if ($ModifiedWrappers) {
                foreach ($Wrapper in @($ModifiedWrappers)) {
                    $ActiveName = $Wrapper.Tag['ActiveQuickSet']
                    $PromptResult = Show-QuickSetSavePromptDialog `
                        -Title 'QuickSet - Save Changes' `
                        -Message "Do you want to save changes to QuickSet '$ActiveName' before closing?"

                    if ($PromptResult -eq 'Save') {
                        $SaveSuccess = Save-QuickSetFile -Wrapper $Wrapper -QuickSetName $ActiveName
                        if (-not $SaveSuccess) {
                            $e.Cancel = $true
                            return
                        }
                    }
                    elseif ($PromptResult -eq 'Cancel') {
                        $e.Cancel = $true
                        return
                    }
                }
            }
            # Active QuickSets exist and are either unmodified or saved/discarded: allow closure
            return
        }

        # 2. Check if no active QuickSet, but root wrapper has entered values
        $RootWrapper = if ($BaseWindow.Content -and $BaseWindow.Content.Content -and $BaseWindow.Content.Content.Children.Count -gt 0) {
            Resolve-TargetElement $BaseWindow.Content.Content.Children[0]
        }
        else { $null }

        if ($RootWrapper -and (Test-WrapperHasQuickSetValue -Wrapper $RootWrapper)) {
            $PromptResult = Show-QuickSetSavePromptDialog `
                -Title 'QuickSet - Save Values' `
                -Message 'You have unsaved values. Do you want to save them as a QuickSet before closing?'

            if ($PromptResult -eq 'Save') {
                $Type = Get-WrapperTargetType -Wrapper $RootWrapper
                $TypeDir = Get-QuickSetTypeDirectory -Type $Type
                $TypeNameDisplay = if ($Type -is [type]) { $Type.Name } else { $Type.ToString().Split('.')[-1] }
                $Target = Request-ValidatedQuickSetTarget `
                    -Title 'Save QuickSet As' `
                    -Prompt "Enter QuickSet name for $($TypeNameDisplay):" `
                    -DefaultValue '' `
                    -TypeDir $TypeDir

                if (-not $Target) {
                    $e.Cancel = $true
                    return
                }

                $SaveSuccess = Save-QuickSetFile -Wrapper $RootWrapper -QuickSetName $Target.Name
                if (-not $SaveSuccess) {
                    $e.Cancel = $true
                    return
                }
            }
            elseif ($PromptResult -eq 'Cancel') {
                $e.Cancel = $true
                return
            }
        }
    })

$BaseWindow.ShowDialog() | Out-Null

#endregion #9 WindowBase