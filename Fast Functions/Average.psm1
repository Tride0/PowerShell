Function Average {
    Begin { $Sum = 0; $c = 0 }
    Process { $Sum += $_; $c ++ }
    End { Return $Sum / $c }
}