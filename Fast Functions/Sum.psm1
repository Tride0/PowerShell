Function Sum {
    Begin { $Sum = 0 }
    Process { $Sum += $_ }
    End { Return $Sum }
}