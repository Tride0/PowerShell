Function Measure-ObjectFast {
    Begin { $i = 0 }
    Process { $i ++ }
    End { @{ Count = $i } }
}