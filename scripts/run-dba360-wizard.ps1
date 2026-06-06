param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    [string]$SchemaPath,
    [string]$ConnectionString,
    [string]$Root = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $Root).Path
$workspaceRoot = Split-Path -Parent $repoRoot
$bootstrapScript = Join-Path $PSScriptRoot "bootstrap-source-of-truth.ps1"
$preflightScript = Join-Path $PSScriptRoot "security-preflight.ps1"

if (-not (Test-Path $bootstrapScript)) { throw "No se encontro bootstrap-source-of-truth.ps1" }
if (-not (Test-Path $preflightScript)) { throw "No se encontro security-preflight.ps1" }

Write-Host "[1/2] Creando fuente de verdad local..."
$bootstrapParams = @{
    ProjectName = $ProjectName
    Root = $repoRoot
}
if ($SchemaPath) { $bootstrapParams.SchemaPath = $SchemaPath }
if ($ConnectionString) { $bootstrapParams.ConnectionString = $ConnectionString }

& $bootstrapScript @bootstrapParams

$projectRoot = Join-Path $workspaceRoot ("dba_" + $ProjectName)
Write-Host "[2/2] Ejecutando preflight de seguridad sobre la fuente de verdad..."
& $preflightScript -Target $projectRoot

Write-Host "Wizard completado. Ya puedes iniciar analisis DBA 360 sobre: $projectRoot"
