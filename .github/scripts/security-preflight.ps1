param(
    [string]$Target = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = (Resolve-Path $Target).Path
Write-Host "[1/2] Ejecutando preflight de seguridad en: $root"

$forbiddenPaths = @(
    "BD.Subvenciones2025"
)

$patterns = @(
    "(?i)\bData\s*Source\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bInitial\s*Catalog\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bServer\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bDatabase\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bUser\s+ID\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bUID\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bPassword\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bPwd\b\s*(?<![=])=(?![=])\s*[^;\r\n]+",
    "(?i)\bapi[_-]?key\b\s*(?::|(?<![=])=(?![=]))\s*\S+",
    "(?i)\bclient[_-]?secret\b\s*(?::|(?<![=])=(?![=]))\s*\S+",
    "(?i)\btoken\b\s*(?::|(?<![=])=(?![=]))\s*\S+"
)

$extensions = @("*.md", "*.sql", "*.tt", "*.json", "*.yml", "*.yaml", "*.config", "*.xml", "*.cs")
$excludedGeneratedFiles = @("SANITIZATION-REPORT.md", "VALIDATION-REPORT.md", "PREFLIGHT-REPORT.md")

$findings = @()

foreach ($path in $forbiddenPaths) {
    $full = Join-Path $root $path
    if (Test-Path $full) {
        $findings += "Ruta sensible presente: $path"
    }
}

$files = Get-ChildItem -Path $root -Recurse -File -Include $extensions |
    Where-Object { $excludedGeneratedFiles -notcontains $_.Name }

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    foreach ($pattern in $patterns) {
        $matches = [regex]::Matches($content, $pattern)
        foreach ($match in $matches) {
            if ($match.Value -match "REDACTED_") {
                continue
            }
            $relativePath = $file.FullName.Substring($root.Length).TrimStart('\\')
            $findings += "${relativePath}: $($match.Value)"
        }
    }
}

Write-Host "[2/2] Generando PREFLIGHT-REPORT.md"
$reportPath = Join-Path $root "PREFLIGHT-REPORT.md"

$lines = @(
    "# Preflight Report",
    "",
    "## Summary",
    "- Target: $root",
    "- Findings: $($findings.Count)",
    "- Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    ""
)

if ($findings.Count -gt 0) {
    $lines += "## Findings (first 50)"
    $findings | Select-Object -First 50 | ForEach-Object { $lines += "- $_" }
    $lines += ""
    $lines += "## Result"
    $lines += "- FAIL: no compartir externamente hasta sanear."
}
else {
    $lines += "## Result"
    $lines += "- PASS: apto para fase de analisis externo controlado."
}

Set-Content -Path $reportPath -Value ($lines -join "`r`n") -Encoding UTF8

if ($findings.Count -gt 0) {
    throw "Preflight fallido. Revisa $reportPath"
}

Write-Host "Preflight completado: PASS"
