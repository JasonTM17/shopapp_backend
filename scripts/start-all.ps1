[CmdletBinding()]
param(
    [switch]$SkipDbImport,
    [switch]$ForceDbImport,
    [switch]$SkipBuild,
    [switch]$NoBackend,
    [switch]$ForegroundBackend,
    [int]$HealthTimeoutSec = 180
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

function Assert-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Command '$Name' was not found in PATH."
    }
}

function Wait-ContainerRunning {
    param(
        [string]$Name,
        [int]$TimeoutSec = 120
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $running = (& docker inspect -f "{{.State.Running}}" $Name 2>$null)
        if ($LASTEXITCODE -eq 0 -and $running -eq "true") {
            return
        }
        Start-Sleep -Seconds 2
    }
    throw "Container '$Name' did not reach running state within $TimeoutSec seconds."
}

function Wait-HealthEndpoint {
    param(
        [string]$Url,
        [int]$TimeoutSec = 180
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                return
            }
        } catch {
        }
        Start-Sleep -Seconds 3
    }
    throw "Health endpoint '$Url' is not ready after $TimeoutSec seconds."
}

function Wait-MySqlReady {
    param(
        [string]$Password,
        [int]$TimeoutSec = 120
    )
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        & docker exec mysql8-container sh -c "MYSQL_PWD='$Password' mysqladmin -uroot ping --silent >/dev/null 2>&1"
        if ($LASTEXITCODE -eq 0) {
            return
        }
        Start-Sleep -Seconds 2
    }
    throw "MySQL in container 'mysql8-container' is not ready within $TimeoutSec seconds."
}

function Get-EnvValue {
    param(
        [string]$Key,
        [string]$DefaultValue
    )
    $current = [Environment]::GetEnvironmentVariable($Key)
    if (-not [string]::IsNullOrWhiteSpace($current)) {
        return $current
    }
    $envFile = Join-Path $projectRoot ".env"
    if (Test-Path $envFile) {
        $match = Get-Content $envFile | Where-Object { $_ -match "^\s*$Key=(.*)$" } | Select-Object -First 1
        if ($match) {
            return ($match -replace "^\s*$Key=", "").Trim()
        }
    }
    return $DefaultValue
}

Assert-Command "docker"
Assert-Command "java"

Write-Step "Checking Docker daemon"
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Docker daemon is not available. Please start Docker Desktop and retry."
}

Write-Step "Starting infrastructure containers"
docker compose -f docker-compose.yml up -d `
    mysql8-container `
    redis-container `
    zookeeper-01 `
    zookeeper-02 `
    zookeeper-03 `
    kafka-broker-01

Write-Step "Waiting infrastructure containers"
$requiredContainers = @(
    "mysql8-container",
    "redis-container",
    "zookeeper-01",
    "zookeeper-02",
    "zookeeper-03",
    "kafka-broker-01"
)
foreach ($container in $requiredContainers) {
    Wait-ContainerRunning -Name $container -TimeoutSec 180
}

$mysqlPassword = Get-EnvValue -Key "MYSQL_ROOT_PASSWORD" -DefaultValue "Abc123456789@"
$dbFile = Join-Path $projectRoot "database.sql"

Write-Step "Waiting MySQL readiness"
Wait-MySqlReady -Password $mysqlPassword -TimeoutSec 180

if (-not $SkipDbImport) {
    if (-not (Test-Path $dbFile)) {
        throw "database.sql not found at '$dbFile'."
    }

    Write-Step "Checking database schema"
    $tableCount = (& docker exec -e "MYSQL_PWD=$mysqlPassword" mysql8-container mysql -uroot -Nse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='ShopApp';" 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot connect to MySQL container with current MYSQL_ROOT_PASSWORD."
    }

    if ($ForceDbImport -or [int]$tableCount -eq 0) {
        Write-Step "Importing database.sql into ShopApp"
        Get-Content -Raw $dbFile | docker exec -e "MYSQL_PWD=$mysqlPassword" -i mysql8-container mysql -uroot ShopApp
    } else {
        Write-Step "Skipping database import because schema is already initialized (tables=$tableCount)"
    }
}

if (-not $SkipBuild) {
    Write-Step "Compiling backend"
    .\mvnw.cmd -q -DskipTests compile
}

if ($NoBackend) {
    Write-Step "Infrastructure is ready. Backend start was skipped."
    exit 0
}

if ($ForegroundBackend) {
    Write-Step "Starting backend in foreground"
    .\mvnw.cmd spring-boot:run
    exit $LASTEXITCODE
}

Write-Step "Starting backend in background"
$backendProcess = Start-Process -FilePath ".\mvnw.cmd" -ArgumentList "spring-boot:run" -WorkingDirectory $projectRoot -PassThru

Write-Step "Waiting backend health endpoint"
Wait-HealthEndpoint -Url "http://localhost:8088/api/v1/actuator/health" -TimeoutSec $HealthTimeoutSec

Write-Host ""
Write-Host "ShopApp backend is running." -ForegroundColor Green
Write-Host "Backend PID: $($backendProcess.Id)"
Write-Host "Swagger: http://localhost:8088/swagger-ui.html"
Write-Host "Health:  http://localhost:8088/api/v1/actuator/health"
