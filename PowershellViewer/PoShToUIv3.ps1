<# PoshToUI
    To Do:
        DropDown
            Sort
            Search

        Content Actions
            Search - Highlights matches
            CopyAs (JSON, CSV)

        Array Actions
            Lock / Unlock - Prevents reordering, adding, or removing items
            Random Values - Fills array with random values
            Search - Highlights matches
            Filter - Removes non-matching items
            Sort
                By: Property, Value
                Order: Ascending, Descending
            AsBlock (Delimiter*) - * Default is Comma; NewLine is always an additional delimiter (NewLine explanation in ToolTip)
                AsBoxes - switches with AsBlock, default

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
$CheckBoxDisabledColor = '#ff8181'

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

$DeleteAllArrayItemsButtonNameSuffix = 'DeleteAllArrayItemsButton'
$DisableEnableAllArrayItemsButtonNameSuffix = 'DisableEnableAllArrayItemsButton'
$MinMaxButtonName = 'MinMaxButton'
$EnableCheckBoxName = 'EnableCheckBox'

$EnableDisableButtonNameSuffix = 'EnableDisableButton'
$DeleteButtonNameSuffix = 'DeleteButton'
$ConstructButtonNameSuffix = 'ConstructButton'
$ClearButtonNameSuffix = 'ClearButton'
$DragHandleNameSuffix = 'DragHandle'

$IndexBoxNameSuffix = 'IndexBox'

$CustomDateTimePickerName = 'CustomDateTimePicker'
$ContentDateTimeDisplayTextBoxName = 'DisplayTextBox'

# UI Element Headers, Icons, & ToolTips
$ClearButtonHeader = 'Clear'
$ClearButtonIcon = '🧹'
$DeleteButtonHeader = 'Delete'
$DeleteButtonIcon = '🗑'
$EnableDisableButtonEnabledHeader = 'Enable'
$EnableDisableButtonEnabledIcon = '✔'
$EnableDisableButtonDisabledHeader = 'Disable'
$EnableDisableButtonDisabledIcon = '❌'
$ConstructButtonHeader = 'Construct'
$ConstructButtonIcon = '🔨'
$MinMaxButtonMaxedIcon = '🔽'
$MinMaxButtonMaxedToolTip = "Minimize`nSHIFT: Alternate Behavior"
$MinMaxButtonMinedIcon = '🔼'
$MinMaxButtonMinedToolTip = "Maximize`nSHIFT: Alternate Behavior"
$DragHandleIcon = '☰'
$DragHandleToolTip = "Drag to reorder`nSHIFT: Swap positions"



#endregion #0 Variables


#region #0 Add Types

Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

#endregion #0 Add Types


#region #0 PowerShell Helper Functions

function ViewUI {
    param([Parameter(ValueFromPipeline = $true)]$UIElement)
    begin {
        $r = @()
    }
    process {
        $r += $UIElement | Select-Object @{n = 'Parent'; e = { $_.Parent.GetType().Name } }, Name, @{n = 'Type'; e = { $_.GetType().Name } },
        Child, Content, Children, Items, ToolBars, Text, SelectedItem, Password, DataContext, Header
    }
    end {
        if ($r.count -gt 1) { $r | Format-Table }
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

function New-BaseCheckBox {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.CheckBox]$Parameters
} # function New-BaseCheckBox

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

    $Menu = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $MenuName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }

    try {
        $Menu.Items.Add($Child.Value) | Out-Null
    }
    catch {
        Write-Host "{Add-CustomMenuChild} $_" -ForegroundColor Red
    }
} # function Add-CustomMenuChild

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

function Clear-WrapperContent {
    param(
        [ref]$Wrapper
    )
    $Contents = Find-ObjectWhere -Object $Wrapper -FindWhere { $_.Name -eq $ContentElementName }
    :Contents foreach ($Content in $Contents) {
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

function Confirm-ArrayEnableButton {
    param( [ref]$CheckBox )
    $ContentHeaderBorder = Find-ObjectWhere -Object $CheckBox -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    $ContentHeaderBorderTitle = Find-Title $ContentHeaderBorder

    # If Wrapper is not an Array, Get GrandWrapper
    if ($ContentHeaderBorderTitle -notlike '*`[]') {
        $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
    }

    $EnableCheckBoxes = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -eq $EnableCheckBoxName } -DepthMax 3 -DepthWhere { $_.Name -eq $ContentSlotElementName }

    [array]$IsCheckedGroupings = $EnableCheckBoxes.IsChecked | Group-Object

    if ($IsCheckedGroupings.Count -eq 1) {
        if ($IsCheckedGroupings.Name -eq 'false') {
            $NewHeader = $EnableDisableButtonEnabledHeader + ' All'
            $NewIcon = $EnableDisableButtonEnabledIcon
        }
        else {
            $NewHeader = $EnableDisableButtonDisabledHeader + ' All'
            $NewIcon = $EnableDisableButtonDisabledIcon
        }
        $EnableDisableButton = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$DisableEnableAllArrayItemsButtonNameSuffix" } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
        try {
            $EnableDisableButton.Header = $NewHeader
            $EnableDisableButton.Icon = $NewIcon
        }
        catch {
            Write-Host "{Confirm-ArrayEnableButton} $_" -ForegroundColor Red
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

    $IsArray = $Type.IsArray

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
        $ClearButton.Header = $ClearButtonHeader + ' All'
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

    $ContentWrapper = New-ContentWrapper -WrapperType $WrapperType -Type $TargetType -Title $Title -Description $Description -ArrayItem ($ArrayType -eq 'ArrayItem') -Depth $Depth

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

    $Menu = Find-ObjectWhere -Object ([ref]$Top) -FindWhere { $_.Name -eq $MenuName } -FindMax 1
    $ClearButton = Find-ObjectWhere -Object ([ref]$Menu) -FindWhere { $_.Name -like "*$ClearButtonNameSuffix" }
    if ($null -eq $ClearButton) {
        $ClearButton = New-ClearButton -Header $ClearButtonHeader -ActionFrom $Top.Name
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

        # Button: Clear All
        $ClearButton = New-ClearButton -Header "$($ClearButtonHeader + ' All')" -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$ClearButton)

        # Button: Enable/Disable All
        $EnableDisableButton = New-DisableEnableAllArrayItemsButton -ActionFrom $Wrapper.Value.Name
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$EnableDisableButton)

        # Button: Delete All
        $DeleteButton = New-DeleteAllArrayItemsButton -ActionFrom $Wrapper.Value.Name
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
        $EnableCheckBox = New-BaseCheckBox @{
            VerticalAlignment = 'Center'
            IsChecked         = $true
            Name              = $EnableCheckBoxName
            Background        = 'Transparent'
            BorderBrush       = 'Transparent'
        }
        $EnableCheckBox.Add_Checked({
                $this.Background = 'Transparent'

                Confirm-ArrayEnableButton -CheckBox ([ref]$this)

                $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$this) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
                $EnableDisableButton = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$EnableDisableButtonNameSuffix" } -FindMax 1 -DepthMax 2 -DepthWhere { $_.Name -eq $ContentSlotElementName }
                if ($EnableDisableButton) {
                    $EnableDisableButton.Header = $EnableDisableButtonDisabledHeader
                    $EnableDisableButton.Icon = $EnableDisableButtonEnabledIcon
                }
            })
        $EnableCheckBox.Add_UnChecked({
                $this.Background = $CheckBoxDisabledColor

                Confirm-ArrayEnableButton -CheckBox ([ref]$this)

                $ContentHeaderBorder = Find-ObjectWhere -Object ([ref]$this) -FindWhere { $_.Name -eq $ContentHeaderBorderName } -DigProperties 'Parent' -FindMax 1
                $EnableDisableButton = Find-ObjectWhere -Object ([ref]$ContentHeaderBorder) -FindWhere { $_.Name -like "*$EnableDisableButtonNameSuffix" } -FindMax 1 -DepthMax 2 -DepthWhere { $_.Name -eq $ContentSlotElementName }
                if ($EnableDisableButton) {
                    $EnableDisableButton.Header = $EnableDisableButtonEnabledHeader
                    $EnableDisableButton.Icon = $EnableDisableButtonEnabledIcon
                }
            })
        $ArrayItemStack = New-BaseStackPanel @{
            Name                = $ArrayItemStackName
            Orientation         = 'Horizontal'
            HorizontalAlignment = 'Stretch'
        }
        $ArrayItemStack.AddChild($DragHandle) | Out-Null
        $ArrayItemStack.AddChild($IndexBlock) | Out-Null
        $ArrayItemStack.AddChild($EnableCheckBox) | Out-Null

        $ContentBorderDock.Children.Insert(0, $ArrayItemStack)

        #endregion Array Item Controls

        #region Array Item Buttons

        # Button: Delete
        $DeleteButton = New-BaseMenuItem @{
            Header = $DeleteButtonHeader
            Name   = $Wrapper.Value.Name + '_' + $DeleteButtonNameSuffix
            Icon   = $DeleteButtonIcon
        }
        $DeleteButton.Add_Click({
                param($sender, $e)
                $ArrayItem = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$DeleteButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                if ($ArrayItem) {
                    $Array = $ArrayItem.Parent
                    $Array.Children.Remove($ArrayItem)
                    Reset-ArrayIndexes ([ref]$Array)
                }
            }
        )

        # Button: Enable/Disable
        $EnableDisableButton = New-BaseMenuItem @{
            Name   = $Wrapper.Value.Name + '_' + $EnableDisableButtonNameSuffix
            Header = $EnableDisableButtonDisabledHeader
            Icon   = $EnableDisableButtonDisabledIcon
        }
        $EnableDisableButton.Add_Click({
                param($sender, $e)
                $ArrayItem = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$EnableDisableButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
                $EnableCheckBox = Find-ObjectWhere -Object ([ref]$ArrayItem) -FindWhere { $_.Name -eq $EnableCheckBoxName } -DepthMax 2 -DepthWhere { $_.Name -eq $ContentSlotElementName }

                $NewIcon = if ($EnableCheckBox.IsChecked) { $EnableDisableButtonDisabledIcon } else { $EnableDisableButtonEnabledIcon }
                $NewHeader = if ($EnableCheckBox.IsChecked) { $EnableDisableButtonDisabledHeader } else { $EnableDisableButtonEnabledHeader }

                if ($EnableCheckBox) {
                    $EnableCheckBox.IsChecked = -not $EnableCheckBox.IsChecked
                    $sender.Header = $NewHeader
                    $sender.Icon = $NewIcon
                }
            })

        # Button: Clear
        $ClearButton = New-ClearButton -ActionFrom $Wrapper.Value.Name

        Add-ChildToItemsButtonMenu $Wrapper ([ref]$ClearButton)
        Add-ChildToItemsButtonMenu $Wrapper ([ref]$EnableDisableButton)
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

    $Value = switch ($Object.GetType().Name) {
        'PasswordBox' { $Object.Password }
        'TextBox' { $Object.Text }
        'ComboBox' { $Object.SelectedItem }
        'Button' { $Object.Content }
    }

    if ([bool]$Value) { return $Value }
    else { return $null }
} # function Get-ContentValue

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

#endregion #3 Content Controls Elements

#region #3 Button Elements

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
        Tag    = $Type.FullName
        Header = '➕'
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

function New-DeleteAllArrayItemsButton {
    param(
        $ActionFrom = $ContentHeaderBorderName
    )
    # Button: Delete All Array Items
    $DeleteAllArrayItemsButton = New-BaseMenuItem @{
        Name   = "$ActionFrom`_$DeleteAllArrayItemsButtonNameSuffix"
        Header = 'Delete All'
        Icon   = '🗑'
    }
    $DeleteAllArrayItemsButton.Add_Click({
            param($sender, $e)
            # Remove all children from the ContentSlotElement of the parent ContentWrapper
            $ContentWrapper = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$DeleteAllArrayItemsButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
            $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -eq $ContentSlotElementName } -FindMax 1
            $ContentSlotElement.Children.RemoveRange(0, $ContentSlotElement.Children.Count)

            # Reset Enable/Disable All button state
            $DisableEnableAllArrayItemsButton = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -like "*$DisableEnableAllArrayItemsButtonNameSuffix" } -FindMax 1
            if ($DisableEnableAllArrayItemsButton) {
                $DisableEnableAllArrayItemsButton.Header = $EnableDisableButtonDisabledHeader + ' All'
                $DisableEnableAllArrayItemsButton.Icon = $EnableDisableButtonDisabledIcon
            }
        })
    return $DeleteAllArrayItemsButton
} # function New-DeleteAllArrayItemsButton

function New-DisableEnableAllArrayItemsButton {
    param(
        $ActionFrom
    )
    # Button: Disable/Enable All
    $DisableEnableAllArrayItemsButton = New-BaseMenuItem @{
        Name   = "$ActionFrom`_$DisableEnableAllArrayItemsButtonNameSuffix"
        Header = $EnableDisableButtonDisabledHeader + ' All'
        Icon   = $EnableDisableButtonDisabledIcon
    }
    $DisableEnableAllArrayItemsButton.Add_Click({
            param($sender, $e)
            $ContentWrapper = Find-ObjectWhere -Object ([ref]$sender) -FindWhere { $_.Name -eq "$($sender.Name.Replace("_$DisableEnableAllArrayItemsButtonNameSuffix", ''))" } -DigProperties 'Parent' -FindMax 1
            $ContentSlotElement = Find-ObjectWhere -Object ([ref]$ContentWrapper) -FindWhere { $_.Name -eq $ContentSlotElementName } -DepthMax 1 -DepthWhere { $_.Name -eq $ContentSlotElementName }
            $EnableCheckBoxes = Find-ObjectWhere -Object ([ref]$ContentSlotElement) -FindWhere { $_.Name -eq $EnableCheckBoxName } -DepthMax 1 -DepthWhere { $_.Name -eq $ConstructName }

            $isCheckedValue = $sender.Header -eq ($EnableDisableButtonEnabledHeader + ' All')
            :EnableCheckBoxes foreach ($CheckBox in $EnableCheckBoxes) {
                if ($CheckBox.IsChecked -ne $isCheckedValue) {
                    $CheckBox.IsChecked = $isCheckedValue
                }
            } # EnableCheckBoxes

        })
    return $DisableEnableAllArrayItemsButton
} # function New-DisableEnableAllArrayItemsButton

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


$BaseWindow.ShowDialog() | Out-Null

#endregion #9 WindowBase
