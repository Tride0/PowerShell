<# PoshToUI
    Content Actions
        Min/Max - DONE
        CopyAs (JSON, CSV)

    Array Actions
        AsBlock (Delimiter)
        AsBoxes
        Sort
        Search
        Filter

    Array Item Actions
        Arrange (DragDrop, NumberBox)
        Enable
        Delete

    Test Types:
        System.String[]
        System.Windows.Automation.DockPosition
        System.DirectoryServices.Protocols.LdapConnection
        System.DirectoryServices.DirectorySearcher
        System.Diagnostics.EventLog

#>

Add-Type -AssemblyName PresentationFramework

#region 0 Variables

$Title = 'DirectorySearcher'

$TypeToShow = 'System.DirectoryServices.DirectorySearcher'

$UIDefaults = @{
    Margin = 1.5
}

$FontSizes = @{
    Default     = 10
    Title       = 16
    MiniTitle   = 12
    Description = 10
    Button      = 14
}

#endregion 0 Variables

#region 0 PowerShell Helper Functions

function ViewUI {
    param([Parameter(ValueFromPipeline = $true)]$UIElement)
    process {
        $UIElement | Select-Object Parent, Tag, @{n = 'Type'; e = { $_.GetType() } }, DataContext, Child, Content, Children, Items, ToolBars, Text
    }
}

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
} # END Function Get-UniqueByProperty


#endregion 0 PowerShell Helper Functions

#region 0 UI Controls

#region 1 UI Helper Functions

function Find-ParentByTag {
    param([Parameter(ValueFromPipeline = $true)][ref]$Object, [string]$Tag)

    $CurrentObject = $Object.Value

    :searchLoop while ($CurrentObject.Parent) {
        if ($CurrentObject.Parent.Tag -eq $Tag) {
            return ([ref]$CurrentObject.Parent)
        }
        elseif ([Bool]$CurrentObject.Parent) {
            $CurrentObject = $CurrentObject.Parent
        }
        else {
            break searchLoop
        }
    }

    return $null
} # function Find-ParentByTag

function Find-ChildByTag {
    param(
        [parameter(ValueFromPipeline)][ref]$Object,
        [string]$Tag,
        $PropertiesToSearch = @('Children', 'Content', 'Child', 'ToolBars', 'Items'),
        $Depth = 0
    )

    foreach ($Property in $PropertiesToSearch) {
        if ([bool]$Object.Value.$Property) {
            foreach ($Child in @($Object.Value.$Property)) {
                if ($Child.Tag -eq $Tag) { return $Child }

                $FoundChild = Find-ChildByTag -Object $([ref]$Child) -Tag $Tag -Depth ($Depth + 1)
                if ($FoundChild) {
                    #Write-Host "{Find-ChildByTag:$Tag} Depth:$Depth Found:$($FoundChild.count) $($Object.Value.Tag) > $($FoundChild.Tag)" -ForegroundColor DarkCyan
                    return $FoundChild
                }
            }
        }
    }
} # Function Find-ChildByTag

function Find-ChildByPropertyValue {
    param(
        [parameter(ValueFromPipeline)][ref]$Object,
        [string]$Property,
        $Value,
        $PropertiesToSearch = @('Children', 'Content', 'Child'),
        $Depth = 0
    )

    foreach ($Property in $PropertiesToSearch) {
        if ([bool]$Object.Value.$Property) {
            foreach ($Child in @($Object.Value.$Property)) {
                if ($Child.$Property -eq $Value) { return $Child }

                $FoundChild = Find-ChildByPropertyValue -Object $([ref]$Child) -Property $Property -Value $Value -Depth ($Depth + 1)
                if ($FoundChild) {
                    Write-Host "{Find-ChildByPropertyValue:$Property=$Value} Depth:$Depth Found:$($FoundChild.count) $($Object.Value.$Property) > $($FoundChild.Tag)" -ForegroundColor DarkCyan
                    return $FoundChild
                }
            }
        }
    }
} # function Find-ChildByPropertyValue

function Find-SiblingByTag {
    param([ref]$Object, $ParentTag, $SiblingTag)

    $Parent = Find-ParentByTag -Object $Object -Tag $ParentTag
    Find-ChildByTag -Object $Parent -Tag $SiblingTag
} # function Find-SiblingByTag

function Find-ChildrenByTag {
    param(
        [parameter(ValueFromPipeline)][ref]$Object,
        [string]$Tag,
        $PropertiesToSearch = @('Children', 'Content', 'Child', 'ToolBars', 'Items'),
        $Depth = 0
    )
    $FoundChildren = @()
    foreach ($Property in $PropertiesToSearch) {
        if ([bool]$Object.Value.$Property) {
            foreach ($Child in @($Object.Value.$Property)) {
                if ($Child.Tag -eq $Tag) { $FoundChildren += $Child }

                $FoundChild = Find-ChildrenByTag -Object $([ref]$Child) -Tag $Tag -Depth ($Depth + 1)
                if ($FoundChild) {
                    #Write-Host "{Find-ChildrenByTag:$Tag} Depth:$Depth Found:$($FoundChild.count) $($Object.Value.Tag) > $($FoundChild.Tag)" -ForegroundColor DarkCyan
                    $FoundChildren += $FoundChild
                }
            }
        }
    }
    return $FoundChildren
} # Function Find-ChilrendByTag

function Find-Title {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [ref]$Object
    )
    $Header = Find-SiblingByTag -Object $Object -ParentTag 'ContentWrapper' -SiblingTag 'Header'
    $Title = Find-ChildByTag -Object ([ref]$Header) -Tag 'Title'
    $Description = Find-ChildByTag -Object ([ref]$Header) -Tag 'Description'
    return "$($Title.Text) - $($Description.Text)"
}

#endregion 1 UI Helper Functions

#region 1 Base UI Controls

#region 2 Base UI Control Actions

function Add-BaseStackPanelChild {
    param( [ref]$StackPanel, [ref]$Child )
    $StackPanel.Value.AddChild($Child.Value)
} # function Add-BaseStackPanelChild

function Add-BaseScrollViewerChild {
    param( [ref]$ScrollViewer, [ref]$Child )
    $ScrollViewer.Value.AddChild($Child.Value)
} # function Add-BaseScrollViewerChild

function Add-BaseDockPanelChild {
    param( [ref]$DockPanel, [ref]$Child, [System.Windows.Controls.Dock]$DockTo )
    Try {
        $DockPanel.Value.AddChild($Child.Value)
        if ($DockTo) { [System.Windows.Controls.DockPanel]::SetDock($Child.Value, $DockTo) }
    }
    Catch {
        Write-Error "{Add-BaseDockPanelChild} $_"
    }
} # function Add-BaseDockPanelChild

function Add-BaseToolBarChild {
    param( [ref]$ToolBar, [ref]$Child )
    $ToolBar.Value.AddChild($Child.Value)
} # function Add-BaseToolBarChild

function Add-BaseToolBarTrayChild {
    param( [ref]$ToolBarTray, [ref]$Child )
    $ToolBarTray.Value.AddChild($Child.Value)
} # function Add-BaseToolBarTrayChild

function Add-BaseMenuChild {
    param( [ref]$Menu, [ref]$Child )
    $Menu.Value.AddChild($Child.Value)
} # function Add-BaseMenuChild

function Remove-BaseMenuChild {
    param( [ref]$Menu, [ref]$Child )
    $Menu.Value.Items.Remove($Child.Value)
}

function Add-BaseMenuItemChild {
    param( [ref]$MenuItem, [ref]$Child )
    $MenuItem.Value.AddChild($Child.Value)
} # function Add-BaseMenuItemChild

#endregion 2 Base UI Control Actions

#region 2 Base UI Control Elements

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
    [System.Windows.Controls.TextBlock]$Parameters
} # function New-BaseTextBlock

function New-BaseButton {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.Button]$Parameters
} # function New-BaseButton

function New-BaseSeparator {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.Separator]$Parameters
} # function New-BaseSeparator

function New-BaseRectangle {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Shapes.Rectangle]$Parameters
} # function New-BaseRectangle

function New-BaseLine {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Shapes.Line]$Parameters
} # function New-BaseLine

function New-BaseCheckBox {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.CheckBox]$Parameters
} # function New-BaseCheckBox

function New-BaseComboBox {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.ComboBox]$Parameters
} # function New-BaseComboBox

function New-BaseToolBar {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.ToolBar]$Parameters
} # function New-BaseToolBar

function New-BaseToolBarTray {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.ToolBarTray]$Parameters
} # function New-BaseToolBarTray

function New-BaseMenu {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.Menu]$Parameters
} # function New-BaseMenu

function New-BaseMenuItem {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.MenuItem]$Parameters
} # function New-BaseMenuItem

function New-BaseDatePicker {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.DatePicker]$Parameters
} # function New-BaseDatePicker

function New-BaseDataGrid {
    param( [hashtable]$Parameters = @{} )
    [System.Windows.Controls.DataGrid]$Parameters
} # function New-BaseDataGrid

#endregion 2 Base UI Control Elements

#endregion 1 Base UI Controls

#region 1 Custom UI Controls

#region 2 Custom UI Actions

function Reindex-ArrayItem {
    param(
        [ref]$Border
    )

    $IndexCounter = 1
    foreach ($Child in $Border.Value.Children) {
        if ($Child.Tag -eq 'ArrayItemBorder') {
            $IdxBlock = Find-ChildByTag -Object ([ref]$Child) -Tag 'Index'
            if ($IdxBlock) {
                $IdxBlock.Text = "$IndexCounter"
            }
            $IndexCounter++
        }
    }

} # function Reindex-ArrayItem

function Add-ContentWrapperContent {
    param( [ref]$ContentWrapper, [ref]$Content )
    $ContentStackBoard = Find-ChildByTag -Object $ContentWrapper -Tag 'ContentStackBoard'
    $ContentStackBoard.AddChild($Content.Value)
} # function Add-ContentWrapperContent

function Add-CustomMenuChild {
    param( [ref]$Wrapper, [ref]$Child )
    $Menu = Find-ChildByTag -Object $Wrapper -Tag 'Menu'
    $Menu.Items.Add($Child.Value) | Out-Null
} # function Add-CustomMenuChild

function Add-ButtonMenuChild {
    param( [ref]$ButtonMenu, [ref]$Child )
    $MenuActionsItem = Find-ChildByTag -Object $ButtonMenu -Tag 'ButtonMenu'
    $MenuActionsItem.Items.Add($Child.Value) | Out-Null
    $MenuActionsItem.Visibility = 'Visible'
} # function Add-ButtonMenuChild

function Remove-ButtonMenuChild {
    param( [ref]$ButtonMenu, [ref]$Child )
    $MenuActionsItem = Find-ChildByTag -Object $ButtonMenu -Tag 'ButtonMenu'
    $MenuActionsItem.Items.Remove($Child.Value) | Out-Null
} # function Remove-ButtonMenuChild

#endregion 2 Custom UI Actions

#region 2 Custom UI Elements

function New-CustomMenu {
    param( $Tag = 'Menu' )
    $Menu = New-BaseMenu @{
        Tag                 = $Tag
        Background          = 'Transparent'
        VerticalAlignment   = 'Center'
        Cursor              = 'Hand'
        HorizontalAlignment = 'Right'
        FlowDirection       = 'RightToLeft'
    }

    $MenuItem = New-BaseMenuItem @{
        Tag        = 'ButtonMenu'
        Header     = '⋮'
        Visibility = 'Collapsed'
    }
    Add-BaseMenuChild ([ref]$Menu) ([ref]$MenuItem)

    $Menu
}

function New-CustomDateTimePicker {
    param(
        [hashtable]$Parameters = @{},
        $SelectedDateTime = (Get-Date)
    )

    $Grid = [System.Windows.Controls.Grid]@{
        Tag                 = 'CustomDateTimePicker'
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
        Tag                 = 'DisplayTextBox'
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
        Focusable         = $false
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
                Background            = '#F4F4F4'
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
                    $TextBox = Find-SiblingByTag -Object ([ref]$PickButton) -ParentTag 'CustomDateTimePicker' -SiblingTag 'DisplayTextBox'
                    $TextBox.Text = $finalDateTime.ToString('yyyy-MM-dd HH:mm:ss')
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
} # function New-CustomDateTimePicker

function New-ContentWrapper {
    param(
        [ValidateSet('Title', 'MiniTitle', 'ArrayItem', 'Border')]
        [string]$WrapperType,
        $Content,
        [string]$Title,
        [string]$Description,
        [Type]$Type,
        [int]$Index = 0
    )
    $IsArray = $Type.IsArray
    switch ($WrapperType) {
        { @('Title', 'MiniTitle') -contains $_ } {
            $Border = New-BaseBorder @{
                Margin          = 2
                BorderBrush     = 'Gray'
                BorderThickness = 2
                CornerRadius    = 2
            }
            if ($_ -eq 'MiniTitle') {
                $Border.Margin = 1
                $Border.BorderThickness = 1
            }
            $StackBoard = New-BaseStackPanel @{
                Background  = 'DarkGray'
                Orientation = 'Vertical'
                Tag         = 'ContentWrapper'
            }
            $Border.AddChild($StackBoard)

            # Header
            $headerBorder = New-BaseBorder @{
                Margin          = 1
                BorderThickness = '0,0,0,1'
                BorderBrush     = 'White'
            }
            Add-BaseStackPanelChild ([ref]$StackBoard) ([ref]$headerBorder)

            $Header = New-BaseDockPanel @{
                Margin     = 0
                Tag        = 'Header'
                Background = 'LightGray'
            }
            Add-BaseStackPanelChild ([ref]$headerBorder) ([ref]$Header)

            $HeaderTitleAndDesc = New-BaseStackPanel @{
                Tag               = 'TitleAndDesc'
                VerticalAlignment = 'Center'
                Orientation       = 'Horizontal'
            }
            Add-BaseStackPanelChild ([ref]$Header) ([ref]$HeaderTitleAndDesc)

            $HeaderTitle = New-BaseTextBlock @{
                Margin     = 2
                Text       = $Title
                Tag        = 'Title'
                FontSize   = $FontSizes.$WrapperType
                FontWeight = 'Bold'
            }
            Add-BaseStackPanelChild ([ref]$HeaderTitleAndDesc) ([ref]$HeaderTitle)

            $HeaderDescription = New-BaseTextBlock @{
                Margin            = 2
                Text              = $Description
                Tag               = 'Description'
                FontSize          = $FontSizes.Description
                Foreground        = 'DimGray'
                VerticalAlignment = 'Center'
            }
            Add-BaseStackPanelChild ([ref]$HeaderTitleAndDesc) ([ref]$HeaderDescription)

            # Buttons
            $ButtonMenu = New-CustomMenu

            # Button: Min Max
            $MinMaxButton = New-BaseMenuItem @{
                Tag    = 'MinMax'
                Header = 'Min'
            }
            $MinMaxButton.Add_Click({
                    param($sender, $e)
                    $ContentStackBoard = Find-SiblingByTag -Object ([ref]$sender) -ParentTag 'ContentWrapper' -SiblingTag 'ContentStackBoard'
                    switch ($sender.Header) {
                        'Min' { $($ContentStackBoard).Visibility = 'Collapsed'; $sender.Header = 'Max' }
                        'Max' { $($ContentStackBoard).Visibility = 'Visible'; $sender.Header = 'Min' }
                    }
                }
            )
            Add-BaseMenuChild ([ref]$ButtonMenu) ([ref]$MinMaxButton)

            # Button: Add Array Item
            if ($IsArray) {
                $AddArrayItemButton = New-BaseMenuItem @{
                    Tag    = $Type.FullName
                    Header = 'Add'
                }
                $AddArrayItemButton.Add_Click({
                        param($sender, $e)
                        $ContentWrapper = Find-ParentByTag -Object ([ref]$sender) -Tag 'ContentWrapper'
                        if ($ContentWrapper) {
                            $NewItem = New-TypeContent -WrapperType ArrayItem -Type $sender.Tag.TrimEnd('[]')
                            Add-ContentWrapperContent $ContentWrapper ([ref]$NewItem)
                        }
                    }
                )
                Add-BaseMenuChild ([ref]$ButtonMenu) ([ref]$AddArrayItemButton)
            }

            $ContentStackBoard = New-BaseStackPanel @{
                Tag = 'ContentStackBoard'
            }
            $ContentStackBoard.AddChild($Content)

            Add-BaseStackPanelChild ([ref]$Header) ([ref]$ButtonMenu)

            $StackBoard.AddChild($ContentStackBoard)

            return $Border
        }
        'ArrayItem' {
            $Border = New-BaseBorder @{
                Margin          = 1
                BorderThickness = 1
                BorderBrush     = 'LightGray'
                Background      = 'White'
                Tag             = 'ArrayItemBorder'
                AllowDrop       = $true
                Uid             = [guid]::NewGuid().ToString()
            }

            $DockPanel = New-BaseDockPanel @{
                LastChildFill = $true
                Margin        = 1
            }
            $Border.AddChild($DockPanel)

            # Drag Handle
            $DragHandle = New-BaseTextBlock @{
                Text              = '☰'
                Foreground        = 'Gray'
                VerticalAlignment = 'Center'
                Cursor            = 'SizeNS'
                Tag               = 'DragHandle'
            }
            $DragHandle.Add_PreviewMouseLeftButtonDown({
                    param($sender, $e)
                    $ArrayItem = Find-ParentByTag -Object ([ref]$sender) -Tag 'ArrayItemBorder'
                    if ($ArrayItem) {
                        [System.Windows.DragDrop]::DoDragDrop($sender, $ArrayItem.Value.Uid, [System.Windows.DragDropEffects]::Move) | Out-Null
                    }
                })
            Add-BaseDockPanelChild ([ref]$DockPanel) ([ref]$DragHandle) ([System.Windows.Controls.Dock]::Left)

            # Drag & Drop Logic
            $Border.Add_DragEnter({
                    param($sender, $e)
                    $SourceUid = $e.Data.GetData([string])
                    if ($SourceUid -and $SourceUid -ne $sender.Uid) {
                        $sender.BorderBrush = 'DodgerBlue'

                        $ParentPanel = $sender.Parent
                        $SourceItem = $ParentPanel.Children | Where-Object Uid -EQ $SourceUid

                        $SourceIndex = Find-ChildByTag -Object ([ref]$SourceItem) -Tag 'Index'
                        $TargetIndex = Find-ChildByTag -Object ([ref]$sender) -Tag 'Index'

                        if ($SourceIndex -and $TargetIndex) {
                            $SourceIndex = [int]$SourceIndex.Text
                            $TargetIndex = [int]$TargetIndex.Text

                            if ($SourceIndex -gt $TargetIndex) {
                                $sender.BorderThickness = '0,2,0,0'
                            }
                            else {
                                $sender.BorderThickness = '0,0,0,2'
                            }
                        }
                    }
                })
            $Border.Add_DragLeave({
                    param($sender, $e)
                    $sender.BorderBrush = 'LightGray'
                    $sender.BorderThickness = 1
                })
            $Border.Add_DragOver({
                    param($sender, $e)
                    $e.Effects = [System.Windows.DragDropEffects]::Move
                    $e.Handled = $true
                })
            $Border.Add_Drop({
                    param($sender, $e)
                    $sender.BorderBrush = 'LightGray'
                    $sender.BorderThickness = 1

                    $SourceUid = $e.Data.GetData([string])
                    if ($SourceUid -and $sender.Parent -is [System.Windows.Controls.Panel]) {
                        $ParentPanel = $sender.Parent
                        $SourceItem = $ParentPanel.Children | Where-Object Uid -EQ $SourceUid
                        if ($SourceItem -and $SourceItem -ne $sender) {
                            $TargetIndex = $ParentPanel.Children.IndexOf($sender)
                            $ParentPanel.Children.Remove($SourceItem)
                            $ParentPanel.Children.Insert($TargetIndex, $SourceItem)
                            Reindex-ArrayItem -Border ([ref]$ParentPanel)
                        }
                    }
                })
            $Border.Add_Loaded({
                    param($sender, $e)
                    Reindex-ArrayItem -Border ([ref]$sender.Parent)
                })

            # Index + 1
            $DisplayIndex = $Index + 1
            $IndexBlock = New-BaseTextBox @{
                Text              = "$DisplayIndex"
                Margin            = '1,0,1,0'
                Foreground        = 'DarkGray'
                VerticalAlignment = 'Center'
                Tag               = 'Index'
                MinWidth          = 12
            }
            $IndexBlock.Add_KeyDown({
                    param($sender, $e)
                    if ($e.Key -eq 'Enter' -or $e.Key -eq 'Return') {
                        $Content = Find-SiblingByTag ([ref]$sender) 'ArrayItemBorder' 'Content'
                        if ($Content) { $Content.Focus() }
                    }
                })
            $IndexBlock.Add_LostFocus({
                    param($sender, $e)
                    $NewIndexText = $sender.Text
                    $ArrayItem = Find-ParentByTag -Object ([ref]$sender) -Tag 'ArrayItemBorder'

                    if ($ArrayItem -and $ArrayItem.Value.Parent -is [System.Windows.Controls.Panel]) {
                        $ParentPanel = $ArrayItem.Value.Parent

                        if ([int]::TryParse($NewIndexText, [ref]$null)) {
                            $NewIndex = [int]$NewIndexText
                            $Items = @($ParentPanel.Children | Where-Object { $_.Tag -EQ 'ArrayItemBorder' })
                            $CurrentIndex = $ParentPanel.Children.IndexOf($ArrayItem.Value)

                            $TargetIndex = $NewIndex - 1
                            if ($TargetIndex -lt 0) { $TargetIndex = 0 }
                            if ($TargetIndex -ge $Items.Count) { $TargetIndex = $Items.Count - 1 }

                            if ($TargetIndex -ne $CurrentIndex -and $TargetIndex -ge 0) {
                                $ParentPanel.Children.Remove($ArrayItem.Value)
                                $ParentPanel.Children.Insert($TargetIndex, $ArrayItem.Value)
                            }
                        }

                        Reindex-ArrayItem -Border ([ref]$ParentPanel)
                    }
                })
            Add-BaseDockPanelChild ([ref]$DockPanel) ([ref]$IndexBlock) ([System.Windows.Controls.Dock]::Left)

            # Enable/Disable Ch1eckBox
            $EnableCheckbox = New-BaseCheckBox @{
                VerticalAlignment = 'Center'
                IsChecked         = $true
                Tag               = 'EnableCheckbox'
            }
            $EnableCheckbox.Add_Checked({
                    param($sender, $e)
                    $ArrayItem = Find-ParentByTag -Object ([ref]$sender) -Tag 'ArrayItemBorder'
                    if ($ArrayItem) {
                        $ArrayItem.Value.Background = 'White'
                    }
                })
            $EnableCheckbox.Add_Unchecked({
                    param($sender, $e)
                    $ArrayItem = Find-ParentByTag -Object ([ref]$sender) -Tag 'ArrayItemBorder'
                    if ($ArrayItem) {
                        $ArrayItem.Value.Background = '#FFDDDD' # Light red
                    }
                })
            Add-BaseDockPanelChild ([ref]$DockPanel) ([ref]$EnableCheckbox) ([System.Windows.Controls.Dock]::Left)

            $Menu = New-CustomMenu
            Add-BaseDockPanelChild ([ref]$DockPanel) ([ref]$Menu) ([System.Windows.Controls.Dock]::Right)

            $DeleteAction = New-BaseMenuItem @{ Header = 'Delete' }
            $DeleteAction.Add_Click({
                    param($sender, $e)
                    $ArrayItem = Find-ParentByTag -Object ([ref]$sender) -Tag 'ArrayItemBorder'
                    if ($ArrayItem -and $ArrayItem.Value.Parent -is [System.Windows.Controls.Panel]) {
                        $ParentPanel = $ArrayItem.Value.Parent
                        $ParentPanel.Children.Remove($ArrayItem.Value)
                        Reindex-ArrayItem -Border ([ref]$ParentPanel)
                    }
                }
            )   
            Add-ButtonMenuChild ([ref]$Menu) ([ref]$DeleteAction)

            # Content
            Add-BaseDockPanelChild ([ref]$DockPanel) ([ref]$Content)
            
            return $Border
        }
        'Border' {
            $Border = New-BaseBorder @{
                Margin          = 2
                BorderThickness = '0,0,0,2'
                Background      = 'Gray'
                CornerRadius    = 5
            }
            $Border.AddChild($Content)
            return $Border
        }
    }
} # function New-ContentWrapper

function New-TypeContent {
    param(
        [ValidateSet('Title', 'MiniTitle', 'ArrayItem', 'Border')]
        [string]$WrapperType = 'Border',
        [Type]$Type,
        [string]$Title = $Type.Name.TrimEnd('[]'),
        [string]$Description = $Type.FullName
    )

    $AddConstructButton = $False
    Write-Host "{New-TypeContent} [$($WrapperType)] $($Type.Name) $Title`:$Description"

    $Content = :TypeSwitch switch ($Type.FullName.TrimEnd('[]')) {
        'System.Object' { return $null }
        { ($Type.IsArray -and $Type.GetElementType().IsEnum) -or $Type.IsEnum } {
            $EnumType = if ($Type.IsArray) { $Type.GetElementType() } else { $Type }
            New-BaseComboBox @{
                Tag         = 'Content'
                ItemsSource = $EnumType.GetEnumNames()
                Margin      = 2
                Background  = 'Silver'
            }
        }
        'System.String' {
            New-BaseTextBox @{
                Tag        = 'Content'
                Text       = $('Hello: ' + ((([char]'a'..'z' + [char]'A'..'Z' + '0'..'9') | Get-Random -Count 10) -join '') )
                Margin     = 2
                Background = 'Silver'
            }
        }
        { $_ -like 'System.Int*' -or $_ -like 'System.UInt*' -or @('System.Single', 'System.Double', 'System.Decimal') -contains $_ } {
            $TargetType = if ($Type.IsArray) { $Type.GetElementType() } else { $Type }
            $TextBox = New-BaseTextBox @{
                Tag         = 'Content'
                DataContext = $TargetType
                Text        = (Get-Random -Minimum 0 -Maximum 100).ToString()
                Margin      = 2
                Background  = 'Silver'
            }

            $TextBox.Add_PreviewTextInput({
                    param($sender, $e)
                    # Allow minus sign only at the beginning if signed type, otherwise digits only.
                    # Allow Decimal points if floating-point type.
                    $isSigned = -not $sender.DataContext.Name.StartsWith('U')
                    $isFloatingPoint = @('System.Single', 'System.Double', 'System.Decimal') -contains $sender.DataContext.FullName
                    $currentText = $sender.Text
                    $caretIndex = $sender.CaretIndex
                    $selectionLength = $sender.SelectionLength
                
                    $predictedText = $currentText.Remove($caretIndex, $selectionLength).Insert($caretIndex, $e.Text)
                    
                    $regex = '^'
                    if ($isSigned) { $regex += '-?' }
                    $regex += '\d*'
                    if ($isFloatingPoint) { $regex += '\.?\d*' }
                    $regex += '$'
                    $e.Handled = -not ($predictedText -match $regex)
                })

            $TextBox.Add_TextChanged({
                    param($sender, $e)
                    $val = $sender.Text
                    if ([string]::IsNullOrWhiteSpace($val) -or $val -eq '-') {
                        $sender.Background = 'Silver'
                        return
                    }

                    try {
                        $null = $this.DataContext::Parse($val)
                        $sender.Background = 'Silver'
                        $sender.ToolTip = $null
                    }
                    catch {
                        $sender.Background = '#FFDDDD' # Light red for overflow / invalid
                        $sender.ToolTip = "Invalid value for $($sender.DataContext.FullName)"
                    }
                })

            $TextBox
        }
        'System.Boolean' {
            # How to unselect a combobox item? 
            New-BaseComboBox @{
                Tag         = 'Content'
                ItemsSource = @(
                    $true,
                    $false
                )
            }
        }
        'System.DateTime' {
            New-CustomDateTimePicker -Parameters @{
                Tag                 = 'Content'
                HorizontalAlignment = 'Stretch'
            }
        }
        'System.Char' {
            $CharBox = New-BaseTextBox @{
                Tag        = 'Content'
                Text       = $Content.FullName
                Margin     = 2
                Background = 'Silver'
                MaxLength  = 1
            }
            $CharBox.Add_TextChanged({
                    param($sender, $e)
                    $val = $sender.Text
                    if ([string]::IsNullOrWhiteSpace($val)) {
                        $sender.Background = 'Silver'
                        return
                    }

                    try {
                        $null = [char]::Parse($val)
                        $sender.Background = 'Silver'
                        $sender.ToolTip = $null
                    }
                    catch {
                        $sender.Background = '#FFDDDD' # Light red for overflow / invalid
                        $sender.ToolTip = "Invalid value for $($sender.DataContext.FullName)"
                    }
                }
            )
            $CharBox
        }
        default {
            $Parameters = Get-TypeConstructors -Type $Type

            $StackPanel = New-BaseStackPanel @{
                Tag                 = 'Content'
                Orientation         = 'Vertical'
                HorizontalAlignment = 'Stretch'
            }

            $UniqueParameters = $Parameters | Get-UniqueByProperty -Property 'Name'
            Foreach ($Parameter in $UniqueParameters.List) {
                $ParameterUIElement = New-TypeContent -WrapperType MiniTitle -Type $Parameter.Type -Title $Parameter.Name -Description $Parameter.Type
                if ($null -ne $ParameterUIElement) {
                    $StackPanel.AddChild($ParameterUIElement)
                }
            }
            $StackPanel

            $AddConstructButton = $true
            $WrapperType = 'Title'
        }
    }

    if ($Type.IsArray) {
        $Content = New-ContentWrapper -WrapperType ArrayItem -Type $Type.GetElementType() -Content $Content
    }

    $Wrapper = New-ContentWrapper -WrapperType $WrapperType -Type $Type -Content $Content -Title $Title -Description $Description

    if ($AddConstructButton) {
        $ConstructButton = New-BaseMenuItem @{
            Header = 'Construct'
        }

        $ConstructButton.Add_Click({
                param($sender, $e)
                Construct-Object -Object ([ref]$Sender)
            })
        
        $Wrapper.DataContext = 'HasConstruct'

        Add-CustomMenuChild ([ref]$Wrapper) ([ref]$ConstructButton)
    }

    return $Wrapper
} # function New-TypeContent

function Construct-Object {
    param([ref]$Object)
    $ContentWrapper = Find-ParentByTag -Object $Object -Tag 'ContentWrapper'
    $Content = Find-ChildrenByTag -Object $ContentWrapper -Tag 'Content' | Where-Object { $_.Type.Name -ne 'StackPanel' }
    
    <# 
        Go through Content
            When coming across another
    #>
}

#endregion 2 Custom UI Elements

#endregion 1 Custom UI Controls

#endregion 0 UI Controls

#region 0 Functions

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
                write-host "HasDefaultValue: $($Parameter.DefaultValue)" -ForegroundColor Yellow -BackgroundColor Cyan
            }
        } # Parameters
    } # Constructors
} # function Get-ClassConstructors

#endregion 0 Functions

#region WindowBase

$Window = New-BaseWindow @{
    Margin = 3
    Height = 500
    Width  = 500
    Title  = $Title
}
$WindowScrollView = New-BaseScrollViewer @{
    VerticalScrollBarVisibility   = 'Auto'
    HorizontalScrollBarVisibility = 'Auto'
}
$Window.AddChild($WindowScrollView)
$WindowContentStackPanel = New-BaseStackPanel @{
    Orientation = 'Vertical'
}
$WindowScrollView.AddChild($WindowContentStackPanel)

#endregion WindowBase

$Array = New-TypeContent -WrapperType Title -Type $TypeToShow -Title $Title
$WindowContentStackPanel.AddChild($Array)

$Window.ShowDialog() | Out-Null
