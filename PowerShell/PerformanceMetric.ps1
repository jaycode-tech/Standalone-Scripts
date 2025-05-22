function Measure-TimeIt {
    param(
        [Parameter(Mandatory)]
        [ScriptBlock]$Script,
        [Parameter()]
        [Hashtable]$NamedArgs,
        [Parameter(ValueFromRemainingArguments = $true)]
        $Args
    )
    $output = $null
    $elapsed = if ($NamedArgs) {
        Measure-Command { $output = & $Script @NamedArgs }
    } else {
        Measure-Command { $output = & $Script @Args }
    }
    return [PSCustomObject]@{
        OutputData = $output
        Timing = $elapsed
    }
}

# Example usage:
# function Add-Numbers { param($a, $b) $a + $b }
# Measure-TimeIt -Script ${function:Add-Numbers} -Args 5 7
# Measure-TimeIt -Script ${function:Add-Numbers} -NamedArgs @{a=5; b=7}
# Measure-TimeIt { Start-Sleep -Seconds 2 }