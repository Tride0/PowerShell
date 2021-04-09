Function Where-ObjectFast {
    #https://powershell.one/tricks/performance/pipeline
    Param( [ScriptBlock]$FilterScript )
    Begin {
        $code = "
            & {
                process { if ($FilterScript) { `$_ } }
            }
        "
        $pip = [ScriptBlock]::Create($code).GetSteppablePipeline()
        $pip.Begin($true)
    }
    Process { $pip.Process($_) }
    End { $pip.End() }
}
