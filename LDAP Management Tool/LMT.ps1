<#
    Development Plans:
        1. Test Connection
        2. Results
        3. Results Selection
        4. Results Display
        5. Results Display Settings
        6. Search Settings
        7. Search Features
            a. new Field displays relevant attribute
                i. OR = same attribute, AND = ?
#>

Clear-Host

Import-Module "$PSScriptRoot\Modules\XAML.psm1" -ErrorAction Stop -Force
$XAMLVerbose = $false

#region Default Variables

$DefaultSavePath = "$ENV:USERPROFILE\Documents\LMT"
$SettingsFilePath = "$DefaultSavePath\settings.json"   
$PrimaryColor = 'DimGray'
$SecondaryColor = 'Gray'
$AccentColor = 'ForestGreen'
$SecondaryAccentColor = 'DarkGreen'
$FontFamily = 'Consolas'

#endregion Default Variables

#region OnDemand UI Elements

$SearchGroupTemplate = {
    param($IncludeRemove, $IncludeEnable, $ParentLOperator, $Margin = '0,3,0,0')

    $SearchGroup = New-XAMLBorder -Name 'SearchGroup' -AsObject -Margin $Margin -HorizontalAlignment Stretch -BorderBrush 'DarkGray' -BorderThickness 1 -OtherAttributes @{ xmlns = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation' } -Content (
        New-XAMLStackPanel -Margin '3,3,3,0' -Orientation Vertical -Content @(
            New-XAMLGrid -HorizontalAlignment Stretch -Content @(
                New-XAMLStackPanel -Orientation Horizontal -Content @(
                    New-XAMLComboBox -Name 'LogicalOperatorsComboBox' -Height 30 -Width 50 -SelectedIndex 0 -VerticalContentAlignment Center -Content @(
                        New-XAMLTextBlock -Text 'And'
                        New-XAMLTextBlock -Text 'Or'
                    )
                    New-XAMLButton -Name 'AddSearchGroup' -Margin '3,0,0,0' -Width 75 -Content 'Add Group' -Background $AccentColor 
                    New-XAMLButton -Name 'AddSearchField' -Margin '3,0,0,0' -Width 75 -Content 'Add Field' -Background $AccentColor 
                )
                New-XAMLStackPanel -Orientation Horizontal -HorizontalAlignment Right -Content @(
                    New-XAMLComboBox -Name 'SavedSearchGroups' -Margin 3 -IsEnabled $False
                    New-XAMLButton -Name 'SaveSearchGroup' -Content 'Save' -Margin '0,0,3,0' -ToolTip 'Save Search Group for future use' -Background $AccentColor 
                    $(
                        if ($IncludeEnable) {
                            New-XAMLViewbox -Margin '0,0,3,0' -Width 36 -Height 36 -Content @(
                                New-XAMLCheckBox -Name 'SearchGroupEnabled' -ToolTip 'Use Search Group' -IsChecked $True
                            )
                        }
                    )
                    New-XAMLButton -Name 'MinimizeSearchGroup' -Margin '0,0,3,0' -Content '-' -Background $AccentColor
                    $(
                        if ($IncludeRemove) {
                            New-XAMLButton -Name 'DeleteSearchGroup' -Background Red -Content 'x' -Focusable $False 
                        }
                    )
                )
            )
            New-XAMLStackPanel -Name 'SearchEntries' -HorizontalAlignment Stretch -Orientation Vertical -Content @(
                # Search Fields
            )
        )
    )

    # Add Search Group
    $SearchGroup.FindName('AddSearchGroup').Add_Click({
            Write-Host "[$(Get-Date)] (AddSearchGroup) Clicked"
            $this.FindName('SearchEntries').AddChild(
                $(
                    $SearchGroupTemplate.Invoke($True, $True, $this.FindName('LogicalOperatorsComboBox').SelectedIndex)
                )
            )
            Update-LDAPFilter
        })

    # Add Search Field
    $SearchGroup.FindName('AddSearchField').Add_Click({
            Write-Host "[$(Get-Date)] (AddSearchField) Clicked"
            $this.FindName('SearchEntries').AddChild(
                $($SearchFieldTemplate.Invoke())
            )
            Update-LDAPFilter
        })

    if ($IncludeRemove) {
        $SearchGroup.FindName('DeleteSearchGroup').Add_Click({
                Write-Host "[$(Get-Date)] (DeleteSearchGroup) Clicked"
                $parent = $this.FindName('SearchGroup')
                $parent.Parent.Children.Remove($parent)
                Update-LDAPFilter
                Remove-Variable parent -ErrorAction SilentlyContinue -Force
            })
    }
    
    # Minimize & Expand
    $SearchGroup.FindName('MinimizeSearchGroup').Add_Click({
            Write-Host "[$(Get-Date)] (MinimizeSearchGroup) Clicked"
            if ($this.Content -eq '-') {
                $this.Content = '+'
                $this.Background = 'Yellow'
                $this.FindName('SearchEntries').Visibility = 'Collapsed'
            }
            else {
                $this.Content = '-'
                $this.Background = $AccentColor
                $this.FindName('SearchEntries').Visibility = 'Visible'
            }
            Update-LDAPFilter
        })

    $SearchGroup.FindName('SearchGroupEnabled').Add_Checked({
            Write-Host "[$(Get-Date)] (SearchGroupEnabled) Checked"
            $this.Background = 'White'
            Update-LDAPFilter
        })

    $SearchGroup.FindName('SearchGroupEnabled').Add_UnChecked({
            Write-Host "[$(Get-Date)] (SearchGroupEnabled) UnChecked"
            $this.Background = 'Yellow'
            Update-LDAPFilter
        })

    $SearchGroup.FindName('LogicalOperatorsComboBox').Add_SelectionChanged({
            Write-Host "[$(Get-Date)] (LogicalOperatorsComboBox) SelectionChanged"
            Update-LDAPFilter
        })

    $SearchGroup.FindName('LogicalOperatorsComboBox').SelectedIndex = $ParentLOperator -bxor 1

    return $SearchGroup
}

$SearchFieldTemplate = {
    $SearchField = New-XAMLGrid -AsObject -Name 'SearchField' -Margin '0,3,0,1.5' -OtherAttributes @{ xmlns = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation' } -Content @(
        New-XAMLElement Grid.ColumnDefinitions -Content @(
            New-XAMLElement ColumnDefinition -Attributes @{ Width = 150 }
            New-XAMLElement ColumnDefinition -Attributes @{ Width = 55 }
            New-XAMLElement ColumnDefinition -Attributes @{ Width = '*' }
            New-XAMLElement ColumnDefinition -Attributes @{ Width = 30 }
        )
        New-XAMLTextBox -Name 'AttributeTextBox' -Margin '0,0,3,0' -VerticalContentAlignment Center -OtherAttributes @{ 'Grid.Column' = 0 } -Text 'Attribute'
        New-XAMLComboBox -Name 'ComparatorComboBox' -Margin '0,0,3,0' -VerticalContentAlignment Center -SelectedIndex 0 -OtherAttributes @{ 'Grid.Column' = 1 } -Content @(
            New-XAMLTextBlock -Text '=' -ToolTip 'Is Equal To' 
            New-XAMLTextBlock -Text '!=' -ToolTip 'Is Not Equal To'
            New-XAMLTextBlock -Text '*=*' -ToolTip 'Contains'
            New-XAMLTextBlock -Text '*=' -ToolTip 'Ends With'
            New-XAMLTextBlock -Text '=*' -ToolTip 'Starts With'
            New-XAMLTextBlock -Text '!*=*' -ToolTip 'Does Not Contain'
            New-XAMLTextBlock -Text '!*=' -ToolTip 'Does Not End With'
            New-XAMLTextBlock -Text '!=*' -ToolTip 'Does Not Start With'
            New-XAMLTextBlock -Text '&lt;=' -ToolTip 'Is Less Than Or Equal To'
            New-XAMLTextBlock -Text '>=' -ToolTip 'Is Greater Than Or Equal To'
            New-XAMLTextBlock -Text '&lt;' -ToolTip 'Is Less Than'
            New-XAMLTextBlock -Text '>' -ToolTip 'Is Greater Than'
        )
        New-XAMLTextBox -Name 'ValueTextBox' -Margin '0,0,3,0' -VerticalContentAlignment Center -OtherAttributes @{ 'Grid.Column' = 2 } -Text 'Value'
        New-XAMLButton -Name 'DeleteSearchField' -VerticalContentAlignment Center -HorizontalContentAlignment Center -Background Red -OtherAttributes @{ 'Grid.Column' = 3 } -Content 'x' -Focusable $False
    )

    $SearchField.FindName('DeleteSearchField').Add_Click({
            Write-Host "[$(Get-Date)] (DeleteSearchField) Clicked"
            $parent = $this.FindName('SearchField')
            $parent.Parent.Children.Remove($parent)
            Update-LDAPFilter
        }
    )

    $SearchField.FindName('AttributeTextBox').Add_TextChanged({
            Update-LDAPFilter
        })

    $SearchField.FindName('ValueTextBox').Add_TextChanged({
            Update-LDAPFilter
        })

    $SearchField.FindName('AttributeTextBox').Add_KeyUp({
            if ($_.key -eq 'Enter') {
                Write-Host "[$(Get-Date)] (AttributeTextBox) Enter"
                $UI.SearchButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            }
        })

    $SearchField.FindName('ValueTextBox').Add_KeyUp({
            if ($_.key -eq 'Enter') {
                Write-Host "[$(Get-Date)] (ValueTextBox) Enter"
                $UI.SearchButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            }
        })

    $SearchField.FindName('ComparatorComboBox').Add_SelectionChanged({
            Write-Host "[$(Get-Date)] (ComparatorComboBox) SelectionChanged"
            Update-LDAPFilter
        })

    return $SearchField
}

$TextBoxTemplate = {
    param($Name = '', $Header = '', $Value = '', $OtherAttributes)

    $TextBox = New-XAMLGrid -Margin '3,0,0,0' -OtherAttributes $OtherAttributes -Content @(
        New-XAMLTextBlock -Text $Header -FontSize 12 -FontWeight Bold
        New-XAMLTextBox -Name $Name -Text $Value -Margin '0,13,0,0' -FontSize 15 -Height 30 -VerticalContentAlignment Center
    )

    return $TextBox
}

$SettingsLDAPConnectionTemplate = {
    param($Name, $Server, $Port, $UserName, $Password, $BaseDN)

    $SettingsLDAPConnection = New-XAMLBorder -Name 'SettingsLDAPConnection' -AsObject -Margin '3' -BorderBrush 'DarkGray' -BorderThickness 1 -OtherAttributes @{ xmlns = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation' } -Content (
        # Connection Name, Server, Port, Bind Username, Bind Password, Base DN
        New-XAMLStackPanel -Margin '3,3,3,3' -Orientation Vertical -Content @(
            New-XAMLGrid -Content @(
                New-XAMLElement Grid.ColumnDefinitions -Content @(
                    New-XAMLElement ColumnDefinition -Attributes @{ Width = '*' }
                    New-XAMLElement ColumnDefinition -Attributes @{ Width = '60' }
                )
                $TextBoxTemplate.Invoke('ConnectionNameTextBox', 'Connection Name', $Name, @{ 'Grid.Column' = 0 })
                New-XAMLMenu -OtherAttributes @{ 'Grid.Column' = 1 } -Margin '3,11,0,0' -VerticalAlignment Center -HorizontalAlignment Center -Content @(
                    New-XAMLMenuItem -Header 'Actions' -Name 'AddLDAPConnection' -Height 30 -Background $AccentColor -Content @(
                        New-XAMLMenuItem -Header 'Test' -Name 'TestLDAPConnection' -Icon 'T'
                        New-XAMLMenuItem -Header 'Remove' -Name 'RemoveLDAPConnection' -Icon '-'
                    )
                )
            )
            New-XAMLGrid -Orientation Horizontal -Content @(
                New-XAMLElement Grid.ColumnDefinitions -Content @(
                    New-XAMLElement ColumnDefinition -Attributes @{ Width = '*' }
                    New-XAMLElement ColumnDefinition -Attributes @{ Width = '60' }
                )
                $TextBoxTemplate.Invoke('ServerTextBox', 'Server', $Server, @{ 'Grid.Column' = 0 })
                $TextBoxTemplate.Invoke('PortTextBox', 'Port', $Port, @{ 'Grid.Column' = 1 })
            )
            New-XAMLUniformGrid -Columns 2 -VerticalAlignment Top -Content @(
                $TextBoxTemplate.Invoke('BindUserTextBox', 'Bind User', $UserName)
                $TextBoxTemplate.Invoke('BindPasswordTextBox', 'Bind Password', $Password)
            )
            $TextBoxTemplate.Invoke('BaseDNTextBox', 'Base DN', $BaseDN)
        )
    )

    $SettingsLDAPConnection.FindName('RemoveLDAPConnection').Add_Click({
            Write-Host "[$(Get-Date)] (RemoveLDAPConnection) Clicked"
            $parent = $this.FindName('SettingsLDAPConnection')
            $index = $UI.Window.FindName('LDAPConnectionSettings').children.IndexOf( $parent )
            $parent.Parent.Children.RemoveAt( $index )
            $UI.LDAPConnectionsPopupPanel.Children.RemoveAt( $index )
            # Recount Connections Popup
            LDAPConnectionSelectorButton_Count
            Remove-Variable parent, index -ErrorAction SilentlyContinue -Force
        })

    $SettingsLDAPConnection.FindName('TestLDAPConnection').Add_Click({
            Write-Host "[$(Get-Date)] (TestLDAPConnection) Clicked" 
            $Connection = @{
                Name         = $this.FindName('SettingsLDAPConnection').FindName('ConnectionNameTextBox').Text
                Server       = $this.FindName('SettingsLDAPConnection').FindName('ServerTextBox').Text
                Port         = $this.FindName('SettingsLDAPConnection').FindName('PortTextBox').Text
                UseSSL       = $this.FindName('SettingsLDAPConnection').FindName('UseSSLCheckBox').IsChecked
                BindDN       = $this.FindName('SettingsLDAPConnection').FindName('BindDNTextBox').Text
                BindPassword = $this.FindName('SettingsLDAPConnection').FindName('BindPasswordTextBox').Text
                BaseDN       = $this.FindName('SettingsLDAPConnection').FindName('BaseDNTextBox').Text
            }
            #Test-LDAPConnection -Connection $Connection
        })

    $SettingsLDAPConnection.FindName('ConnectionNameTextBox').Add_TextChanged({
            $parent = $this.FindName('SettingsLDAPConnection')
            $index = $UI.Window.FindName('LDAPConnectionSettings').children.IndexOf( $parent )
            $UI.LDAPConnectionsPopupPanel.Children[ ($index) ].Content.Text = $this.Text
            Remove-Variable parent, index -ErrorAction SilentlyContinue -Force
        })

    return $SettingsLDAPConnection
}

$ResultSelectableTemplate = {
    $ResultSelectable = New-XAMLGrid -AsObject -Margin '0,0,3,3' -Height 72 -OtherAttributes @{ 'xmlns' = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation' } -Content @(
        New-XAMLElement Grid.ColumnDefinitions -Content @(
            New-XAMLElement ColumnDefinition -Attributes @{ Width = '20' }
            New-XAMLElement ColumnDefinition -Attributes @{ Width = '*' }
        )
        New-XAMLBorder -BorderBrush Black -BorderThickness 1 -OtherAttributes @{ 'Grid.Column' = 0 } -Content (
            New-XAMLTextBlock -Text 1 -VerticalAlignment Center -HorizontalAlignment Center
        )
        New-XAMLBorder -BorderBrush Gray -BorderThickness 1 -OtherAttributes @{ 'Grid.Column' = 1 } -Content (
            New-XAMLStackPanel -Orientation Vertical -Margin '3,0,0,0' -Content @(
                New-XAMLTextBlock -Text 'Identifier' -FontSize 20 -FontWeight Bold 
                New-XAMLBorder -BorderBrush LightGray -BorderThickness '0,0,0,1' -Margin '0,0,3,0'
                New-XAMLTextBlock -Text 'Attribute 1' -FontSize 15 -VerticalAlignment Top -HorizontalAlignment Left
                New-XAMLTextBlock -Text 'Attribute 2' -FontSize 15 -VerticalAlignment Top -HorizontalAlignment Left
                New-XAMLViewbox -VerticalAlignment Bottom -HorizontalAlignment Right -Height 30 -Width 30 -Margin '0,-28,0,0' -Content (
                    New-XAMLCheckBox -Name 'CompareCheckBox' -ToolTip 'Check to Compare' -BorderThickness 2
                )
            )
        )
    )

    $ResultSelectable.FindName('CompareCheckBox').Add_Checked({
            Write-Host "[$(Get-Date)] (CompareCheckBox) Checked"
            $UI.CompareButton.Tag = [int]$UI.CompareButton.Tag + 1
            if ($UI.CompareButton.Tag -eq 2) {
                $UI.CompareButton.IsEnabled = $True
            }
            elseif ($UI.CompareButton.Tag -gt 2) {
                $this.IsChecked = $False
            }
        })

    $ResultSelectable.FindName('CompareCheckBox').Add_UnChecked({
            Write-Host "[$(Get-Date)] (CompareCheckBox) UnChecked"
            $UI.CompareButton.Tag = [int]$UI.CompareButton.Tag - 1
            if ($UI.CompareButton.Tag -le 1) {
                $UI.CompareButton.IsEnabled = $False
            }
        })

    return $ResultSelectable
}

$SearchLDAPConnectionToggleTemplate = {
    param($IsChecked = $False)
    
    $ToggleButton = New-XAMLToggleButton -Margin '2' -IsChecked $IsChecked -AsObject -Content @(
        New-XAMLElement -ElementType 'ToggleButton.Style' -Content @(
            New-XAMLStyle -TargetType '{x:Type ToggleButton}' -Content @(
                New-XAMLSetter -Property 'Template' -Content @(
                    New-XAMLElement -ElementType 'Setter.Value' -Content @(
                        New-XAMLElement -ElementType 'ControlTemplate' -Attributes @{ TargetType = '{x:Type ToggleButton}' } -Content @(
                            New-XAMLElement -ElementType 'Border' -Attributes @{ BorderBrush = '{TemplateBinding BorderBrush}'; Background = '{TemplateBinding Background}' } -Content @(
                                New-XAMLElement -ElementType 'ContentPresenter' -Attributes @{ HorizontalAlignment = 'Center'; VerticalAlignment = 'Center' }
                            )
                        )
                    )
                )
                New-XAMLElement -ElementType 'Style.Triggers' -Content @(
                    New-XAMLElement -ElementType 'Trigger' -Attributes @{ Property = 'IsMouseOver'; Value = 'True' } -Content @(
                        New-XAMLSetter -Property 'Cursor' -Value 'Hand'
                    )
                    New-XAMLElement -ElementType 'Trigger' -Attributes @{ Property = 'IsMouseOver'; Value = 'True' } -Content @(
                        New-XAMLSetter -Property 'BorderBrush' -Value 'White'
                    )
                    New-XAMLElement -ElementType 'Trigger' -Attributes @{ Property = 'IsChecked'; Value = 'True' } -Content (
                        New-XAMLSetter -Property 'Background' -Value $AccentColor
                    )
                    New-XAMLElement -ElementType 'Trigger' -Attributes @{ Property = 'IsChecked'; Value = 'False' } -Content (
                        New-XAMLSetter -Property 'Background' -Value $SecondaryAccentColor
                    )
                )
            )
        )
        New-XAMLTextBlock -Content 'Connection Name' -Margin '2'
    )

    $ToggleButton.Add_Checked({
            Write-Host "[$(Get-Date)] (SearchLDAPConnectionToggle) Checked"
            LDAPConnectionSelectorButton_Count
        })

    $ToggleButton.Add_UnChecked({
            Write-Host "[$(Get-Date)] (SearchLDAPConnectionToggle) UnChecked"
            LDAPConnectionSelectorButton_Count
        })

    return $ToggleButton
}

#endregion OnDemand UI Elements

#region Main Window

$XAML = New-XAMLWindow -Title 'LDAP Management Tool' -Background $PrimaryColor -Width 1229 -Height 871 -MinWidth 927 -MinHeight 595 -FontFamily $FontFamily -HorizontalAlignment Center -VerticalAlignment Center -WindowStartupLocation CenterScreen -Content @(
    New-XAMLElement 'Window.Resources' -Content (
        New-XAMLStyle -TargetType 'Button' -Content @(
            New-XAMLSetter -Property Height -Value 30
            New-XAMLSetter -Property MinHeight -Value 30
            New-XAMLSetter -Property MaxHeight -Value 30
            New-XAMLSetter -Property Width -Value 30
            New-XAMLSetter -Property Cursor -Value Hand
        )
    )
    New-XAMLGrid -Margin 2 -Content @(
        New-XAMLElement Grid.RowDefinitions -Content @(
            New-XAMLElement RowDefinition -Attributes @{ Height = '*' }
            New-XAMLElement RowDefinition -Attributes @{ Height = 30 }
        )
        New-XAMLTabControl -OtherAttributes @{ 'Grid.Row' = 0 } -Background $SecondaryColor -Content @(
            New-XAMLTabItem -Name 'SearchTab' -Header 'Search' -Width 100 -Height 30 -Background $SecondaryAccentColor -Content (
                New-XAMLGrid -Content @(
                    New-XAMLElement Grid.ColumnDefinitions -Content @(
                        New-XAMLElement ColumnDefinition @{ Width = '*' }
                        New-XAMLElement ColumnDefinition @{ Width = '*' }
                    )
                    New-XAMLGrid -Margin '0,0,1.5,0' -HorizontalAlignment Stretch -VerticalAlignment Stretch -OtherAttributes @{ 'Grid.Column' = 0 } -Content @(
                        New-XAMLElement Grid.RowDefinitions -Content @(
                            New-XAMLElement RowDefinition -Attributes @{ Height = '*' }
                            New-XAMLElement RowDefinition -Attributes @{ Height = 66.5 }
                        )
                        New-XAMLScrollViewer -VerticalAlignment Top -HorizontalAlignment Stretch -VerticalScrollBarVisibility Auto -OtherAttributes @{ 'Grid.Row' = '0' } -Content @(
                            New-XAMLBorder -VerticalAlignment Stretch -HorizontalAlignment Stretch -BorderBrush Black -BorderThickness 1 -Content @(
                                New-XAMLStackPanel -Name 'SearchGroupsPanel' -Content @(
                                    # Search Groups
                                )
                            )
                        )
                        New-XAMLStackPanel -Orientation Vertical -VerticalAlignment Bottom -OtherAttributes @{ 'Grid.Row' = '1' } -Content @(
                            New-XAMLTextBox -Name 'LDAPFilterTextBox' -HorizontalAlignment Stretch -VerticalAlignment Bottom -Height 25 -VerticalContentAlignment Center
                            New-XAMLGrid -Orientation Horizontal -HorizontalAlignment Stretch -Margin '0,3,0,0' -Content @(
                                New-XAMLElement 'Grid.ColumnDefinitions' -Content @(
                                    New-XAMLElement 'ColumnDefinition' -Attributes @{ Width = 200 }
                                    New-XAMLElement 'ColumnDefinition' -Attributes @{ Width = '*' }
                                    New-XAMLElement 'ColumnDefinition' -Attributes @{ Width = 78 }
                                    New-XAMLElement 'ColumnDefinition' -Attributes @{ Width = 75 }
                                )
                                New-XAMLButton -Name 'LDAPConnectionSelectorButton' -Content 'Connections' -Width 100 -Height 37.5 -Margin '0,0,3,0' -HorizontalAlignment Left -Background $AccentColor -OtherAttributes @{ 'Grid.Column' = 0 } -IsEnabled $False
                                New-XAMLButton -Name 'ExportButton' -Content 'Export' -Width 75 -Height 37.5 -Margin '0,0,3,0' -HorizontalAlignment Right -Background $AccentColor -OtherAttributes @{ 'Grid.Column' = 2 } -IsEnabled $False
                                New-XAMLButton -Name 'SearchButton' -Content 'Search' -Width 75 -Height 37.5 -HorizontalAlignment Right -Background $AccentColor -OtherAttributes @{ 'Grid.Column' = 3 } -IsEnabled $False
                            )
                        )
                        New-XAMLPopup -Name 'LDAPConnectionsPopup' -PlacementTarget '{Binding ElementName=LDAPConnectionSelectorButton}' -Placement 'Top' -StaysOpen $False -AllowsTransparency $True -PopupAnimation Fade -Content (
                            New-XAMLBorder -BorderBrush Black -BorderThickness 1 -Background White -Content (
                                New-XAMLScrollViewer -MinHeight 0 -MaxHeight 200 -VerticalScrollBarVisibility Auto -Content (
                                    New-XAMLStackPanel -Name 'LDAPConnectionsPopupPanel' -Content @(
                                        # LDAP Connections for Selection
                                    )
                                )
                            )
                        )
                    )
                    New-XAMLTabControl -Margin '1.5,0,0,0' -HorizontalAlignment Stretch -VerticalAlignment Stretch -OtherAttributes @{ 'Grid.Column' = 1 } -Content @(
                        New-XAMLTabItem -Header 'Selector' -Width 100 -Height 30 -Background $SecondaryAccentColor -Content @(
                            New-XAMLGrid -Background $SecondaryColor -Content @(
                                New-XAMLElement Grid.RowDefinitions -Content @(
                                    New-XAMLElement RowDefinition -Attributes @{ Height = '40' }
                                    New-XAMLElement RowDefinition -Attributes @{ Height = '*' }
                                )
                                New-XAMLBorder -BorderBrush DarkGray -BorderThickness '0,0,0,1' -Margin '0,0,0,0' -OtherAttributes @{ 'Grid.Row' = '0' } -Content (
                                    New-XAMLGrid -Margin '0,3,0,0' -Content @(
                                        New-XAMLElement Grid.ColumnDefinitions -Content @(
                                            New-XAMLElement ColumnDefinition -Attributes @{ Width = '*' }
                                            New-XAMLElement ColumnDefinition -Attributes @{ Width = '78' }
                                            New-XAMLElement ColumnDefinition -Attributes @{ Width = '53' }
                                            New-XAMLElement ColumnDefinition -Attributes @{ Width = '53' }
                                        )
                                        New-XAMLButton -Name 'CompareButton' -Tag 0 -Height 30 -Width 75 -Margin '0,0,3,0' -OtherAttributes @{ 'Grid.Column' = 1 } -Content 'Compare' -Background $AccentColor -IsEnabled $False
                                        New-XAMLTextBox -Name 'ResultSelectorTextBox' -Height 30 -Width 50 -Margin '0,0,3,0' -VerticalContentAlignment Center -HorizontalContentAlignment Center -OtherAttributes @{ 'Grid.Column' = 2 } -ToolTip 'Enter Number and Press Enter to Select Result'
                                        New-XAMLButton -Name 'SelectButton' -Height 30 -Width 50 -Margin '0,0,3,0' -OtherAttributes @{ 'Grid.Column' = 3 } -Content 'Select' -Background $AccentColor -IsEnabled $False
                                    )
                                )
                                New-XAMLScrollViewer -Margin '0,3,0,0' -OtherAttributes @{ 'Grid.Row' = '1' } -Height 653 -Content @(
                                    New-XAMLStackPanel -Name 'ResultSelections' -Orientation Vertical -Content @()
                                )
                            )
                        )
                        New-XAMLTabItem -Name 'SelectionResult' -Header 'Results' -Width 100 -Height 30 -Background $SecondaryAccentColor -Content @(
                            # RESULTS PAGE
                        )
                    )
                )
            )
            New-XAMLTabItem -Name 'SettingsTab' -Header 'Settings' -Width 100 -Height 30 -Background $SecondaryAccentColor -Content (
                New-XAMLGrid -Content @(
                    New-XAMLElement 'Grid.ColumnDefinitions' -Content @(
                        New-XAMLElement 'ColumnDefinition' -Attributes @{ Width = 150 }
                        New-XAMLElement 'ColumnDefinition' -Attributes @{ Width = '*' }
                    )
                    New-XAMLBorder -OtherAttributes @{ 'Grid.Column' = 0 } -BorderBrush Black -BorderThickness 1 -Content (
                        New-XAMLScrollViewer -HorizontalAlignment Stretch -VerticalAlignment Stretch -VerticalScrollBarVisibility Auto -Content @(
                            New-XAMLStackPanel -HorizontalAlignment Stretch -VerticalAlignment Stretch -Name 'SettingsQuickLinks' -Background DarkGray -Content @(

                            )
                        )
                    )
                    New-XAMLScrollViewer -OtherAttributes @{ 'Grid.Column' = 1 } -Content @(
                        New-XAMLStackPanel -Name 'SettingsPanel' -Content @(
                            # Settings
                            New-XAMLStackPanel -Name 'LDAPConnectionSettingsSection' -Content @(
                                New-XAMLTextBlock -FontSize 20 -FontWeight Bold -Text 'LDAP Connections' -Margin '3,0,0,0'
                                New-XAMLBorder -BorderBrush Black -BorderThickness '0,0,0,1' -Margin '0,0,3,3'
                                New-XAMLButton -Name 'AddLDAPConnection' -Content 'Add Connection' -Width 100 -Margin '3,0,0,0' -Background $AccentColor
                                # LDAP Connections
                                New-XAMLUniformGrid -Name 'LDAPConnectionSettings' -Columns 2
                            )
                        )
                    )
                )
            )
        )
        New-XAMLBorder -Background DarkGray -BorderBrush Black -BorderThickness 1 -Height 30 -Margin '0,3,0,0' -OtherAttributes @{ 'Grid.Row' = 1 } -Content (
            New-XAMLTextBlock -Content 'Status Update' -HorizontalAlignment Left -VerticalAlignment Center -Margin '3,0,0,0'
        )
    )
)

#endregion Main Window

# Required for the UI Functionality 
$UI = Initialize-XAMLWindow $XAML

#region UI Functionality

$UI.SearchButton.Add_Click({
        Write-Host "[$(Get-Date)] (SearchButton) Clicked"
    })

$UI.ExportButton.Add_Click({
        Write-Host "[$(Get-Date)] (ExportButton) Clicked"
    })

$UI.CompareButton.Add_Click({
        Write-Host "[$(Get-Date)] (CompareButton) Clicked"
    })

$UI.LDAPConnectionSelectorButton.Add_Click({
        Write-Host "[$(Get-Date)] (LDAPConnectionSelector) Clicked"
        $UI.LDAPConnectionsPopup.IsOpen = $UI.LDAPConnectionsPopupPanel.Children.Count -gt 0
    })

function LDAPConnectionSelectorButton_Count {
    $Count = $UI.LDAPConnectionsPopupPanel.Children.Where({ $_.IsChecked }).Count
    $TotalCount = $UI.LDAPConnectionsPopupPanel.Children.Count
    $UI.LDAPConnectionSelectorButton.Content = "Connections: $Count / $TotalCount"
    $UI.LDAPConnectionSelectorButton.IsEnabled = $TotalCount -gt 0
    SearchButton_Enabled 
}

function SearchButton_Enabled {
    $Enabled = $UI.LDAPConnectionsPopupPanel.Children.Where({ $_.IsChecked }).Count -gt 0 -and $UI.LDAPFilterTextBox.Text -ne ''
    $UI.SearchButton.IsEnabled = $Enabled
    $UI.ExportButton.IsEnabled = $Enabled
}

$UI.ResultSelectorTextBox.Add_TextChanged({
        if ($UI.ResultSelectorTextBox.Text -notmatch '^\d+$') {
            Write-Host "[$(Get-Date)] (ResultSelectorTextBox) Removed non-digits"
            $UI.ResultSelectorTextBox.Text = $UI.ResultSelectorTextBox.Text -replace '\D', ''
            $UI.ResultSelectorTextBox.Select($UI.ResultSelectorTextBox.Text.Length, 0)
        }
        $UI.SelectButton.IsEnabled = $UI.ResultSelectorTextBox.Text -ne ''
    })

$UI.ResultSelectorTextBox.Add_KeyUp({
        if ($_.Key -eq 'Enter' -and $UI.SelectButton.IsEnabled) {
            Write-Host "[$(Get-Date)] (ResultSelectorTextBox) Key:Enter"
            $UI.SelectButton.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
        }
    })

$UI.SelectButton.Add_Click({
        Write-Host "[$(Get-Date)] (SelectButton) Clicked"
    })

$UI.AddLDAPConnection.Add_Click({
        Write-Host "[$(Get-Date)] (AddLDAPConnection) Clicked"
        $UI.LDAPConnectionSettings.AddChild(
            $(
                $SettingsLDAPConnectionTemplate.Invoke('Connection Name', 'ldap.example.com', '389', 'cn=admin,dc=example,dc=com', 'pwdhere', 'dc=example,dc=com')
            )
        )

        $IsChecked = $UI.LDAPConnectionSettings.Children.Count -eq 1
        $UI.LDAPConnectionSelectorButton.IsEnabled = $True
        $UI.LDAPConnectionsPopupPanel.AddChild(
            $(
                $SearchLDAPConnectionToggleTemplate.Invoke(
                    $IsChecked
                )
            )
        )
        if ($IsChecked) {
            LDAPConnectionSelectorButton_Count
        }

        #Save-Settings
        #Load-Settings
    })

#endregion UI Functionality

#region Functions

function _ProcessSearchGroup {
    param($SearchGroup)

    if (!$SearchGroup.FindName('SearchGroupEnabled').IsChecked) {
        return
    }

    $Filters = @()
    :SearchEntries foreach ($Entry in $SearchGroup.Child.FindName('SearchEntries').Children) {
        if ($Entry.Name -eq 'SearchGroup') {
            $Filters += _ProcessSearchGroup $Entry
        }
        else {
            $Value = $Entry.FindName('ValueTextBox').Text

            if ($Value -eq '') { continue SearchEntries }

            $Attribute = $Entry.FindName('AttributeTextBox').Text
            $Comparator = $Entry.FindName('ComparatorComboBox').SelectedItem.Text
            $Filters += switch ($Comparator) {
                '!=' { "(!$Attribute=$Value)" }
                '*=*' { "($Attribute=*$Value*)" }
                '*=' { "($Attribute=*$Value)" }
                '=*' { "($Attribute=$Value*)" }
                '!*=*' { "(!$Attribute=*$Value*)" }
                '!*=' { "(!$Attribute=*$Value)" }
                '!=*' { "(!$Attribute=$Value*)" }
                default { "($Attribute$Comparator$Value)" }
            }
        }
    }

    if ($Filters.Count -gt 0) {
        $LOperator = switch ($SearchGroup.FindName('LogicalOperatorsComboBox').SelectedItem.Text) {
            'And' { '&' }
            'Or' { '|' }
        }
        "($LOperator$($Filters -join ''))"
    }
}

function Update-LDAPFilter {
    $UI.LDAPFilterTextBox.Text = _ProcessSearchGroup $UI.SearchGroupsPanel.Children
}

$SettingIntTemplate = {
    param($Key, $Value)
    New-XAMLGrid -Margin 3 -Content @(
        New-XAMLElement Grid.ColumnDefinitions -Content @(
            New-XAMLElement ColumnDefinition @{ Width = '200' }
            New-XAMLElement ColumnDefinition @{ Width = '*' }
        )
        New-XAMLGrid -Margin 3 -HorizontalAlignment Right -VerticalAlignment Center -OtherAttributes @{ 'Grid.Column' = 0 } -Content (
            New-XAMLTextBlock -Margin '0,0,5,0' -HorizontalAlignment Center -VerticalAlignment Center -Content $Key
        )
        New-XAMLTextBox -Height 30 -OtherAttributes @{ 'Grid.Column' = 1 } -Content $Value -VerticalContentAlignment Center
    )
}

$SettingStringTemplate = {
    param($Key, $Value)
    New-XAMLGrid -Margin 3 -VerticalAlignment Center -Content @(
        $(
            if ([bool]$Key) {
                New-XAMLElement Grid.ColumnDefinitions -Content @(
                    New-XAMLElement ColumnDefinition @{ Width = '200' }
                    New-XAMLElement ColumnDefinition @{ Width = '*' }
                )
                New-XAMLGrid -Margin 3 -HorizontalAlignment Right -VerticalAlignment Center -OtherAttributes @{ 'Grid.Column' = 0 } -Content (
                    New-XAMLTextBlock -Margin '0,0,5,0' -HorizontalAlignment Left -VerticalAlignment Center -Content $Key
                )
            }
        )
        New-XAMLTextBox -Height 30 -OtherAttributes @{ 'Grid.Column' = 1 } -VerticalContentAlignment Center -Content $Value.replace('&', '&amp;')
    )
}

$SettingBoolTemplate = {
    param($Key, $Value)
    New-XAMLGrid -Margin 3 -VerticalAlignment Center -Content @(
        New-XAMLElement Grid.ColumnDefinitions -Content @(
            New-XAMLElement ColumnDefinition @{ Width = '200' }
            New-XAMLElement ColumnDefinition @{ Width = '*' }
        )
        New-XAMLGrid -HorizontalAlignment Right -VerticalAlignment Center -OtherAttributes @{ 'Grid.Column' = 0 } -Content (
            New-XAMLTextBlock -Margin '0,0,5,0' -HorizontalAlignment Center -VerticalAlignment Center -Content $Key
        )
        New-XAMLCheckBox -OtherAttributes @{ 'Grid.Column' = 1 } -IsChecked:$Value -HorizontalAlignment Left -VerticalAlignment Center -VerticalContentAlignment Center -HorizontalContentAlignment Center
    )
}

$SettingArrayTemplate = {
    param($Key, $Array)
    if ([Bool]$Key) {
        $Background = 'LightGray'
        if ($KeyEditable) {
            $Background = 'White'
        }
    }
    New-XAMLBorder -Margin '3,1.5,3,1.5' -BorderBrush Black -BorderThickness 1 -HorizontalAlignment Stretch -Background $Background -Content (
        New-XAMLGrid -Content @(
            New-XAMLElement Grid.RowDefinitions -Content @(
                New-XAMLElement RowDefinition @{ Height = '50' }
                New-XAMLElement RowDefinition @{ Height = '*' }
            )
            New-XAMLBorder -BorderBrush Black -Margin '5,0,5,0' -BorderThickness '0,0,0,2' -HorizontalAlignment Stretch -VerticalAlignment Stretch -OtherAttributes @{ 'Grid.Row' = 0 } -Content (
                New-XAMLTextBlock -Margin '10,0,0,0' -FontSize 20 -Height 30 -FontWeight Bold -VerticalAlignment Center -HorizontalAlignment Left -Content $Key
            )
            New-XAMLButton -Margin '0,0,10,0' -Width 35 -OtherAttributes @{ 'Grid.Row' = 0 } -Content + -VerticalAlignment Center -HorizontalAlignment Right -VerticalContentAlignment Center -HorizontalContentAlignment Center -Background $AccentColor
            New-XAMLStackPanel -Margin 3 -Orientation Vertical -OtherAttributes @{ 'Grid.Row' = 1 } -Content @(
                foreach ($Item in $Array) {
                    Convert-FromObjectToXAML -Object $Item
                }
            )
        )
    )
}

$SettingHashTableTemplate = {
    param($Key, $Children, $KeyEditable = $true)
    if ([Bool]$Key) {
        $Background = 'LightGray'
        if ($KeyEditable) {
            $Background = 'White'
        }
    }
    New-XAMLBorder -Margin '3,1.5,3,1.5' -BorderBrush Black -BorderThickness 1 -Background $Background -Content (
        New-XAMLGrid -Content @(
            New-XAMLElement Grid.RowDefinitions -Content @(
                if ([bool]$Key) { New-XAMLElement RowDefinition @{ Height = '50' } }
                New-XAMLElement RowDefinition @{ Height = '*' }
            )

            if ([bool]$Key) {
                New-XAMLBorder -BorderBrush Black -Margin '5,0,5,0' -BorderThickness '0,0,0,2' -HorizontalAlignment Stretch -VerticalAlignment Stretch -OtherAttributes @{ 'Grid.Row' = 0 } -Content $(
                    if ($KeyEditable) {
                        New-XAMLTextBox -Margin '10,0,10,0' -FontSize 20 -Height 30 -MinWidth 50 `
                            -HorizontalAlignment Left -VerticalAlignment Center -VerticalContentAlignment Center -HorizontalContentAlignment Left -Text $Key 
                    }
                    else {
                        New-XAMLTextBlock -Margin '10,0,0,0' -FontSize 20 -Height 30 -FontWeight Bold `
                            -HorizontalAlignment Left -VerticalAlignment Center -Content $Key
                    }
                )
            }

            if ($AddAbleHashTables -contains $Key) { 
                New-XAMLButton -OtherAttributes @{ 'Grid.Row' = 0 } -Width 35 -Margin '0,0,10,0' -Content + -VerticalAlignment Center -HorizontalAlignment Right -VerticalContentAlignment Center -HorizontalContentAlignment Center -Background $AccentColor
            }
            
            New-XAMLBorder -BorderBrush Black -OtherAttributes @{ 'Grid.Row' = 1 } -Content $(
                New-XAMLStackPanel -Orientation Vertical -Content @(
                    $Children
                )
            )
        )
    )
}

function Convert-FromObjectToXAML {
    param($Key, $Object, $AsObject = $True)
    $ReturnObjects = @()
    switch ($Object) {
        { $_ -is 'PSObject' -or $_ -is 'PSCustomObject' -or $_ -is 'HashTable' } {
            if ($_ -is 'hashtable') { $SubKeys = $Object.Keys }
            else { $SubKeys = $Object.psobject.Properties.Name }
            $HashChildren = @()

            foreach ($SubKey in $SubKeys) {
                if ($Object.$SubKey.GetType().Name -eq 'Object[]') {
                    $HashChildren += $SettingArrayTemplate.Invoke($SubKey, $Object.$SubKey)
                }
                else {
                    $HashChildren += Convert-FromObjectToXAML -Key $SubKey -Object $Object.$SubKey -AsObject $false
                }
            }
            $SettingHashTableTemplate.Invoke($Key, $HashChildren, $($NonEditableHeaders -notcontains $Key))
        }
        { $_ -is 'String' } {
            $ReturnObjects += $SettingStringTemplate.Invoke($Key, $Object, $False)
        }
        { $_ -is 'Int64' } {
            $ReturnObjects += $SettingIntTemplate.Invoke($Key, $Object)
        }
        { $_ -is 'Boolean' } {
            $ReturnObjects += $SettingBoolTemplate.Invoke($Key, $Object)
        }
        default { '[Convert-FromObjectToXAML] Type Not Specified' }
    }
    return $ReturnObjects
}

function Set-Setting {
    param($Item, $Property, $Value)
    $UI.$Item.$Property = $Value
}

#endregion Functions

#region Setup UI

$UI.Window.Content.Children[0].SelectedIndex = 1

# Initial Search Group
$UI.SearchGroupsPanel.AddChild($($SearchGroupTemplate.Invoke($False, $True, 1, '0,0,0,0')))
if ((Test-Path $SettingsFilePath)) {
    $Settings = Get-Content $SettingsFilePath | ConvertFrom-Json
    $NonEditableHeaders = $Settings.psobject.Properties.Name
    $AddAbleHashTables = @(
        'LDAPConnections'
    )

    #$Settings.psobject.Properties.Name | ForEach-Object { $UI.SettingsQuickLinks.AddChild($($SettingsQuickLinkTemplate.Invoke($_))) }
}

#endregion Setup UI

$UI.Window | Show-XAMLWindow | Out-Null

<#
    $XAML | CLIP
#>