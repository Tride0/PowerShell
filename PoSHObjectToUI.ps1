<# Internal Script Documentation
     Created By: Kyle Hewitt
     Created On: 2025-12-24
        Version: 2026.1.10
           Name: User Class Interface Generator
    Description: This module provides functions to dynamically generate UI elements for PowerShell objects, facilitating the creation of interactive management tools.
        Purpose: To be used as a template to quickly create tools based off .NET Classes
           Plan:
                - UI
                    Window
                        Input StackPanel
                            [Create Object Button] (Label as Validate, On validate populate Properties section with current values)
                            Non-Parameter Properties (Not available until Validated)
                            Methods as Buttons (Not available until Validated)
                        Output StackPanel
                - Properties
                - Methods
            UI Layout:
                Base Elements
                Featured Elements

    Feature: Parameter Requirement Checks
        When filling out the fields, it should check with the constructors to see if any other field is required when that specific field is filled out.
        Example:
            Constructors for System.DirectoryServices.DirectorySearcher:
                adsisearcher new()
                adsisearcher new(adsi searchRoot)
                adsisearcher new(adsi searchRoot, string filter)
                adsisearcher new(adsi searchRoot, string filter, string[] propertiesToLoad)
                adsisearcher new(string filter)
                adsisearcher new(string filter, string[] propertiesToLoad)
                adsisearcher new(string filter, string[] propertiesToLoad, System.DirectoryServices.SearchScope scope)
                adsisearcher new(adsi searchRoot, string filter, string[] propertiesToLoad, System.DirectoryServices.SearchScope scope)
            Expected Behavior:
                If string[] propertiesToLoad is filled out, then string filter is required.
                If System.DirectoryServices.SearchScope scope is filled out, then string filter and string[] propertiesToLoad are required.
        Process:
            Lost_Focus
                1. Is field populated?
                    a. Yes: Get all populated fields.
                        i. Filter constructors to only those that have the populated fields.
                        ii. Are there any constructors left?
                            1. Yes: Get Constructor with least number of parameters.
                                a. Are there any required parameters not populated?
                                    i. Yes: Highlight those fields as required.
                                    ii. No: Do nothing.
                            2. No: Do nothing.
                    b. No: Do nothing.

    Feature: Method Execution Wrapper
        SubFeatures:
            1. Retry
            2. Error Handling
            3. Output Capture and Formatting
            4. Timeout
            5. Asynchronous Execution
            6. Logging
            7. Export to file (CSV, JSON, XML, TXT)
            8. Export to clipboard (CSV, JSON, XML, TXT)
            9. Recursion (Paging, Continuation Tokens)
            10. Progress Indication

    Classes to test with:
        System.DirectoryServices.Protocols.LdapConnection
        System.DirectoryServices.DirectorySearcher
        System.Diagnostics.EventLog
#>

param(
    $Class = 'adsisearcher',
    $DefaultFontSize = 14,
    $ColorScheme = @(
        'Gray'
        'DarkGray'
        'LightGray'
    )
)

#region Variables

$ConstructedObjects = @()

$SectionBorderName = 'SectionBorder' # Used 7 times
$SectionContentName = 'SectionContent' # Used 5 times
$SectionHeaderTextBlockName = 'SectionHeaderTextBlock' # Used 3 times
$SectionItemDockPanelName = 'SectionItemDockPanel' # Used 1 times
$RemoveButtonName = 'RemoveButton' # Used 1 times
$SectionGridName = 'SectionGrid' # Used 1 times
$SectionHeaderDockPanelName = 'SectionHeaderDockPanel' # Used 1 times
$SectionHeaderButtonStackPanelName = 'SectionHeaderButtonStackPanel' # Used 1 times
$MinimizeButtonName = 'MinimizeButton' # Used 1 times
$SectionScrollViewerName = 'SectionScrollViewer' # Used 2 times
$AddButtonName = 'AddButton' # Used 1 times
$ConstructButtonName = 'ConstructButton' # Used 2 times

# Color Gradient for Constructor Parameters . Colors between Red and Yellow
$ConstructorParameterColorGradient = @(
    'Red'
    'OrangeRed'
    'DarkOrange'
    'Orange'
    'Gold'
    'Goldenrod'
    'LightGoldenrodYellow'
    'Yellow'
    'YellowGreen'
)

#endregion Variables

#region All Functions

#region PowerShell Object shortcut functions

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

function Find-ParentByName {
    param(
        [parameter(ValueFromPipeline)][ref]$Object,
        [string]$Name
    )
    $CurrentObject = $Object.Value
    :searchLoop while ($CurrentObject.Parent) {
        if ($CurrentObject.Parent.Name -eq $Name) {
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
} # END Function Find-ParentByName

function Find-ChildByName {
    param(
        [parameter(ValueFromPipeline)][ref]$Object,
        [string]$Name,
        $PropertiesToSearch = @('Children', 'Content', 'Child'),
        $Depth = 0
    )

    foreach ($Property in $PropertiesToSearch) {
        if ([bool]$Object.Value.$Property) {
            foreach ($Child in @($Object.Value.$Property)) {
                if ($Child.Name -eq $Name) { return $Child }

                $FoundChild = Find-ChildByName -Object $([ref]$Child) -Name $Name -Depth ($Depth + 1)
                if ($FoundChild) {
                    Write-Host "[Find-ChildByName] $Depth $($FoundChild.count) $Name $($Object.Value.Name) > $($FoundChild.Name)" -ForegroundColor DarkCyan
                    return $FoundChild
                }
            }
        }
    }
} # END Function Find-ChildByName

function Find-ChildByLabel {
    param(
        [parameter(ValueFromPipeline)][ref]$Object,
        [string]$Label,
        $PropertiesToSearch = @('Children', 'Content', 'Child'),
        $Depth = 0
    )

    foreach ($Property in $PropertiesToSearch) {
        if ([bool]$Object.Value.$Property) {
            foreach ($Child in @($Object.Value.$Property)) {
                $ChildLabel = Find-ChildByName -Object $([ref]$Child) -Name $SectionHeaderTextBlockName -Depth 0
                if ($ChildLabel -and $ChildLabel.Text -eq $Label) { return $Child }

                $FoundChild = Find-ChildByLabel -Object $([ref]$Child) -Label $Label -Depth ($Depth + 1)
                if ($FoundChild) {
                    Write-Host "[Find-ChildByLabel] $Depth $($FoundChild.count) $Label $($Object.Value.Name) > $($FoundChild.Name)" -ForegroundColor DarkCyan
                    return $FoundChild
                }
            }
        }
    }
} # END Function Find-ChildByLabel

function Get-ObjectProperties {
    param(
        [parameter(ValueFromPipeline)]$Object,
        [string]$Match = '.\.github'
    )
    $Object.PSObject.Properties -match $Match
} # END Function Get-ObjectProperties

function Get-ObjectMethods {
    param(
        [parameter(ValueFromPipeline)]$Object,
        [string]$Match = '.'
    )
    $Object.PSObject.methods -notlike '*_*' -match $Match
} # END Function Get-ObjectMethods

function Get-TypeConstructors {
    param([parameter(ValueFromPipeline)][string]$Object)
    $c = 0
    try {
        $ObjectType = [Type]$Object
    }
    catch {
        Write-Host "[Get-TypeConstructors] ERROR: Could not convert $Object to Type." -ForegroundColor Red
        return $null
    }
    $ObjectType.GetConstructors().foreach({
            $ConstructorParameters = $_.GetParameters() | ForEach-Object {
                $Type, $Name = $_.ToString().Split(' ')
                [PSCustomObject]@{
                    Name = $Name
                    Type = $Type
                }
            }
            [PSCustomObject]@{
                Constructor = $c
                Parameters  = $ConstructorParameters
            }
            $c ++
        })
} # END Function Get-TypeConstructors

function Get-ObjectStructure {
    param(
        [parameter(ValueFromPipeline)]$Object
    )
    [string[]]$ChildProperties = @('Children', 'Content', 'Child')
    [string[]]$ParentProperty = 'Parent'
    $Structure = @()
    $Structure += "$($Object.GetType().Name)"
    $CurrentObject = $Object

    # Child Recursion
    function Get-ChildStructure {
        param(
            $Object,
            [string[]]$ChildProperties,
            $Depth = 1
        )

        $ChildStructure = @()
        foreach ($Property in $ChildProperties) {
            if ([bool]$Object.$Property) {
                foreach ($Child in @($Object.$Property)) {
                    $ChildStructure += ("`t" * $Depth) + "$($Child.GetType().Name) ($($Property)) ($($Child.Name))"
                    $ChildStructure += Get-ChildStructure -Object $Child -ChildProperties $ChildProperties -Depth ($Depth + 1)
                }
            }
        }
        return $ChildStructure
    }

    # Get Parents, Insert at Start
    $Depth = 0
    :parentLoop while ($CurrentObject.$ParentProperty) {
        $StructureString = ("`t" * $Depth) + $($CurrentObject.$ParentProperty.GetType().Name) + " ($($ParentProperty)) ($($CurrentObject.$ParentProperty.Name))"
        [Void]$Structure.Insert(0, $StructureString)
        if ([Bool]$CurrentObject.$ParentProperty) {
            $CurrentObject = $CurrentObject.$ParentProperty
            $Depth ++
        }
        else {
            break parentLoop
        }
    }

    # Get Children, Append at End
    $Structure += Get-ChildStructure -Object $Object -ChildProperties $ChildProperties
    $Structure
} # END Function Get-ObjectStructure

#endregion PowerShell Object shortcut functions

#region UI Base Elements

Add-Type -AssemblyName PresentationFramework

function New-UIBorder {
    param(
        $Name,
        $Background = 'LightGray',
        $Tag
    )
    #Write-Host "[New-UIBorder] Border $Name" -ForegroundColor Green
    return [System.Windows.Controls.Border]@{
        Name            = $Name
        Tag             = $Tag
        BorderBrush     = 'Gray'
        BorderThickness = '1'
        CornerRadius    = '5'
        Margin          = '5'
        Background      = $Background
    }
} # END Function New-UIBorder

function New-UIStackPanelElement {
    param(
        $Name,
        $Orientation = 'Vertical',
        [System.Windows.FlowDirection]$FlowDirection = 'LeftToRight',
        $HorizontalAlignment
    )
    #Write-Host "[New-UIStackPanelElement] StackPanel $Orientation $Name" -ForegroundColor Green
    $StackPanel = [System.Windows.Controls.StackPanel]@{
        Name          = $Name
        Orientation   = $Orientation
        Margin        = '2'
        FlowDirection = $FlowDirection
    }

    if ($HorizontalAlignment) {
        $StackPanel.HorizontalAlignment = $HorizontalAlignment
    }

    return $StackPanel
} # END Function New-UIStackPanelElement

function New-UIDockPanelElement {
    param(
        $Name,
        $LastChildFill = $True
    )
    #Write-Host "[New-UIDockPanelElement] DockPanel Name: $Name" -ForegroundColor Green
    return [System.Windows.Controls.DockPanel]@{
        Name          = $Name
        LastChildFill = $LastChildFill
    }
} # END Function New-UIDockPanelElement

function New-UIScrollViewerElement {
    param(
        $Name
    )
    #Write-Host "[New-UIScrollViewerElement] ScrollViewer $Name" -ForegroundColor Green
    return [System.Windows.Controls.ScrollViewer]@{
        Name                          = $Name
        HorizontalScrollBarVisibility = 'Auto'
        VerticalScrollBarVisibility   = 'Auto'
    }
} # END Function New-UIScrollViewerElement

function New-UITextBoxElement {
    param(
        $Text,
        $Name
    )
    #Write-Host "[New-UITextBoxElement] TextBox $Name Text: $Text" -ForegroundColor Green
    $TextBox = [System.Windows.Controls.TextBox]@{
        Name     = $Name
        Text     = $Text
        FontSize = $DefaultFontSize
    }
    return $TextBox
} # END Function New-UITextBoxElement

function New-UITextBlockElement {
    param(
        $Name,
        $Text
    )
    #Write-Host "[New-UITextBlockElement] $Name Text: $Text" -ForegroundColor Green
    $TextBlock = [System.Windows.Controls.TextBlock]@{
        Name              = $Name
        Text              = $Text
        FontSize          = $DefaultFontSize
        VerticalAlignment = 'Center'
    }
    return $TextBlock

} # END Function New-UITextBlockElement

function New-UIButton {
    param(
        $Content,
        $Name,
        $Tag = 'None',
        $Margin = 0
    )
    #Write-Host "[New-UIButton] $Name ($Tag) Content: $Content" -ForegroundColor Green
    return [System.Windows.Controls.Button]@{
        Name     = $Name
        Tag      = $Tag
        Content  = $Content
        Margin   = $Margin
        FontSize = $DefaultFontSize
    }
} # END Function New-UIButton

#region UI Base Elements Actions

function Add-UIDropDownItem {
    param([ref]$DropDown, [ref]$Value)
    ##Write-Host "[Add-UIDropDownItem] Value: $($Value.Value)" -ForegroundColor DarkYellow
    [void]$DropDown.Value.AddChild($Value.Value)
} # END Function Add-UIDropDownItem

function Add-UIStackPanelChildElement {
    param([ref]$Array, [ref]$ArrayItem)
    ##Write-Host "[Add-UIStackPanelChildElement] $($Array.Value.Name) <-- $($ArrayItem.Value.Name)" -ForegroundColor DarkYellow
    [void]$Array.Value.AddChild($ArrayItem.Value)
} # END Function Add-UIStackPanelChildElement

#endregion UI Base Elements Actions

#endregion UI Base Elements

#region UI Featured Elements

#region UI Featured Elements Wrappers

function New-UIWrapperSection {
    param(
        [string]$Name,
        [string]$Label = $null,
        [string]$Type,
        [ValidateSet('Basic', 'Array', 'ArrayItem', 'Constructor')]
        $WrapperType = 'Basic',
        $Depth
    )
    Write-Host "[New-UIWrapperSection] $Depth $Label ($Type) ($WrapperType)" -ForegroundColor DarkGreen
    if ($Type.Contains('[]')) {
        $WrapperType = 'Array'
    }

    $BorderBackgroundColor = $ColorScheme[$Depth % $ColorScheme.Count]
    $SectionTop = New-UIBorder -Name $SectionBorderName -Tag $Depth -Background $BorderBackgroundColor

    #region Section Container

    if ($WrapperType -eq 'ArrayItem') {
        $Section_Panel = New-UIDockPanelElement -Name $SectionItemDockPanelName
        $SectionTop.Margin = '1'

        $ArrayItem_RemoveButton = New-UIButton -Content 'Remove' -Name $RemoveButtonName -Margin '2'
        [void]$Section_Panel.AddChild($ArrayItem_RemoveButton)
        [System.Windows.Controls.DockPanel]::SetDock($ArrayItem_RemoveButton, 'Right')

        $ArrayItem_RemoveButton.Add_Click({
                #Write-Host "[RemoveButton] $($this.Name)" -ForegroundColor Blue
                Remove-UIWrapperSectionContent ([ref]$this)
            })
    }
    else {
        $Section_Panel = [System.Windows.Controls.Grid]@{
            Name = $SectionGridName
        }

        $RowDef_Header = [System.Windows.Controls.RowDefinition]@{
            Height = 'Auto'
        }
        [void]$Section_Panel.RowDefinitions.Add($RowDef_Header)

        $RowDef_Content = [System.Windows.Controls.RowDefinition]@{
            Height = '*'
        }
        [void]$Section_Panel.RowDefinitions.Add($RowDef_Content)

        $RowDef_Footer = [System.Windows.Controls.RowDefinition]@{
            Height = 'Auto'
        }
        [void]$Section_Panel.RowDefinitions.Add($RowDef_Footer)
    }
    [void]$SectionTop.AddChild($Section_Panel)

    #endregion Section Container

    #region Header Section

    if ($Label -match '\S') {
        $Section_HeaderPanel = New-UIDockPanelElement -Name $SectionHeaderDockPanelName
        [void]$Section_Panel.AddChild($Section_HeaderPanel)
        [System.Windows.Controls.Grid]::SetRow($Section_HeaderPanel, 0)

        $SectionHeader_ButtonStackPanel = New-UIStackPanelElement -Name $SectionHeaderButtonStackPanelName -Orientation 'Horizontal' -FlowDirection 'RightToLeft' -HorizontalAlignment 'Right'
        [void]$Section_HeaderPanel.AddChild($SectionHeader_ButtonStackPanel)
        [System.Windows.Controls.DockPanel]::SetDock($SectionHeader_ButtonStackPanel, 'Right')

        $SectionHeader_TextBlock = New-UITextBlockElement -Name $SectionHeaderTextBlockName -Text $Label
        [void]$Section_HeaderPanel.AddChild($SectionHeader_TextBlock)
        $SectionHeader_TextBlock.Margin = '5,0,0,0'
        [System.Windows.Controls.DockPanel]::SetDock($SectionHeader_TextBlock, 'Left')

        # Minimize Button
        $Section_MinimizeButton = New-UIButton -Content 'Collapse' -Name $MinimizeButtonName -Margin '2'
        [void]$SectionHeader_ButtonStackPanel.AddChild($Section_MinimizeButton)

        $Section_MinimizeButton.Add_Click({
                #Write-Host "[MinimizeButton] $($this.Name) $($this.Content)" -ForegroundColor Blue
                $ScrollViewer = $this.Parent.Parent.Parent.Children | Where-Object { $_.Name -eq $SectionScrollViewerName }
                if ($ScrollViewer.Visibility -eq 'Visible') {
                    $ScrollViewer.Visibility = 'Collapsed'
                    $this.Content = 'Expand'
                }
                else {
                    $ScrollViewer.Visibility = 'Visible'
                    $this.Content = 'Collapse'
                }
            })

        if ($WrapperType -eq 'Array') {
            $Section_AddButton = New-UIButton -Content 'Add' -Name $AddButtonName -Tag $Type.TrimEnd('[]') -Margin '2'
            [void]$SectionHeader_ButtonStackPanel.AddChild($Section_AddButton)

            $Section_AddButton.Add_Click({
                    #Write-Host "[AddButton] $($this.tag)" -ForegroundColor Blue
                    $Section = Find-ParentByName -Object ([ref]$this) -Name $SectionBorderName
                    $SectionDepth = $Section.Tag
                    $NewItem = New-UIFeaturedElement -Type $this.Tag -WrapperType 'ArrayItem' -Depth ($SectionDepth + 1)
                    Add-UIWrapperSectionContent -Section ([ref]$Section) -Content ([ref]$NewItem)
                })
        }

        if ($WrapperType -eq 'Constructor') {
            $Section_ConstructButton = New-UIButton -Content 'Construct' -Name $ConstructButtonName -Tag $Type -Margin '2'
            [void]$SectionHeader_ButtonStackPanel.AddChild($Section_ConstructButton)

            # TODO Click: Construct Object
            $Section_ConstructButton.Add_Click({
                    Write-Host "[ConstructButton] $($this.tag)" -ForegroundColor Blue
                    $Constructors = Get-TypeConstructors -Object $this.tag
                    [array]$FilledParameters = Get-ClassConstructorFilledParameters -Object $([ref]$this)

                    if ($FilledParameters.count -gt 0) {
                        foreach ($Parameter in $FilledParameters) {
                            $Constructors = $Constructors | Where-Object { $_.Parameters.Name -contains $Parameter.keys }
                        }
                    }
                    else {
                        $Constructors = $Constructors | Where-Object { $_.Parameters.Count -eq 0 }
                    }

                    Update-UIConstructorParameters -Object $([ref]$this) -FilledParameters $FilledParameters -MatchingConstructors $Constructors -AllConstructors $Constructors
                    if ($null -ne $Constructor) {
                        $Object = New-ClassObject -ObjectType $this.tag -Properties $FilledParameters
                    }
                    else {
                        Write-Host "[ConstructButton] No matching constructor found for $($this.tag) with parameters $($FilledParameters)" -ForegroundColor Red
                    }
                })
        }
    }

    #endregion Header Section

    #region Content Section

    $Section_ScrollViewer = New-UIScrollViewerElement -Name $SectionScrollViewerName
    [void]$Section_Panel.AddChild($Section_ScrollViewer)
    [System.Windows.Controls.Grid]::SetRow($Section_ScrollViewer, 1)

    $Section_ContentStackPanel = New-UIStackPanelElement -Name $SectionContentName -Orientation 'Vertical'
    [void]$Section_ScrollViewer.AddChild($Section_ContentStackPanel)

    #endregion Content Section

    #region Footer Section

    # TODO Check for Methods that have been specified for the footer & Create Footer
    #[System.Windows.Controls.Grid]::SetRow($Section_FooterPanel, 1)

    #endregion Footer Section

    return $SectionTop
} # END Function New-UIWrapperSection

function Add-UIWrapperSectionContent {
    param([ref]$Section, [ref]$Content)
    #Write-Host "[Add-UIWrapperSectionContent] $($Section.Value.Name) <-- $($Content.Value.Name) ($($Content.Value.GetType().Fullname))" -ForegroundColor Blue
    try {
        $SectionContent = Find-ChildByName -Object $Section -Name $SectionContentName
        if ($null -ne $SectionContent) {
            $SectionContent.AddChild($Content.Value)
        }
        else {
            Write-Host "[Add-UIWrapperSectionContent] WARNING: Could not find SectionContent in $($Section.Value.Name)" -ForegroundColor Red
        }
    }
    catch {
        #Write-Host "[Add-UIWrapperSectionContent] ERROR: Adding content to SectionContent. $_" -ForegroundColor Red
    }
    Remove-Variable -Name SectionContent -ErrorAction SilentlyContinue
} # END Function Add-UIWrapperSectionContent

function Remove-UIWrapperSectionContent {
    param([ref]$Button)
    #Write-Host "[Remove-UIWrapperSectionContent] $($Content.Value.Name)" -ForegroundColor Blue
    try {
        $ArrayItemSectionBorder = Find-ParentByName -Object $Button -Name $SectionBorderName
        $ArraySectionBorder = Find-ParentByName -Object ([ref]$ArrayItemSectionBorder.Parent) -Name $SectionBorderName
        $ArraySectionContent = Find-ChildByName -Object ([ref]$ArraySectionBorder) -Name $SectionContentName
        [void]$ArraySectionContent.Children.Remove($ArrayItemSectionBorder)
    }
    catch {
        #Write-Host "[Remove-UIWrapperSectionContent] ERROR: Adding content to SectionContent. $_" -ForegroundColor Red
    }
    Remove-Variable -Name SectionContent -ErrorAction SilentlyContinue
} # END Function Remove-UIWrapperSectionContent

function New-UIFeaturedElement {
    param(
        $Label = $null,
        $Type,
        $ParentType,
        [ValidateSet('Basic', 'Array', 'ArrayItem', 'Construct')]
        $WrapperType = 'Basic',
        $Depth = 0
    )
    $ElementIsInterface = $False
    if ($Type.Contains('[]')) { $WrapperType = 'Array' }
    Write-Host "`n`n[New-UIFeaturedElement] $Depth $Label ($Type) ($WrapperType)" -ForegroundColor Magenta
    if ($ParentType -is [string]) {
        #Write-Host "[New-UIFeaturedElement] Converting ParentType string to Type: $ParentType" -ForegroundColor DarkCyan
        $ParentType = [Type]$ParentType
    }
    if ($Type -is [string]) {
        #Write-Host "[New-UIFeaturedElement] Converting Type string to Type: $Type" -ForegroundColor DarkCyan
        $Type = [Type]$Type
    }
    $TypeName = $Type.FullName

    $UIElementParameters = @{
        Label       = $Label
        WrapperType = $WrapperType
        Type        = $Type.FullName
    }

    if ($WrapperType -ne 'Array') {
        switch ($TypeName.TrimEnd('[]')) {
            $null {
                #Write-Host "[New-UIFeaturedElement] NULL Type for Label: $Label" -ForegroundColor Yellow
                $Element = $null
            }
            { $Type.IsEnum } {
                $Element = New-FeaturedDropDown @UIElementParameters
            }
            { @('System.String') -contains $_ } {
                $Element = New-FeaturedTextBox @UIElementParameters
            }
            { $_ -like 'System.Int*' } {
                $Element = New-FeaturedIntBox @UIElementParameters
            }
            { @('System.Boolean') -contains $_ } {
                $Element = New-FeaturedBoolean @UIElementParameters
            }
            { @('System.DateTime') -contains $_ } {
                $Element = New-FeaturedDate @UIElementParameters
            }
            { @('System.TimeSpan') -contains $_ } {
                $Element = New-FeaturedTime @UIElementParameters
            }
            default {
                if ($ParentType -ne $Type -and $null -ne $ParentType) {
                    #Write-Host "DEFAULT: $Type ($ParentType)" -ForegroundColor Blue
                    $Element = New-TypeInterface -Type $Type -Label $Label -Depth $Depth
                    $ElementIsInterface = $True
                }
                else {
                    #Write-Host "[New-UIFeaturedElement] Skipping self-referential type: $Type" -ForegroundColor Yellow
                    return $null
                }
            }
        }
    }
    else {
        $Element = New-UIFeaturedElement -Type $Type.FullName.TrimEnd('[]') -ParentType $ParentType -WrapperType 'ArrayItem' -Depth ($Depth + 1)
    }

    if (!$ElementIsInterface) {
        $WrapperElement = New-UIWrapperSection @UIElementParameters -Depth $Depth
        Add-UIWrapperSectionContent -Section ([ref]$WrapperElement) -Content ([ref]$Element)
        return $WrapperElement
    }

    return $Element

} # END Function New-UIFeaturedElement

#endregion UI Featured Elements Wrappers

function New-FeaturedDropDown {
    param(
        $Label,
        $Type
    )
    $ObjectType = [type]$Type
    $Values = $ObjectType.GetEnumValues()
    ##Write-Host "[New-FeaturedDropDown] Type: $Type $($Values -join ', ')" -ForegroundColor DarkCyan

    $DropDown = [System.Windows.Controls.ComboBox]@{
        SelectedIndex = 0
        FontSize      = $DefaultFontSize
        Name          = $Label
    }

    Add-UIDropDownItem -DropDown ([ref]$DropDown) -Value ([ref]'[Select an option]')
    foreach ($Value in $Values) {
        Add-UIDropDownItem -DropDown ([ref]$DropDown) -Value ([ref]$Value)
    }

    # $DropDown.Add_SelectionChanged({
    #         Update-UIConstructorParameters -Object $([ref]$this)
    #     })

    return $DropDown
} # END Function New-FeaturedDropDown

function New-FeaturedTextBox {
    param($Text)
    ##Write-Host "[New-FeaturedTextBox] Text: $Text" -ForegroundColor DarkCyan

    $TextBox = New-UITextBoxElement -Text $Text

    # $TextBox.Add_LostFocus({
    #        Update-UIConstructorParameters -Object $([ref]$this)
    #    })

    return $TextBox
} # END Function New-FeaturedTextBox

function New-FeaturedIntBox {
    <#
        Desired Features
            1. Up/Down Arrows on side
            2. Input Validation
    #>
    param($Int)
    ##Write-Host "[New-FeaturedIntBox] Int: $Int" -ForegroundColor DarkCyan

    New-FeaturedTextBox -Text $Int
} # END Function New-FeaturedIntBox

function New-FeaturedBoolean {
    param($Label, $IsArray = $False, $Value)
    ##Write-Host "[New-FeaturedBoolean] Value: $Value" -ForegroundColor DarkCyan

    $ToggledButton = [System.Windows.Controls.Primitives.ToggleButton]@{
        Content   = $Label
        IsChecked = $Value
        FontSize  = $DefaultFontSize
    }

    # $ToggledButton.Add_Checked({
    #         Update-UIConstructorParameters -Object $([ref]$this)
    #     })

    return $ToggledButton
} # END Function New-FeaturedBoolean

function New-FeaturedDate {
    param(
        $Label = 'Date',
        $IsArray = $False,
        $Date = (Get-Date)
    )
    ##Write-Host "[New-FeaturedDate] Date: $Date" -ForegroundColor DarkCyan

    New-UIWrapperLabel "$Label - Date: $Date"
} # END Function New-FeaturedDate

function New-FeaturedTime {
    param(
        $Label = 'Time',
        $IsArray = $False,
        $Time = (Get-Date).TimeOfDay
    )
    ##Write-Host "[New-FeaturedTime] Time: $Time" -ForegroundColor DarkCyan

    New-UIWrapperLabel "$Label - Time: $Time"
} # END Function New-FeaturedTime

#endregion UI Featured Elements

#region Interfaces

# Parent Interface
function New-TypeInterface {
    param (
        [parameter(ValueFromPipeline)]$Type,
        $Label,
        $Depth = 0
    )
    $HasElements = $False

    if ($Type -isnot [type]) { $Type = [Type]$Type }
    $Name = $Type.FullName.split('.')[-1]
    if (![bool]$Label) { $Label = $Name }

    Write-Host "`n`n[New-TypeInterface] $Depth $Label ($Type) ($WrapperType)" -ForegroundColor Magenta
    $Constructors = Get-TypeConstructors $Type.FullName
    if ($Constructors.Parameters.count -gt 0) {
        $AllConstructorParameters = ($Constructors.Parameters | Get-UniqueByProperty 'Name').List
    }
    elseif ($Constructors.Parameters.count -eq 0) {
        #Write-Host "[New-TypeInterface] No Constructors found for $Type" -ForegroundColor Yellow
        return $null
    }

    $ConstructorUI = New-UIWrapperSection -Label $Label -Name $Name -Type $Type.FullName -WrapperType 'Constructor' -Depth $Depth

    foreach ($Parameter in $AllConstructorParameters) {
        #Write-Host "`n[New-TypeInterface] Processing Parameter: $($Parameter.Name) Type: $($Parameter.Type)" -ForegroundColor DarkMagenta
        $ParameterUIElement = New-UIFeaturedElement -Label $Parameter.Name -Type $Parameter.Type -ParentType $Type -Depth ($Depth + 1)
        if ([bool]$ParameterUIElement) {
            Add-UIWrapperSectionContent -Section ([ref]$ConstructorUI) -Content ([ref]$ParameterUIElement)
            $HasElements = $True
        }
    }

    if ($HasElements) {
        return $ConstructorUI
    }
} # END Function New-TypeInterface

# Child Interface
function New-ObjectPropertiesInterface {
    param([parameter(ValueFromPipeline)]$Object)
} # END Function New-ObjectPropertiesInterface

# Sibling Interface
function New-ObjectMethodsInterface {
    param([parameter(ValueFromPipeline)]$Object)
} # END Function New-ObjectMethodsInterface

#endregion Interfaces

#region Processes

[System.Collections.Generic.List[string]]$HighlightedParameters = @()
function Update-UIConstructorParameters {
    param([ref]$Object, $FilledParameters, $MatchingConstructors, $AllConstructors)

    $SectionTop = Find-ParentByName -Object $Object -Name $SectionBorderName
    $AllParameters = $AllConstructors.Parameters.Name | Sort-Object -Unique
    $AcceptableParameters = $MatchingConstructors.Parameters.Name | Sort-Object -Unique
    $AcceptableParametersUsageCount = $MatchingConstructors.Parameters.Name | Group-Object | Sort-Object Count -Descending

    foreach ($Parameter in $AllParameters) {
        $ParameterSection = Find-ChildByLabel -Object $SectionTop -Label $Parameter
        if ($ParameterSection.GetType().FullName -ne 'System.Windows.Controls.Border') {
            $Border = Find-ChildByName -Object $([ref]$ParameterSection) -Name $SectionBorderName
        }
        else {
            $Border = $ParameterSection
        }

        if ($FilledParameters.Keys.Contains($Parameter)) {
            $Border.BorderBrush = 'Green'
            $Border.BorderThickness = 2
        }
        elseif ($AcceptableParameters -contains $Parameter) {
            $ColorIndex = $AcceptableParametersUsageCount.Name.IndexOf($Parameter)
            $Border.BorderBrush = $ConstructorParameterColorGradient[$ColorIndex]
            $Border.BorderThickness = 1 + (($ColorIndex + 1) / $AcceptableParametersUsageCount.count)
        }
        else {
            $Border.BorderBrush = 'Gray'
            $Border.BorderThickness = 1
        }
    }

} # END Function Update-UIRequiredConstructorParameters

#endregion Processes

#region ProcessesSteps (Actions)

function Get-ClassConstructorFilledParameters {
    param([parameter(ValueFromPipeline)][ref]$Object)
    $Properties = @{}

    $SectionTop = Find-ParentByName -Object $Object -Name $SectionBorderName
    $SectionContent = Find-ChildByName -Object $SectionTop -Name $SectionContentName

    foreach ($Item in $SectionContent.Children) {
        $ItemLabelObject = Find-ChildByName -Object ([ref]$Item) -Name $SectionHeaderTextBlockName
        $ItemLabel = $ItemLabelObject.Text

        $ItemContent = Find-ChildByName -Object ([ref]$Item) -Name $SectionContentName

        foreach ($SubItem in $ItemContent.Children) {
            switch ($SubItem.GetType().FullName) {
                'System.Windows.Controls.TextBox' {
                    if ([bool]$SubItem.Text) {
                        $Properties.$ItemLabel = $SubItem.Text
                    }
                }
                #'System.Windows.Controls.Primitives.ToggleButton' {
                #    $Properties.$ItemLabel = $SubItem.IsChecked
                #}
                'System.Windows.Controls.ComboBox' {
                    if ($SubItem.SelectedItem -ne '[Select an option]') {
                        $Properties.$ItemLabel = $SubItem.SelectedItem
                    }
                    # $Properties.$ItemLabel = $SubItem.SelectedItem
                }
                'System.Windows.Controls.Border' {
                    # Nested Object
                    $NestedProperties = Get-ClassConstructorFilledParameters -Object ([ref]$SubItem)
                    if ($NestedProperties.Keys.count -gt 0) {
                        $Properties.$ItemLabel = $NestedProperties
                    }
                }
                # Default
                default {
                    Write-Host "[Get-ClassConstructorFilledParameters] WARNING: Unsupported UI Element Type: $($SubItem.GetType().FullName) for Property: $ItemLabel" -ForegroundColor DarkYellow
                }
            }
        }
    }

    if ($Properties.Keys.count -gt 0) {
        return $Properties
    }
    return $null
} # END Function Get-ClassConstructorFilledParameters

function New-ClassObject {
    param(
        $ObjectType,
        $Properties
    )
    $Object = New-Object -TypeName $ObjectType -Property $Properties
    return $Object
} # END Function New-ClassObject

#endregion ProcessesSteps (Actions)

#endregion All Functions

#region START

$Interface = New-TypeInterface -Type $Class

$Window = [System.Windows.Window]@{
    Title = $Class.split('.')[-1] + ' Interface'
}
$Window.AddChild($Interface)
[Void]$Window.ShowDialog()

#endregion START
