<# PoshToUI
    Project:
        - Dynamic PowerShell Object Viewer
        - UI is created using PowerShell
        - No hardcoded UI
        - No Abbrevations

    To Do:
        Array Actions
            1 Random Values 
                9. FUTURE FEATURE: Customize how they generate.
            Sort - Only for Arrays.
                By: Property, Value
                Order: Ascending, Descending
            AsBlock (Delimiter*) - * Default is Comma; NewLine is always an additional delimiter (NewLine explanation in ToolTip)
                AsBoxes - switches with AsBlock, default

        DropDown
            Sort
            Search
            Filter

        Content Actions
            Search - Highlights matches
            CopyAs (JSON, CSV)

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
$LockUnlockButtonToolTipUnlocked = "Lock to protect from Random Value, Clear, Disable, and Delete"
$LockUnlockButtonToolTipLocked = "Unlock to allow Random Value, Clear, Disable, and Delete"
$LockedButtonToolTip = "Unlock to use"

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
$SearchRegexButtonHeader = '.*'
$SearchRegexButtonToolTipEnabled = "Regex Mode: ON (Alt+R to toggle)"
$SearchRegexButtonToolTipDisabled = "Regex Mode: OFF (Literal String - Alt+R to toggle)"
$SearchActionsButtonHeader = '⚡ Actions ▾'
$SearchActionsButtonToolTip = "Actions on Matches"

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

            if ($DepthMax -ne -1) {
                if ($Depth -ge $DepthMax) { return $null }
                if ($null -eq $DepthWhere ) { $Depth ++ }
                elseif ($DepthWhere.Invoke()) { $Depth ++ }
            }

            $ObjectGrandChild = Find-ObjectWhere -Object ([ref]$ObjectChild) `
                -FindWhere $FindWhere -FindMax $FindMax -AlreadyFound $AlreadyFound `
                -DigProperties $DigProperties -DepthWhere $DepthWhere -DepthMax $DepthMax -Depth $Depth
            $RecurseCount ++

            if ([bool]$ObjectGrandChild) {
                $Found += $ObjectGrandChild
                $AlreadyFound += $ObjectGrandChild.count
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

    # 4. Remove default RichTextBox padding and margins
    $RichTextBox.Document.PagePadding = '0'
    $Paragraph = New-Object System.Windows.Documents.Paragraph
    $Paragraph.Margin = '0' # Removes the weird vertical spacing

    # 5. Insert the initial text if any was provided
    if (-not [string]::IsNullOrEmpty($InitialText)) {
        $Paragraph.InLines.Add($InitialText)
    }

    $RichTextBox.Document.Blocks.Clear()
    $RichTextBox.Document.Blocks.Add($Paragraph)

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

    if ($Wrapper.Value.Name -eq 'ButtonMenu') {
        $Menu = $Wrapper.Value.Parent
    }
    else {
        $Menu = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $MenuName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
    }

    try {
        $Menu.Items.Insert($Index, $Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Add-CustomMenuChild} $_" -ForegroundColor Red
    }
} # function Add-CustomMenuChild

function Remove-CustomMenuChild {
    param( [ref]$Wrapper, [ref]$Child )
    if ($Wrapper.Value.Name -eq $MenuName) { $Menu = $Wrapper.Value }
    else {
        $Menu = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $MenuName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
    }
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

    if ($Index -eq -1) { $Index = $ButtonMenu.Items.Count }
    try {
        $ButtonMenu.Items.Insert($Index, $Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Add-ChildToItemsButtonMenu} $_" -ForegroundColor Red
    }
    $ButtonMenu.Visibility = 'Visible'
} # function Add-ChildToItemsButtonMenu

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

function Clear-WrapperContent {
    param(
        [ref]$Wrapper
    )
    $Contents = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentElementName }
    :Contents foreach ($Content in $Contents) {
        if ((Get-IsLocked ([ref]$Content))) { continue Contents } # TODO: Flash lock

        if ($Content.Uid -and $SearchOriginalStyles.ContainsKey($Content.Uid)) {
            $Content.BorderBrush = $SearchOriginalStyles[$Content.Uid].BorderBrush
            $Content.BorderThickness = $SearchOriginalStyles[$Content.Uid].BorderThickness
            $SearchOriginalStyles.Remove($Content.Uid)
        }

        switch ($Content.GetType().Name) {
            'TextBox' { $Content.Text = $null }
            'ComboBox' { $Content.SelectedItem = $null }
            'PasswordBox' { $Content.Password = $null }
            'RichTextBox' {
                $Content.Document.Blocks.Clear()
                $Paragraph = New-Object System.Windows.Documents.Paragraph
                $Paragraph.Margin = '0'
                $Content.Document.Blocks.Add($Paragraph)
            }
            default {
                Write-Host "What is this? ($($Content.GetType().Name))" -ForegroundColor Red -BackgroundColor Yellow
            }
        }
    } # Contents

    $DateTimePickers = @()
    if ($Wrapper.Value.Name -eq $CustomDateTimePickerName) {
        $DateTimePickers += $Wrapper.Value
    }
    $ChildDateTimePickers = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $CustomDateTimePickerName }
    if ($ChildDateTimePickers) {
        $DateTimePickers += $ChildDateTimePickers
    }

    :DateTimePickers foreach ($DTP in $DateTimePickers) {
        if ((Get-IsLocked ([ref]$DTP))) { continue DateTimePickers }
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox) {
            if ($DateBox.Uid -and $SearchOriginalStyles.ContainsKey($DateBox.Uid)) {
                $DateBox.BorderBrush = $SearchOriginalStyles[$DateBox.Uid].BorderBrush
                $DateBox.BorderThickness = $SearchOriginalStyles[$DateBox.Uid].BorderThickness
                $SearchOriginalStyles.Remove($DateBox.Uid)
            }
            $DateBox.Text = $null
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

        if ($Content.Uid -and $SearchOriginalStyles.ContainsKey($Content.Uid)) {
            $Content.BorderBrush = $SearchOriginalStyles[$Content.Uid].BorderBrush
            $Content.BorderThickness = $SearchOriginalStyles[$Content.Uid].BorderThickness
            $SearchOriginalStyles.Remove($Content.Uid)
        }

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
                $Content.Document.Blocks.Clear()
                $Paragraph = New-Object System.Windows.Documents.Paragraph
                $Paragraph.Margin = '0'
                $Paragraph.InLines.Add((([char[]](0..200) | Get-Random -Count 10) -join ''))
                $Content.Document.Blocks.Add($Paragraph)
            }
            default {
                Write-Host "What is this? ($($Content.GetType().Name))" -ForegroundColor Red -BackgroundColor Yellow
            }
        }
    } # Contents

    $DateTimePickers = @()
    if ($Wrapper.Value.Name -eq $CustomDateTimePickerName) {
        $DateTimePickers += $Wrapper.Value
    }
    $ChildDateTimePickers = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $CustomDateTimePickerName }
    if ($ChildDateTimePickers) {
        $DateTimePickers += $ChildDateTimePickers
    }

    :DateTimePickers foreach ($DTP in $DateTimePickers) {
        if ((Get-IsLocked ([ref]$DTP))) { continue DateTimePickers }
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox) {
            if ($DateBox.Uid -and $SearchOriginalStyles.ContainsKey($DateBox.Uid)) {
                $DateBox.BorderBrush = $SearchOriginalStyles[$DateBox.Uid].BorderBrush
                $DateBox.BorderThickness = $SearchOriginalStyles[$DateBox.Uid].BorderThickness
                $SearchOriginalStyles.Remove($DateBox.Uid)
            }
            $DateBox.Text = (Get-Date).AddDays((Get-Random -Minimum -30 -Maximum 30)).ToString('yyyy-MM-dd HH:mm:ss')
        }
    }
} # function Set-WrapperRandomContent

function Confirm-ArrayEnableButton {
    param( [ref]$Item )
    $Target = if ($Item -is [System.Management.Automation.PSReference]) { $Item.Value } else { $Item }
    if ($Target.Name -eq $ContentHeaderBorderName) {
        $ContentHeaderBorder = $Target
    }
    else {
        $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    }
    
    if (-not $ContentHeaderBorder) { return }

    $ContentHeaderBorderTitle = Find-Title $ContentHeaderBorder

    # If Wrapper is not an Array, Get GrandWrapper
    if ($ContentHeaderBorderTitle -notlike '*`[]') {
        $GrandWrapper = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
        if ($GrandWrapper) { $ContentHeaderBorder = $GrandWrapper }
    }

    $ArrayButton = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
    if (-not $ArrayButton) { return }

    $ItemButtons = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $ArrayButton }
    $ItemCount = if ($ItemButtons) { @($ItemButtons).Count } else { 0 }

    if ($ItemCount -eq 0) {
        if ($ArrayButton.Icon -eq $DisableEnableButtonIconDisabled) {
            $ArrayParent = $ArrayButton.Parent
            $ArrayButton.Header = $DisableEnableButtonHeaderEnabled + ' All'
            $ArrayButton.Icon = $DisableEnableButtonIconEnabled
            $TargetIndex = if ($ArrayButton.Tag -is [hashtable]) { $ArrayButton.Tag.Index } else { $ArrayButton.Tag }
            Remove-CustomMenuChild ([ref]$ArrayParent) ([ref]$ArrayButton)
            Add-ChildToItemsButtonMenu ([ref]$ArrayParent) ([ref]$ArrayButton) $TargetIndex
            $ArrayButton.Tag = $null
        }
        return
    }

    $DisabledButtons = $ItemButtons | Where-Object { $null -eq $_.Icon }
    $DisabledCount = if ($DisabledButtons) { @($DisabledButtons).Count } else { 0 }

    if ($DisabledCount -eq $ItemCount) {
        if ($ArrayButton.Icon -eq $DisableEnableButtonIconEnabled) {
            $ArrayParent = $ArrayButton.Parent
            $ArrayButton.Tag = @{ Index = $ArrayParent.Items.IndexOf($ArrayButton); IsAll = $true }
            $ArrayButton.Header = $DisableEnableButtonHeaderDisabled + ' All'
            $ArrayButton.Icon = $DisableEnableButtonIconDisabled
            Remove-ChildToItemsButtonMenu ([ref]$ArrayParent) ([ref]$ArrayButton)
            Add-CustomMenuChild ([ref]$ArrayParent) ([ref]$ArrayButton)
        }
    }
    elseif ($DisabledCount -eq 0) {
        if ($ArrayButton.Icon -eq $DisableEnableButtonIconDisabled) {
            $ArrayParent = $ArrayButton.Parent
            $ArrayButton.Header = $DisableEnableButtonHeaderEnabled + ' All'
            $ArrayButton.Icon = $DisableEnableButtonIconEnabled
            $TargetIndex = if ($ArrayButton.Tag -is [hashtable]) { $ArrayButton.Tag.Index } else { $ArrayButton.Tag }
            Remove-CustomMenuChild ([ref]$ArrayParent) ([ref]$ArrayButton)
            Add-ChildToItemsButtonMenu ([ref]$ArrayParent) ([ref]$ArrayButton) $TargetIndex
            $ArrayButton.Tag = $null
        }
    }
} # function Confirm-ArrayEnableButton

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

    $IsArray = ($null -ne $Type -and $Type.IsArray) -or ($Description -match '\[\]')
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

    # Array Setting Differences
    if ($IsArray) {
        $ClearButton = Find-ObjectWhere -Object ([ref]$ContentHeaderButtonMenu) -FindWhere { $_.Name -like "*$ClearButtonNameSuffix" }
        if ($ClearButton) { $ClearButton.Header = $ClearButtonHeader + 's' }
        $RandomValuesButton = Find-ObjectWhere -Object ([ref]$ContentHeaderButtonMenu) -FindWhere { $_.Name -like "*$RandomValuesButtonNameSuffix" }
        if ($RandomValuesButton) { $RandomValuesButton.Header = $RandomValuesButtonHeader + 's' }
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

    $Menu = Find-ObjectWhere -Object ([ref]$Top) -FindWhere { $_.Name -eq $MenuName } -FindMax 1

    # For non-Construct, non-Array items, add Search to ButtonMenu above the Lock button
    if (-not $IsConstruct -and -not $IsArrayType -and $ArrayType -ne 'ArrayItem') {
        $SearchButton = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" }
        if ($null -eq $SearchButton) {
            $SearchButton = New-SearchButton -Header $SearchButtonHeader -Icon $SearchButtonIcon -ActionFrom $Top.Name
            Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$SearchButton)
        }
    }

    $QuickSetButton = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" }
    if ($null -eq $QuickSetButton) {
        $QuickSetButton = New-QuickSetMenuItem -ActionFrom $Top.Name -IsConstruct $IsConstruct
        Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$QuickSetButton)
    }

    $LockButton = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $LockUnlockButtonName }
    if ($null -eq $LockButton) {
        $LockButton = New-LockButton -ActionFrom $Top.Name
        Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$LockButton)
    }

    $RandomValuesButton = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$RandomValuesButtonNameSuffix" }
    if ($null -eq $RandomValuesButton) {
        $RandomValuesButton = New-RandomValuesButton -ActionFrom $Top.Name
        Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$RandomValuesButton)
    }

    $ClearButton = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$ClearButtonNameSuffix" }
    if ($null -eq $ClearButton) {
        $ClearButton = New-ClearButton -ActionFrom $Top.Name
        Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$ClearButton)
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
            Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$(New-BaseSeparator)) 0
            Add-ChildToItemsButtonMenu ([ref]$Top) ([ref]$ConstructButton) 0
        }
        else {
            Add-CustomMenuChild ([ref]$Top) ([ref]$ConstructButton)
            $SearchButton = New-SearchButton -ActionFrom $Top.Name
            Add-CustomMenuChild ([ref]$Top) ([ref]$SearchButton)
        }
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

        # Button: Search
        $SearchButton = New-SearchButton -ActionFrom $Wrapper.Value.Name
        Add-CustomMenuChild $Wrapper ([ref]$SearchButton)

        # Button: QuickSet
        $QuickSetButton = New-QuickSetMenuItem -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$QuickSetButton)

        # Button: Lock, Unlock All
        $LockUnlockButton = New-LockButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$LockUnlockButton)

        # Button: Random Values All
        $RandomValuesButton = New-RandomValuesButton -Header "$($RandomValuesButtonHeader + 's')" -ToolTip $RandomValuesButtonAllToolTip -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$RandomValuesButton)

        # Button: Clear All
        $ClearButton = New-ClearButton -Header "$($ClearButtonHeader + 's')" -ToolTip $ClearButtonAllToolTip -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$ClearButton)

        # Button: Enable/Disable All
        $DisableEnableButton = New-DisableEnableButton -Header ($DisableEnableButtonHeaderEnabled + ' All') -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$DisableEnableButton)

        # Button: Delete All
        $DeleteButton = New-DeleteButton -Header ($DeleteButtonHeader + ' All') -ToolTip $DeleteButtonAllToolTip -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$DeleteButton)
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

        # Button: QuickSet
        $QuickSetButton = New-QuickSetMenuItem -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$QuickSetButton)

        # Button: Lock, Unlock All
        $LockUnlockButton = New-LockButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$LockUnlockButton)

        # Button: Random Values
        $RandomValuesButton = New-RandomValuesButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$RandomValuesButton)

        # Button: Clear
        $ClearButton = New-ClearButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$ClearButton)

        # Button: Enable/Disable
        $DisableEnableButton = New-DisableEnableButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$DisableEnableButton)

        # Button: Delete
        $DeleteButton = New-DeleteButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$DeleteButton)

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

    if ([bool]$Value) { return $Value }
    else { return $null }
} # function Get-ContentValue

#endregion #4 Content Value

#region #4 QuickSet

function Invoke-QuickSetInputDialogResult {
    param($Dialog, [string]$Value = $null, [bool]$DialogResult = $false)
    $script:QuickSetDialogResult = $Value
    $Dialog.DialogResult = $DialogResult
    $Dialog.Close()
} # function Invoke-QuickSetInputDialogResult


function Show-QuickSetInputDialog {
    param(
        [string]$Title = 'QuickSet',
        [string]$Prompt = 'Enter name:',
        [string]$DefaultValue = ''
    )
    $Dialog = New-Object System.Windows.Window
    $Dialog.Title = $Title
    $Dialog.Width = 380
    $Dialog.Height = 160
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

    $OkButton = New-BaseButton @{
        Content         = 'OK'
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
    $ButtonStack.Children.Add($OkButton) | Out-Null

    $CancelButton = New-BaseButton @{
        Content         = 'Cancel'
        Width           = 70
        Height          = 26
        Background      = 'Transparent'
        Foreground      = '#EDEAFA'
        BorderBrush     = '#7A6E94'
        BorderThickness = 1
        Cursor          = 'Hand'
        IsCancel        = $true
    }
    $ButtonStack.Children.Add($CancelButton) | Out-Null

    $PromptLabel = New-BaseTextBlock @{
        Text       = $Prompt
        Foreground = '#EDEAFA'
        FontSize   = 11
        Margin     = '0,0,0,6'
    }
    [System.Windows.Controls.DockPanel]::SetDock($PromptLabel, 'Top')
    $Dock.Children.Add($PromptLabel) | Out-Null

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
    $Dock.Children.Add($InputBox) | Out-Null

    $script:QuickSetDialogResult = $null
    $OkButton.Add_Click({ Invoke-QuickSetInputDialogResult -Dialog $Dialog -Value $InputBox.Text -DialogResult $true })
    $CancelButton.Add_Click({ Invoke-QuickSetInputDialogResult -Dialog $Dialog -DialogResult $false })


    $Dialog.Add_Loaded({
            $InputBox.Focus() | Out-Null
            $InputBox.SelectAll()
        })

    $null = $Dialog.ShowDialog()
    return $script:QuickSetDialogResult
} # function Show-QuickSetInputDialog

function Invoke-QuickSetConfirmDialogResult {
    param($Dialog, [bool]$Result = $false)
    $script:QuickSetConfirmResult = $Result
    $Dialog.DialogResult = $Result
    $Dialog.Close()
} # function Invoke-QuickSetConfirmDialogResult


function Show-QuickSetConfirmDialog {
    param(
        [string]$Title = 'Confirm',
        [string]$Message = 'Are you sure?'
    )
    $Dialog = New-Object System.Windows.Window
    $Dialog.Title = $Title
    $Dialog.Width = 380
    $Dialog.Height = 150
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

    $YesButton = New-BaseButton @{
        Content         = 'Yes'
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
    $ButtonStack.Children.Add($YesButton) | Out-Null

    $NoButton = New-BaseButton @{
        Content         = 'No'
        Width           = 70
        Height          = 26
        Background      = 'Transparent'
        Foreground      = '#EDEAFA'
        BorderBrush     = '#7A6E94'
        BorderThickness = 1
        Cursor          = 'Hand'
        IsCancel        = $true
    }
    $ButtonStack.Children.Add($NoButton) | Out-Null

    $MsgBlock = New-BaseTextBlock @{
        Text              = $Message
        Foreground        = '#EDEAFA'
        FontSize          = 11
        TextWrapping      = 'Wrap'
        VerticalAlignment = 'Center'
    }
    $Dock.Children.Add($MsgBlock) | Out-Null

    $script:QuickSetConfirmResult = $false
    $YesButton.Add_Click({ Invoke-QuickSetConfirmDialogResult -Dialog $Dialog -Result $true })
    $NoButton.Add_Click({ Invoke-QuickSetConfirmDialogResult -Dialog $Dialog -Result $false })


    $null = $Dialog.ShowDialog()
    return $script:QuickSetConfirmResult
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
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
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
    $Target = if ($s -is [System.Management.Automation.PSReference]) { $s.Value } else { $s }
    if ($Target -is [array]) { $Target = $Target[0] }
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
    $TargetSender = if ($s -is [System.Management.Automation.PSReference]) { $s.Value } else { $s }
    if ($TargetSender -is [array]) { $TargetSender = $TargetSender[0] }

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
        $ContentWrapper = Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { $_.Name -eq $ActionFrom } -DigProperties 'Parent' -FindMax 1
    }
    if (-not $ContentWrapper) {
        $ContentWrapper = Find-ObjectWhere -Object ([ref]$TargetSender) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent' -FindMax 1
    }
    if ($ContentWrapper -is [array]) { return $ContentWrapper[0] }
    return $ContentWrapper
} # function Get-QuickSetWrapper

function Get-WrapperHeaderTitleElement {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
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
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
    if (-not $Target) { return $false }

    if ($Target.Tag -is [hashtable] -and $Target.Tag.ContainsKey('ArrayItem') -and $Target.Tag.ArrayItem) {
        return $true
    }

    $ItemStack = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ArrayItemStackName } -DepthMax 2 -FindMax 1
    return ($null -ne $ItemStack)
} # function Get-IsArrayItem

function Get-WrapperDisplayName {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
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
    $Menu = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $MenuName } -FindMax 1
    if ($Menu -is [array]) { $Menu = $Menu[0] }
    if ($Menu) {
        $ExistingBadge = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $BadgeName } -FindMax 1
        if ($ExistingBadge -is [array]) { $ExistingBadge = $ExistingBadge[0] }
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
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
    if (-not $Target) { return }

    if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
        if (-not ($Target.Tag -is [hashtable])) { $Target.Tag = @{} }
        $Target.Tag.ActiveQuickSet = $DisplayName

        $TitleElement = Get-WrapperHeaderTitleElement $Target
        if ($TitleElement -is [System.Windows.Controls.TextBox] -and -not $TitleElement.IsReadOnly) {
            if (-not $Target.Tag.ContainsKey('OriginalTitle')) {
                $Target.Tag.OriginalTitle = $TitleElement.Text
            }
            $TitleElement.Text = $DisplayName
        }

        Update-QuickSetBadge -Wrapper $Target -DisplayName $DisplayName

        $QSMenu = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -FindMax 1
        if ($QSMenu -is [array]) { $QSMenu = $QSMenu[0] }
        if ($QSMenu) {
            Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $Target
        }
    }
    else {
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
    }
} # function Set-WrapperDisplayName

function Get-WrapperQuickSetValue {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
    if (-not $Target) { return $null }

    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

    $AddButton = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$AddArrayItemButtonName*" } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    $ContentSlot = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1

    if ($AddButton -and $ContentSlot) {
        $List = [System.Collections.ArrayList]@()
        foreach ($Child in @($ContentSlot.Children)) {
            $ChildVal = Get-WrapperQuickSetValue -Wrapper $Child
            [void]$List.Add($ChildVal)
        }
        return , @($List)
    }

    $RawValue = $null

    $Construct = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ConstructName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($Construct) {
        $ObjMap = [ordered]@{}
        foreach ($Child in @($Construct.Children)) {
            $Title = Find-Title $Child
            $ParamName = if ($Title) { ($Title.Split('-')[0]).Trim() } else { $Child.Name }
            $ObjMap[$ParamName] = Get-WrapperQuickSetValue -Wrapper $Child
        }
        $RawValue = $ObjMap
    }
    else {
        $Content = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
        if ($Content) {
            $RawValue = (Get-ContentValue -Object $Content)
        }
        else {
            $DTP = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
            if ($DTP) {
                $RawValue = (Get-ContentValue -Object $DTP)
            }
        }
    }

    if (Get-IsArrayItem -Wrapper $Target) {
        $ChildDisplayName = Get-WrapperDisplayName -Wrapper $Target
        return [ordered]@{
            displayName = $ChildDisplayName
            value       = $RawValue
        }
    }

    return $RawValue
} # function Get-WrapperQuickSetValue

function Set-WrapperQuickSetValue {
    param(
        [Parameter(Mandatory)]$Wrapper,
        $Value
    )
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
    if (-not $Target) { return }

    if ((Get-IsLocked ([ref]$Target))) { return }

    if ($Target.Uid -and $SearchOriginalStyles.ContainsKey($Target.Uid)) {
        $Target.BorderBrush = $SearchOriginalStyles[$Target.Uid].BorderBrush
        $Target.BorderThickness = $SearchOriginalStyles[$Target.Uid].BorderThickness
        $SearchOriginalStyles.Remove($Target.Uid)
    }

    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

    $AddButton = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$AddArrayItemButtonName*" } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    $ContentSlot = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1

    if ($AddButton -and $ContentSlot) {
        $List = @($Value)
        while ($ContentSlot.Children.Count -lt $List.Count) {
            $AddButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
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
        Confirm-ArrayEnableButton -Item ([ref]$ContentSlot)

        for ($i = 0; $i -lt $List.Count; $i++) {
            Set-WrapperQuickSetValue -Wrapper $ContentSlot.Children[$i] -Value $List[$i]
        }
        return
    }

    # If this is not an array, unpack { displayName, value } if present
    $ActualValue = $Value
    $HasExplicitDisplayName = $false
    $ItemDisplayName = $null

    if ($Value -is [System.Collections.IDictionary]) {
        if ($Value.Contains('displayName') -or $Value.Contains('DisplayName')) {
            $HasExplicitDisplayName = $true
            if ($Value.Contains('value')) {
                $ActualValue = $Value['value']
                $ItemDisplayName = if ($Value.Contains('displayName')) { $Value['displayName'] } else { $Value['DisplayName'] }
            }
            elseif ($Value.Contains('Value')) {
                $ActualValue = $Value['Value']
                $ItemDisplayName = if ($Value.Contains('displayName')) { $Value['displayName'] } else { $Value['DisplayName'] }
            }
        }
        elseif ($Value.Contains('value') -and $Value.Keys.Count -eq 1) {
            $ActualValue = $Value['value']
        }
    }
    elseif ($Value -is [System.Management.Automation.PSCustomObject]) {
        $HasProp = $null -ne $Value.PSObject.Properties['displayName'] -or $null -ne $Value.PSObject.Properties['DisplayName']
        if ($HasProp) {
            $HasExplicitDisplayName = $true
            if ($null -ne $Value.PSObject.Properties['value']) {
                $ActualValue = $Value.value
                $ItemDisplayName = if ($null -ne $Value.PSObject.Properties['displayName']) { $Value.displayName } else { $Value.DisplayName }
            }
            elseif ($null -ne $Value.PSObject.Properties['Value']) {
                $ActualValue = $Value.Value
                $ItemDisplayName = if ($null -ne $Value.PSObject.Properties['displayName']) { $Value.displayName } else { $Value.DisplayName }
            }
        }
        elseif ($null -ne $Value.PSObject.Properties['value'] -and $Value.PSObject.Properties.Count -eq 1) {
            $ActualValue = $Value.value
        }
    }

    if ($HasExplicitDisplayName) {
        Set-WrapperDisplayName -Wrapper $Target -DisplayName $ItemDisplayName
    }

    $Value = $ActualValue

    $Construct = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ConstructName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($Construct -and $null -ne $Value) {
        $PropNames = if ($Value -is [System.Collections.IDictionary]) {
            @($Value.Keys)
        }
        elseif ($Value -is [System.Management.Automation.PSCustomObject]) {
            @($Value.PSObject.Properties.Name)
        }
        else {
            @()
        }

        foreach ($Prop in $PropNames) {
            $ChildParam = Find-ObjectWhere -Object ([ref]$Construct) -FindWhere {
                $T = Find-Title $_
                if ($T) {
                    $NamePart = ($T.Split('-')[0]).Trim()
                    $NamePart -eq $Prop
                }
                else {
                    $_.Name -eq $Prop
                }
            } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1

            if ($ChildParam) {
                $PropVal = if ($Value -is [System.Collections.IDictionary]) { $Value[$Prop] } else { $Value.$Prop }
                Set-WrapperQuickSetValue -Wrapper $ChildParam -Value $PropVal
            }
        }
        return
    }

    $Content = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($Content) {
        if ((Get-IsLocked ([ref]$Content))) { return }
        if ($Content.Uid -and $SearchOriginalStyles.ContainsKey($Content.Uid)) {
            $Content.BorderBrush = $SearchOriginalStyles[$Content.Uid].BorderBrush
            $Content.BorderThickness = $SearchOriginalStyles[$Content.Uid].BorderThickness
            $SearchOriginalStyles.Remove($Content.Uid)
        }

        switch ($Content.GetType().Name) {
            'TextBox' {
                $Content.Text = if ($null -ne $Value) { [string]$Value } else { '' }
            }
            'ComboBox' {
                if ($null -ne $Value) {
                    $Content.SelectedItem = $Value
                    if ($null -eq $Content.SelectedItem -and $Content.ItemsSource) {
                        $MatchItem = @($Content.ItemsSource) | Where-Object { $_.ToString() -eq $Value.ToString() } | Select-Object -First 1
                        if ($MatchItem) { $Content.SelectedItem = $MatchItem }
                    }
                }
            }
            'PasswordBox' {
                $Content.Password = if ($null -ne $Value) { [string]$Value } else { '' }
            }
            'RichTextBox' {
                $Content.Document.Blocks.Clear()
                $Paragraph = New-Object System.Windows.Documents.Paragraph
                $Paragraph.Margin = '0'
                $Paragraph.InLines.Add([string]$Value)
                $Content.Document.Blocks.Add($Paragraph)
            }
        }
        return
    }

    $DTP = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($DTP) {
        if ((Get-IsLocked ([ref]$DTP))) { return }
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox) {
            if ($DateBox.Uid -and $SearchOriginalStyles.ContainsKey($DateBox.Uid)) {
                $DateBox.BorderBrush = $SearchOriginalStyles[$DateBox.Uid].BorderBrush
                $DateBox.BorderThickness = $SearchOriginalStyles[$DateBox.Uid].BorderThickness
                $SearchOriginalStyles.Remove($DateBox.Uid)
            }
            $DateBox.Text = if ($null -ne $Value) { [string]$Value } else { '' }
        }
        return
    }
} # function Set-WrapperQuickSetValue

function Clear-WrapperQuickSetValue {
    param([Parameter(Mandatory)]$Wrapper)
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
    if (-not $Target) { return }

    if ((Get-IsLocked ([ref]$Target))) { return }

    if ($Target.Uid -and $SearchOriginalStyles.ContainsKey($Target.Uid)) {
        $Target.BorderBrush = $SearchOriginalStyles[$Target.Uid].BorderBrush
        $Target.BorderThickness = $SearchOriginalStyles[$Target.Uid].BorderThickness
        $SearchOriginalStyles.Remove($Target.Uid)
    }

    $StopAtChild = { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name }

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
    $AddButton = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$AddArrayItemButtonName*" } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    $ContentSlot = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($AddButton -and $ContentSlot) {
        :DeleteArrayItems foreach ($Child in @($ContentSlot.Children)) {
            if ((Get-IsLocked $Child)) { continue DeleteArrayItems }
            $ContentSlot.Children.Remove($Child)
        }
        Reset-ArrayIndexes ([ref]$ContentSlot)
        Confirm-ArrayEnableButton -Item ([ref]$ContentSlot)
        return
    }

    # 2. Object constructor: recurse on each parameter wrapper
    $Construct = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ConstructName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($Construct) {
        foreach ($Child in @($Construct.Children)) {
            Clear-WrapperQuickSetValue -Wrapper $Child
        }
        return
    }

    # 3. Direct content controls
    $Content = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $ContentElementName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($Content) {
        if ((Get-IsLocked ([ref]$Content))) { return }
        if ($Content.Uid -and $SearchOriginalStyles.ContainsKey($Content.Uid)) {
            $Content.BorderBrush = $SearchOriginalStyles[$Content.Uid].BorderBrush
            $Content.BorderThickness = $SearchOriginalStyles[$Content.Uid].BorderThickness
            $SearchOriginalStyles.Remove($Content.Uid)
        }
        switch ($Content.GetType().Name) {
            'TextBox' { $Content.Text = '' }
            'ComboBox' {
                $Content.SelectedItem = $null
                $Content.Text = ''
            }
            'PasswordBox' { $Content.Password = '' }
            'RichTextBox' {
                $Content.Document.Blocks.Clear()
                $Paragraph = New-Object System.Windows.Documents.Paragraph
                $Paragraph.Margin = '0'
                $Content.Document.Blocks.Add($Paragraph)
            }
        }
        return
    }

    $DTP = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $CustomDateTimePickerName } -DepthMax 1 -DepthWhere $StopAtChild -FindMax 1
    if ($DTP) {
        if ((Get-IsLocked ([ref]$DTP))) { return }
        $DateBox = Find-ObjectWhere -Object ([ref]$DTP) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName } -FindMax 1
        if ($DateBox) {
            if ($DateBox.Uid -and $SearchOriginalStyles.ContainsKey($DateBox.Uid)) {
                $DateBox.BorderBrush = $SearchOriginalStyles[$DateBox.Uid].BorderBrush
                $DateBox.BorderThickness = $SearchOriginalStyles[$DateBox.Uid].BorderThickness
                $SearchOriginalStyles.Remove($DateBox.Uid)
            }
            $DateBox.Text = ''
        }
        return
    }
} # function Clear-WrapperQuickSetValue

function Set-QuickSetActiveButtonsState {
    param(
        [Parameter(Mandatory)]$QuickSetMenuItem,
        [Parameter(Mandatory)][bool]$IsEnabled
    )
    $QSMenu = if ($QuickSetMenuItem -is [System.Management.Automation.PSReference]) { $QuickSetMenuItem.Value } else { $QuickSetMenuItem }
    if ($QSMenu -is [array]) { $QSMenu = $QSMenu[0] }
    if (-not $QSMenu) { return }

    $ActiveOnlyButtonSuffixes = @(
        $QuickSetSaveButtonNameSuffix
        $QuickSetOverwriteButtonNameSuffix
        $QuickSetRenameButtonNameSuffix
        $QuickSetClearButtonNameSuffix
        $QuickSetCloseButtonNameSuffix
        $QuickSetDeleteButtonNameSuffix
    )

    foreach ($Suffix in $ActiveOnlyButtonSuffixes) {
        $Item = Find-ObjectWhere -Object ([ref]$QSMenu) -FindWhere { $_.Name -like "*_$Suffix" } -FindMax 1
        if ($Item -is [array]) { $Item = $Item[0] }
        if ($Item) {
            $Item.IsEnabled = $IsEnabled
        }
    }
} # function Set-QuickSetActiveButtonsState

function Invoke-ExistingBadgeClick {
    param($s, $e)
    if ($e) { $e.Handled = $true }
    try {
        $TargetWrapper = if ($s.Tag) { $s.Tag } else { Get-QuickSetWrapper $s }
        if (-not $TargetWrapper) { return }

        $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet') -and -not [string]::IsNullOrWhiteSpace($TargetWrapper.Tag.ActiveQuickSet)) {
            $TargetWrapper.Tag.ActiveQuickSet
        }
        elseif (-not [string]::IsNullOrWhiteSpace($s.ToolTip)) {
            $s.ToolTip
        }
        else { $null }

        if (-not [string]::IsNullOrWhiteSpace($ActiveName)) {
            $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
            $TypeDir = Get-QuickSetTypeDirectory -Type $Type
            $CleanName = $ActiveName -replace '[\\/:*?"<>|]', '_'
            $FilePath = Join-Path $TypeDir "$CleanName.json"

            Set-WrapperDisplayName -Wrapper $TargetWrapper -DisplayName $CleanName

            $CurrentValue = Get-WrapperQuickSetValue -Wrapper $TargetWrapper
            $JsonText = ConvertTo-Json -InputObject $CurrentValue -Depth 20
            Set-Content -LiteralPath $FilePath -Value $JsonText -Encoding UTF8
        }

        Clear-WrapperQuickSetValue -Wrapper $TargetWrapper

        if (-not ($TargetWrapper.Tag -is [hashtable])) { $TargetWrapper.Tag = @{} }
        $TargetWrapper.Tag.ActiveQuickSet = $null
        Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $null

        $QSMenu = Find-ObjectWhere -Object ([ref]$TargetWrapper) -FindWhere { $_.Name -like "*$QuickSetMenuNameSuffix" } -FindMax 1
        if ($QSMenu) {
            Set-QuickSetActiveButtonsState -QuickSetMenuItem $QSMenu -IsEnabled $false
            Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
        }
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
    $Target = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($Target -is [array]) { $Target = $Target[0] }
    if (-not $Target) { return }

    $Menu = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -eq $MenuName } -FindMax 1
    if ($Menu -is [array]) { $Menu = $Menu[0] }
    if (-not $Menu) { return }

    $BadgeName = "$($Target.Name)_$QuickSetBadgeNameSuffix"
    $ExistingBadge = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -eq $BadgeName } -FindMax 1
    if ($ExistingBadge -is [array]) { $ExistingBadge = $ExistingBadge[0] }

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

        Set-WrapperDisplayName -Wrapper $WrapperToUpdate -DisplayName $TargetName
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
    $TargetWrapper = if ($Wrapper -is [System.Management.Automation.PSReference]) { $Wrapper.Value } else { $Wrapper }
    if ($TargetWrapper -is [array]) { $TargetWrapper = $TargetWrapper[0] }
    if (-not $TargetWrapper) { return }

    $QSMenu = if ($QuickSetMenuItem -is [System.Management.Automation.PSReference]) { $QuickSetMenuItem.Value } else { $QuickSetMenuItem }
    if ($QSMenu -is [array]) { $QSMenu = $QSMenu[0] }
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

function Expand-ElementParents {
    param([Parameter(Mandatory)]$Element)
    $Curr = $Element
    while ($Curr -and $Curr -ne $BaseWindow) {
        $Parent = $Curr.Parent
        if (-not $Parent) { break }

        if ($Parent.Name -eq $ContentSlotElementName -and $Parent.Visibility -ne 'Visible') {
            $Parent.Visibility = 'Visible'
            $HeaderBorder = Find-ObjectWhere -Object ([ref]$Parent) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent' -FindMax 1
            if ($HeaderBorder) {
                $MinMaxButton = Find-ObjectWhere -Object ([ref]$HeaderBorder) -FindWhere { $_.Name -eq $MinMaxButtonName } -FindMax 1
                if ($MinMaxButton) {
                    $MinMaxButton.Header = $MinMaxButtonMinedIcon
                    $MinMaxButton.ToolTip = $MinMaxButtonMinedToolTip
                }
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
    $Target = if ($Element -is [System.Management.Automation.PSReference]) { $Element.Value } else { $Element }
    if (-not $Target) { return }

    if ([string]::IsNullOrEmpty($Target.Uid)) {
        $Target.Uid = [guid]::NewGuid().ToString()
    }

    # Expand any collapsed parent container so this item is visible
    Expand-ElementParents -Element $Target

    $BrushConverter = [System.Windows.Media.BrushConverter]::new()

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

        # Also highlight its immediate field border (e.g. MiniHeader) so the field is clearly identifiable
        $ParentFieldBorder = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent' -FindMax 1
        if ($ParentFieldBorder) {
            Set-BorderHighlight -Target $ParentFieldBorder -HighlightType $HighlightType
        }
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

        if ($HighlightType -eq 'Active') {
            $Target.BorderBrush = $BrushConverter.ConvertFromString('#E67E22')
            $Target.BorderThickness = [System.Windows.Thickness]::new(3.5)
        }
        else {
            $Target.BorderBrush = $BrushConverter.ConvertFromString('#F1C40F')
            $Target.BorderThickness = [System.Windows.Thickness]::new(2.5)
        }

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

        # Also highlight parent field border if inside one
        $ParentFieldBorder = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent' -FindMax 1
        if ($ParentFieldBorder) {
            Set-BorderHighlight -Target $ParentFieldBorder -HighlightType $HighlightType
        }
    }
    else {
        if (-not $SearchOriginalStyles.ContainsKey($Target.Uid)) {
            $SearchOriginalStyles[$Target.Uid] = @{
                Element         = $Target
                Type            = 'Control'
                BorderBrush     = $Target.BorderBrush
                BorderThickness = $Target.BorderThickness
            }
        }

        if ($HighlightType -eq 'Active') {
            $Target.BorderBrush = $BrushConverter.ConvertFromString('#E67E22')
            $Target.BorderThickness = [System.Windows.Thickness]::new(3.5)
        }
        else {
            $Target.BorderBrush = $BrushConverter.ConvertFromString('#F1C40F')
            $Target.BorderThickness = [System.Windows.Thickness]::new(2.5)
        }

        # If it's a content control inside a field (e.g. MiniHeader), also highlight the parent field border
        if ($Target.Name -eq $ContentElementName -or $Target.Name -eq $ContentDateTimeDisplayTextBoxName) {
            $ParentFieldBorder = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent' -FindMax 1
            if ($ParentFieldBorder) {
                Set-BorderHighlight -Target $ParentFieldBorder -HighlightType $HighlightType
            }
        }
    }
} # function Set-ElementHighlight

function Reset-ElementHighlight {
    param([Parameter(Mandatory)][ref]$Element)
    $Target = if ($Element -is [System.Management.Automation.PSReference]) { $Element.Value } else { $Element }
    if (-not $Target) { return }

    if ($Target.Uid -and $SearchOriginalStyles.ContainsKey($Target.Uid)) {
        $Original = $SearchOriginalStyles[$Target.Uid]
        if ($Original.Type -eq 'TextBlock') {
            $Target.Background = $Original.Background
            $Target.Foreground = $Original.Foreground
            $Target.FontWeight = $Original.FontWeight
        }
        elseif ($Original.Type -eq 'RichTextBox') {
            $Target.BorderBrush = $Original.BorderBrush
            $Target.BorderThickness = $Original.BorderThickness
            if ($null -ne $Original.OriginalText) {
                $Paragraph = New-Object System.Windows.Documents.Paragraph
                $Paragraph.Margin = [System.Windows.Thickness]::new(0)
                $Paragraph.Inlines.Add($Original.OriginalText) | Out-Null
                $Target.Document.Blocks.Clear()
                $Target.Document.Blocks.Add($Paragraph)
            }
        }
        else {
            $Target.BorderBrush = $Original.BorderBrush
            $Target.BorderThickness = $Original.BorderThickness
        }
        $SearchOriginalStyles.Remove($Target.Uid)
    }

    # Reset parent field border if it was highlighted
    $ParentFieldBorder = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent' -FindMax 1
    if ($ParentFieldBorder -and $ParentFieldBorder.Uid -and $SearchOriginalStyles.ContainsKey($ParentFieldBorder.Uid)) {
        $BorderOrig = $SearchOriginalStyles[$ParentFieldBorder.Uid]
        $ParentFieldBorder.BorderBrush = $BorderOrig.BorderBrush
        $ParentFieldBorder.BorderThickness = $BorderOrig.BorderThickness
        $SearchOriginalStyles.Remove($ParentFieldBorder.Uid)
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
                $El = $Entry.Element
                if ($Entry.Type -eq 'TextBlock') {
                    $El.Background = $Entry.Background
                    $El.Foreground = $Entry.Foreground
                    $El.FontWeight = $Entry.FontWeight
                }
                elseif ($Entry.Type -eq 'RichTextBox') {
                    $El.BorderBrush = $Entry.BorderBrush
                    $El.BorderThickness = $Entry.BorderThickness
                    if ($null -ne $Entry.OriginalText) {
                        $Paragraph = New-Object System.Windows.Documents.Paragraph
                        $Paragraph.Margin = [System.Windows.Thickness]::new(0)
                        $Paragraph.Inlines.Add($Entry.OriginalText) | Out-Null
                        $El.Document.Blocks.Clear()
                        $El.Document.Blocks.Add($Paragraph)
                    }
                }
                else {
                    $El.BorderBrush = $Entry.BorderBrush
                    $El.BorderThickness = $Entry.BorderThickness
                }
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
    $Target = if ($ChildElement -is [System.Management.Automation.PSReference]) { $ChildElement.Value } else { $ChildElement }
    $SearchBar = if ($Target.Name -like "*$SearchBarNameSuffix") { $Target } else {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
    }
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
} # function Close-SearchBar

function Invoke-SearchExecution {
    param([Parameter(Mandatory)]$SearchBox)

    $SearchBar = Find-ObjectWhere -Object ([ref]$SearchBox) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
    if (-not $SearchBar) { return }

    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    if (-not $ContentHeaderBorder) { return }

    $ContentHeaderBorderStack = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderStackName } -FindMax 1
    if (-not $ContentHeaderBorderStack) { return }

    $ContentSlot = $ContentHeaderBorderStack.Children | Where-Object { $_.Name -eq $ContentSlotElementName }
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

    $SearchBar = if ($ChildElement.Name -like "*$SearchBarNameSuffix") { $ChildElement } else {
        Find-ObjectWhere -Object ([ref]$ChildElement) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
    }
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
    $Target = if ($ChildElement -is [System.Management.Automation.PSReference]) { $ChildElement.Value } else { $ChildElement }
    $SearchBar = if ($Target.Name -like "*$SearchBarNameSuffix") { $Target } else {
        Find-ObjectWhere -Object ([ref]$Target) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
    }
    if (-not $SearchBar) { return $null }

    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    if (-not $ContentHeaderBorder) { return $null }

    $ContentHeaderBorderStack = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderStackName } -FindMax 1
    if (-not $ContentHeaderBorderStack) { return $null }

    $ContentSlot = $ContentHeaderBorderStack.Children | Where-Object { $_.Name -eq $ContentSlotElementName }
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

function Invoke-SearchBatchAction {
    param(
        [Parameter(Mandatory)]$ChildElement,
        [ValidateSet('Random', 'Clear', 'Disable', 'Delete', 'Lock', 'Unlock')][string]$Action = 'Random'
    )
    $SlotInfo = Get-MatchedSlotItems -ChildElement $ChildElement
    if (-not $SlotInfo -or $SlotInfo.Matched.Count -eq 0) { return }

    $SearchBar = $SlotInfo.SearchBar
    $SearchInput = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchInputNameSuffix" } -FindMax 1

    switch ($Action) {
        'Lock' {
            foreach ($Item in $SlotInfo.Matched) {
                $LockButton = Find-ObjectWhere -Object ([ref]$Item) -FindWhere { $_.Name -eq $LockUnlockButtonName } -FindMax 1
                if ($LockButton -and $LockButton.Header -ne $LockUnlockButtonHeaderLocked) {
                    $LockButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
                }
            }
        }
        'Unlock' {
            foreach ($Item in $SlotInfo.Matched) {
                $LockButtons = Find-ObjectWhere -Object ([ref]$Item) -FindWhere { $_.Name -eq $LockUnlockButtonName }
                foreach ($LButton in $LockButtons) {
                    if ($LButton.Header -eq $LockUnlockButtonHeaderLocked) {
                        $LButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
                    }
                }
            }
        }
        'Random' {
            foreach ($Item in $SlotInfo.Matched) {
                # Discard search original styles so it doesn't revert to old text
                $Contents = @()
                if ($Item.Name -eq $ContentElementName) { $Contents += $Item }
                $ChildContents = Find-ObjectWhere -Object ([ref]$Item) -FindWhere { $_.Name -eq $ContentElementName }
                if ($ChildContents) { $Contents += $ChildContents }
                foreach ($C in $Contents) {
                    if ($C.Uid -and $SearchOriginalStyles.ContainsKey($C.Uid)) {
                        $C.BorderBrush = $SearchOriginalStyles[$C.Uid].BorderBrush
                        $C.BorderThickness = $SearchOriginalStyles[$C.Uid].BorderThickness
                        $SearchOriginalStyles.Remove($C.Uid)
                    }
                }
                Set-WrapperRandomContent -Wrapper ([ref]$Item)
            }
        }
        'Clear' {
            foreach ($Item in $SlotInfo.Matched) {
                # Discard search original styles so it doesn't revert to old text
                $Contents = @()
                if ($Item.Name -eq $ContentElementName) { $Contents += $Item }
                $ChildContents = Find-ObjectWhere -Object ([ref]$Item) -FindWhere { $_.Name -eq $ContentElementName }
                if ($ChildContents) { $Contents += $ChildContents }
                foreach ($C in $Contents) {
                    if ($C.Uid -and $SearchOriginalStyles.ContainsKey($C.Uid)) {
                        $C.BorderBrush = $SearchOriginalStyles[$C.Uid].BorderBrush
                        $C.BorderThickness = $SearchOriginalStyles[$C.Uid].BorderThickness
                        $SearchOriginalStyles.Remove($C.Uid)
                    }
                }
                Clear-WrapperContent -Wrapper ([ref]$Item)
            }
        }
        'Disable' {
            foreach ($Item in $SlotInfo.Matched) {
                if (Get-IsLocked $Item) { continue }
                $DisableButton = Find-ObjectWhere -Object ([ref]$Item) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -FindMax 1
                if ($DisableButton -and $DisableButton.Icon -ne $DisableEnableButtonIconDisabled) {
                    $DisableButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
                }
            }
        }
        'Delete' {
            foreach ($Item in @($SlotInfo.Matched)) {
                if (Get-IsLocked $Item) { continue }
                $DelButton = Find-ObjectWhere -Object ([ref]$Item) -FindWhere { $_.Name -like "*$DeleteButtonNameSuffix" } -FindMax 1
                if ($DelButton) {
                    $SlotInfo.ContentSlot.Children.Remove($Item)
                }
            }
            Reset-ArrayIndexes ([ref]$SlotInfo.ContentSlot)
            Confirm-ArrayEnableButton -Item ([ref]$SlotInfo.ContentSlot)
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
        Content           = '✖'
        Name              = "$WrapperName`_$SearchCloseButtonNameSuffix"
        Width             = 22
        Height            = 20
        Margin            = '2,0,0,0'
        Padding           = '0'
        Background        = 'Transparent'
        Foreground        = '#EDEAFA'
        BorderThickness   = 0
        Cursor            = 'Hand'
        ToolTip           = 'Close Search (Esc)'
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
        @{ Header = '👁️  Show Matches'; ToolTip = 'Show matching items'; Action = 'ShowOnly'; Type = 'Filter' },
        @{ Header = '🙈  Hide Matches'; ToolTip = 'Hide matching items'; Action = 'Hide'; Type = 'Filter' },
        @{ Header = '🔄  Show All'; ToolTip = 'Restore all items'; Action = 'ShowAll'; Type = 'Filter' },
        @{ Separator = $true },
        @{ Header = '🔒  Lock Matches'; ToolTip = 'Lock matching items'; Action = 'Lock'; Type = 'Batch' },
        @{ Header = '🔓  Unlock Matches'; ToolTip = 'Unlock matching items'; Action = 'Unlock'; Type = 'Batch' },
        @{ Header = '🎲  Randomize Matches'; ToolTip = 'Randomize matching items'; Action = 'Random'; Type = 'Batch' },
        @{ Header = '🧹  Clear Matches'; ToolTip = 'Clear matching items'; Action = 'Clear'; Type = 'Batch' },
        @{ Header = '❌  Disable Matches'; ToolTip = 'Disable matching array items'; Action = 'Disable'; Type = 'Batch' },
        @{ Header = '🗑️  Delete Matches'; ToolTip = 'Delete matching array items'; Action = 'Delete'; Type = 'Batch' }
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
        Content           = '▼'
        Name              = "$WrapperName`_$SearchNextButtonNameSuffix"
        Width             = 20
        Height            = 20
        Margin            = '1,0,1,0'
        Padding           = '0'
        Background        = 'Transparent'
        Foreground        = '#EDEAFA'
        BorderThickness   = 0
        Cursor            = 'Hand'
        ToolTip           = 'Next match (Enter)'
        VerticalAlignment = 'Center'
        Focusable         = $false
    }
    [System.Windows.Controls.DockPanel]::SetDock($NextButton, 'Right')
    $SearchDock.Children.Add($NextButton) | Out-Null

    # Prev button (Dock Right)
    $PrevButton = New-BaseButton @{
        Content           = '▲'
        Name              = "$WrapperName`_$SearchPrevButtonNameSuffix"
        Width             = 20
        Height            = 20
        Margin            = '1,0,1,0'
        Padding           = '0'
        Background        = 'Transparent'
        Foreground        = '#EDEAFA'
        BorderThickness   = 0
        Cursor            = 'Hand'
        ToolTip           = 'Previous match (Shift+Enter)'
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
        Text              = '🔍 '
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
                $SearchBar = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
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
    $SearchBarBorder = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -DigProperties 'Parent' -FindMax 1
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

function Invoke-MinMaxButtonClick {
    param($s, $e)
    if ([System.Windows.Forms.Control]::ModifierKeys -match 'Shift') {
        $AlternateBehavior = $true
    }
    $ChangedChild = $false

    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
    if ($AlternateBehavior) {
        [array]$MinMaxButtons = Find-ObjectWhere -Object ([ref]$ContentSlotElement) -FindWhere { $_.Name -eq $MinMaxButtonName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
        :MinMaxButtons foreach ($MinMaxButton in $MinMaxButtons) {
            if ($MinMaxButton.Header -eq $s.Header) { $ChangedChild = $true }

            $ButtonsContentHeaderBorder = Find-ObjectWhere -Object ([ref]$MinMaxButton) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
            $ButtonsContentSlotElement = Find-ObjectWhere -Object ([ref]$ButtonsContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

            switch ($s.Header) {
                $MinMaxButtonMinedIcon {
                    $ButtonsContentSlotElement.Visibility = 'Collapsed'
                    $MinMaxButton.Header = $MinMaxButtonMaxedIcon
                    $MinMaxButton.Tooltip = $MinMaxButtonMaxedToolTip
                    $ChildSearchBar = Find-ObjectWhere -Object ([ref]$ButtonsContentHeaderBorder) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -FindMax 1
                    if ($ChildSearchBar -and $ChildSearchBar.Visibility -eq 'Visible') {
                        Close-SearchBar -ChildElement $ChildSearchBar
                    }
                }
                $MinMaxButtonMaxedIcon {
                    $ButtonsContentSlotElement.Visibility = 'Visible'
                    $MinMaxButton.Header = $MinMaxButtonMinedIcon
                    $MinMaxButton.Tooltip = $MinMaxButtonMinedToolTip
                }
            }
        } # MinMaxButtons
    }

    if (!$AlternateBehavior -or ($AlternateBehavior -and (-not $ChangedChild -or $s.Header -eq $MinMaxButtonMaxedIcon))) {
        switch ($s.Header) {
            $MinMaxButtonMinedIcon {
                $ContentSlotElement.Visibility = 'Collapsed'
                $s.Header = $MinMaxButtonMaxedIcon
                $s.Tooltip = $MinMaxButtonMaxedToolTip
                $SearchBar = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -FindMax 1
                if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
                    Close-SearchBar -ChildElement $SearchBar
                }
            }
            $MinMaxButtonMaxedIcon {
                $ContentSlotElement.Visibility = 'Visible'
                $s.Tooltip = $MinMaxButtonMinedToolTip
                $s.Header = $MinMaxButtonMinedIcon
            }
        }
    }
} # function Invoke-MinMaxButtonClick

function Invoke-AddArrayItemButtonClick {
    param($s, $e)
    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    if ($ContentHeaderBorder) {
        $Color = '#' + $ContentHeaderBorder.Background.Color.ToString().Substring(3)
        $IndexOfColorSequence = $ColorSequence.IndexOf($Color)

        $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

        $NewItem = New-TypeContent -WrapperType 'Border' -Type $s.Tag.TrimEnd('[]') -ArrayType 'ArrayItem' -Index $ContentSlotElement.Children.Count -Depth ($IndexOfColorSequence + 1)
        Add-ContentToWrapper ([ref]$ContentHeaderBorder) ([ref]$NewItem)

        $SaveItem = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*_$QuickSetSaveButtonNameSuffix" } -FindMax 1
        if ($SaveItem -is [array]) { $SaveItem = $SaveItem[0] }
        if ($SaveItem) {
            $SaveItem.IsEnabled = $true
        }
    }
} # function Invoke-AddArrayItemButtonClick

function Invoke-QuickSetRefreshButtonClick {
    param($s, $e)
    $QSMenu = Get-QuickSetMenuFromSender $s
    $TargetWrapper = Get-QuickSetWrapper $s
    if ($TargetWrapper -and $QSMenu) {
        Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
    }
} # function Invoke-QuickSetRefreshButtonClick

function Invoke-QuickSetSaveButtonClick {
    param($s, $e)
    $QSMenu = Get-QuickSetMenuFromSender $s
    $TargetWrapper = Get-QuickSetWrapper $s
    if (-not $TargetWrapper) { return }

    $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type

    $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet') -and -not [string]::IsNullOrWhiteSpace($TargetWrapper.Tag.ActiveQuickSet)) {
        $TargetWrapper.Tag.ActiveQuickSet
    }
    else {
        Get-WrapperDisplayName -Wrapper $TargetWrapper
    }

    $TypeNameDisplay = if ($Type -is [type]) { $Type.Name } else { $Type.ToString().Split('.')[-1] }
    $NewName = Show-QuickSetInputDialog -Title "Save QuickSet As" -Prompt "Enter QuickSet name for $($TypeNameDisplay):" -DefaultValue $ActiveName
    if ([string]::IsNullOrWhiteSpace($NewName)) { return }
    $NewName = ($NewName.Trim() -replace '[\\/:*?"<>|]', '_')

    $FilePath = Join-Path $TypeDir "$NewName.json"
    if (Test-Path -LiteralPath $FilePath) {
        $Confirm = Show-QuickSetConfirmDialog -Title "Overwrite QuickSet" -Message "A QuickSet named '$NewName' already exists. Overwrite it?"
        if (-not $Confirm) { return }
    }

    Set-WrapperDisplayName -Wrapper $TargetWrapper -DisplayName $NewName

    $CurrentValue = Get-WrapperQuickSetValue -Wrapper $TargetWrapper
    $JsonText = ConvertTo-Json -InputObject $CurrentValue -Depth 20
    Set-Content -LiteralPath $FilePath -Value $JsonText -Encoding UTF8

    if ($QSMenu) {
        Set-QuickSetActiveButtonsState -QuickSetMenuItem $QSMenu -IsEnabled $true
        Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
    }
} # function Invoke-QuickSetSaveButtonClick

function Invoke-QuickSetRenameButtonClick {
    param($s, $e)
    $QSMenu = Get-QuickSetMenuFromSender $s
    $TargetWrapper = Get-QuickSetWrapper $s
    if (-not $TargetWrapper) { return }

    $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet')) {
        $TargetWrapper.Tag.ActiveQuickSet
    }
    else { $null }

    if ([string]::IsNullOrWhiteSpace($ActiveName)) {
        [System.Windows.MessageBox]::Show("Please select a QuickSet first to rename.", "QuickSet - Rename", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        return
    }

    $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type
    $OldFile = Join-Path $TypeDir "$ActiveName.json"
    if (-not (Test-Path -LiteralPath $OldFile)) {
        [System.Windows.MessageBox]::Show("QuickSet file not found on disk: $ActiveName.json", "QuickSet", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }

    $NewName = Show-QuickSetInputDialog -Title "Rename QuickSet" -Prompt "Enter new name for '$ActiveName':" -DefaultValue $ActiveName
    if ([string]::IsNullOrWhiteSpace($NewName) -or $NewName.Trim() -eq $ActiveName) { return }
    $NewName = ($NewName.Trim() -replace '[\\/:*?"<>|]', '_')
    $NewFile = Join-Path $TypeDir "$NewName.json"

    if (Test-Path -LiteralPath $NewFile) {
        $Overwrite = Show-QuickSetConfirmDialog -Title "Overwrite QuickSet" -Message "A QuickSet named '$NewName' already exists. Overwrite it?"
        if (-not $Overwrite) { return }
    }

    Move-Item -LiteralPath $OldFile -Destination $NewFile -Force
    Set-WrapperDisplayName -Wrapper $TargetWrapper -DisplayName $NewName

    $CurrentValue = Get-WrapperQuickSetValue -Wrapper $TargetWrapper
    $JsonText = ConvertTo-Json -InputObject $CurrentValue -Depth 20
    Set-Content -LiteralPath $NewFile -Value $JsonText -Encoding UTF8

    if ($QSMenu) {
        Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
    }
} # function Invoke-QuickSetRenameButtonClick

function Invoke-QuickSetOverwriteButtonClick {
    param($s, $e)
    $QSMenu = Get-QuickSetMenuFromSender $s
    $TargetWrapper = Get-QuickSetWrapper $s
    if (-not $TargetWrapper) { return }

    $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet')) {
        $TargetWrapper.Tag.ActiveQuickSet
    }
    else { $null }

    if ([string]::IsNullOrWhiteSpace($ActiveName)) {
        [System.Windows.MessageBox]::Show("Please select a QuickSet first to overwrite.", "QuickSet - Overwrite", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        return
    }

    $Confirm = Show-QuickSetConfirmDialog -Title "Overwrite QuickSet" -Message "Are you sure you want to overwrite '$ActiveName' with current values?"
    if (-not $Confirm) { return }

    $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type
    $FilePath = Join-Path $TypeDir "$ActiveName.json"

    Set-WrapperDisplayName -Wrapper $TargetWrapper -DisplayName $ActiveName

    $CurrentValue = Get-WrapperQuickSetValue -Wrapper $TargetWrapper
    $JsonText = ConvertTo-Json -InputObject $CurrentValue -Depth 20
    Set-Content -LiteralPath $FilePath -Value $JsonText -Encoding UTF8

    if ($QSMenu) {
        Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
    }
} # function Invoke-QuickSetOverwriteButtonClick

function Invoke-QuickSetDeleteButtonClick {
    param($s, $e)
    $QSMenu = Get-QuickSetMenuFromSender $s
    $TargetWrapper = Get-QuickSetWrapper $s
    if (-not $TargetWrapper) { return }

    $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet')) {
        $TargetWrapper.Tag.ActiveQuickSet
    }
    else { $null }

    if ([string]::IsNullOrWhiteSpace($ActiveName)) {
        [System.Windows.MessageBox]::Show("Please select a QuickSet first to delete.", "QuickSet - Delete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        return
    }

    $Confirm = Show-QuickSetConfirmDialog -Title "Delete QuickSet" -Message "Are you sure you want to delete QuickSet '$ActiveName'?"
    if (-not $Confirm) { return }

    $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
    $TypeDir = Get-QuickSetTypeDirectory -Type $Type
    $FilePath = Join-Path $TypeDir "$ActiveName.json"
    if (Test-Path -LiteralPath $FilePath) {
        Remove-Item -LiteralPath $FilePath -Force -ErrorAction SilentlyContinue
    }

    $TargetWrapper.Tag.ActiveQuickSet = $null
    Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $null
    if ($QSMenu) {
        Set-QuickSetActiveButtonsState -QuickSetMenuItem $QSMenu -IsEnabled $false
        Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
    }
} # function Invoke-QuickSetDeleteButtonClick

function Invoke-QuickSetClearButtonClick {
    param($s, $e)
    try {
        $QSMenu = Get-QuickSetMenuFromSender $s
        $TargetWrapper = Get-QuickSetWrapper $s
        if (-not $TargetWrapper) { return }

        $ActiveName = if ($TargetWrapper.Tag -is [hashtable] -and $TargetWrapper.Tag.ContainsKey('ActiveQuickSet') -and -not [string]::IsNullOrWhiteSpace($TargetWrapper.Tag.ActiveQuickSet)) {
            $TargetWrapper.Tag.ActiveQuickSet
        }
        else { $null }

        if (-not [string]::IsNullOrWhiteSpace($ActiveName)) {
            $Type = Get-WrapperTargetType -Wrapper $TargetWrapper
            $TypeDir = Get-QuickSetTypeDirectory -Type $Type
            $CleanName = $ActiveName -replace '[\\/:*?"<>|]', '_'
            $FilePath = Join-Path $TypeDir "$CleanName.json"

            Set-WrapperDisplayName -Wrapper $TargetWrapper -DisplayName $CleanName

            $CurrentValue = Get-WrapperQuickSetValue -Wrapper $TargetWrapper
            $JsonText = ConvertTo-Json -InputObject $CurrentValue -Depth 20
            Set-Content -LiteralPath $FilePath -Value $JsonText -Encoding UTF8
        }

        Clear-WrapperQuickSetValue -Wrapper $TargetWrapper

        if (-not ($TargetWrapper.Tag -is [hashtable])) { $TargetWrapper.Tag = @{} }
        $TargetWrapper.Tag.ActiveQuickSet = $null
        Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $null

        if ($QSMenu) {
            Set-QuickSetActiveButtonsState -QuickSetMenuItem $QSMenu -IsEnabled $false
            Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error saving QuickSet: $_", "QuickSet Error") | Out-Null
    }
} # function Invoke-QuickSetClearButtonClick

function Invoke-QuickSetCloseButtonClick {
    param($s, $e)
    try {
        $QSMenu = Get-QuickSetMenuFromSender $s
        $TargetWrapper = Get-QuickSetWrapper $s
        if (-not $TargetWrapper) { return }

        Clear-WrapperQuickSetValue -Wrapper $TargetWrapper

        if (-not ($TargetWrapper.Tag -is [hashtable])) { $TargetWrapper.Tag = @{} }
        $TargetWrapper.Tag.ActiveQuickSet = $null
        Update-QuickSetBadge -Wrapper $TargetWrapper -DisplayName $null

        if ($QSMenu) {
            Set-QuickSetActiveButtonsState -QuickSetMenuItem $QSMenu -IsEnabled $false
            Update-QuickSetSubMenu -QuickSetMenuItem $QSMenu -Wrapper $TargetWrapper
        }
    }
    catch {
        [System.Windows.MessageBox]::Show("Error closing QuickSet: $_", "QuickSet Error") | Out-Null
    }
} # function Invoke-QuickSetCloseButtonClick

function Invoke-ClearButtonClick {
    param($s, $e)
    $ContentWrapper = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$ClearButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
    if ($ContentWrapper) { Clear-WrapperContent ([ref]$ContentWrapper) }
} # function Invoke-ClearButtonClick

function Invoke-RandomValuesButtonClick {
    param($s, $e)
    $ContentWrapper = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$RandomValuesButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
    if ($ContentWrapper) { Set-WrapperRandomContent ([ref]$ContentWrapper) }
} # function Invoke-RandomValuesButtonClick

function Invoke-DisableEnableButtonClick {
    param($s, $e)
    if ((Get-IsLocked $s)) { return }
    $Parent = $s.Parent
    $IsAll = $s.Header -like '* All' -or ($s.Tag -is [hashtable] -and $s.Tag.IsAll)

    switch ($s.Icon) {
        $DisableEnableButtonIconDisabled {
            $s.Header = if ($IsAll) { $DisableEnableButtonHeaderEnabled + ' All' } else { $DisableEnableButtonHeaderEnabled }
            $s.Icon = $DisableEnableButtonIconEnabled
            $TargetIndex = if ($s.Tag -is [hashtable]) { $s.Tag.Index } else { $s.Tag }
            Remove-CustomMenuChild ([ref]$Parent) ([ref]$s)
            Add-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$s) $TargetIndex
            $s.Tag = $null

            if ($IsAll) {
                $ContentWrapper = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$DisableEnableButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                $ChildButtons = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $s }
                :ChildButtons foreach ($ChildButton in $ChildButtons) {
                    if ((Get-IsLocked $ChildButton)) { continue ChildButtons }
                    if ($ChildButton.Icon -eq $DisableEnableButtonIconDisabled) {
                        $ChildParent = $ChildButton.Parent
                        $ChildButton.Header = $DisableEnableButtonHeaderEnabled
                        $ChildButton.Icon = $DisableEnableButtonIconEnabled
                        $ChildIndex = if ($ChildButton.Tag -is [hashtable]) { $ChildButton.Tag.Index } else { $ChildButton.Tag }
                        Remove-CustomMenuChild ([ref]$ChildParent) ([ref]$ChildButton)
                        Add-ChildToItemsButtonMenu ([ref]$ChildParent) ([ref]$ChildButton) $ChildIndex
                        $ChildButton.Tag = $null
                    }
                }
            }
            else {
                Confirm-ArrayEnableButton -Item ([ref]$s)
            }
        }
        $DisableEnableButtonIconEnabled {
            $TagInfo = if ($IsAll) { @{ Index = $Parent.Items.IndexOf($s); IsAll = $true } } else { $Parent.Items.IndexOf($s) }
            $s.Tag = $TagInfo
            $s.Header = if ($IsAll) { $DisableEnableButtonHeaderDisabled + ' All' } else { $DisableEnableButtonHeaderDisabled }
            $s.Icon = $DisableEnableButtonIconDisabled
            Remove-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$s)
            Add-CustomMenuChild ([ref]$Parent) ([ref]$s)

            if ($IsAll) {
                $ContentWrapper = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$DisableEnableButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                $ChildButtons = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $s }
                :ChildButtons foreach ($ChildButton in $ChildButtons) {
                    if ((Get-IsLocked $ChildButton)) { continue ChildButtons }
                    if ($ChildButton.Icon -eq $DisableEnableButtonIconEnabled) {
                        $ChildParent = $ChildButton.Parent
                        $ChildButton.Tag = $ChildParent.Items.IndexOf($ChildButton)
                        $ChildButton.Header = $DisableEnableButtonHeaderDisabled
                        $ChildButton.Icon = $DisableEnableButtonIconDisabled
                        Remove-ChildToItemsButtonMenu ([ref]$ChildParent) ([ref]$ChildButton)
                        Add-CustomMenuChild ([ref]$ChildParent) ([ref]$ChildButton)
                    }
                }
            }
            else {
                Confirm-ArrayEnableButton -Item ([ref]$s)
            }
        }
    }
} # function Invoke-DisableEnableButtonClick

function Invoke-DeleteButtonClick {
    param($s, $e)
    if ((Get-IsLocked $s)) { return }
    $ContentWrapper = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq "$($s.Name.Replace("_$DeleteButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
    if (-not $ContentWrapper) { return }

    $IsAll = $s.Header -like '* All'
    if ($IsAll) {
        $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
        if ($ContentSlotElement) {
            :Delete foreach ($Child in @($ContentSlotElement.Children)) {
                if ((Get-IsLocked $Child)) { continue Delete } # TODO: Flash Lock
                $ContentSlotElement.Children.Remove($Child)
            }
            Reset-ArrayIndexes ([ref]$ContentSlotElement)
            Confirm-ArrayEnableButton -Item ([ref]$ContentWrapper)
            if ($ContentSlotElement.Children.Count -eq 0) {
                $SaveItem = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -like "*_$QuickSetSaveButtonNameSuffix" } -FindMax 1
                if ($SaveItem -is [array]) { $SaveItem = $SaveItem[0] }
                if ($SaveItem) { $SaveItem.IsEnabled = $false }
            }
        }
    }
    else {
        if ((Get-IsLocked $ContentWrapper)) { return }
        $Array = $ContentWrapper.Parent
        if ($Array) {
            $Array.Children.Remove($ContentWrapper)
            Reset-ArrayIndexes ([ref]$Array)
            Confirm-ArrayEnableButton -Item ([ref]$Array)
            if ($Array.Children.Count -eq 0) {
                $ParentWrapper = Find-ObjectWhere -Object ([ref]$Array) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
                if ($ParentWrapper -is [array]) { $ParentWrapper = $ParentWrapper[0] }
                if ($ParentWrapper) {
                    $SaveItem = Find-ObjectWhere -Object ([ref]$ParentWrapper) -FindWhere { $_.Name -like "*_$QuickSetSaveButtonNameSuffix" } -FindMax 1
                    if ($SaveItem -is [array]) { $SaveItem = $SaveItem[0] }
                    if ($SaveItem) { $SaveItem.IsEnabled = $false }
                }
            }
        }
    }
} # function Invoke-DeleteButtonClick

function Invoke-SearchButtonClick {
    param($s, $e)
    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$s) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
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
        $ContentHeaderBorderStack = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderStackName } -FindMax 1
        $ContentSlot = if ($ContentHeaderBorderStack) { $ContentHeaderBorderStack.Children | Where-Object { $_.Name -eq $ContentSlotElementName } } else { $null }
        if ($ContentSlot -and $ContentSlot.Visibility -ne 'Visible') {
            $ContentSlot.Visibility = 'Visible'
            $MinMaxButton = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $MinMaxButtonName } -FindMax 1
            if ($MinMaxButton) {
                $MinMaxButton.Header = $MinMaxButtonMinedIcon
                $MinMaxButton.ToolTip = $MinMaxButtonMinedToolTip
            }
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
    $Parent = $s.Parent
    switch ($s.Icon) {
        $LockUnlockButtonIconLocked {
            $s.Header = $LockUnlockButtonHeaderUnlocked
            $s.Icon = $LockUnlockButtonIconUnlocked
            Remove-CustomMenuChild ([ref]$Parent) ([ref]$s)
            Add-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$s) $s.Tag
            # Remove LockButton Index from Tag property
            $s.Tag = $null
            Set-LockableButtonsState -LockButton $s -IsEnabled $true
        }
        $LockUnlockButtonIconUnlocked {
            # Add LockButton Index to Tag property
            $s.Tag = $Parent.Items.IndexOf($s)
            $s.Header = $LockUnlockButtonHeaderLocked
            $s.Icon = $LockUnlockButtonIconLocked
            Remove-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$s)
            Add-CustomMenuChild ([ref]$Parent) ([ref]$s)
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

    # QuickSet Button Functionaility
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
        [string]$Header = $SearchButtonIcon,
        $Icon = $null,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

    $SearchButton = New-BaseMenuItem @{
        Name    = "$ActionFrom`_$SearchButtonNameSuffix"
        Header  = $Header
        Icon    = $Icon
        ToolTip = $SearchButtonToolTip
    }

    $SearchButton.Add_Click({ param($s, $e) Invoke-SearchButtonClick $s $e })

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
    if ($Button.Icon -eq $LockUnlockButtonIconLocked) { return $LockUnlockButtonToolTipLocked }
    return $LockUnlockButtonToolTipUnlocked
} # function Get-LockUnlockButtonToolTip

function Set-LockableButtonsState {
    param(
        [Parameter(Mandatory)]$LockButton,
        [Parameter(Mandatory)][bool]$IsEnabled
    )
    # Only search this item's own menu, so nested child items keep their own state
    $Menu = Find-ObjectWhere -Object ([ref]$LockButton) -FindWhere { $_.Name -eq $MenuName } -DigProperties 'Parent' -FindMax 1
    if ($Menu -is [array]) { $Menu = $Menu[0] }
    if (-not $Menu) { return }

    $LockableButtonSuffixes = @(
        $RandomValuesButtonNameSuffix
        $ClearButtonNameSuffix
        $DisableEnableButtonNameSuffix
        $DeleteButtonNameSuffix
    )

    :suffixes foreach ($Suffix in $LockableButtonSuffixes) {
        $Buttons = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*_$Suffix" }
        :buttons foreach ($Button in @($Buttons)) {
            if ($Button) { $Button.IsEnabled = $IsEnabled }
        } # buttons foreach
    } # suffixes foreach
} # function Set-LockableButtonsState

function Get-IsLocked {
    param($Object)
    $Target = if ($Object -is [System.Management.Automation.PSReference]) { $Object.Value } else { $Object }
    $ContentBorders = @()
    if (@($ContentHeaderBorderName, $ContentBorderName) -contains $Target.Name) {
        $ContentBorders += $Target
    }
    $ParentBorders = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent'
    if ($ParentBorders) {
        $ContentBorders += $ParentBorders
    }

    :Borders foreach ($ContentBorder in $ContentBorders) {
        $LockButton = Find-ObjectWhere -Object ([ref]$ContentBorder) -FindWhere { $_.Name -eq $LockUnlockButtonName } -FindMax 1
        $LockButtonValue = Get-ContentValue $LockButton
        if ($LockButtonValue -eq $LockUnlockButtonHeaderLocked) {
            return $true
        }
    }

    return $false
} # function Get-IsLocked

function Get-IsDisabled {
    param($Object)
    $Target = if ($Object -is [System.Management.Automation.PSReference]) { $Object.Value } else { $Object }
    $ContentBorders = @()
    if (@($ContentHeaderBorderName, $ContentBorderName) -contains $Target.Name) {
        $ContentBorders += $Target
    }
    $ParentBorders = Find-ObjectWhere -Object ([ref]$Target) -FindWhere { @($ContentHeaderBorderName, $ContentBorderName) -contains $_.Name } -DigProperties 'Parent'
    if ($ParentBorders) {
        $ContentBorders += $ParentBorders
    }

    :Borders foreach ($ContentBorder in $ContentBorders) {
        $DisableEnableButton = Find-ObjectWhere -Object ([ref]$ContentBorder) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" } -FindMax 1
        $DisableEnableButtonValue = Get-ContentValue $DisableEnableButton
        if ($DisableEnableButtonValue -like "$DisableEnableButtonHeaderDisabled*") {
            return $true
        }
    }

    return $false
} # function Get-IsDisabled

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
} # function Get-ClassConstructors

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
                    $TargetButton = Find-ObjectWhere -Object ([ref]$ParentBorder) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" } -FindMax 1
                }
            }
            if (-not $TargetButton) {
                $SearchButtons = Find-ObjectWhere -Object ([ref]$BaseWindow) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" }
                if ($SearchButtons -and @($SearchButtons).Count -gt 0) {
                    $TargetButton = @($SearchButtons)[0]
                }
            }
            if ($TargetButton) {
                $TargetButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
                $e.Handled = $true
            }
        }
    })

$BaseWindow.ShowDialog() | Out-Null

#endregion #9 WindowBase
