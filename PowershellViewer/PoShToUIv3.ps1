<# PoshToUI
    Project:
        - Dynamic PowerShell Object Viewer
        - UI is created using PowerShell
        - No hardcoded UI
        - No Abbrevations

    To Do:
        Content Actions
            a. Copy - Each copy should be put into their own clipboard for their particular Type via hashtable key is type.
            b. CopyAs: JSON, XML, CSV - Only the most recent CopyAs should put into Window's Clipboard
            c. Pasted - only enabled when something has been Copied using CopyAs.

        Array Actions
            1 Random Values 
                9. FUTURE FEATURE: Customize how they generate.
            AsBlock (Delimiter*) - * Default is Comma; NewLine is always an additional delimiter (NewLine explanation in ToolTip)
                AsBoxes - switches with AsBlock, default
            Password
                How to save securely?

        DropDown
            Sort
            Search
            Filter

        Construct Button
            Turns Green when it's created
                Clears error, where ever that goes
            Turns Red when it errors
                Tooltip should show error, or somewhere
            Turns Yellow when something changes inside the form to indiciate the Object doesn't match the fields.
            Fields with values will be highlighted.
            Fields get marked as required (*) when the object requires additional fields with filled in fields.

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

$MinMaxButtonName = 'MinMaxButton'
$AddArrayItemButtonName = 'AddArrayItemButton'

$RandomValuesButtonNameSuffix = 'RandomValuesButton'
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
$QuickSetOverwriteButtonNameSuffix = 'QuickSet_Overwrite'
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
$QuickSetSaveButtonHeader = 'Save As'
$QuickSetSaveButtonIcon = '💾'
$QuickSetSaveButtonToolTip = "Save the current values as a new QuickSet"
$QuickSetRenameButtonHeader = 'Rename'
$QuickSetRenameButtonIcon = '✏️'
$QuickSetRenameButtonToolTip = "Rename the active QuickSet`nLoad a QuickSet first"
$QuickSetOverwriteButtonHeader = 'Overwrite'
$QuickSetOverwriteButtonIcon = '⚠️'
$QuickSetOverwriteButtonToolTip = "Replace the active QuickSet with the current values`nLoad a QuickSet first"
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

#endregion #0 Variables


#region #0 Add Types

Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

#endregion #0 Add Types


#region #0 PowerShell Helper Functions

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
        return $Return
    }
} # function Get-UniqueByProperty

function Resolve-TargetElement {
    param($Element)
    $Target = if ($Element -is [System.Management.Automation.PSReference]) { $Element.Value } else { $Element }
    if ($Target -is [array]) { $Target = $Target[0] }
    return $Target
} # function Resolve-TargetElement

function Get-ObjectPropertyEntryCaseInsensitive {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )
    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($Key in $InputObject.Keys) {
            if ($Key.ToString() -eq $PropertyName) {
                return @{ Exists = $true; Value = $InputObject[$Key] }
            }
        }
        return $null
    }

    if ($InputObject -is [System.Management.Automation.PSObject] -or $InputObject -is [System.Management.Automation.PSCustomObject]) {
        $Property = $InputObject.PSObject.Properties[$PropertyName]
        if ($null -ne $Property) {
            return @{ Exists = $true; Value = $Property.Value }
        }
    }

    return $null
} # function Get-ObjectPropertyEntryCaseInsensitive

function Test-ObjectPropertyCaseInsensitive {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )
    return ($null -ne (Get-ObjectPropertyEntryCaseInsensitive -InputObject $InputObject -PropertyName $PropertyName))
} # function Test-ObjectPropertyCaseInsensitive

function Get-ObjectPropertyCaseInsensitive {
    param(
        $InputObject,
        [Parameter(Mandatory = $true)][string]$PropertyName
    )
    $Entry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $InputObject -PropertyName $PropertyName
    if ($null -ne $Entry) { return $Entry.Value }
    return $null
} # function Get-ObjectPropertyCaseInsensitive

function Test-IsQuickSetWrapper {
    param($Element)
    # A wrapper is any element whose Tag was stamped with 'IsArray' by New-TypeContent
    return ($null -ne $Element -and $Element.Tag -is [hashtable] -and $Element.Tag.ContainsKey('IsArray'))
} # function Test-IsQuickSetWrapper

function Resolve-QuickSetWrapper {
    param($Element)
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
        #Write-Host "[$(Get-Date)] {Find-ObjectWhere} [$($Object.Value.Name)] D:$Depth\$DepthMax`:$RecurseCount - $($Found.Name -join ', ') F:$AlreadyFound/$FindMax" -ForegroundColor Magenta
        return $Found
    }
} # function Find-ObjectWhere

function Find-Title {
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        $Object
    )
    process {
        if ($Object.Name -eq $ContentHeaderBorderName) { $ContentHeaderBorder = $Object }
        else {
            $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$Object) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
        }
        $ContentHeaderTitleBorderDock = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
        $ContentHeaderTitleValue = Find-ObjectWhere -Object ([ref]$ContentHeaderTitleBorderDock) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName } -FindMax 1
        $ContentHeaderDescriptionValue = Find-ObjectWhere -Object ([ref]$ContentHeaderTitleBorderDock) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName } -FindMax 1
        "$($ContentHeaderTitleValue.Text) - $($ContentHeaderDescriptionValue.Text)"
    }
} # function Find-Title

function Get-ContentWrapperFromButton {
    param(
        [Parameter(Mandatory)]$Button,
        [Parameter(Mandatory)][string]$Suffix
    )
    $TargetButton = Resolve-TargetElement $Button
    if (-not $TargetButton -or -not $TargetButton.Name) { return $null }
    $ExpectedWrapperName = $TargetButton.Name.Replace("_$Suffix", '')
    $ContentWrapper = Find-ObjectWhere -Object ([ref]$TargetButton) -FindWhere { $_.Name -eq $ExpectedWrapperName } -DigProperties 'Parent' -FindMax 1
    return (Resolve-TargetElement $ContentWrapper)
} # function Get-ContentWrapperFromButton

function Get-ParentWrapperBorder {
    param(
        [Parameter(Mandatory)]$Element,
        [switch]$HeaderOnly
    )
    $Target = Resolve-TargetElement $Element
    if (-not $Target) { return $null }
    $TargetNames = if ($HeaderOnly) { @($ContentHeaderBorderName) } else { @($ContentHeaderBorderName, $ContentBorderName) }
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $TargetNames -contains $_.Name } -DigProperties 'Parent' -FindMax 1
    return (Resolve-TargetElement $Found)
} # function Get-ParentWrapperBorder

function Get-WrapperMenu {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }
    if ($Target.Name -eq $MenuName) { return $Target }
    if ($Target.Name -eq $ButtonMenuName) { return $Target.Parent }
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $MenuName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
    return (Resolve-TargetElement $Found)
} # function Get-WrapperMenu

function Get-WrapperContentSlot {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }
    if ($Target.Name -eq $ContentSlotElementName) { return $Target }
    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContentSlot) {
        return (Resolve-TargetElement $Target.Tag.ContentSlot)
    }
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
    return (Resolve-TargetElement $Found)
} # function Get-WrapperContentSlot

function Set-RichTextBoxText {
    param(
        [Parameter(Mandatory)]$RichTextBox,
        [string]$Text = $null
    )
    $Paragraph = New-Object System.Windows.Documents.Paragraph
    $Paragraph.Margin = '0'
    if (-not [string]::IsNullOrEmpty($Text)) {
        $Paragraph.Inlines.Add($Text) | Out-Null
    }
    $RichTextBox.Document.Blocks.Clear()
    $RichTextBox.Document.Blocks.Add($Paragraph)
} # function Set-RichTextBoxText

function Get-CustomDateTimePickers {
    param(
        [Parameter(Mandatory)]$Wrapper
    )
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
    return @($Pickers)
} # function Get-CustomDateTimePickers

#endregion #1 UI Helper Functions

#region #1 Base UI Controls

#region #2 Base UI Control Actions

function Add-BaseStackPanelChild {
    param( [ref]$StackPanel, [ref]$Child )
    try {
        $StackPanel.Value.AddChild($Child.Value)
    }
    catch {
        Write-Host "{Add-BaseStackPanelChild} $_" -ForegroundColor Red
    }
} # function Add-BaseStackPanelChild

function Add-BaseDockPanelChild {
    param( [ref]$DockPanel, [ref]$Child, [System.Windows.Controls.Dock]$DockTo )
    try {
        $DockPanel.Value.AddChild($Child.Value)
        if ($DockTo) { [System.Windows.Controls.DockPanel]::SetDock($Child.Value, $DockTo) }
    }
    catch {
        Write-Host "{Add-BaseDockPanelChild} $_" -ForegroundColor Red
    }
} # function Add-BaseDockPanelChild

function Add-BaseMenuChild {
    param( [ref]$Menu, [ref]$Child, [int]$Index = 0 )
    try {
        $Menu.Value.Items.Insert($Index, $Child.Value)
    }
    catch {
        Write-Host "{Add-BaseMenuChild} $_" -ForegroundColor Red
    }
} # function Add-BaseMenuChild

#endregion #2 Base UI Control Actions

#region #2 Base UI Control Elements

function New-BaseWindow {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Window]$Parameters
} # function New-BaseWindow

function New-BaseBorder {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.Border]$Parameters
} # function New-BaseBorder

function New-BaseStackPanel {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.StackPanel]$Parameters
} # function New-BaseStackPanel

function New-BaseScrollViewer {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.ScrollViewer]$Parameters
} # function New-BaseScrollViewer

function New-BaseDockPanel {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.DockPanel]$Parameters
} # function New-BaseDockPanel

function New-BaseTextBox {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.TextBox]$Parameters
} # function New-BaseTextBox

function New-BaseTextBlock {
    param( [hashtable]$Parameters = @{} )
    try {
        [System.Windows.Controls.TextBlock]$Parameters
    }
    catch {
        Write-Host "{New-BaseTextBlock} $_" -ForegroundColor Red
    }
} # function New-BaseTextBlock

function New-BaseRichTextBox {
    param( [hashtable]$Parameters = @{} )

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

    return $RichTextBox
} # function New-BaseRichTextBox

function New-BaseButton {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.Button]$Parameters
} # function New-BaseButton

function New-BaseSeparator {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.Separator]$Parameters
} # function New-BaseSeparator

function New-BaseComboBox {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.ComboBox]$Parameters
} # function New-BaseComboBox

function New-BaseMenu {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.Menu]$Parameters
} # function New-BaseMenu

function New-BaseMenuItem {
    param( [hashtable]$Parameters = @{} )
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
} # function New-BaseMenuItem

function New-BasePasswordBox {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.PasswordBox]$Parameters
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
    $Array = $ItemInArray.Value
    if ($Array.Name -ne $ContentSlotElementName) {
        $Array = Find-ObjectWhere -Object $ItemInArray -FindWhere { $_.Name -eq $ContentSlotElementName } -DigProperties 'Parent' -FindMax 1
    }
    $IndexBlocks = Find-ObjectWhere -Object ([ref]$Array) -FindWhere { $_.Name -like "*$IndexBoxNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }

    $IndexCounter = 1
    :IndexBlocks foreach ($IndexBlock in $IndexBlocks) {
        $IndexBlock.Text = "$($IndexCounter)"
        $IndexCounter ++
    } # IndexBlocks
} # function Reset-ArrayIndexes

function Build-Object {
    param(
        [ref]$Object,
        [Switch]$DoNotCreateIfNoParameters
    )
    $ConstructTitle, $ConstructDescription = (Find-Title $Object.Value).Split('-').Trim()

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
        $ParameterValue = Get-ContentValue -Object $Parameter
        if ($null -ne $ParameterValue) {
            if ($ParameterType -like '*`[]') {
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
} # function Build-Object

function Add-ContentToWrapper {
    param( [ref]$Wrapper, [ref]$Content )

    $ContentSlot = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

    try {
        $ContentSlot.AddChild($Content.Value) | Out-Null
    }
    catch {
        Write-Host "[Add-ContentToWrapper] $($Wrapper.Name) $($Content.Value.Name) $($_)" -ForegroundColor Red
    }
} # function Add-ContentToWrapper

function Add-CustomMenuChild {
    param( [ref]$Wrapper, [ref]$Child, [int]$Index = 0 )

    $Menu = Get-WrapperMenu -Wrapper $Wrapper

    try {
        $Menu.Items.Insert($Index, $Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Add-CustomMenuChild} $_" -ForegroundColor Red
    }
} # function Add-CustomMenuChild

function Remove-CustomMenuChild {
    param( [ref]$Wrapper, [ref]$Child )
    $Menu = Get-WrapperMenu -Wrapper $Wrapper
    try {
        $Menu.Items.Remove($Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Remove-CustomMenuChild} $_" -ForegroundColor Red
    }
} # function Remove-CustomMenuChild

function Add-ChildToItemsButtonMenu {
    param( [ref]$Item, [ref]$Child, [int]$Index = -1 )

    $ButtonMenu = Find-ObjectWhere -Object $Item -FindWhere { $_.Name -eq $ButtonMenuName } -FindMax 1

    if ($Index -lt 0 -or $Index -gt $ButtonMenu.Items.Count) { $Index = $ButtonMenu.Items.Count }
    try {
        $ButtonMenu.Items.Insert($Index, $Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Add-ChildToItemsButtonMenu} $_" -ForegroundColor Red
    }
    $ButtonMenu.Visibility = 'Visible'
} # function Add-ChildToItemsButtonMenu

function Add-ChildrenToItemsButtonMenu {
    param(
        [Parameter(Mandatory)][ref]$Item,
        [Parameter(Mandatory)][array]$Children
    )
    foreach ($Child in $Children) {
        if ($Child) {
            Add-ChildToItemsButtonMenu $Item ([ref]$Child)
        }
    }
} # function Add-ChildrenToItemsButtonMenu

function Remove-ChildToItemsButtonMenu {
    param( [ref]$Item, [ref]$Child )
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
} # function Remove-ChildToItemsButtonMenu

function Get-MenuItemRelativePriority {
    param(
        [Parameter(Mandatory)]$MenuItem,
        [Parameter(Mandatory)][ValidateSet('CustomMenu', 'ButtonMenu')][string]$MenuType
    )
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
    return 100
} # function Get-MenuItemRelativePriority

function Get-MenuRelativeInsertIndex {
    param(
        [Parameter(Mandatory)]$MenuContainer,
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][ValidateSet('CustomMenu', 'ButtonMenu')][string]$MenuType
    )
    $TargetPriority = Get-MenuItemRelativePriority -MenuItem $Item -MenuType $MenuType
    for ($i = 0; $i -lt $MenuContainer.Items.Count; $i++) {
        $ExistingPriority = Get-MenuItemRelativePriority -MenuItem $MenuContainer.Items[$i] -MenuType $MenuType
        if ($ExistingPriority -gt $TargetPriority) {
            return $i
        }
    }
    return $MenuContainer.Items.Count
} # function Get-MenuRelativeInsertIndex

function Move-MenuItemBetweenMenus {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][ValidateSet('ToCustomMenu', 'ToButtonMenu')][string]$Direction
    )
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
} # function Move-MenuItemBetweenMenus

function Clear-SingleContentElement {
    param(
        [Parameter(Mandatory)]$Element,
        [switch]$UseEmptyString
    )
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
} # function Clear-SingleContentElement

function Clear-WrapperContent {
    param(
        [ref]$Wrapper
    )
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
} # function Clear-WrapperContent

function Set-WrapperRandomContent {
    param(
        [ref]$Wrapper
    )
    $Contents = @()
    if ($Wrapper.Value.Name -eq $ContentElementName) {
        $Contents += $Wrapper.Value
    }
    $ChildContents = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentElementName }
    if ($ChildContents) {
        $Contents += $ChildContents
    }

    :Contents foreach ($Content in $Contents) {
        if ((Get-IsLocked ([ref]$Content))) { continue Contents }

        Restore-ElementSearchStyle -Element $Content

        switch ($Content.GetType().Name) {
            'TextBox' {
                if ($Content.MaxLength -eq 1) {
                    $Content.Text = [string]([char](Get-Random -Minimum 65 -Maximum 90))
                }
                else {
                    $Content.Text = (Get-Random -Minimum 0 -Maximum 100).ToString()
                }
            }
            'ComboBox' {
                if ($Content.ItemsSource -and @($Content.ItemsSource).Count -gt 0) {
                    $Content.SelectedItem = Get-Random -InputObject @($Content.ItemsSource)
                }
            }
            'PasswordBox' {
                $Content.Password = (([char[]](0..200) | Get-Random -Count 10) -join '')
            }
            'RichTextBox' {
                Set-RichTextBoxText -RichTextBox $Content -Text ((([char[]](0..200) | Get-Random -Count 10) -join ''))
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
} # function Set-WrapperRandomContent

function Set-DisableEnableButtonVisualState {
    param(
        [Parameter(Mandatory)]$Button,
        [Parameter(Mandatory)][bool]$IsDisabled
    )
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
} # function Set-DisableEnableButtonVisualState

function Confirm-ArrayEnableButton {
    param( [ref]$Item )
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
    if ($ContentHeaderBorderTitle -notlike '*`[]') {
        $GrandWrapper = Get-ParentWrapperBorder -Element $ContentHeaderBorder -HeaderOnly
        if ($GrandWrapper) { $ContentHeaderBorder = $GrandWrapper }
    }

    $ArrayButton = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
    if (-not $ArrayButton) { return }

    $ItemButtons = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $ArrayButton }
    $ItemCount = if ($ItemButtons) { @($ItemButtons).Count } else { 0 }

    if ($ItemCount -eq 0) {
        Set-DisableEnableButtonVisualState -Button $ArrayButton -IsDisabled $false
        return
    }

    $DisabledButtons = $ItemButtons | Where-Object { $null -eq $_.Icon }
    $DisabledCount = if ($DisabledButtons) { @($DisabledButtons).Count } else { 0 }

    if ($DisabledCount -eq $ItemCount) {
        Set-DisableEnableButtonVisualState -Button $ArrayButton -IsDisabled $true
    }
    elseif ($DisabledCount -eq 0) {
        Set-DisableEnableButtonVisualState -Button $ArrayButton -IsDisabled $false
    }
} # function Confirm-ArrayEnableButton

function Update-ArrayButtonsState {
    param(
        [Parameter(Mandatory)]$Wrapper
    )
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    if ($Target.Name -eq $ContentSlotElementName) {
        $Target = Get-ParentWrapperBorder -Element $Target -HeaderOnly
    }
    if (-not $Target) { return }

    $IsArrayWrapper = ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('IsArray') -and $Target.Tag.IsArray)
    if (-not $IsArrayWrapper) {
        $TitleText = Find-Title $Target
        $IsArrayWrapper = ($TitleText -like '*`[]')
    }
    if (-not $IsArrayWrapper) { return }

    $ContentSlot = Get-WrapperContentSlot -Wrapper $Target

    $ItemCount = if ($ContentSlot -and $ContentSlot.Children) { $ContentSlot.Children.Count } else { 0 }
    $HasItems = ($ItemCount -gt 0)
    $IsLocked = Get-IsElementLockedSelf $Target

    $Menu = Get-WrapperMenu -Wrapper $Target
    if (-not $Menu) { return }

    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes @($SearchButtonNameSuffix, $QuickSetSaveButtonNameSuffix, $CopyButtonNameSuffix, $CopyAsMenuNameSuffix) -IsEnabled $HasItems

    $ConstructAllButtons = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$ConstructButtonNameSuffix" }
    foreach ($CButton in @($ConstructAllButtons)) {
        if ($CButton) { $CButton.IsEnabled = $HasItems }
    }

    $LockableBatchSuffixes = @(
        $RandomValuesButtonNameSuffix
        $ClearButtonNameSuffix
        $DisableEnableButtonNameSuffix
        $DeleteButtonNameSuffix
    )
    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes $LockableBatchSuffixes -IsEnabled ($HasItems -and (-not $IsLocked))
    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes @($SortMenuNameSuffix) -IsEnabled (($ItemCount -gt 1) -and (-not $IsLocked))
    Update-WrapperPasteButtonState -Wrapper $Target

    $AddButtons = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $AddArrayItemButtonName }
    foreach ($AButton in @($AddButtons)) {
        if ($AButton) { $AButton.IsEnabled = (-not $IsLocked) }
    }

    if (-not $HasItems) {
        $SearchBar = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1)
        if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
            Close-SearchBar -ChildElement $SearchBar
        }
    }
} # function Update-ArrayButtonsState

function Sync-ArraySlotState {
    param(
        [Parameter(Mandatory)]$ContentSlot,
        $ContainerWrapper = $null
    )
    $TargetSlot = Resolve-TargetElement $ContentSlot
    if (-not $TargetSlot) { return }
    Reset-ArrayIndexes ([ref]$TargetSlot)
    $SyncTarget = if ($ContainerWrapper) { $ContainerWrapper } else { $TargetSlot }
    Confirm-ArrayEnableButton -Item ([ref]$SyncTarget)
    Update-ArrayButtonsState -Wrapper $SyncTarget
} # function Sync-ArraySlotState

function Clear-ContentSlotArrayItems {
    param(
        [Parameter(Mandatory = $true)]
        $ContentSlot,
        $ContainerWrapper = $null
    )
    $TargetSlot = Resolve-TargetElement $ContentSlot
    if (-not $TargetSlot) { return }

    :DeleteArrayItems foreach ($Child in @($TargetSlot.Children)) {
        if ((Get-IsLocked $Child)) { continue DeleteArrayItems }
        $TargetSlot.Children.Remove($Child)
    }
    Sync-ArraySlotState -ContentSlot $TargetSlot -ContainerWrapper $ContainerWrapper
} # function Clear-ContentSlotArrayItems

#endregion #3 Content Wrapper Actions

#region #3 Content Wrapper Elements

function New-CustomMenu {
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
                Update-WrapperPasteButtonState -Wrapper $ParentWrapper
            }
        })
    
    Add-BaseMenuChild ([ref]$Menu) ([ref]$MenuItem)

    $Menu
} # function New-CustomMenu

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
        Foreground          = '#0B132B'
        HorizontalAlignment = 'Center'
        VerticalAlignment   = 'Center'
    }
    Add-BaseStackPanelChild ([ref]$ContentHeaderTitleBorderDockStack) ([ref]$HeaderDescription)

    #endregion Header

    #region Buttons

    $ContentHeaderButtonMenu = New-CustomMenu

    $MinMaxButton = New-MinMaxButton
    Add-BaseMenuChild ([ref]$ContentHeaderButtonMenu) ([ref]$MinMaxButton) 0

    Add-BaseDockPanelChild ([ref]$ContentHeaderTitleBorderDock) ([ref]$ContentHeaderButtonMenu) 'Right'

    #endregion Buttons

    # Search Bar
    $SearchBar = New-SearchBar -WrapperName $ContentHeaderBorderName
    $ContentHeaderBorderStack.AddChild($SearchBar) | Out-Null

    # Content Slot
    $ContentSlot = New-BaseStackPanel @{
        Name       = $ContentSlotElementName
        Background = $ColorSequence[ ($Depth + 1) % $ColorSequence.Count ]
    }
    $ContentHeaderBorderStack.AddChild($ContentSlot)

    # MiniHeader Setting Differences
    if ($WrapperType -eq 'MiniHeader') {
        $ContentHeaderBorder.Margin = 1.5
        $ContentHeaderBorder.BorderThickness = 1.5
        $ContentHeaderTitleBorder.BorderThickness = '0,0,0,1.5'
        $ContentHeaderTitleBorder.BorderBrush = 'White'
        $MinMaxButton.Header = $MinMaxButtonMaxedIcon
        $ContentSlot.Visibility = 'Collapsed'
    }

    return $ContentHeaderBorder
} # function New-ContentHeader

#endregion #3 Content Wrapper Elements

#endregion #2 Content Wrappers

#region #2 Content Controls

#region #3 Content Controls Processes

function Invoke-ConstructButtonClick {
    param($s, $e)
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
        $Top.Tag.ContentSlot = Find-ObjectWhere -Object ([ref]$Top) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 0 -DepthWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -FindMax 1
        if (-not $Top.Tag.ContainsKey('AddButton')) { $Top.Tag.AddButton = $null }
    }

    if (-not $IsArrayType -and $ArrayType -ne 'ArrayItem') {
        Add-ChildrenToItemsButtonMenu ([ref]$Top) (Get-StandardActionButtons -ActionFrom $Top.Name -IncludeSearch -IsConstruct:$IsConstruct)
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

    return $Top
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

        return $Border
    }

    $Wrapper = New-ContentHeader -TitleType $WrapperType -Title $Title -Description $Description -Type $Type -ArrayItemHeader $ArrayItem -Depth $Depth
    return $Wrapper

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
        Add-ChildrenToItemsButtonMenu $Wrapper (Get-StandardActionButtons -ActionFrom $Wrapper.Value.Name -IsBatch -IncludeSearch -TargetType $TargetType)
    }
    elseif ($ArrayItemType -eq 'ArrayItem') {
        if (@('Header', 'MiniHeader') -contains $WrapperType) {
            $ContentBorderDock = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
        }
        elseif ($WrapperType -eq 'Border') {
            $ContentBorderDock = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentBorderDockName } -FindMax 1
            $ButtonMenu = New-CustomMenu
            $ContentBorderDock.Children.Insert(0, $ButtonMenu)
            [System.Windows.Controls.DockPanel]::SetDock($ButtonMenu, 'Right')
        }
        else {
            Write-Host '{Add-ArrayFunctionality} $_' -ForegroundColor Red
        }

        #region Array Item Controls

        $DragHandle = New-DragHandle -WrapperName $Wrapper.Value.Name
        $IndexBlock = New-IndexBox -WrapperName $Wrapper.Value.Name -Index ($Index + 1)
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

        $HasHeaderMenu = ($WrapperType -ne 'Border' -and $WrapperType -ne 'None')
        Add-ChildrenToItemsButtonMenu $Wrapper (Get-StandardActionButtons -ActionFrom $Wrapper.Value.Name -IncludeArrayItemActions -IncludeSearch:$HasHeaderMenu -IsConstruct:$HasHeaderMenu)

        #endregion Array Item Buttons
    }
    else {
        Write-Host "[Add-ArrayFunctionality] Unknown ArrayItemType: $ArrayItemType" -ForegroundColor Red
    }

} # function Add-ArrayFunctionality

#endregion #3 Content Controls Processes

#region #3 Content Controls Actions

#region #4 Content Value

function Get-ContentValue {
    param($Object)

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
            return $Value.ToString()
        }
        if ($Value -is [string] -and [string]::IsNullOrEmpty($Value)) {
            return $null
        }
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
        [string]$NegativeButtonText = 'Cancel',
        [scriptblock]$ResultProvider,
        [scriptblock]$OnLoadedCallback
    )

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

    $AffirmativeButton = New-BaseButton @{
        Content         = $AffirmativeButtonText
        Width           = 70
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

    $NegativeButton = New-BaseButton @{
        Content         = $NegativeButtonText
        Width           = 70
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

    $AffirmativeButton.Add_Click({
            if ($ResultProvider) {
                $DialogResultContainer.Value = & $ResultProvider
            }
            else {
                $DialogResultContainer.Value = $true
            }
            $Dialog.DialogResult = $true
            $Dialog.Close()
        })

    $NegativeButton.Add_Click({
            $DialogResultContainer.Value = if ($AffirmativeButtonText -eq 'Yes') { $false } else { $null }
            $Dialog.DialogResult = $false
            $Dialog.Close()
        })

    if ($OnLoadedCallback) {
        $Dialog.Add_Loaded($OnLoadedCallback)
    }

    $null = $Dialog.ShowDialog()
    return $DialogResultContainer.Value
} # function New-QuickSetModalDialog


function Show-QuickSetInputDialog {
    param(
        [string]$Title = 'QuickSet',
        [string]$Prompt = 'Enter name:',
        [string]$DefaultValue = ''
    )

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
} # function Show-QuickSetInputDialog


function Show-QuickSetConfirmDialog {
    param(
        [string]$Title = 'Confirm',
        [string]$Message = 'Are you sure?'
    )

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
    return $false
} # function Show-QuickSetConfirmDialog

function Get-QuickSetTypeDirectory {
    param($Type)
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
    return $TypeDir
} # function Get-QuickSetTypeDirectory

function Get-WrapperTargetType {
    param([Parameter(Mandatory)]$Wrapper)
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
        try { return [type]$DescBlock.Text } catch { return $DescBlock.Text }
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
    return [object]
} # function Get-WrapperTargetType

function Get-QuickSetMenuFromSender {
    param($s)
    if (-not $s) { return $null }
    $Target = Resolve-TargetElement $s
    if ($Target -is [System.Windows.Controls.MenuItem] -and $Target.Name -like "*$QuickSetMenuNameSuffix") {
        return $Target
    }
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -DigProperties 'Parent' -FindMax 1
    if ($Found -is [array]) { return $Found[0] }
    return $Found
} # function Get-QuickSetMenuFromSender

function Get-QuickSetWrapper {
    param(
        [Parameter(Mandatory)]$s,
        [string]$ActionFrom
    )
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
    return $ContentWrapper
} # function Get-QuickSetWrapper

function Get-WrapperHeaderTitleElement {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $null }

    $TitleDock = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderTitleBorderDockName } -FindMax 1
    if ($TitleDock -is [array]) { $TitleDock = $TitleDock[0] }
    if (-not $TitleDock) { return $null }

    $TitleElem = Find-ObjectWhere -Object ([ref]$TitleDock) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName } -FindMax 1
    if ($TitleElem -is [array]) { $TitleElem = $TitleElem[0] }
    return $TitleElem
} # function Get-WrapperHeaderTitleElement

function Get-IsArrayItem {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return $false }

    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('ArrayItem') -and $Target.Tag.ArrayItem) {
        return $true
    }

    $ItemStack = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ArrayItemStackName } -DepthMax 2 -FindMax 1
    return ($null -ne $ItemStack)
} # function Get-IsArrayItem

function Get-WrapperDisplayName {
    param([Parameter(Mandatory)]$Wrapper)
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

    return $null
} # function Get-WrapperDisplayName

function Set-WrapperDisplayName {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [string]$DisplayName
    )
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
} # function Set-WrapperDisplayName

function Save-QuickSetFile {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [Parameter(Mandatory)][string]$QuickSetName
    )
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
    Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $SanitizedName

    return $true
} # function Save-QuickSetFile

function Get-WrapperQuickSetValue {
    param([Parameter(Mandatory)]$Wrapper)
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
                $ChildVal = Get-WrapperQuickSetValue -Wrapper $Child
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
            $ObjMap[$ParamName] = Get-WrapperQuickSetValue -Wrapper $Child
        }
        $RawValue = $ObjMap
    }
    else {
        # Simple wrapper: read its own Content control (or the wrapper is the Content control)
        $Content = if ($Target.Name -eq $ContentElementName) { $Target } else {
            Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
        }
        if ($Content) {
            $RawValue = (Get-ContentValue -Object $Content)
        }
        else {
            $DTP = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
            if ($DTP) {
                $RawValue = (Get-ContentValue -Object $DTP)
            }
        }
    }

    $IsArrayItem = Get-IsArrayItem -Wrapper $Target
    $TitleElement = Get-WrapperHeaderTitleElement $Target
    $HasHeader = ($null -ne $TitleElement)
    $SelfLocked = Get-IsElementLockedSelf $Target
    $SelfDisabled = Get-IsElementDisabledSelf $Target
    $SelfMinMaxState = Get-WrapperMinMaxState $Target

    if (($IsArrayItem -and $HasHeader) -or $SelfLocked -or $SelfDisabled -or ($null -ne $SelfMinMaxState)) {
        $Envelope = [ordered]@{}
        if ($IsArrayItem -and $HasHeader) {
            $Envelope['displayName'] = Get-WrapperDisplayName -Wrapper $Target
        }
        if ($null -ne $SelfMinMaxState) { $Envelope['isMinimized'] = [bool]$SelfMinMaxState }
        if ($SelfLocked) { $Envelope['isLocked'] = $true }
        if ($SelfDisabled) { $Envelope['isDisabled'] = $true }
        $Envelope['value'] = $RawValue
        return $Envelope
    }

    # The leading comma stops PowerShell from unrolling an array result
    if ($Tag.IsArray) { return , $RawValue }

    return $RawValue
} # function Get-WrapperQuickSetValue

function Set-WrapperQuickSetValue {
    param(
        [Parameter(Mandatory)]$Wrapper,
        $Value
    )
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return }

    $Tag = if ($Target.Tag -is [hashtable]) { $Target.Tag } else { @{} }

    Restore-ElementSearchStyle -Element $Target

    # -DepthMax 0 with this DepthWhere means a search never goes inside a child wrapper
    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

    $SearchBar = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
    if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
        Close-SearchBar -ChildElement $SearchBar
    }

    $ActualValue = $Value
    $DesiredLocked = $false
    $DesiredDisabled = $false
    $HasDesiredMinimized = $false
    $DesiredMinimized = $false

    if (($Value -is [System.Collections.IDictionary] -or $Value -is [System.Management.Automation.PSObject] -or $Value -is [System.Management.Automation.PSCustomObject]) -and $Value -isnot [array]) {
        $ValueEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'Value'
        if ($null -ne $ValueEntry) {
            $ActualValue = $ValueEntry.Value
        }

        $DisplayNameEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'DisplayName'
        if ($null -ne $DisplayNameEntry) {
            Set-WrapperDisplayName -Wrapper $Target -DisplayName $DisplayNameEntry.Value
        }

        $MinimizedEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'IsMinimized'
        if ($null -ne $MinimizedEntry -and $null -ne $MinimizedEntry.Value) {
            $HasDesiredMinimized = $true
            $DesiredMinimized = [bool]$MinimizedEntry.Value
        }

        $LockedEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'IsLocked'
        if ($null -ne $LockedEntry) {
            $DesiredLocked = [bool]$LockedEntry.Value
        }

        $DisabledEntry = Get-ObjectPropertyEntryCaseInsensitive -InputObject $Value -PropertyName 'IsDisabled'
        if ($null -ne $DisabledEntry) {
            $DesiredDisabled = [bool]$DisabledEntry.Value
        }
    }

    # Unlock control first to permit value updates
    Set-TargetLockedState -Target $Target -IsLocked $false

    $Value = $ActualValue

    # Array wrapper: grow/shrink the item list to match, then set each item
    if ($Tag.IsArray) {
        $ContentSlot = $Tag.ContentSlot
        $AddButton = $Tag.AddButton
        if ($ContentSlot -and $AddButton) {
            $List = if ($null -eq $Value) { @() } else { @($Value) }
            while ($ContentSlot.Children.Count -lt $List.Count) {
                $CountBefore = $ContentSlot.Children.Count
                $AddButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
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
            Sync-ArraySlotState -ContentSlot $ContentSlot -ContainerWrapper $Target

            $SetCount = [Math]::Min($List.Count, $ContentSlot.Children.Count)
            for ($i = 0; $i -lt $SetCount; $i++) {
                Set-WrapperQuickSetValue -Wrapper $ContentSlot.Children[$i] -Value $List[$i]
            }
        }
    }
    elseif ($Tag.IsConstruct -and $Tag.Construct -and $null -ne $Value) {
        $Construct = $Tag.Construct
        $PropNames = if ($Value -is [System.Collections.IDictionary]) {
            @($Value.Keys)
        }
        elseif ($Value -is [System.Management.Automation.PSCustomObject]) {
            @($Value.PSObject.Properties.Name)
        }
        else {
            @()
        }

        foreach ($Child in @($Construct.Children)) {
            $Title = Find-Title $Child
            $ParamName = if ($Title) { ($Title.Split('-')[0]).Trim() } else { $Child.Name }
            $MatchedProp = $PropNames | Where-Object { $_ -eq $ParamName } | Select-Object -First 1
            if ($MatchedProp) {
                $PropVal = if ($Value -is [System.Collections.IDictionary]) { $Value[$MatchedProp] } else { $Value.$MatchedProp }
                Set-WrapperQuickSetValue -Wrapper $Child -Value $PropVal
            }
        }
    }
    else {
        $Content = if ($Target.Name -eq $ContentElementName) { $Target } else {
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
            $DTP = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
            if ($DTP) {
                $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
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
    Set-TargetDisabledState -Target $Target -IsDisabled $DesiredDisabled
    Set-TargetLockedState -Target $Target -IsLocked $DesiredLocked
} # function Set-WrapperQuickSetValue

function Clear-WrapperQuickSetValue {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return }

    $Tag = if ($Target.Tag -is [hashtable]) { $Target.Tag } else { @{} }

    if ((Get-IsLocked ([ref]$Target))) { return }

    Restore-ElementSearchStyle -Element $Target

    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

    $SearchBar = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DepthMax 0 -DepthWhere $StopAtChild -FindMax 1
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
} # function Clear-WrapperQuickSetValue

function Set-QuickSetActiveButtonsState {
    param(
        [Parameter(Mandatory)]$QuickSetMenuItem,
        [Parameter(Mandatory)][bool]$IsEnabled
    )
    $QSMenu = Resolve-TargetElement $QuickSetMenuItem
    if (-not $QSMenu) { return }

    $ActiveOnlyButtonSuffixes = @(
        $QuickSetSaveButtonNameSuffix
        $QuickSetOverwriteButtonNameSuffix
        $QuickSetRenameButtonNameSuffix
        $QuickSetClearButtonNameSuffix
        $QuickSetCloseButtonNameSuffix
        $QuickSetDeleteButtonNameSuffix
    )

    Set-MenuButtonsEnabledState -Menu $QSMenu -Suffixes $ActiveOnlyButtonSuffixes -IsEnabled $IsEnabled
} # function Set-QuickSetActiveButtonsState

function Reset-WrapperQuickSet {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [switch]$SaveCurrentValues,
        $QuickSetMenuItem = $null
    )
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
        Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $null
    }

    $QSMenu = if ($QuickSetMenuItem) { Resolve-TargetElement $QuickSetMenuItem } else {
        Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetWrapper) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -FindMax 1)
    }
    if ($QSMenu) {
        Set-QuickSetActiveButtonsState -QuickSetMenuItem $QSMenu -IsEnabled $false
        Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
    }
} # function Reset-WrapperQuickSet

function Invoke-ExistingBadgeClick {
    param($s, $e)
    if ($e) { $e.Handled = $true }
    try {
        $TargetWrapper = if ($s.Tag) { $s.Tag } else { Get-QuickSetWrapper $s }
        if (-not $TargetWrapper) { return }
        Reset-WrapperQuickSet -Wrapper $TargetWrapper -SaveCurrentValues
    }
    catch {
        [System.Windows.MessageBox]::Show("Error saving QuickSet: $_", "QuickSet Error") | Out-Null
    }
} # function Invoke-ExistingBadgeClick

function Update-QuickSetBadge {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [string]$DisplayName
    )
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
} # function Update-QuickSetBadge

function Invoke-QuickSetSetItemClick {
    param($s, $e, $TargetWrapper, $TargetFile, $TargetName, $CurrentQSMenu)
    try {
        $MenuToUpdate = if ($CurrentQSMenu) { $CurrentQSMenu } else { Get-QuickSetMenuFromSender $s }
        $WrapperToUpdate = if ($TargetWrapper) { $TargetWrapper } else { Get-QuickSetWrapper $s }
        if (-not $WrapperToUpdate) { return }

        $RawJson = Get-Content -LiteralPath $TargetFile -Raw -Encoding UTF8
        $LoadedVal = try { $RawJson | ConvertFrom-Json } catch { $RawJson }
        Set-WrapperQuickSetValue -Wrapper $WrapperToUpdate -Value $LoadedVal

        if (-not ($WrapperToUpdate.Tag -is [hashtable])) { $WrapperToUpdate.Tag = @{} }
        $WrapperToUpdate.Tag.ActiveQuickSet = $TargetName
        Update-QuickSetBadge -Wrapper $WrapperToUpdate -DisplayName $TargetName

        if ($MenuToUpdate) {
            Set-QuickSetActiveButtonsState -QuickSetMenuItem $MenuToUpdate -IsEnabled $true
            Update-QuickSetSubMenu -QuickSetMenuItem $MenuToUpdate -Wrapper $WrapperToUpdate
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error loading QuickSet: $_", "QuickSet Error") | Out-Null
    }
} # function Invoke-QuickSetSetItemClick

function Update-QuickSetSubMenu {
    param(
        [Parameter(Mandatory)]$QuickSetMenuItem,
        [Parameter(Mandatory)]$Wrapper
    )
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
} # function Update-QuickSetSubMenu

#endregion #4 QuickSet

#region #4 Search

function Restore-ElementSearchStyle {
    param(
        [Parameter(Mandatory)]$Element
    )
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
} # function Restore-ElementSearchStyle

function Resolve-SearchBar {
    param(
        [Parameter(Mandatory)]$ChildElement
    )
    $Target = Resolve-TargetElement $ChildElement
    if (-not $Target) { return $null }
    if ($Target.Name -like "*$SearchBarNameSuffix") { return $Target }
    $Found = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
    if ($Found -is [array]) { return $Found[0] }
    return $Found
} # function Resolve-SearchBar

function Expand-ElementParents {
    param([Parameter(Mandatory)]$Element)
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
} # function Expand-ElementParents

function Set-BorderHighlight {
    param(
        [Parameter(Mandatory)]$Target,
        [ValidateSet('Match', 'Active')][string]$HighlightType = 'Match'
    )
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
} # function Set-BorderHighlight

function Set-ElementHighlight {
    param(
        [Parameter(Mandatory)][ref]$Element,
        [ValidateSet('Match', 'Active')][string]$HighlightType = 'Match',
        [string]$Query = '',
        [regex]$CompiledRegex = $null
    )
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
} # function Set-ElementHighlight

function Reset-ElementHighlight {
    param([Parameter(Mandatory)][ref]$Element)
    $Target = Resolve-TargetElement $Element
    if (-not $Target) { return }

    Restore-ElementSearchStyle -Element $Target

    # Reset parent field border if it was highlighted
    $ParentFieldBorder = Get-ParentWrapperBorder -Element $Target
    if ($ParentFieldBorder) {
        Restore-ElementSearchStyle -Element $ParentFieldBorder
    }
} # function Reset-ElementHighlight

function Test-ElementMatchesQuery {
    param(
        [Parameter(Mandatory)]$Element,
        [Parameter(Mandatory)][string]$Query,
        [regex]$CompiledRegex = $null
    )
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

    # 1. Match titles / property names inside element
    if ($Element.Name -eq $ContentHeaderTitleValueName) {
        if (& $TestString $Element.Text) {
            [void]$MatchedParts.Add($Element)
        }
    }
    $TitleBlocks = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName }
    :Titles foreach ($TBlock in $TitleBlocks) {
        if (& $TestString $TBlock.Text) {
            [void]$MatchedParts.Add($TBlock)
        }
    }

    # 2. Match descriptions inside element
    if ($Element.Name -eq $ContentHeaderDescriptionValueName) {
        if (& $TestString $Element.Text) {
            [void]$MatchedParts.Add($Element)
        }
    }
    $DescBlocks = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName }
    :Descs foreach ($DBlock in $DescBlocks) {
        if (& $TestString $DBlock.Text) {
            [void]$MatchedParts.Add($DBlock)
        }
    }

    # 3. Match content controls inside element
    $Contents = @()
    if ($Element.Name -eq $ContentElementName) {
        $Contents += $Element
    }
    $ChildContents = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -eq $ContentElementName }
    if ($ChildContents) {
        $Contents += $ChildContents
    }
    :Contents foreach ($Content in $Contents) {
        $Val = Get-ContentValue $Content
        if ($null -ne $Val) {
            $StrVal = "$Val"
            if (& $TestString $StrVal) {
                [void]$MatchedParts.Add($Content)
            }
        }
        if ($Content -is [System.Windows.Controls.ComboBox] -and $Content.ItemsSource) {
            foreach ($Item in $Content.ItemsSource) {
                if ($Item -and (& $TestString "$Item")) {
                    if (-not $MatchedParts.Contains($Content)) {
                        [void]$MatchedParts.Add($Content)
                    }
                    break
                }
            }
        }
    }

    # 4. Match DateTime pickers inside element
    $DateTimePickers = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -eq $CustomDateTimePickerName }
    :DTPs foreach ($DTP in $DateTimePickers) {
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox -and (& $TestString $DateBox.Text)) {
            [void]$MatchedParts.Add($DateBox)
        }
    }

    # 5. Match Index boxes inside element
    $IndexBoxes = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -like "*$IndexBoxNameSuffix" }
    :Indices foreach ($IBox in $IndexBoxes) {
        if ($IBox.Text) {
            $IVal = $IBox.Text.Trim()
            if ($CompiledRegex) {
                if ($CompiledRegex.IsMatch($IVal)) {
                    [void]$MatchedParts.Add($IBox)
                }
            }
            elseif ($IVal -eq $Query.Trim()) {
                [void]$MatchedParts.Add($IBox)
            }
        }
    }

    if ($MatchedParts.Count -gt 0) {
        return $MatchedParts
    }
    return $null
} # function Test-ElementMatchesQuery

function Clear-SearchHighlights {
    param([Parameter(Mandatory)][ref]$SearchBar)

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
} # function Clear-SearchHighlights

function Close-SearchBar {
    param([Parameter(Mandatory)]$ChildElement)
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
} # function Close-SearchBar

function Invoke-SearchExecution {
    param([Parameter(Mandatory)]$SearchBox)

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
    :Matches foreach ($Match in $MatchedElements) {
        Set-ElementHighlight -Element ([ref]$Match) -HighlightType 'Match' -Query $Query -CompiledRegex $CompiledRegex
    }

    $SearchBar.Tag.Matches = $MatchedElements
    $SearchBar.Tag.CurrentIndex = 0
    Set-ElementHighlight -Element ([ref]$MatchedElements[0]) -HighlightType 'Active' -Query $Query -CompiledRegex $CompiledRegex
    $MatchedElements[0].BringIntoView()

    if ($CountBlock) {
        $CountBlock.Text = "1 / $($MatchedElements.Count)"
        $CountBlock.Foreground = '#C1B8D1'
    }
} # function Invoke-SearchExecution

function Step-SearchMatch {
    param(
        [Parameter(Mandatory)]$ChildElement,
        [ValidateSet('Next', 'Prev')][string]$Direction = 'Next'
    )

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

    $CountBlock = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchCountNameSuffix" } -FindMax 1
    if ($CountBlock) {
        $CountBlock.Text = "$($NewIdx + 1) / $($Matches.Count)"
        $CountBlock.Foreground = '#C1B8D1'
    }
} # function Step-SearchMatch

#endregion #4 Search

#region #4 Filter

function Get-MatchedSlotItems {
    param(
        [Parameter(Mandatory)]$ChildElement
    )
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
} # function Get-MatchedSlotItems

function Invoke-SearchFilterAction {
    param(
        [Parameter(Mandatory)]$ChildElement,
        [ValidateSet('ShowOnly', 'Hide', 'ShowAll')][string]$Action = 'ShowOnly'
    )
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
} # function Invoke-SearchFilterAction

#endregion #4 Filter

#region #4 Batch

function Get-MatchedWrappers {
    param(
        [Parameter(Mandatory)]$ChildElement
    )
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
} # function Get-MatchedWrappers

function Invoke-SearchMatchesSort {
    param(
        [Parameter(Mandatory)]$SearchBar,
        [ValidateSet('Ascending', 'Descending')][string]$Direction = 'Ascending'
    )
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
} # function Invoke-SearchMatchesSort

function Invoke-SearchBatchAction {
    param(
        [Parameter(Mandatory)]$ChildElement,
        [ValidateSet('SortAscending', 'SortDescending', 'Random', 'Clear', 'Disable', 'Enable', 'Delete', 'Lock', 'Unlock')][string]$Action = 'Random'
    )
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
} # function Invoke-SearchBatchAction

#endregion #4 Batch

#endregion #3 Content Controls Actions

#region #3 Content Controls Elements

function Invoke-DateTimeNowButtonClick {
    param($Calendar, $HourCombo, $MinuteCombo, $SecondCombo)
    $now = Get-Date
    $Calendar.SelectedDate = $now.Date
    $Calendar.DisplayDate = $now.Date
    $HourCombo.SelectedItem = $now.ToString('HH')
    $MinuteCombo.SelectedItem = $now.ToString('mm')
    $SecondCombo.SelectedItem = $now.ToString('ss')
} # function Invoke-DateTimeNowButtonClick

function Invoke-DateTimeOkButtonClick {
    param($Calendar, $HourCombo, $MinuteCombo, $SecondCombo, $PickButton, $Dialog)
    $selDate = if ($Calendar.SelectedDate) { $Calendar.SelectedDate } else { (Get-Date).Date }
    $h = [int]($HourCombo.SelectedItem -as [int])
    $m = [int]($MinuteCombo.SelectedItem -as [int])
    $s = [int]($SecondCombo.SelectedItem -as [int])

    $finalDateTime = [DateTime]::new($selDate.Year, $selDate.Month, $selDate.Day, $h, $m, $s)
    $CustomDateTimePicker = Find-ObjectWhere -Object ([ref]$PickButton) -FindWhere { $_.Name -eq $CustomDateTimePickerName }
    $ContentDateTimeDisplayTextBox = Find-ObjectWhere -Object ([ref]$CustomDateTimePicker) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName }
    $ContentDateTimeDisplayTextBox.Text = $finalDateTime.ToString('yyyy-MM-dd HH:mm:ss')
    $Dialog.Close()
} # function Invoke-DateTimeOkButtonClick

function Invoke-DateTimeCancelButtonClick {
    param($Dialog)
    $Dialog.Close()
} # function Invoke-DateTimeCancelButtonClick

function Invoke-SearchItemButtonClick {
    param($s, $e, $TargetButton, $ActionType, $ActionName)
    if ($TargetButton.Tag) {
        $TargetButton.Tag.IsOpen = $false
    }
    if ($ActionType -eq 'Filter') {
        Invoke-SearchFilterAction -ChildElement $TargetButton -Action $ActionName
    }
    else {
        Invoke-SearchBatchAction -ChildElement $TargetButton -Action $ActionName
    }
} # function Invoke-SearchItemButtonClick

function Invoke-SearchActionsButtonClick {
    param($s, $e)
    if ($s.Tag) {
        $s.Tag.IsOpen = -not $s.Tag.IsOpen
    }
} # function Invoke-SearchActionsButtonClick

function New-ContentEnum {
    param([type]$EnumType)
    New-BaseComboBox @{
        Name        = $ContentElementName
        ItemsSource = $EnumType.GetEnumNames()
        Margin      = 2
    }
} # function New-ContentEnum

function New-ContentPassword {
    New-BasePasswordBox @{
        Name   = $ContentElementName
        Margin = 2
    }
} # function New-ContentPassword

function New-ContentString {
    New-BaseRichTextBox @{
        Name      = $ContentElementName
        Margin    = 2
        AllowDrop = $false
    }
} # function New-ContentString

function New-ContentNumber {
    param( [type]$TargetType )
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
} # function New-ContentNumber

function New-ContentBoolean {
    New-BaseComboBox @{
        Name        = $ContentElementName
        ItemsSource = @(
            $true,
            $false
        )
    }
} # function New-ContentBoolean

function New-ContentDateTime {
    param(
        [hashtable]$Parameters = @{},
        $SelectedDateTime = (Get-Date)
    )

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

    return $Grid
} # function New-ContentDateTime

function New-ContentChar {
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
} # function New-ContentChar

function New-DragHandle {
    param($WrapperName)

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
} # function New-DragHandle

function Add-DragDropLogic {
    param([ref]$DragDropTarget)

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
} # function Add-DragDropLogic

function New-IndexBox {
    param(
        $WrapperName,
        [int]$Index = $Index + 1
    )
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
                $IndexBlockParent = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$IndexBoxNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                $Content = Find-ObjectWhere -Object ([ref]$IndexBlockParent) -FindWhere { $_.Name -eq $ContentElementName } -FindMax 1
                if ($Content) { $Content.Focus() }
            }
        }
    )
    $IndexBlock.Add_LostFocus({
            param($s, $e)

            # This section moves the item to the new index if the user has changed it.
            $ArrayItem = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$IndexBoxNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
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
} # function New-IndexBox

function New-SearchBar {
    param(
        [string]$WrapperName = $ContentHeaderBorderName
    )

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

    return $SearchBarBorder
} # function New-SearchBar

#endregion #3 Content Controls Elements

#region #3 Button Elements

function Invoke-SearchRegexButtonClick {
    param($s, $e)
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
} # function Invoke-SearchRegexButtonClick

function Invoke-SearchStepButtonClick {
    param(
        $s,
        $e,
        [ValidateSet('Next', 'Prev')][string]$Direction = 'Next'
    )
    Step-SearchMatch -ChildElement $s -Direction $Direction
} # function Invoke-SearchStepButtonClick

function Invoke-SearchCloseButtonClick {
    param($s, $e)
    Close-SearchBar -ChildElement $s
} # function Invoke-SearchCloseButtonClick

function Set-ContentSlotCollapseState {
    param(
        [Parameter(Mandatory = $true)]$ContentSlotElement,
        [Parameter(Mandatory = $true)]$MinMaxButton,
        $ContentHeaderBorder,
        [Parameter(Mandatory = $true)][bool]$Collapse
    )
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
} # function Set-ContentSlotCollapseState

function Invoke-MinMaxButtonClick {
    param($s, $e)
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
} # function Invoke-MinMaxButtonClick

function Invoke-AddArrayItemButtonClick {
    param($s, $e)
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
} # function Invoke-AddArrayItemButtonClick

function Get-QuickSetActionContext {
    param(
        [Parameter(Mandatory)]$Sender,
        [string]$RequireActiveForAction,
        [switch]$IncludeTypeDirectory,
        [switch]$FallbackToDisplayName
    )
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
} # function Get-QuickSetActionContext

function Request-ValidatedQuickSetTarget {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Prompt,
        [string]$DefaultValue,
        [Parameter(Mandatory)][string]$TypeDir,
        [string]$RejectIfSameAs
    )
    $RawName = Show-QuickSetInputDialog -Title $Title -Prompt $Prompt -DefaultValue $DefaultValue
    if ([string]::IsNullOrWhiteSpace($RawName)) { return $null }

    $SanitizedName = ($RawName.Trim() -replace '[\\/:*?"<>|]', '_')
    if ([string]::IsNullOrWhiteSpace($SanitizedName)) { return $null }
    if (-not [string]::IsNullOrWhiteSpace($RejectIfSameAs) -and $SanitizedName -eq $RejectIfSameAs) { return $null }

    $TargetFilePath = Join-Path $TypeDir "$SanitizedName.json"
    if (Test-Path -LiteralPath $TargetFilePath) {
        $Confirm = Show-QuickSetConfirmDialog -Title "Overwrite QuickSet" -Message "A QuickSet named '$SanitizedName' already exists. Overwrite it?"
        if (-not $Confirm) { return $null }
    }

    return [pscustomobject]@{
        Name     = $SanitizedName
        FilePath = $TargetFilePath
    }
} # function Request-ValidatedQuickSetTarget

function Invoke-QuickSetRefreshButtonClick {
    param($s, $e)
    $Ctx = Get-QuickSetActionContext -Sender $s
    if ($Ctx -and $Ctx.QSMenu) {
        Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
    }
} # function Invoke-QuickSetRefreshButtonClick

function Invoke-QuickSetSaveButtonClick {
    param($s, $e)
    $Ctx = Get-QuickSetActionContext -Sender $s -IncludeTypeDirectory -FallbackToDisplayName
    if (-not $Ctx) { return }

    $TypeNameDisplay = if ($Ctx.Type -is [type]) { $Ctx.Type.Name } else { $Ctx.Type.ToString().Split('.')[-1] }
    $Target = Request-ValidatedQuickSetTarget -Title "Save QuickSet As" -Prompt "Enter QuickSet name for $($TypeNameDisplay):" -DefaultValue $Ctx.ActiveName -TypeDir $Ctx.TypeDir
    if (-not $Target) { return }

    $null = Save-QuickSetFile -Wrapper $Ctx.TargetWrapper -QuickSetName $Target.Name

    if ($Ctx.QSMenu) {
        Set-QuickSetActiveButtonsState -QuickSetMenuItem $Ctx.QSMenu -IsEnabled $true
        Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
    }
} # function Invoke-QuickSetSaveButtonClick

function Invoke-QuickSetRenameButtonClick {
    param($s, $e)
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
} # function Invoke-QuickSetRenameButtonClick

function Invoke-QuickSetOverwriteButtonClick {
    param($s, $e)
    $Ctx = Get-QuickSetActionContext -Sender $s -RequireActiveForAction 'overwrite'
    if (-not $Ctx) { return }

    $Confirm = Show-QuickSetConfirmDialog -Title "Overwrite QuickSet" -Message "Are you sure you want to overwrite '$($Ctx.ActiveName)' with current values?"
    if (-not $Confirm) { return }

    $null = Save-QuickSetFile -Wrapper $Ctx.TargetWrapper -QuickSetName $Ctx.ActiveName

    if ($Ctx.QSMenu) {
        Update-QuickSetSubMenu -QuickSetMenuItem $Ctx.QSMenu -Wrapper $Ctx.TargetWrapper
    }
} # function Invoke-QuickSetOverwriteButtonClick

function Invoke-QuickSetDeleteButtonClick {
    param($s, $e)
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
} # function Invoke-QuickSetDeleteButtonClick

function Invoke-QuickSetClearButtonClick {
    param($s, $e)
    try {
        $Ctx = Get-QuickSetActionContext -Sender $s
        if (-not $Ctx) { return }
        Reset-WrapperQuickSet -Wrapper $Ctx.TargetWrapper -SaveCurrentValues -QuickSetMenuItem $Ctx.QSMenu
    }
    catch {
        [System.Windows.MessageBox]::Show("Error saving QuickSet: $_", "QuickSet Error") | Out-Null
    }
} # function Invoke-QuickSetClearButtonClick

function Invoke-QuickSetCloseButtonClick {
    param($s, $e)
    try {
        $Ctx = Get-QuickSetActionContext -Sender $s
        if (-not $Ctx) { return }
        Reset-WrapperQuickSet -Wrapper $Ctx.TargetWrapper -QuickSetMenuItem $Ctx.QSMenu
    }
    catch {
        [System.Windows.MessageBox]::Show("Error closing QuickSet: $_", "QuickSet Error") | Out-Null
    }
} # function Invoke-QuickSetCloseButtonClick

function Invoke-ClearButtonClick {
    param($s, $e)
    $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $ClearButtonNameSuffix
    if ($ContentWrapper) { Clear-WrapperContent ([ref]$ContentWrapper) }
} # function Invoke-ClearButtonClick

function Invoke-RandomValuesButtonClick {
    param($s, $e)
    $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $RandomValuesButtonNameSuffix
    if ($ContentWrapper) { Set-WrapperRandomContent ([ref]$ContentWrapper) }
} # function Invoke-RandomValuesButtonClick

function Invoke-DisableEnableButtonClick {
    param($s, $e)
    if ((Get-IsLocked $s)) { return }
    $IsAll = $s.Header -like '* All' -or ($s.Tag -is [hashtable] -and $s.Tag.IsAll)
    $TargetDisabledState = ($s.Icon -eq $DisableEnableButtonIconEnabled)

    Set-DisableEnableButtonVisualState -Button $s -IsDisabled $TargetDisabledState

    if ($IsAll) {
        $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $DisableEnableButtonNameSuffix
        $ChildButtons = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $s }
        :ChildButtons foreach ($ChildButton in $ChildButtons) {
            if ((Get-IsLocked $ChildButton)) { continue ChildButtons }
            Set-DisableEnableButtonVisualState -Button $ChildButton -IsDisabled $TargetDisabledState
        }
    }
    else {
        Confirm-ArrayEnableButton -Item ([ref]$s)
    }
} # function Invoke-DisableEnableButtonClick

function Invoke-DeleteButtonClick {
    param($s, $e)
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
        $Array = $ContentWrapper.Parent
        if ($Array) {
            $Array.Children.Remove($ContentWrapper)
            Sync-ArraySlotState -ContentSlot $Array
        }
    }
} # function Invoke-DeleteButtonClick

function Invoke-SearchButtonClick {
    param($s, $e)
    if ($s -and -not $s.IsEnabled) { return }
    $ContentHeaderBorder = Get-ParentWrapperBorder -Element $s -HeaderOnly
    if (-not $ContentHeaderBorder) { return }

    $ContentHeaderBorderStack = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderStackName } -FindMax 1
    if (-not $ContentHeaderBorderStack) { return }

    $SearchBar = $ContentHeaderBorderStack.Children | Where-Object { $_.Name -like "*$SearchBarNameSuffix" }
    if (-not $SearchBar) {
        $SearchBar = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -FindMax 1
    }
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
            $SearchInput.Focus()
            $SearchInput.SelectAll()
        }
    }
} # function Invoke-SearchButtonClick

function Invoke-LockUnlockButtonClick {
    param($s, $e)
    switch ($s.Icon) {
        $LockUnlockButtonIconLocked {
            $s.Header = $LockUnlockButtonHeaderUnlocked
            $s.Icon = $LockUnlockButtonIconUnlocked
            Move-MenuItemBetweenMenus -Item $s -Direction 'ToButtonMenu'
            Set-LockableButtonsState -LockButton $s -IsEnabled $true
        }
        $LockUnlockButtonIconUnlocked {
            $s.Header = $LockUnlockButtonHeaderLocked
            $s.Icon = $LockUnlockButtonIconLocked
            Move-MenuItemBetweenMenus -Item $s -Direction 'ToCustomMenu'
            Set-LockableButtonsState -LockButton $s -IsEnabled $false
        }
    }
} # function Invoke-LockUnlockButtonClick

function New-MinMaxButton {
    $MinMaxButton = New-BaseMenuItem @{
        Name    = $MinMaxButtonName
        Header  = $MinMaxButtonMinedIcon
        ToolTip = $MinMaxButtonMinedToolTip
    }
    $MinMaxButton.Add_Click({ param($s, $e) Invoke-MinMaxButtonClick $s $e })
    return $MinMaxButton
} # function New-MinMaxButton

function New-AddArrayItemButton {
    param( [type]$Type )
    $AddArrayItemButton = New-BaseMenuItem @{
        Name    = $AddArrayItemButtonName
        Tag     = $Type.FullName
        Header  = $AddArrayItemButtonIcon
        ToolTip = $AddArrayItemButtonToolTip
    }
    $AddArrayItemButton.Add_Click({ param($s, $e) Invoke-AddArrayItemButtonClick $s $e })
    Add-LockableButtonToolTip -Button $AddArrayItemButton -ToolTip $AddArrayItemButtonToolTip

    return $AddArrayItemButton
} # function New-AddArrayItemButton

function New-QuickSetMenuItem {
    param(
        [string]$ActionFrom = $ContentHeaderBorderName,
        [bool]$IsConstruct = $false
    )

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
        IsEnabled = $IsConstruct
    }
    $QuickSetMenu.Items.Add($SaveButton) | Out-Null

    $OverwriteButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$QuickSetOverwriteButtonNameSuffix"
        Header    = $QuickSetOverwriteButtonHeader
        Icon      = $QuickSetOverwriteButtonIcon
        ToolTip   = $QuickSetOverwriteButtonToolTip
        IsEnabled = $false
    }
    $QuickSetMenu.Items.Add($OverwriteButton) | Out-Null

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
    $OverwriteButton.Add_Click({ param($s, $e) Invoke-QuickSetOverwriteButtonClick $s $e })
    $RenameButton.Add_Click({ param($s, $e) Invoke-QuickSetRenameButtonClick $s $e })
    $ClearButton.Add_Click({ param($s, $e) Invoke-QuickSetClearButtonClick $s $e })
    $CloseButton.Add_Click({ param($s, $e) Invoke-QuickSetCloseButtonClick $s $e })
    $DeleteButton.Add_Click({ param($s, $e) Invoke-QuickSetDeleteButtonClick $s $e })

    # Populate the Set submenu once, the first time the QuickSet menu is loaded into the visual tree
    $LoadedState = @{ HasRefreshed = $false }
    $QuickSetMenu.Add_Loaded(({
                param($s, $e)
                if ($LoadedState.HasRefreshed) { return }
                $LoadedState.HasRefreshed = $true
                Invoke-QuickSetRefreshButtonClick $s $e
            }).GetNewClosure())

    return $QuickSetMenu
} # function New-QuickSetMenuItem

function Test-IsSimpleContentType {
    param($Type)
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
    return $false
} # function Test-IsSimpleContentType

function Get-WrapperSortableScalarValue {
    param(
        [Parameter(Mandatory)]$Wrapper,
        [switch]$SortByArrayCount
    )
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

    return $null
} # function Get-WrapperSortableScalarValue

function Get-ArrayItemSortKey {
    param(
        [Parameter(Mandatory)]$ItemWrapper,
        [string[]]$PropertyPath = @(),
        [switch]$SortByTitle,
        [switch]$SortByArrayCount
    )
    $TargetItem = Resolve-TargetElement $ItemWrapper
    if (-not $TargetItem) { return $null }

    if ($SortByTitle) {
        $DisplayName = Get-WrapperDisplayName -Wrapper $TargetItem
        if ([string]::IsNullOrWhiteSpace($DisplayName)) { return $null }
        return $DisplayName.Trim()
    }

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
    }

    if (-not $CurrentWrapper) { return $null }
    return (Get-WrapperSortableScalarValue -Wrapper $CurrentWrapper -SortByArrayCount:$SortByArrayCount)
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
    $TargetSender = Resolve-TargetElement $Sender
    if (-not $TargetSender) { return }

    $ArrayWrapper = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1)
    if (-not $ArrayWrapper) {
        $ArrayWrapper = Get-ParentWrapperBorder -Element $TargetSender -HeaderOnly
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
} # function Invoke-ArraySort

function Add-SortDirectionMenuItems {
    param(
        [Parameter(Mandatory)]$ParentMenuItem,
        [Parameter(Mandatory)][string]$ActionFrom,
        [string[]]$PropertyPath = @(),
        [switch]$SortByTitle,
        [switch]$SortByArrayCount
    )
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
} # function Add-SortDirectionMenuItems

function Add-ConstructSortPropertyMenuItems {
    param(
        [Parameter(Mandatory)]$ParentMenuItem,
        [Parameter(Mandatory)][string]$ActionFrom,
        [Parameter(Mandatory)]$ConstructType,
        [string[]]$ParentPath = @(),
        [int]$Depth = 0
    )
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
} # function Add-ConstructSortPropertyMenuItems

function New-SortMenuItem {
    param(
        [string]$ActionFrom = $ContentHeaderBorderName,
        $TargetType = $null
    )
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

    return $SortMenu
} # function New-SortMenuItem

function Get-WrapperTypeClipboardKey {
    param([Parameter(Mandatory)]$Wrapper)
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
        $IsArray = ($TitleText -like '*`[]')
    }

    if ($IsArray) {
        return "$TypeName`[]"
    }
    return $TypeName
} # function Get-WrapperTypeClipboardKey

function Test-HasClipboardForWrapper {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $false }
    $TypeKey = Get-WrapperTypeClipboardKey -Wrapper $Target
    return ($TypeClipboard -is [hashtable] -and $TypeClipboard.ContainsKey($TypeKey))
} # function Test-HasClipboardForWrapper

function Update-WrapperPasteButtonState {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-TargetElement $Wrapper
    if (-not $Target) { return }

    $Menu = Get-WrapperMenu -Wrapper $Target
    if (-not $Menu) { return }

    $IsLocked = Get-IsElementLockedSelf $Target
    $HasClipboard = Test-HasClipboardForWrapper -Wrapper $Target
    Set-MenuButtonsEnabledState -Menu $Menu -Suffixes @($PasteButtonNameSuffix) -IsEnabled ($HasClipboard -and (-not $IsLocked))
} # function Update-WrapperPasteButtonState

function Save-WrapperToTypeClipboard {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = Resolve-QuickSetWrapper $Wrapper
    if (-not $Target) { return $null }

    $TypeKey = Get-WrapperTypeClipboardKey -Wrapper $Target
    $CurrentValue = Get-WrapperQuickSetValue -Wrapper $Target
    $JsonSnapshot = ConvertTo-Json -InputObject $CurrentValue -Depth 20
    $TypeClipboard[$TypeKey] = $JsonSnapshot

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

    return $CurrentValue
} # function Save-WrapperToTypeClipboard

function Convert-QuickSetNodeToCsvRowObject {
    param($Node)
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
    return [PSCustomObject]$Row
} # function Convert-QuickSetNodeToCsvRowObject

function Convert-WrapperValueToTextFormat {
    param(
        $Value,
        [Parameter(Mandatory)][ValidateSet('JSON', 'XML', 'CSV')][string]$Format
    )
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
} # function Convert-WrapperValueToTextFormat

function Invoke-CopyButtonClick {
    param($s, $e)
    $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $CopyButtonNameSuffix
    if (-not $ContentWrapper) {
        $ContentWrapper = Get-ParentWrapperBorder -Element $s
    }
    if (-not $ContentWrapper) { return }
    $null = Save-WrapperToTypeClipboard -Wrapper $ContentWrapper
} # function Invoke-CopyButtonClick

function Invoke-CopyAsButtonClick {
    param(
        $s,
        $e,
        [Parameter(Mandatory)][string]$ActionFrom,
        [Parameter(Mandatory)][ValidateSet('JSON', 'XML', 'CSV')][string]$Format
    )
    $TargetSender = Resolve-TargetElement $s
    if (-not $TargetSender) { return }

    $ContentWrapper = Resolve-TargetElement (Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1)
    if (-not $ContentWrapper) {
        $ContentWrapper = Get-ParentWrapperBorder -Element $TargetSender
    }
    if (-not $ContentWrapper) { return }

    $CapturedValue = Save-WrapperToTypeClipboard -Wrapper $ContentWrapper
    $FormattedText = Convert-WrapperValueToTextFormat -Value $CapturedValue -Format $Format
    if ($null -eq $FormattedText) { $FormattedText = '' }
    [System.Windows.Clipboard]::SetText([string]$FormattedText)
} # function Invoke-CopyAsButtonClick

function Invoke-PasteButtonClick {
    param($s, $e)
    $ContentWrapper = Get-ContentWrapperFromButton -Button $s -Suffix $PasteButtonNameSuffix
    if (-not $ContentWrapper) {
        $ContentWrapper = Get-ParentWrapperBorder -Element $s
    }
    if (-not $ContentWrapper) { return }
    if (Get-IsElementLockedSelf $ContentWrapper) { return }

    $TypeKey = Get-WrapperTypeClipboardKey -Wrapper $ContentWrapper
    if (-not ($TypeClipboard -is [hashtable]) -or -not $TypeClipboard.ContainsKey($TypeKey)) { return }

    $JsonSnapshot = $TypeClipboard[$TypeKey]
    $ClonedValue = if ([string]::IsNullOrEmpty($JsonSnapshot)) { $null } else { ConvertFrom-Json -InputObject $JsonSnapshot }
    Set-WrapperQuickSetValue -Wrapper $ContentWrapper -Value $ClonedValue
} # function Invoke-PasteButtonClick

function Get-PasteButtonToolTip {
    param([Parameter(Mandatory)]$Button)
    if ($Button.IsEnabled) { return $PasteButtonToolTip }
    $ParentBorder = Get-ParentWrapperBorder -Element $Button
    if ($ParentBorder -and (Get-IsElementLockedSelf $ParentBorder)) {
        return "$PasteButtonToolTip`n$LockedButtonToolTip"
    }
    return "$PasteButtonToolTip`n$EmptyClipboardButtonToolTip"
} # function Get-PasteButtonToolTip

function New-CopyButton {
    param([string]$ActionFrom = $ContentHeaderBorderName)
    $CopyButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$CopyButtonNameSuffix"
        Header  = $CopyButtonHeader
        Icon    = $CopyButtonIcon
        ToolTip = $CopyButtonToolTip
    }
    $CopyButton.Add_Click({ param($s, $e) Invoke-CopyButtonClick $s $e })
    Add-LockableButtonToolTip -Button $CopyButton -ToolTip $CopyButtonToolTip
    return $CopyButton
} # function New-CopyButton

function New-CopyAsMenuItem {
    param([string]$ActionFrom = $ContentHeaderBorderName)
    $CopyAsMenu = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$CopyAsMenuNameSuffix"
        Header  = $CopyAsMenuHeader
        Icon    = $CopyAsMenuIcon
        ToolTip = $CopyAsMenuToolTip
    }
    Add-LockableButtonToolTip -Button $CopyAsMenu -ToolTip $CopyAsMenuToolTip

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
        $BoundActionFrom = $ActionFrom
        $BoundFormat = $Fmt.Format
        $FmtItem.Add_Click(({
                    param($s, $e)
                    Invoke-CopyAsButtonClick -s $s -e $e -ActionFrom $BoundActionFrom -Format $BoundFormat
                }).GetNewClosure())
        $CopyAsMenu.Items.Add($FmtItem) | Out-Null
    }

    return $CopyAsMenu
} # function New-CopyAsMenuItem

function New-PasteButton {
    param([string]$ActionFrom = $ContentHeaderBorderName)
    $PasteButton = New-BaseMenuItem @{
        Name      = "$ActionFrom`_$PasteButtonNameSuffix"
        Header    = $PasteButtonHeader
        Icon      = $PasteButtonIcon
        ToolTip   = $PasteButtonToolTip
        IsEnabled = $false
    }
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($PasteButton, $true)
    $PasteButton.Add_Click({ param($s, $e) Invoke-PasteButtonClick $s $e })
    $PasteButton.Add_ToolTipOpening({
            param($s, $e)
            $s.ToolTip = Get-PasteButtonToolTip -Button $s
        })
    return $PasteButton
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

    return @($Buttons)
} # function Get-StandardActionButtons

function New-ClearButton {
    param(
        [string]$Header = $ClearButtonHeader,
        [string]$ToolTip = $ClearButtonToolTip,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

    $ClearButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$ClearButtonNameSuffix"
        Header  = $Header
        Icon    = $ClearButtonIcon
        ToolTip = $ToolTip
    }
    $ClearButton.Add_Click({ param($s, $e) Invoke-ClearButtonClick $s $e })
    Add-LockableButtonToolTip -Button $ClearButton -ToolTip $ToolTip
    return $ClearButton
} # function New-ClearButton

function New-RandomValuesButton {
    param(
        [string]$Header = $RandomValuesButtonHeader,
        [string]$ToolTip = $RandomValuesButtonToolTip,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

    $RandomValuesButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$RandomValuesButtonNameSuffix"
        Header  = $Header
        Icon    = $RandomValuesButtonIcon
        ToolTip = $ToolTip
    }
    $RandomValuesButton.Add_Click({ param($s, $e) Invoke-RandomValuesButtonClick $s $e })
    Add-LockableButtonToolTip -Button $RandomValuesButton -ToolTip $ToolTip
    return $RandomValuesButton
} # function New-RandomValuesButton

function New-DisableEnableButton {
    param(
        [string]$Header = $DisableEnableButtonHeaderEnabled,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

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

    return $DisableEnableButton
} # function New-DisableEnableButton

function New-DeleteButton {
    param(
        [string]$Header = $DeleteButtonHeader,
        [string]$ToolTip = $DeleteButtonToolTip,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

    $DeleteButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$DeleteButtonNameSuffix"
        Header  = $Header
        Icon    = $DeleteButtonIcon
        ToolTip = $ToolTip
    }

    $DeleteButton.Add_Click({ param($s, $e) Invoke-DeleteButtonClick $s $e })
    Add-LockableButtonToolTip -Button $DeleteButton -ToolTip $ToolTip

    return $DeleteButton
} # function New-DeleteButton

function New-SearchButton {
    param(
        [string]$Header = $SearchButtonHeader,
        $Icon = $SearchButtonIcon,
        [string]$ActionFrom = $ContentHeaderBorderName,
        [bool]$IsEnabled = $true
    )

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

    return $SearchButton
} # function New-SearchButton

function New-LockButton {
    param($ActionFrom)

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

    return $LockUnlockButton
} # function New-LockButton

function Add-LockableButtonToolTip {
    param(
        [Parameter(Mandatory)]$Button,
        [Parameter(Mandatory)][string]$ToolTip
    )
    [System.Windows.Controls.ToolTipService]::SetShowOnDisabled($Button, $true)
    $BaseToolTip = $ToolTip
    $Button.Add_ToolTipOpening(({
                param($s, $e)
                $s.ToolTip = Get-LockableToolTip -Button $s -ToolTip $BaseToolTip
            }).GetNewClosure())
} # function Add-LockableButtonToolTip

function Get-LockableToolTip {
    param(
        [Parameter(Mandatory)]$Button,
        [string]$ToolTip
    )
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
    return "$ToolTip`n$LockedButtonToolTip"
} # function Get-LockableToolTip

function Get-DisableEnableButtonToolTip {
    param([Parameter(Mandatory)]$Button)
    $IsAll = $Button.Header -like '* All' -or ($Button.Tag -is [hashtable] -and $Button.Tag.IsAll)
    $IsDisabled = $Button.Icon -eq $DisableEnableButtonIconDisabled
    if ($IsAll) {
        if ($IsDisabled) { return $DisableEnableButtonAllToolTipDisabled }
        return $DisableEnableButtonAllToolTipEnabled
    }
    if ($IsDisabled) { return $DisableEnableButtonToolTipDisabled }
    return $DisableEnableButtonToolTipEnabled
} # function Get-DisableEnableButtonToolTip

function Get-LockUnlockButtonToolTip {
    param([Parameter(Mandatory)]$Button)
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
    return $LockUnlockButtonToolTipUnlocked
} # function Get-LockUnlockButtonToolTip

function Get-SearchButtonToolTip {
    param([Parameter(Mandatory)]$Button)
    if (-not $Button.IsEnabled) { return "$SearchButtonToolTip`n$EmptyArrayButtonToolTip" }
    if ($null -eq $Button.Icon) { return $SearchButtonToolTipActive }
    return $SearchButtonToolTip
} # function Get-SearchButtonToolTip

function Set-MenuButtonsEnabledState {
    param(
        [Parameter(Mandatory = $true)]$Menu,
        [Parameter(Mandatory = $true)][string[]]$Suffixes,
        [Parameter(Mandatory = $true)][bool]$IsEnabled
    )
    $TargetMenu = Resolve-TargetElement $Menu
    if (-not $TargetMenu) { return }

    :Suffixes foreach ($Suffix in $Suffixes) {
        $Buttons = Find-ObjectWhere -Object ([ref]$TargetMenu) -FindWhere { $_.Name -like "*_$Suffix" -or $_.Name -eq $Suffix }
        :Buttons foreach ($Button in @($Buttons)) {
            if ($Button) { $Button.IsEnabled = $IsEnabled }
        }
    }
} # function Set-MenuButtonsEnabledState

function Set-LockableButtonsState {
    param(
        [Parameter(Mandatory)]$LockButton,
        [Parameter(Mandatory)][bool]$IsEnabled
    )
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
} # function Set-LockableButtonsState

function Test-AncestorBorderButtonState {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][scriptblock]$ButtonSelector,
        [Parameter(Mandatory)][scriptblock]$ValueCondition
    )
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
        $Button = & $ButtonSelector $ContentBorder
        if ($Button) {
            $Value = Get-ContentValue $Button
            if (& $ValueCondition $Value) {
                return $true
            }
        }
    }

    return $false
} # function Test-AncestorBorderButtonState

function Get-IsLocked {
    param($Object)
    return Test-AncestorBorderButtonState -Object $Object `
        -ButtonSelector { param($Border) Find-ObjectWhere -Object ([ref]$Border) -FindWhere { $_.Name -eq $LockUnlockButtonName } -FindMax 1 } `
        -ValueCondition { param($Value) $Value -eq $LockUnlockButtonHeaderLocked }
} # function Get-IsLocked

function Get-IsDisabled {
    param($Object)
    return Test-AncestorBorderButtonState -Object $Object `
        -ButtonSelector { param($Border) Find-ObjectWhere -Object ([ref]$Border) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -FindMax 1 } `
        -ValueCondition { param($Value) $Value -like "$DisableEnableButtonHeaderDisabled*" }
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
    $TargetElem = Resolve-TargetElement $Element
    if (-not $TargetElem) { return $null }
    $SearchRoot = Get-WrapperMenu -Wrapper $TargetElem
    if (-not $SearchRoot) { $SearchRoot = $TargetElem }
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
    return (Resolve-TargetElement $Found)
} # function Get-WrapperOwnActionButton

function Get-IsElementLockedSelf {
    param($Element)
    $LockButton = Get-WrapperOwnActionButton -Element $Element
    if ($LockButton) {
        return ($LockButton.Icon -eq $LockUnlockButtonIconLocked)
    }
    return $false
} # function Get-IsElementLockedSelf

function Get-IsElementDisabledSelf {
    param($Element)
    $DisableButton = Get-WrapperOwnActionButton -Element $Element -IsDisableButton
    if ($DisableButton) {
        return ($DisableButton.Icon -eq $DisableEnableButtonIconDisabled)
    }
    return $false
} # function Get-IsElementDisabledSelf

function Set-TargetLockedState {
    param(
        $Target,
        [bool]$IsLocked
    )
    $LockButton = Get-WrapperOwnActionButton -Element $Target
    if (-not $LockButton) { return }

    $CurrentlyLocked = ($LockButton.Icon -eq $LockUnlockButtonIconLocked)
    if ($CurrentlyLocked -ne $IsLocked) {
        Invoke-LockUnlockButtonClick $LockButton $null
    }
} # function Set-TargetLockedState

function Get-WrapperMinMaxState {
    param($Element)
    $TargetElem = Resolve-TargetElement $Element
    if (-not $TargetElem -or $TargetElem.Name -ne $ContentHeaderBorderName) { return $null }
    $MinMaxButton = Get-WrapperOwnActionButton -Element $TargetElem -Name $MinMaxButtonName
    if (-not $MinMaxButton) { return $null }
    $ContentSlot = Get-WrapperContentSlot -Wrapper $TargetElem
    if ($ContentSlot) {
        return ($ContentSlot.Visibility -eq 'Collapsed')
    }
    return ($MinMaxButton.Header -eq $MinMaxButtonMaxedIcon)
} # function Get-WrapperMinMaxState

function Set-TargetMinMaxState {
    param(
        $Target,
        [bool]$IsMinimized
    )
    $TargetElem = Resolve-TargetElement $Target
    if (-not $TargetElem -or $TargetElem.Name -ne $ContentHeaderBorderName) { return }
    $MinMaxButton = Get-WrapperOwnActionButton -Element $TargetElem -Name $MinMaxButtonName
    $ContentSlot = Get-WrapperContentSlot -Wrapper $TargetElem
    if (-not $MinMaxButton -or -not $ContentSlot) { return }

    Set-ContentSlotCollapseState -ContentSlotElement $ContentSlot -MinMaxButton $MinMaxButton -ContentHeaderBorder $TargetElem -Collapse $IsMinimized
} # function Set-TargetMinMaxState

function Set-TargetDisabledState {
    param(
        $Target,
        [bool]$IsDisabled
    )
    $DisableButton = Get-WrapperOwnActionButton -Element $Target -IsDisableButton
    if (-not $DisableButton) { return }

    $CurrentlyDisabled = ($DisableButton.Icon -eq $DisableEnableButtonIconDisabled)
    if ($CurrentlyDisabled -ne $IsDisabled) {
        Invoke-DisableEnableButtonClick $DisableButton $null
    }
} # function Set-TargetDisabledState

#endregion #3 Button Elements

#endregion #2 Content Controls

#endregion #1 Content Controls

#endregion #0 UI Controls


#region #0 Functions

function Get-TypeConstructors {
    param([type]$Type)
    $i = 0
    try {
        $Constructors = $Type.GetConstructors()
    }
    catch {
        Write-Host "{Get-TypeConstructors} Error: $_"
        return $null
    }
    :Constructors foreach ($Constructor in $Constructors) {
        $i ++
        $Parameters = $Constructor.GetParameters()
        :Parameters foreach ($Parameter in $Parameters) {
            [PSCustomObject]@{
                Constructor  = $i
                Name         = $Parameter.Name
                Type         = $Parameter.ParameterType.FullName
                DefaultValue = $Parameter.DefaultValue
            }
            if ($Parameter.HasDefaultValue) {
                Write-Host "HasDefaultValue: $($Parameter.DefaultValue)" -ForegroundColor Yellow
            }
        } # Parameters
    } # Constructors
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
    })

$BaseWindow.ShowDialog() | Out-Null

#endregion #9 WindowBase
