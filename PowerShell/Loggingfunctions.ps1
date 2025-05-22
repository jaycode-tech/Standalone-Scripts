# Author: Jaya Surya Pennada
# Date: 2025-05-20
#
# DESCRIPTION:
#   This script provides two PowerShell classes for advanced logging:
#   - Logger: Logs messages to the console and optionally to a file, with log level and color support.
#   - TranscriptLogger: Inherits from Logger and adds PowerShell transcript logging.
#
# USAGE:
#   $logger = [Logger]::new("Info", "C:\Logs\MyLog.log", $true)
#   $logger.WriteLog("This is an info message", "Info")
#   $transcriptLogger = [TranscriptLogger]::new("Info", "C:\Logs\MyLog.log", $true)
#   $transcriptLogger.WriteLog("This is a test message", "Info")
#   $transcriptLogger.StopTranscript()
#
# NOTES:
#   - Ensure the script has permission to write to the specified log file path.
#   - The transcript is started automatically if a log file path is provided.
#   - Use StopTranscript() to end the transcript.

class Logger {
    [string]$SetLogLevel
    [string]$LogFilePath
    [bool]$CreateLogFileIfNotExists

    Logger(
        [string]$SetLogLevel = "Info", 
        [string]$LogFilePath = $null,
        [bool]$CreateLogFileIfNotExists = $false
    ) {
        $this.SetLogLevel = $SetLogLevel
        $this.LogFilePath = $LogFilePath
        $this.CreateLogFileIfNotExists = $CreateLogFileIfNotExists

        # Create log file at initialization if required
        try {
            if ($this.LogFilePath -and $this.CreateLogFileIfNotExists -and -not (Test-Path -Path $this.LogFilePath)) {
                New-Item -ItemType File -Path $this.LogFilePath -Force | Out-Null
            }
        } catch {
            Write-Warning "Failed to create log file: $_"
        }
    }
    <#
    .SYNOPSIS
    Writes a formatted log message to the console and optionally to a log file.

    .DESCRIPTION
    The WriteLog method outputs a timestamped and formatted log message to the console with color coding based on log type.
    If a log file path is specified, the message is also appended to the file. Log output respects the configured log level.

    .PARAMETER Message
    The message to be logged.

    .PARAMETER LogType
    The type of log message (e.g., Info, Error, Success, Processing, Warning). Default is "Info".

    .PARAMETER LogLevel
    The log level for this message (e.g., Info, Debug, Warning, Error, Critical). Default is "Info".

    .PARAMETER ForegroundColor
    Optional. The color to use for the console output. If not specified, a default color is chosen based on LogType.

    .EXAMPLE
    $logger.WriteLog("This is an info message", "Info")
    $logger.WriteLog("This is a warning message", "Warning")
    $logger.WriteLog("This is an error message", "Error")
    $logger.WriteLog("This is a success message", "Success")
    $logger.WriteLog("Processing started...", "Processing")
    $logger.WriteLog("This is a debug message", "Info", "Debug")
    $logger.WriteLog("Critical failure occurred!", "Error", "Critical", "Magenta")

    Writes an informational message to the console and, if configured, to the log file.

    .NOTES
    The log message will only be displayed or written if its LogType meets or exceeds the configured SetLogLevel.
    Ensure the script has permission to write to the specified log file path if logging to file is enabled.
    #>
    [void] WriteLog(
        [string]$Message, 
        [string]$LogType = "Info", 
        [string]$LogLevel = "Info",
        [string]$ForegroundColor = $null
    ) {
        # Default colors for log types
        $LogColors = @{
            "Info"       = "White"
            "Error"      = "Red"
            "Success"    = "Green"
            "Processing" = "Yellow"
            "Warning"    = "DarkOrange"
        }

        # Determine if the log should be displayed based on log level
        $LogLevelPriority = @{
            "Critical" = 1
            "Error"    = 2
            "Warning"  = 3
            "Info"     = 4
            "Debug"    = 5
        }

        if ($LogLevelPriority[$LogType] -gt $LogLevelPriority[$this.SetLogLevel]) {
            return
        }

        # Set the foreground color
        $ColorToUse = if ($ForegroundColor) { $ForegroundColor } else { $LogColors[$LogType] }

        # Display the log message
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        try {
            Write-Host -ForegroundColor $ColorToUse -Object "[${Timestamp}] [${LogLevel}] [${LogType}] - $Message"
        } catch {
            Write-Warning "Failed to write to console: $_"
        }

        # Append the log message to the log file if provided
        if ($this.LogFilePath) {
            try {
                if (Test-Path -Path $this.LogFilePath) {
                    Add-Content -Path $this.LogFilePath -Value "[${Timestamp}] [${LogLevel}] [${LogType}] - $Message"
                }
            } catch {
                Write-Warning "Failed to write to log file: $_"
            }
        }
    }
}

<#
.SYNOPSIS
Extends Logger to provide transcript logging functionality.

.DESCRIPTION
The TranscriptLogger class inherits from Logger and adds the ability to start and stop a PowerShell transcript.
A transcript records all output from the session to a file, in addition to standard log messages.
The transcript file is automatically named based on the main log file path.

.PARAMETER SetLogLevel
Specifies the minimum log level for messages to be logged or displayed.

.PARAMETER LogFilePath
The path to the main log file. The transcript file will be created in the same directory with a modified name.

.PARAMETER CreateLogFileIfNotExists
If set to $true, creates the log file and transcript file if they do not exist.

.EXAMPLE
$transcriptLogger = [TranscriptLogger]::new("Info", "C:\Logs\MyLog.log", $true)
$transcriptLogger.WriteLog("This is a test message", "Info")
$transcriptLogger.WriteLog("This is a warning message", "Warning")

.NOTES
The transcript is started automatically if a log file path is provided. Use StopTranscript() to end the transcript.
#>
class TranscriptLogger : Logger {
    [string]$TranscriptPath

    TranscriptLogger(
        [string]$SetLogLevel = "Info",
        [string]$LogFilePath = $null,
        [bool]$CreateLogFileIfNotExists = $false
    ) : base($SetLogLevel, $LogFilePath, $CreateLogFileIfNotExists) {
        if ($this.LogFilePath) {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($this.LogFilePath)
            $ext = [System.IO.Path]::GetExtension($this.LogFilePath)
            $dir = [System.IO.Path]::GetDirectoryName($this.LogFilePath)
            $this.TranscriptPath = Join-Path $dir ("${base}_transcript${ext}")
            try {
                if (
                    ($this.CreateLogFileIfNotExists -and -not (Test-Path -Path $this.LogFilePath)) -or
                    (Test-Path -Path $this.LogFilePath)
                ) {
                    # Ensure the transcript file exists before starting transcript
                    if (-not (Test-Path -Path $this.TranscriptPath)) {
                        New-Item -ItemType File -Path $this.TranscriptPath -Force | Out-Null
                    }
                    try {
                        Start-Transcript -Path $this.TranscriptPath -Force | Out-Null
                    } catch {
                        Write-Warning "Failed to start transcript: $_"
                    }
                }
            } catch {
                Write-Warning "Failed to initialize transcript file: $_"
            }
        }
    }

    <#
    .SYNOPSIS
    Stops the PowerShell transcript.

    .DESCRIPTION
    Ends the transcript started by the TranscriptLogger. Should be called when logging is complete.

    .EXAMPLE
    $logger.StopTranscript()
    #>
    [void] StopTranscript() {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            Write-Warning "Failed to stop transcript: $_"
        }
    }
}