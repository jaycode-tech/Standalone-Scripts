<#
.SYNOPSIS
    Installs and imports one or more PowerShell modules, with support for version, path, force, and retry logic.

.DESCRIPTION
    This function attempts to install and import the specified PowerShell module(s). It supports:
    - Installing a specific version or the latest version if not specified.
    - Importing from a custom path if provided.
    - Forcing import/install if requested.
    - Retrying failed operations a configurable number of times with a delay between attempts.
    - Accepts a single module name or a list of module names.
    - Provides detailed status and error messages for each step.

.PARAMETER ModuleName
    The name of the module to install/import. Accepts a string or an array of strings.

.PARAMETER ModuleVersion
    (Optional) The specific version of the module to install/import. If not specified, the latest available version is used.

.PARAMETER ModulePath
    (Optional) The file system path to the module to import. If specified, the module is imported from this path instead of the gallery.

.PARAMETER Force
    (Optional) If specified, forces the import and install operations.

.PARAMETER Retry
    (Optional) The number of times to retry a failed install/import operation. Default is 1.

.PARAMETER TimeDelay
    (Optional) The number of seconds to wait between retries. Default is 10 seconds.

.EXAMPLE
    Install-Import_PSModules -ModuleName Az -ModuleVersion 10.0.0 -Retry 2 -TimeDelay 15
    # Installs and imports version 10.0.0 of the Az module, retrying up to 2 times with a 15 second delay if needed.

.EXAMPLE
    Install-Import_PSModules -ModuleName @('Az','Pester') -Force
    # Installs and imports the latest versions of Az and Pester modules, forcing the operation.

.EXAMPLE
    Install-Import_PSModules -ModuleName Pester -ModulePath '/Users/jay/Modules/Pester' -Force
    # Imports the Pester module from a custom path, forcing the import.

.EXAMPLE
    Install-Import_PSModules -ModuleName 'SqlServer' -Retry 3 -TimeDelay 30
    # Installs and imports the latest version of SqlServer, retrying up to 3 times with a 30 second delay if needed.

.EXAMPLE
    Install-Import_PSModules -ModuleName 'Az' -ModuleVersion '11.3.0'
    # Installs and imports version 11.3.0 of the Az module with default retry and delay settings.

.NOTES
    Author: Jaya Surya Pennada
    Date: 2025-05-23
    Platform: Cross-platform (Windows, macOS, Linux with PowerShell Core)
#>

function Install-Import_PSModules {
    param (
        [Parameter(Mandatory)]
        [Alias('Name')]
        [Object]$ModuleName, # Accepts string or array
        [Parameter()]
        [string]$ModuleVersion,
        [Parameter()]
        [string]$ModulePath,
        [Parameter()]
        [switch]$Force,
        [Parameter()]
        [int]$Retry = 1,
        [Parameter()]
        [int]$TimeDelay = 10
    )
    function Write-RetryMessage {
        param($TimeDelay, $CurrentAttempt, $MaxAttempts)
        $retryNum = $CurrentAttempt
        if ($TimeDelay -ge 60) {
            $mins = [math]::Floor($TimeDelay/60)
            $secs = $TimeDelay % 60
            if ($secs -gt 0) {
                Write-Host ("Retry ${retryNum}/${MaxAttempts}: Retrying in ${mins} min ${secs} sec...")
            } else {
                Write-Host ("Retry ${retryNum}/${MaxAttempts}: Retrying in ${mins} min...")
            }
        } else {
            Write-Host ("Retry ${retryNum}/${MaxAttempts}: Retrying in ${TimeDelay} sec...")
        }
    }
    try {
        $moduleNames = @($ModuleName)
        foreach ($name in $moduleNames) {
            $attempt = 0
            $success = $false
            while (-not $success -and $attempt -le $Retry) {
                $attempt++
                try {
                    # Check if the module is already installed
                    $module = Get-Module -Name $name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
                    if ($ModuleVersion) {
                        # If version is specified, only accept exact version
                        $moduleExact = Get-Module -Name $name -ListAvailable | Where-Object { $_.Version -eq $ModuleVersion } | Select-Object -First 1
                        if ($moduleExact) {
                            Write-Host "Module '$name' version '$ModuleVersion' is already installed."
                            try {
                                Import-Module -Name $name -RequiredVersion $ModuleVersion -Force:$Force -ErrorAction Stop
                                Write-Host "Module '$name' version '$ModuleVersion' imported successfully."
                            } catch {
                                Write-Host "Failed to import module '$name' version '$ModuleVersion': $_"
                                if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                                continue
                            }
                            $success = $true
                            continue
                        }
                    } else {
                        # If no version specified, import any available version
                        if ($module) {
                            Write-Host "Module '$name' is already installed (version $($module.Version))."
                            try {
                                Import-Module -Name $name -Force:$Force -ErrorAction Stop
                                Write-Host "Module '$name' imported successfully."
                            } catch {
                                Write-Host "Failed to import module '$name': $_"
                                if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                                continue
                            }
                            $success = $true
                            continue
                        }
                    }
                    # Check if the module path is provided
                    if ($ModulePath) {
                        if (-Not (Test-Path -Path $ModulePath)) {
                            Write-Host "Module path '$ModulePath' does not exist."
                            $success = $true
                            continue
                        }
                        try {
                            Import-Module -Name $ModulePath -Force:$Force -ErrorAction Stop
                            Write-Host "Module '$name' imported successfully from path '$ModulePath'."
                        } catch {
                            Write-Host "Failed to import module from path '$ModulePath': $_"
                            if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                            continue
                        }
                        $success = $true
                        continue
                    }
                    # Install the module (specific version if given, otherwise latest)
                    if ($ModuleVersion) {
                        try {
                            Install-Module -Name $name -RequiredVersion $ModuleVersion -Force:$Force -Scope CurrentUser -ErrorAction Stop
                            Write-Host "Module '$name' version '$ModuleVersion' installed successfully."
                            try {
                                Import-Module -Name $name -RequiredVersion $ModuleVersion -Force:$Force -ErrorAction Stop
                                Write-Host "Module '$name' version '$ModuleVersion' imported successfully."
                            } catch {
                                Write-Host "Failed to import module '$name' version '$ModuleVersion': $_"
                                if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                                continue
                            }
                            $success = $true
                        } catch {
                            Write-Host "Failed to install module '$name' version '$ModuleVersion': $_"
                            if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                            continue
                        }
                    } else {
                        try {
                            Install-Module -Name $name -Force:$Force -Scope CurrentUser -ErrorAction Stop
                            Write-Host "Module '$name' installed successfully."
                            $module = Get-Module -Name $name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
                            if ($module) {
                                try {
                                    Import-Module -Name $name -Force:$Force -ErrorAction Stop
                                    Write-Host "Module '$name' imported successfully."
                                } catch {
                                    Write-Host "Failed to import module '$name': $_"
                                    if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                                    continue
                                }
                                $success = $true
                            } else {
                                Write-Host "Failed to install or import module '$name'."
                                if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                            }
                        } catch {
                            Write-Host "Failed to install module '$name': $_"
                            if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                            continue
                        }
                    }
                } catch {
                    Write-Host "Unexpected error (Attempt $attempt/$($Retry+1)): $_"
                    if ($attempt -le $Retry) { Write-RetryMessage $TimeDelay $attempt ($Retry+1); Start-Sleep -Seconds $TimeDelay }
                }
            }
        }
    } catch {
        Write-Host "Unexpected error: $_"
    }
}