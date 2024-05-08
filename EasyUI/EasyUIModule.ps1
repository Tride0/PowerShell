Function New-UIBase {
    Param(
        $Title = 'Untitled',
        $PrimaryColor = 'Gray',
        $SecondaryColor = 'Purple'
    )
    Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

    $Window = [System.Windows.Window]@{
        Title       = $Title
        Background  = $PrimaryColor
        BorderBrush = $SecondaryColor
        MinHeight   = 500
        MinWidth    = 500
    }
    $Border = [System.Windows.Controls.Border]@{
        BorderBrush     = $SecondaryColor
        BorderThickness = 1
    }
    $ViewBox = [System.Windows.Controls.ViewBox]@{
        Stretch          = 'Fill'
        StretchDirection = 'Both'
        Margin           = '2'
    }
    $ItemsControl = [System.Windows.Controls.ItemsControl]::New()

    $ViewBox.AddChild($ItemsControl)
    $Border.AddChild($ViewBox)
    $Window.AddChild($Border)

    Return $ItemsControl
}

Function New-UIItem {
    Param(
        [ValidateSet('Button', 'TextBox', 'TextBlock', 'Hidden')]
        [String[]]$Types,
        [int[]]$WidthRatios = 1,
        [HashTable[]]$ItemProperties
    )

    $Objects = @()
    Foreach ($SelectedType in $Types) {
        $Objects += Switch ($SelectedType) {
            'Button' {
                [System.Windows.Controls.Button]@{}
            }
            'TextBox' {
                [System.Windows.Controls.TextBox]@{}
            }
            'TextBlock' {
                [System.Windows.Controls.TextBlock]@{
                    TextWrapping = 'Wrap'
                }
            }
            'Hidden' {
                [System.Windows.Controls.TextBlock]@{
                    Visibility = 'Hidden'
                }
            }
        }
    }

    $Grid = [System.Windows.Controls.Grid]@{}
    For ($i = 0; $i -lt $Objects.Count; $i++) {
        If ($WidthRatios.Count -gt 0) {
            $Grid.ColumnDefinitions.Add(
                [System.Windows.Controls.ColumnDefinition]@{
                    Width = "$($WidthRatios[$i])*"
                }
            )
        }

        If ($ItemProperties.Count -gt 0) {
            $Properties = $ItemProperties[$i]
            If ($Properties.Keys.Count -gt 0) {
                Foreach ($Key in $Properties.Keys) {
                    $Objects[$i].$Key = $Properties.$Key
                }
            }
        }

        $Objects[$i].Margin = '1'
        $Grid.AddChild($Objects[$i])

        [System.Windows.Controls.Grid]::SetColumn($Objects[$i], $i)
    }

    Return $Grid
}

Function Add-UIItem {
    Param(
        $Parent,
        [Array][Parameter(ValueFromPipeline)]$Children
    )
    Process {
        Foreach ($Child in $Children) {
            If ([Bool]$Child.Parent) {
                $ChildParent = $Child.Parent
                While ($ChildParent.Parent) {
                    $ChildParent = $ChildParent.Parent
                }
            }
            Else { $ChildParent = $Child }

            $Parent.AddChild($ChildParent)
        }
    }
}

Function Start-UI {
    Param($UI)
    If ($UI.GetType().FullName -ne 'System.Windows.Window') {
        $Window = $UI
        While ($Window.GetType().FullName -ne 'System.Windows.Window') {
            $Window = $Window.Parent
        }
    }
    Else {
        $Window = $UI
    }

    $SetColors = {
        # $Window.Background #? Primary
        # $Window.BorderBrush #? Secondary
        Param([Array]$Items)
        Foreach ($Item in $Items) {
            'Content', 'Children', 'Child', 'Items', 'Item' | ForEach-Object -Process {
                If ($Item.BorderBrush) {
                    If ($Item.GetType().FullName -like '*Button*') {
                        $RGB = '{0:X2}{1:X2}{2:X2}' -f $Window.BorderBrush.Color.r, $Window.BorderBrush.Color.g, $Window.BorderBrush.Color.b
                        $Item.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#' + $RGB / 2)
                    }
                    Else {
                        $Item.BorderBrush = $Window.BorderBrush
                    }
                }
                If ([Bool]$Item.$_) {
                    $SetColors.Invoke($Item.$_)
                }
            }
        }
    }
    $SetColors.Invoke($Window)

    $Window.Width = $Window.MinWidth
    $Window.MinHeight = $Window.Height = @($UI.Items.Height -notMatch 'NaN') + $Window.MinHeight | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $Window.ShowDialog()
}

function Convert-Color {
    param(
        [Parameter(ParameterSetName = 'RGB', Position = 0)]
        [ValidateScript( { $_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$' })]
        $RGB,
        [Parameter(ParameterSetName = 'HEX', Position = 0)]
        [ValidateScript( { $_ -match '[A-Fa-f0-9]{6}' })]
        [string]
        $HEX
    )
    Switch ($PsCmdlet.ParameterSetName) {
        'RGB' {
            if ($null -eq $RGB[2]) {
                Write-Error 'Value missing. Please enter all three values separated by comma.'
            }
            $red = [convert]::ToString($RGB[0], 16)
            $green = [convert]::ToString($RGB[1], 16)
            $blue = [convert]::ToString($RGB[2], 16)
            if ($red.Length -eq 1) { $red = '0' + $red }
            if ($green.Length -eq 1) { $green = '0' + $green }
            if ($blue.Length -eq 1) { $blue = '0' + $blue }
            Write-Output $red$green$blue
        }
        'HEX' {
            $red = $HEX.Remove(2, 4)
            $Green = $HEX.Remove(4, 2)
            $Green = $Green.remove(0, 2)
            $Blue = $hex.Remove(0, 4)
            $Red = [convert]::ToInt32($red, 16)
            $Green = [convert]::ToInt32($green, 16)
            $Blue = [convert]::ToInt32($blue, 16)
            Write-Output $red, $Green, $blue
        }
    }
}

$UIBase = New-UIBase

$MenuGroup = New-UIItem -Types Button, Hidden, Button -WidthRatios 1, 1000, 1 -ItemProperties @{ Content = 'Menu' }, @{}, @{Content = 'Profile' }

$Group1 = New-UIItem -Types TextBox, Button -WidthRatios 10, 2 -ItemProperties @{}, @{ Content = 'Search' }

$Group2 = New-UIItem -Types TextBox -ItemProperties @{
    IsReadOnly = $True
}

$Group3 = New-UIItem -Types TextBox, Button -WidthRatios 10, 5 -ItemProperties @{IsReadOnly = $True }, @{Content = 'Commit' }
$Group3.Children[1].Content = 'Commit'

$MenuGroup, $Group1, $Group2, $Group3 | Add-UIItem -Parent $UIBase

Start-UI -UI $UIBase