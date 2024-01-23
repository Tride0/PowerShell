<#
    .NOTES
        Created By: Kyle Hewitt
        Contact: PushPishPoSh@gmail.com
        Created On: 11-09-2020
        Version: 2020.11.09

    .DESCRIPTION
        Show which months have bi weekly 3 paychecks
#>

$DayOfWeek = 'Thursday'
$Year = '2021'
$FirstPaycheck = '1/14'

# Get all occurances of the day of week in the year
$Days = @()
:GetDatesWithDayOfWeek for ($m = 1; $m -le 12; $m++) { 
    for ($d = 1; $d -le [DateTime]::DaysInMonth($Year, $m); $d++) { 
        $Date = Get-Date "$m/$d/$Year"
        If ($Date.DayOfWeek -eq $DayOfWeek) {
            $Days += [PSCustomObject]@{
                Month       = (Get-Culture).DateTimeFormat.GetMonthName($Date.Month)
                MonthNumber = $Date.Month
                Day         = $Date.Day
            }
        }
    }
}

# Return occurances of days of week if First Pay Check day is not one of those days
If (([DateTime]"$FirstPayCheck/$Year").DayOfWeek -ne $DayOfWeek) {
    Return $Days | Select-Object -Property Month, Day
}

# Get Index of First Paycheck relative to all occurances of the day of the week
:Indexing For ($i = 0; $i -lt $Days.Count; $i++) {
    If ($Days[$i].MonthNumber -eq $FirstPaycheck.Split('/').Split('\')[0] -and $Days[$i].Day -eq $FirstPaycheck.Split('/').Split('\')[1]) {
        $Index = $i
        Break Indexing
    }
}

# Get every other day of the week from the first index
$PayDays = @()
:PayDays For ($i = $Index; $i -lt $Days.Count; $i = $i + 2) {
    $PayDays += $Days[$i]
}


Return $PayDays | Group-Object -Property Month | Where-Object -FilterScript { $_.Count -ge 3 } | Select-Object -ExpandProperty Name
