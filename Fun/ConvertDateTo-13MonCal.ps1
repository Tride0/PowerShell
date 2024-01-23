$Dates = @(
    '1/1 - (New Years)'
    '2/14 - (Valentine''s)'
    '7/4 - (Independence Day)'
    '10/31 - (Halloween)'
    '12/25 - (Christmas)'
    '12/30 - (Year''s End)'
    '12/31 - (!Year Day!)'
)

$DaysOfWeek = @(
    'Sun'
    'Mon'
    'Tue'
    'Wed'
    'Thu'
    'Fri'
    'Sat'
)

$MonthsOfNewCal = @(
    'January'
    'February'
    'March'
    'April'
    'May'
    'June'
    'Sol'
    'July'
    'August'
    'September'
    'October'
    'November'
    'December'
)

Foreach ($Date in $Dates) {
    Remove-Variable Day, note -ErrorAction SilentlyContinue
    
    If ($Date -like '* *') {
        $Note = "- $($Date.Split('-')[1].Trim())"
        $Day = $Date.Split('-')[0].Trim()
    }
    Else {
        $Day = $Date
    }

    Write-Host $Day -ForegroundColor Magenta -NoNewline
    $Date = [DateTime]"$Day/1999" # Year is there because this doesn't work on leap years
    
    $CurrentDay = [int]$Date.Day
    $CurrentMonth = [int]$Date.Month
    
    $DaysToSubtract = ($CurrentMonth - 1) * 28

    $NewDayOfMonth = $Date.DayOfYear - $DaysToSubtract

    If ($CurrentMonth -eq 12 -and $CurrentDay -eq 31) {
        $NewDayOfMonth = 29
        $NewMonth = 13
    }
    ElseIf ($NewDayOfMonth -gt 28) {
        $Multiplier = [Math]::Floor($NewDayOfMonth / 28)

        $NewDayOfMonth = $NewDayOfMonth - 28 * $Multiplier
        
        If ($NewDayOfMonth -eq 0) {
            $Multiplier -= 1
            $NewDayOfMonth = 28
        }

        $NewMonth = $CurrentMonth + $Multiplier
    }
    Else {
        $NewMonth = $CurrentMonth
    }

    Write-Host " - $($DaysOfWeek[($NewDayOfMonth%7-1)]), $($MonthsOfNewCal[$NewMonth-1]) $NewDayOfMonth $Note"
}

Write-Host "`n`nGood Start Years" -ForegroundColor Cyan
$CheckYearsIntoFuture = 50
(([DateTime]::Now.Year)..([DateTime]::Now.AddYears($CheckYearsIntoFuture).Year)) | ForEach-Object {
    $Year = [DateTime]"1/1/$_"
    If ($Year.DayOfWeek -like "$($DaysOfWeek[0])*") {
        If ($Year.Year % 4 -eq 0) {
            Write-Host 'Leap year::: ' -NoNewline -ForegroundColor Green
        }
        $Year.ToString('ddd, MMM dd, yyyy').Trim()
    }
}
