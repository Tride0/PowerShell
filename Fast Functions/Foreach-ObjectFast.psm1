Function Foreach-ObjectFast {
    param (
        [ScriptBlock] $Process,
        [ScriptBlock] $Begin,
        [ScriptBlock] $End
    )
    begin {
        $code = " & { begin { $Begin } process { $Process } end { $End } }"
        $pip = [ScriptBlock]::Create($code).GetSteppablePipeline()
        $pip.Begin($true)
    }
    process { $pip.Process($_) }
    end { $pip.End() }
}
