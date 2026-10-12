<# PoshToUI
    To Do:
        Array Actions
            1 Random Values 
                9. FUTURE FEATURE: Customize how they generate.
            Filter - Removes non-matching items
            Sort
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

[string[]]$PasswordFields = @(
    'password'
)

[bool]$RandomValues = $True

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

# UI Element Headers, Icons, & ToolTips
$MinMaxButtonMaxedIcon = '🔽'
$MinMaxButtonMaxedToolTip = "Minimize`nSHIFT: Alternate Behavior"
$MinMaxButtonMinedIcon = '🔼'
$MinMaxButtonMinedToolTip = "Maximize`nSHIFT: Alternate Behavior"

$AddArrayItemButtonIcon = '➕'
$ClearButtonHeader = 'Clear Value'
$ClearButtonIcon = '🧹'
$RandomValuesButtonHeader = 'Random Value'
$RandomValuesButtonIcon = '🎲'
$DisableEnableButtonHeaderDisabled = '❌'
$DisableEnableButtonIconDisabled = $null
$DisableEnableButtonHeaderEnabled = 'Disable'
$DisableEnableButtonIconEnabled = '❌'
$DeleteButtonHeader = 'Delete'
$DeleteButtonIcon = '🗑'
$LockUnlockButtonHeaderLocked = '🔒'
$LockUnlockButtonIconLocked = $null
$LockUnlockButtonHeaderUnlocked = 'Lock'
$LockUnlockButtonIconUnlocked = '🔓'

$ConstructButtonHeader = 'Construct'
$ConstructButtonIcon = '🔨'

$DragHandleIcon = '☰'
$DragHandleToolTip = "Drag to reorder`nSHIFT: Swap positions"

$SearchButtonHeader = 'Search'
$SearchButtonIcon = '🔍'
$SearchButtonToolTip = "Search (Ctrl+F)"

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
        [string[]]$PropertiesToLookAt = @('Name', 'DataContext', 'Header', 'Child', 'Content', 'Children', 'Items', 'ToolBars', 'Text', 'SelectedItem', 'Password')
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
    param( [ref]$Menu, [ref]$Child )
    try {
        $Menu.Value.AddChild($Child.Value)
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
}

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
        [System.Windows.Controls.MenuItem]$Parameters
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
    param( [ref]$Wrapper, [ref]$Child )

    if ($Wrapper.Value.Name -eq 'ButtonMenu') {
        $Menu = $Wrapper.Value.Parent
    }
    else {
        $Menu = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $MenuName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
    }

    try {
        $Menu.Items.Add($Child.Value) | Out-Null
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
        FlowDirection       = 'RightToLeft'
    }

    $MenuItem = New-BaseMenuItem @{
        Name          = $ButtonMenuName
        Header        = '⋮'
        Visibility    = 'Collapsed'
        FlowDirection = 'LeftToRight'
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
    Add-BaseMenuChild ([ref]$ContentHeaderButtonMenu) ([ref]$MinMaxButton)

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
        $Top.DataContext = $TargetType.FullName
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
            ToolTip = 'Construct Object'
        }

        $ConstructButton.Add_Click({
                param($sender, $e)
                if ($sender.Header -eq ($ConstructButtonHeader + ' All')) {
                    $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$Sender) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
                    $Constructs = Find-ObjectWhere -Object $ContentHeaderBorder -FindWhere { $_.Name -eq $ConstructName }
                    :Constructs foreach ($Construct in $Constructs) {
                        Build-Object -Object ([ref]$Construct)
                    } # Constructs
                }
                else {
                    Build-Object -Object ([ref]$Sender)
                }
            }
        )

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
        $AddButton = New-AddArrayItemButton -Type $Wrapper.Value.DataContext
        Add-CustomMenuChild $Wrapper ([ref]$AddButton)

        # Button: Search
        $SearchButton = New-SearchButton -ActionFrom $Wrapper.Value.Name
        Add-CustomMenuChild $Wrapper ([ref]$SearchButton)

        # Button: Lock, Unlock All
        $LockUnlockButton = New-LockButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$LockUnlockButton)

        # Button: Random Values All
        $RandomValuesButton = New-RandomValuesButton -Header "$($RandomValuesButtonHeader + 's')" -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$RandomValuesButton)

        # Button: Clear All
        $ClearButton = New-ClearButton -Header "$($ClearButtonHeader + 's')" -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$ClearButton)

        # Button: Enable/Disable All
        $DisableEnableButton = New-DisableEnableButton -Header ($DisableEnableButtonHeaderEnabled + ' All') -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$DisableEnableButton)

        # Button: Delete All
        $DeleteButton = New-DeleteButton -Header ($DeleteButtonHeader + ' All') -ActionFrom $Wrapper.Value.Name
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
                $MinMaxBtn = Find-ObjectWhere -Object ([ref]$HeaderBorder) -FindWhere { $_.Name -eq $MinMaxButtonName } -FindMax 1
                if ($MinMaxBtn) {
                    $MinMaxBtn.Header = $MinMaxButtonMinedIcon
                    $MinMaxBtn.ToolTip = $MinMaxButtonMinedToolTip
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
        [string]$Query = ''
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
        if (-not [string]::IsNullOrEmpty($Query) -and -not [string]::IsNullOrEmpty($OrigText)) {
            $BgBrush = if ($HighlightType -eq 'Active') { $BrushConverter.ConvertFromString('#E67E22') } else { $BrushConverter.ConvertFromString('#F1C40F') }
            $FgBrush = if ($HighlightType -eq 'Active') { $BrushConverter.ConvertFromString('#FFFFFF') } else { $BrushConverter.ConvertFromString('#1E1E1E') }

            $Paragraph = New-Object System.Windows.Documents.Paragraph
            $Paragraph.Margin = [System.Windows.Thickness]::new(0)

            $CurrentIdx = 0
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
        [Parameter(Mandatory)][string]$Query
    )
    if ([string]::IsNullOrWhiteSpace($Query)) { return $false }

    $MatchedParts = [System.Collections.ArrayList]@()

    # 1. Match titles / property names inside element
    if ($Element.Name -eq $ContentHeaderTitleValueName) {
        if ($Element.Text -and $Element.Text.IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0) {
            [void]$MatchedParts.Add($Element)
        }
    }
    $TitleBlocks = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -eq $ContentHeaderTitleValueName }
    :Titles foreach ($TBlock in $TitleBlocks) {
        if ($TBlock.Text -and $TBlock.Text.IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0) {
            [void]$MatchedParts.Add($TBlock)
        }
    }

    # 2. Match descriptions inside element
    if ($Element.Name -eq $ContentHeaderDescriptionValueName) {
        if ($Element.Text -and $Element.Text.IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0) {
            [void]$MatchedParts.Add($Element)
        }
    }
    $DescBlocks = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -eq $ContentHeaderDescriptionValueName }
    :Descs foreach ($DBlock in $DescBlocks) {
        if ($DBlock.Text -and $DBlock.Text.IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0) {
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
            if ($StrVal.IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0) {
                [void]$MatchedParts.Add($Content)
            }
        }
        if ($Content -is [System.Windows.Controls.ComboBox] -and $Content.ItemsSource) {
            foreach ($Item in $Content.ItemsSource) {
                if ($Item -and "$Item".IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0) {
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
        if ($DateBox -and $DateBox.Text -and $DateBox.Text.IndexOf($Query, [System.StringComparison]::CurrentCultureIgnoreCase) -ge 0) {
            [void]$MatchedParts.Add($DateBox)
        }
    }

    # 5. Match Index boxes inside element
    $IndexBoxes = Find-ObjectWhere -Object ([ref]$Element) -FindWhere { $_.Name -like "*$IndexBoxNameSuffix" }
    :Indices foreach ($IBox in $IndexBoxes) {
        if ($IBox.Text -and $IBox.Text.Trim() -eq $Query.Trim()) {
            [void]$MatchedParts.Add($IBox)
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

    $MatchedElements = [System.Collections.ArrayList]@()
    :Children foreach ($Child in @($ContentSlot.Children)) {
        $Matches = Test-ElementMatchesQuery -Element $Child -Query $Query
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
    :Matches foreach ($Match in $MatchedElements) {
        Set-ElementHighlight -Element ([ref]$Match) -HighlightType 'Match' -Query $Query
    }

    $SearchBar.Tag.Matches = $MatchedElements
    $SearchBar.Tag.CurrentIndex = 0
    Set-ElementHighlight -Element ([ref]$MatchedElements[0]) -HighlightType 'Active' -Query $Query
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

    if ($CurrentIdx -ge 0 -and $CurrentIdx -lt $Matches.Count) {
        Set-ElementHighlight -Element ([ref]$Matches[$CurrentIdx]) -HighlightType 'Match' -Query $Query
    }

    if ($Direction -eq 'Next') {
        $NewIdx = ($CurrentIdx + 1) % $Matches.Count
    }
    else {
        $NewIdx = ($CurrentIdx - 1 + $Matches.Count) % $Matches.Count
    }

    $SearchBar.Tag.CurrentIndex = $NewIdx
    Set-ElementHighlight -Element ([ref]$Matches[$NewIdx]) -HighlightType 'Active' -Query $Query
    $Matches[$NewIdx].BringIntoView()

    $CountBlock = Find-ObjectWhere -Object ([ref]$SearchBar) -FindWhere { $_.Name -like "*$SearchCountNameSuffix" } -FindMax 1
    if ($CountBlock) {
        $CountBlock.Text = "$($NewIdx + 1) / $($Matches.Count)"
        $CountBlock.Foreground = '#C1B8D1'
    }
} # function Step-SearchMatch

#endregion #3 Content Controls Actions

#region #3 Content Controls Elements

function New-ContentEnum {
    param([type]$EnumType)
    New-BaseComboBox @{
        Name          = $ContentElementName
        ItemsSource   = $EnumType.GetEnumNames()
        SelectedValue = if ($RandomValues) { Get-Random -InputObject $EnumType.GetEnumNames() } else { $null }
        Margin        = 2
    }
} # function New-ContentEnum

function New-ContentPassword {
    New-BasePasswordBox @{
        Name     = $ContentElementName
        Password = if ($RandomValues) { (([char[]](0..200) | Get-Random -Count 10) -join '') } else { $null }
        Margin   = 2
    }
} # function New-ContentPassword

function New-ContentString {
    New-BaseRichTextBox @{
        Name      = $ContentElementName
        Text      = if ($RandomValues) { (([char[]](0..200) | Get-Random -Count 10) -join '') } else { $null }
        Margin    = 2
        AllowDrop = $false
    }
} # function New-ContentString

function New-ContentNumber {
    param( [type]$TargetType )
    $TextBox = New-BaseTextBox @{
        Name        = $ContentElementName
        DataContext = $TargetType
        Text        = if ($RandomValues) { (Get-Random -Minimum 0 -Maximum 100).ToString() } else { $null }
        Margin      = 2
    }

    $TextBox.Add_PreviewTextInput({
            param($sender, $e)
            $isSigned = -not $sender.DataContext.Name.StartsWith('U')
            $isFloatingPoint = @('System.Single', 'System.Double', 'System.Decimal') -contains $sender.DataContext.FullName
            $currentText = $sender.Text
            $caretIndex = $sender.CaretIndex
            $selectionLength = $sender.SelectionLength

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
            param($sender, $e)
            $val = $sender.Text
            if ([string]::IsNullOrWhiteSpace($val) -or $val -eq '-') {
                return
            }

            try {
                $null = $this.DataContext::Parse($val)
                $sender.ToolTip = $null
            }
            catch {
                $sender.ToolTip = "Invalid value for $($sender.DataContext.FullName)"
            }
        })

    $TextBox
} # function New-ContentNumber

function New-ContentBoolean {
    New-BaseComboBox @{
        Name         = $ContentElementName
        ItemsSource  = @(
            $true,
            $false
        )
        SelectedItem = if ($RandomValues) { Get-Random -InputObject @($true, $false) } else { $null }
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
            $NowButton.Add_Click({
                    $now = Get-Date
                    $Calendar.SelectedDate = $now.Date
                    $Calendar.DisplayDate = $now.Date
                    $HourCombo.SelectedItem = $now.ToString('HH')
                    $MinuteCombo.SelectedItem = $now.ToString('mm')
                    $SecondCombo.SelectedItem = $now.ToString('ss')
                })

            $OkButton = New-BaseButton @{
                Content   = 'OK'
                Width     = 55
                Margin    = '0,0,6,0'
                IsDefault = $true
            }
            $OkButton.Add_Click({
                    $selDate = if ($Calendar.SelectedDate) { $Calendar.SelectedDate } else { (Get-Date).Date }
                    $h = [int]($HourCombo.SelectedItem -as [int])
                    $m = [int]($MinuteCombo.SelectedItem -as [int])
                    $s = [int]($SecondCombo.SelectedItem -as [int])

                    $finalDateTime = [DateTime]::new($selDate.Year, $selDate.Month, $selDate.Day, $h, $m, $s)
                    $CustomDateTimePicker = Find-ObjectWhere -Object ([ref]$PickButton) -FindWhere { $_.Name -eq $CustomDateTimePickerName }
                    $ContentDateTimeDisplayTextBox = Find-ObjectWhere -Object ([ref]$CustomDateTimePicker) -FindWhere { $_.Name -eq $ContentDateTimeDisplayTextBoxName }
                    $ContentDateTimeDisplayTextBox.Text = $finalDateTime.ToString('yyyy-MM-dd HH:mm:ss')
                    $Dialog.Close()
                })

            $CancelButton = New-BaseButton @{
                Content  = 'Cancel'
                Width    = 55
                IsCancel = $true
            }
            $CancelButton.Add_Click({
                    $Dialog.Close()
                })

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
        Text      = $Content.FullName
        Margin    = 2
        MaxLength = 1
    }
    $CharBox.Add_TextChanged({
            param($sender, $e)
            $val = $sender.Text
            if ([string]::IsNullOrWhiteSpace($val)) {
                return
            }

            try {
                $null = [char]::Parse($val)
                $sender.ToolTip = $null
            }
            catch {
                $sender.ToolTip = "Invalid value for $($sender.DataContext.FullName)"
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
            param($sender, $e)
            $DraggingItem = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$DragHandleNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
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
            param($sender, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true

            #Write-Host "DragEnter: $($sender.Name) - $(find-title $sender)"

            $SourceUid = $e.Data.GetData([String])
            if (($SourceUid -and $SourceUid -eq $sender.Uid)) { return }

            $Array = $sender.Parent
            $DraggingItemIndex = $Array.Children.IndexOf($DraggingItem)
            if ($DraggingItemIndex -eq -1) { return }

            $SourceIndex = $Array.Children.IndexOf($sender)
            $sender.BorderBrush = 'DodgerBlue'

            $Thickness = $Sender.BorderThickness.ToString()[0]
            if ($SourceIndex -gt $DraggingItemIndex) {
                $sender.BorderThickness = "0,0,0,$Thickness"
            }
            else {
                $sender.BorderThickness = "0,$Thickness,0,0"
            }
        })
    $DragDropTarget.Value.Add_DragLeave({
            param($sender, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true

            $SourceUid = $e.Data.GetData([String])
            if (($SourceUid -and $SourceUid -eq $sender.Uid)) { return }

            $Array = $sender.Parent
            $DraggingItemIndex = $Array.Children.IndexOf($DraggingItem)
            if ($DraggingItemIndex -eq -1) { return }

            $sender.BorderBrush = 'Black'
            $Thickness = $Sender.BorderThickness.ToString().Split(',') | Where-Object { $_ -ne 0 }
            $sender.BorderThickness = $Thickness
        })
    $DragDropTarget.Value.Add_DragOver({
            param($sender, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true
        })
    $DragDropTarget.Value.Add_Drop({
            param($sender, $e)
            $e.Effects = [System.Windows.DragDropEffects]::Move
            $e.Handled = $true

            $SourceUid = $e.Data.GetData([String])
            if (($SourceUid -and $SourceUid -eq $sender.Uid)) { return }

            $Array = $sender.Parent
            $DraggingItemIndex = $Array.Children.IndexOf($DraggingItem)
            if ($DraggingItemIndex -eq -1) { return }

            $sender.BorderBrush = 'Black'
            $Thickness = $Sender.BorderThickness.ToString().Split(',') | Where-Object { $_ -ne 0 }
            if ($Sender.Count -gt 1) {
                Write-Host '{Add_Drop} pause, why more than 1 object here??' -ForegroundColor Red -BackgroundColor Yellow #0 Issue last seen, 10-3-2026.
            }
            $sender.BorderThickness = $Thickness

            $TargetIndex = $Array.Children.IndexOf($sender)

            $Array.Children.Remove($DraggingItem)
            $Array.Children.Insert($TargetIndex, $DraggingItem)

            if ([System.Windows.Forms.Control]::ModifierKeys -match 'Shift') {
                $Array.Children.Remove($sender)
                $Array.Children.Insert($DraggingItemIndex, $sender)
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
            param($sender, $e)
            if ($e.Key -eq 'Enter' -or $e.Key -eq 'Return') {
                $IndexBlockParent = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($Sender.Name.Replace("_$IndexBoxNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                $Content = Find-ObjectWhere -Object ([ref]$IndexBlockParent) -FindWhere { $_.Name -eq $ContentElementName } -FindMax 1
                if ($Content) { $Content.Focus() }
            }
        }
    )
    $IndexBlock.Add_LostFocus({
            param($sender, $e)

            # This section moves the item to the new index if the user has changed it.
            $ArrayItem = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$IndexBoxNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
            $Array = $ArrayItem.Parent
            $CurrentIndex = $Array.Children.IndexOf($ArrayItem)
            $NewIndexText = $sender.Text
            if ($ArrayItem -and $Array) {
                if ([int]::TryParse($NewIndexText, [ref]$null)) {
                    $NewIndex = [int]$NewIndexText

                    $TargetIndex = $NewIndex - 1
                    if ($TargetIndex -lt 0) { $TargetIndex = 0 }
                    if ($TargetIndex -ge $Array.Children.Count) { $TargetIndex = $Array.Children.Count - 1 }
                    $Sender.Text = "$($TargetIndex + 1)"

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
    $CloseBtn = New-BaseButton @{
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
    [System.Windows.Controls.DockPanel]::SetDock($CloseBtn, 'Right')
    $SearchDock.Children.Add($CloseBtn) | Out-Null

    # Next button (Dock Right)
    $NextBtn = New-BaseButton @{
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
    [System.Windows.Controls.DockPanel]::SetDock($NextBtn, 'Right')
    $SearchDock.Children.Add($NextBtn) | Out-Null

    # Prev button (Dock Right)
    $PrevBtn = New-BaseButton @{
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
    [System.Windows.Controls.DockPanel]::SetDock($PrevBtn, 'Right')
    $SearchDock.Children.Add($PrevBtn) | Out-Null

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
        Matches      = [System.Collections.ArrayList]@()
        CurrentIndex = -1
    }

    $SearchInput.Add_TextChanged({
            param($sender, $e)
            Invoke-SearchExecution -SearchBox $sender
        })

    $SearchInput.Add_KeyDown({
            param($sender, $e)
            if ($e.Key -eq 'Escape') {
                Close-SearchBar -ChildElement $sender
                $e.Handled = $true
            }
            elseif ($e.Key -eq 'Enter' -or $e.Key -eq 'Return') {
                if ([System.Windows.Forms.Control]::ModifierKeys -match 'Shift') {
                    Step-SearchMatch -ChildElement $sender -Direction 'Prev'
                }
                else {
                    Step-SearchMatch -ChildElement $sender -Direction 'Next'
                }
                $e.Handled = $true
            }
        })

    $NextBtn.Add_Click({
            param($sender, $e)
            Step-SearchMatch -ChildElement $sender -Direction 'Next'
        })

    $PrevBtn.Add_Click({
            param($sender, $e)
            Step-SearchMatch -ChildElement $sender -Direction 'Prev'
        })

    $CloseBtn.Add_Click({
            param($sender, $e)
            Close-SearchBar -ChildElement $sender
        })

    return $SearchBarBorder
} # function New-SearchBar

#endregion #3 Content Controls Elements

#region #3 Button Elements

function New-MinMaxButton {
    $MinMaxButton = New-BaseMenuItem @{
        Name    = $MinMaxButtonName
        Header  = $MinMaxButtonMinedIcon
        ToolTip = $MinMaxButtonMinedToolTip
    }
    $MinMaxButton.Add_Click({
            param($sender, $e)
            if ([System.Windows.Forms.Control]::ModifierKeys -match 'Shift') {
                $AlternateBehavior = $true
            }
            $ChangedChild = $false

            $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
            $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
            if ($AlternateBehavior) {
                [array]$MinMaxButtons = Find-ObjectWhere -Object ([ref]$ContentSlotElement) -FindWhere { $_.Name -eq $MinMaxButtonName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
                :MinMaxButtons foreach ($MinMaxButton in $MinMaxButtons) {
                    if ($MinMaxButton.Header -eq $sender.Header) { $ChangedChild = $true }

                    $ButtonsContentHeaderBorder = Find-ObjectWhere -Object ([ref]$MinMaxButton) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
                    $ButtonsContentSlotElement = Find-ObjectWhere -Object ([ref]$ButtonsContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

                    switch ($sender.Header) {
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

            if (!$AlternateBehavior -or ($AlternateBehavior -and (-not $ChangedChild -or $sender.Header -eq $MinMaxButtonMaxedIcon))) {
                switch ($sender.Header) {
                    $MinMaxButtonMinedIcon {
                        $ContentSlotElement.Visibility = 'Collapsed'
                        $sender.Header = $MinMaxButtonMaxedIcon
                        $sender.Tooltip = $MinMaxButtonMaxedToolTip
                        $SearchBar = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$SearchBarNameSuffix" } -FindMax 1
                        if ($SearchBar -and $SearchBar.Visibility -eq 'Visible') {
                            Close-SearchBar -ChildElement $SearchBar
                        }
                    }
                    $MinMaxButtonMaxedIcon {
                        $ContentSlotElement.Visibility = 'Visible'
                        $sender.Tooltip = $MinMaxButtonMinedToolTip
                        $sender.Header = $MinMaxButtonMinedIcon
                    }
                }
            }
        }
    )
    return $MinMaxButton
} # function New-MinMaxButton

function New-AddArrayItemButton {
    param( [type]$Type )
    $AddArrayItemButton = New-BaseMenuItem @{
        Name   = $AddArrayItemButtonName
        Tag    = $Type.FullName
        Header = $AddArrayItemButtonIcon
    }
    $AddArrayItemButton.Add_Click({
            param($sender, $e)
            $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
            if ($ContentHeaderBorder) {
                $Color = '#' + $ContentHeaderBorder.Background.Color.ToString().Substring(3)
                $IndexOfColorSequence = $ColorSequence.IndexOf($Color)

                $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1

                $NewItem = New-TypeContent -WrapperType 'Border' -Type $sender.Tag.TrimEnd('[]') -ArrayType 'ArrayItem' -Index $ContentSlotElement.Children.Count -Depth ($IndexOfColorSequence + 1)
                Add-ContentToWrapper ([ref]$ContentHeaderBorder) ([ref]$NewItem)
            }
        })

    return $AddArrayItemButton
} # function New-AddArrayItemButton

function New-ClearButton {
    param(
        [string]$Header = $ClearButtonHeader,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

    $ClearButton = New-BaseMenuItem @{
        Name   = "$ActionFrom`_$ClearButtonNameSuffix"
        Header = $Header
        Icon   = $ClearButtonIcon
    }
    $ClearButton.Add_Click({
            param($sender, $e)
            $ContentWrapper = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$ClearButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
            if ($ContentWrapper) { Clear-WrapperContent ([ref]$ContentWrapper) }
        }
    )
    return $ClearButton
} # function New-ClearButton

function New-RandomValuesButton {
    param(
        [string]$Header = $RandomValuesButtonHeader,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

    $RandomValuesButton = New-BaseMenuItem @{
        Name   = "$ActionFrom`_$RandomValuesButtonNameSuffix"
        Header = $Header
        Icon   = $RandomValuesButtonIcon
    }
    $RandomValuesButton.Add_Click({
            param($sender, $e)
            $ContentWrapper = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$RandomValuesButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
            if ($ContentWrapper) { Set-WrapperRandomContent ([ref]$ContentWrapper) }
        }
    )
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

    $DisableEnableButton.Add_Click({
            param($sender, $e)
            if ((Get-IsLocked $sender)) { return }
            $Parent = $Sender.Parent
            $IsAll = $sender.Header -like '* All' -or ($sender.Tag -is [hashtable] -and $sender.Tag.IsAll)

            switch ($sender.Icon) {
                $DisableEnableButtonIconDisabled {
                    $sender.Header = if ($IsAll) { $DisableEnableButtonHeaderEnabled + ' All' } else { $DisableEnableButtonHeaderEnabled }
                    $sender.Icon = $DisableEnableButtonIconEnabled
                    $TargetIndex = if ($sender.Tag -is [hashtable]) { $sender.Tag.Index } else { $sender.Tag }
                    Remove-CustomMenuChild ([ref]$Parent) ([ref]$sender)
                    Add-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$sender) $TargetIndex
                    $sender.Tag = $null

                    if ($IsAll) {
                        $ContentWrapper = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$DisableEnableButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                        $ChildButtons = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $sender }
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
                        Confirm-ArrayEnableButton -Item ([ref]$sender)
                    }
                }
                $DisableEnableButtonIconEnabled {
                    $TagInfo = if ($IsAll) { @{ Index = $Parent.Items.IndexOf($sender); IsAll = $true } } else { $Parent.Items.IndexOf($sender) }
                    $sender.Tag = $TagInfo
                    $sender.Header = if ($IsAll) { $DisableEnableButtonHeaderDisabled + ' All' } else { $DisableEnableButtonHeaderDisabled }
                    $sender.Icon = $DisableEnableButtonIconDisabled
                    Remove-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$sender)
                    Add-CustomMenuChild ([ref]$Parent) ([ref]$sender)

                    if ($IsAll) {
                        $ContentWrapper = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$DisableEnableButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                        $ChildButtons = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -like "*$DisableEnableButtonNameSuffix" -and $_ -ne $sender }
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
                        Confirm-ArrayEnableButton -Item ([ref]$sender)
                    }
                }
            }
        })

    return $DisableEnableButton
} # function New-DisableEnableButton

function New-DeleteButton {
    param(
        [string]$Header = $DeleteButtonHeader,
        [string]$ActionFrom = $ContentHeaderBorderName
    )

    $DeleteButton = New-BaseMenuItem @{
        Name   = "$ActionFrom`_$DeleteButtonNameSuffix"
        Header = $Header
        Icon   = $DeleteButtonIcon
    }

    $DeleteButton.Add_Click({
            param($sender, $e)
            if ((Get-IsLocked $sender)) { return }
            $ContentWrapper = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$DeleteButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
            if (-not $ContentWrapper) { return }

            $IsAll = $sender.Header -like '* All'
            if ($IsAll) {
                $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
                if ($ContentSlotElement) {
                    :Delete foreach ($Child in @($ContentSlotElement.Children)) {
                        if ((Get-IsLocked $Child)) { continue Delete } # TODO: Flash Lock
                        $ContentSlotElement.Children.Remove($Child)
                    }
                    Reset-ArrayIndexes ([ref]$ContentSlotElement)
                    Confirm-ArrayEnableButton -Item ([ref]$ContentWrapper)
                }
            }
            else {
                if ((Get-IsLocked $ContentWrapper)) { return }
                $Array = $ContentWrapper.Parent
                if ($Array) {
                    $Array.Children.Remove($ContentWrapper)
                    Reset-ArrayIndexes ([ref]$Array)
                    Confirm-ArrayEnableButton -Item ([ref]$Array)
                }
            }
        }
    )

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

    $SearchButton.Add_Click({
            param($sender, $e)
            $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
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
        })

    return $SearchButton
} # function New-SearchButton

function New-LockButton {
    param($ActionFrom)

    $LockUnlockButton = New-BaseMenuItem @{
        Name   = $LockUnlockButtonName
        Header = $LockUnlockButtonHeaderUnlocked
        Icon   = $LockUnlockButtonIconUnlocked
    }

    $LockUnlockButton.Add_Click({
            param($sender, $e)
            $Parent = $Sender.Parent
            switch ($sender.Icon) {
                $LockUnlockButtonIconLocked {
                    $sender.Header = $LockUnlockButtonHeaderUnlocked
                    $sender.Icon = $LockUnlockButtonIconUnlocked
                    Remove-CustomMenuChild ([ref]$Parent) ([ref]$sender)
                    Add-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$sender) $sender.Tag
                    # Remove LockButton Index from Tag property
                    $sender.Tag = $null
                }
                $LockUnlockButtonIconUnlocked {
                    # Add LockButton Index to Tag property
                    $sender.Tag = $Parent.Items.IndexOf($sender)
                    $sender.Header = $LockUnlockButtonHeaderLocked
                    $sender.Icon = $LockUnlockButtonIconLocked
                    Remove-ChildToItemsButtonMenu ([ref]$Parent) ([ref]$sender)
                    Add-CustomMenuChild ([ref]$Parent) ([ref]$sender)
                }
            }


        })

    return $LockUnlockButton
} # function New-LockButton

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
        param($sender, $e)
        if ($e.Key -eq 'F' -and [System.Windows.Input.Keyboard]::Modifiers -match 'Control') {
            $Focused = [System.Windows.Input.FocusManager]::GetFocusedElement($BaseWindow)
            $TargetBtn = $null
            if ($Focused) {
                $ParentBorder = Find-ObjectWhere -Object ([ref]$Focused) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
                if ($ParentBorder) {
                    $TargetBtn = Find-ObjectWhere -Object ([ref]$ParentBorder) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" } -FindMax 1
                }
            }
            if (-not $TargetBtn) {
                $SearchButtons = Find-ObjectWhere -Object ([ref]$BaseWindow) -FindWhere { $_.Name -like "*$SearchButtonNameSuffix" }
                if ($SearchButtons -and @($SearchButtons).Count -gt 0) {
                    $TargetBtn = @($SearchButtons)[0]
                }
            }
            if ($TargetBtn) {
                $TargetBtn.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.MenuItem]::ClickEvent)))
                $e.Handled = $true
            }
        }
    })

$BaseWindow.ShowDialog() | Out-Null

#endregion #9 WindowBase
