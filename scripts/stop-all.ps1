[CmdletBinding()]
param(
    [switch]$RemoveVolumes
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Stop-BackendProcesses {
    $targets = Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -eq "java.exe" -and
            (
                ($_.CommandLine -match "ShopappApplication") -or
                ($_.CommandLine -match "spring-boot:run") -or
                ($_.CommandLine -match "shopapp-backend")
            )
        }

    if (-not $targets) {
        Write-Host "No backend java process found."
        return
    }

    foreach ($proc in $targets) {
        try {
            Stop-Process -Id $proc.ProcessId -Force -ErrorAction Stop
            Write-Host "Stopped backend process PID=$($proc.ProcessId)"
        } catch {
            Write-Host "Failed to stop PID=$($proc.ProcessId): $($_.Exception.Message)"
        }
    }
}

Write-Step "Stopping backend process"
Stop-BackendProcesses

Write-Step "Stopping infrastructure containers"
$args = @("compose", "-f", "deployment.yaml", "-f", "kafka-deployment.yaml", "down")
if ($RemoveVolumes) {
    $args += "-v"
}
& docker @args

Write-Host ""
Write-Host "All services are stopped." -ForegroundColor Green
