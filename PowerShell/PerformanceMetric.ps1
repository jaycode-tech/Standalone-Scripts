<#
.SYNOPSIS
    Measures the execution time of a script block and returns its output and timing information.

.DESCRIPTION
    The Measure-TimeIt function executes a provided script block, optionally with named or positional arguments,
    and measures the time taken for its execution. It returns a custom object containing the output of the script
    and the timing details.

.PARAMETER Script
    The script block to execute and measure.

.PARAMETER NamedArgs
    A hashtable of named arguments to pass to the script block.

.PARAMETER Args
    Positional arguments to pass to the script block.

.EXAMPLE
    # Measure the time taken to sleep for 2 seconds
    Measure-TimeIt { Start-Sleep -Seconds 2 }

.EXAMPLE
    # Define a function and measure its execution with positional arguments
    function Add-Numbers { param($a, $b) $a + $b }
    Measure-TimeIt -Script ${function:Add-Numbers} -Args 5 7

.EXAMPLE
    # Measure execution with named arguments
    function Multiply-Numbers { param($x, $y) $x * $y }
    Measure-TimeIt -Script ${function:Multiply-Numbers} -NamedArgs @{x=3; y=4}

.EXAMPLE
    # Measure a script block that outputs multiple lines
    Measure-TimeIt { 1..3 | ForEach-Object { Write-Output "Line $_"; Start-Sleep -Milliseconds 200 } }

.EXAMPLE
    # Handle an error in the script block
    Measure-TimeIt { throw "Intentional error" }

.NOTES
    Author: Jaya Surya Pennada
    Date: 2025-05-23
#>

function Measure-TimeIt {
    param(
        [Parameter(Mandatory)]
        [ScriptBlock]$Script,
        [Parameter()]
        [Hashtable]$NamedArgs,
        [Parameter(ValueFromRemainingArguments = $true)]
        $Args
    )

    # Error handling: Ensure Script is a valid ScriptBlock
    if (-not $Script -or -not ($Script -is [ScriptBlock])) {
        throw "The -Script parameter must be a valid ScriptBlock."
    }

    $output = $null
    $elapsed = $null

    try {
        $elapsed = if ($NamedArgs) {
            if (-not ($NamedArgs -is [Hashtable])) {
                throw "The -NamedArgs parameter must be a hashtable."
            }
            Measure-Command { $output = & $Script @NamedArgs }
        } else {
            Measure-Command { $output = & $Script @Args }
        }
    } catch {
        Write-Error "An Error Occured: $_"
        return [PSCustomObject]@{
            OutputData = $null
            Timing = $null
            Error = $_.Exception.Message
        }
    }

    return [PSCustomObject]@{
        OutputData = $output
        Timing = $elapsed
    }
}