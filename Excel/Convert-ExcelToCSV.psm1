Function Convert-ExcelToCSV {
    Param(
        $FilePath,
        $Password,
        [int]$DeleteFirstRows
    )
    
    $Parent = Split-Path $FilePath -Parent
    $File = Get-Item $FilePath
    
    $Excel = New-Object -ComObject Excel.Application
    $Excel.Visible = $false
    $Excel.DisplayAlerts = $false

    If ([Boolean]$Password) {
        $Workbook = $Excel.Workbooks.Open($FilePath, 0, 0, 5, $Password)
    }
    Else {
        $Workbook = $Excel.Workbooks.Open($FilePath)
    }

    If ([Boolean]$DeleteFirstRows -and $DeleteFirstRows -gt 0) {
        $Sheet = $WorkBook.Sheets.Item(1)
        For ($I = 0; $I -lt $DeleteFirstRows; $I++) {
            [Void] $Sheet.Cells.Item(1, 1).EntireRow.Delete()
        }
    }

    $Workbook.SaveAs("$Parent\$($File.BaseName).csv", 6)
    $WorkBook.Close()
    $Excel.Quit()
}

