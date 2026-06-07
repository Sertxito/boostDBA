param(
    [Parameter(Mandatory = $true)]
    [string]$SchemaFile,
    [string]$OutDir = "workspaces/ProjectName/plans"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $SchemaFile)) {
    throw "Schema file not found: $SchemaFile"
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$content = Get-Content -Path $SchemaFile -Raw

# Capture each procedure block from CREATE PROCEDURE ... until next GO
$procRegex = '(?is)CREATE\s+PROCEDURE\s+\[(?<schema>[^\]]+)\]\.\[(?<name>[^\]]+)\](?<body>.*?)(?:\r?\nGO\b|\z)'
$matches = [regex]::Matches($content, $procRegex)

$results = @()

foreach ($m in $matches) {
    $schema = $m.Groups['schema'].Value
    $name = $m.Groups['name'].Value
    $body = $m.Groups['body'].Value
    $fullName = "$schema.$name"

    $isSelectHeavy = [regex]::IsMatch($body, '(?is)^\s*(?:--.*\r?\n|/\*.*?\*/\s*)*\bAS\b.*\bSELECT\b')
    $hasInsert = [regex]::IsMatch($body, '(?i)\bINSERT\b')
    $hasUpdate = [regex]::IsMatch($body, '(?i)\bUPDATE\b')
    $hasDelete = [regex]::IsMatch($body, '(?i)\bDELETE\b')
    $hasMerge = [regex]::IsMatch($body, '(?i)\bMERGE\b')
    $hasTran = [regex]::IsMatch($body, '(?i)\bBEGIN\s+(TRAN|TRANSACTION)\b|\bCOMMIT\b|\bROLLBACK\b')
    $hasCursor = [regex]::IsMatch($body, '(?i)\bCURSOR\b')
    $hasDynamicSql = [regex]::IsMatch($body, '(?i)\bsp_executesql\b|\bEXEC\s*\(\s*@')
    $hasCrypto = [regex]::IsMatch($body, '(?i)\bOPEN\s+SYMMETRIC\s+KEY\b|\bDECRYPT\w*\b|\bENCRYPT\w*\b')

    $writes = @($hasInsert, $hasUpdate, $hasDelete, $hasMerge) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count

    $category = "Simple"
    $wave = "Wave-2"
    $strategy = "CSharp-Service"

    if ($hasCrypto -or $hasTran -or $hasCursor -or $hasDynamicSql) {
        $category = "Critical"
        $wave = "Wave-4"
        $strategy = "Domain-Service+High-Coverage"
    } elseif ($writes -ge 2 -or (($writes -ge 1) -and -not $isSelectHeavy)) {
        $category = "Complex"
        $wave = "Wave-3"
        $strategy = "Domain-Service"
    } elseif ($writes -eq 1) {
        $category = "Simple"
        $wave = "Wave-2"
        $strategy = "Command-Handler"
    } else {
        $category = "CRUD"
        $wave = "Wave-1"
        $strategy = "Dapper-Query"
    }

    # Schema overrides based on the migration strategy
    if ($schema -eq "bi") {
        $category = "CRUD"
        $wave = "Wave-1"
        $strategy = "Dapper-Query"
    }

    $results += [PSCustomObject]@{
        Schema = $schema
        Procedure = $name
        FullName = $fullName
        Category = $category
        Wave = $wave
        Strategy = $strategy
        HasWriteOps = ($writes -gt 0)
        HasTransaction = $hasTran
        HasCursor = $hasCursor
        HasDynamicSql = $hasDynamicSql
        HasCrypto = $hasCrypto
    }
}

$csvPath = Join-Path $OutDir "full-db-sp-classification.csv"
$mdPath = Join-Path $OutDir "full-db-sp-classification.md"
$schemaSummaryPath = Join-Path $OutDir "full-db-schema-wave-summary.csv"

$results | Sort-Object Schema, Procedure | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

$byCategory = $results | Group-Object Category | Sort-Object Name
$byWave = $results | Group-Object Wave | Sort-Object Name
$bySchema = $results | Group-Object Schema | Sort-Object Name

$schemaWaveRows = @()
foreach ($g in $bySchema) {
    $items = $g.Group
    $schemaWaveRows += [PSCustomObject]@{
        Schema = $g.Name
        Total = $items.Count
        Wave1 = @($items | Where-Object Wave -eq "Wave-1").Count
        Wave2 = @($items | Where-Object Wave -eq "Wave-2").Count
        Wave3 = @($items | Where-Object Wave -eq "Wave-3").Count
        Wave4 = @($items | Where-Object Wave -eq "Wave-4").Count
    }
}
$schemaWaveRows | Export-Csv -Path $schemaSummaryPath -NoTypeInformation -Encoding UTF8

$topCritical = $results |
    Where-Object { $_.Wave -eq "Wave-4" } |
    Sort-Object Schema, Procedure |
    Select-Object -First 40

$topWave1 = $results |
    Where-Object { $_.Wave -eq "Wave-1" } |
    Sort-Object Schema, Procedure |
    Select-Object -First 40

$nl = [Environment]::NewLine
$md = "# Full DB SP Classification (C# Migration)`n`n"
$md += "- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$md += "- Source: $SchemaFile`n"
$md += "- Total procedures: $($results.Count)`n`n"

$md += "## Category Summary`n`n"
$md += "| Category | Count |`n|---|---:|`n"
foreach ($c in $byCategory) {
    $md += "| $($c.Name) | $($c.Count) |`n"
}

$md += "`n## Wave Summary`n`n"
$md += "| Wave | Count | Strategy |`n|---|---:|---|`n"
foreach ($w in $byWave) {
    $strategy = switch ($w.Name) {
        "Wave-1" { "Dapper queries (read-first)" }
        "Wave-2" { "Simple commands/handlers" }
        "Wave-3" { "Domain service extraction" }
        "Wave-4" { "Critical transactional/crypto" }
        default { "TBD" }
    }
    $md += "| $($w.Name) | $($w.Count) | $strategy |`n"
}

$md += "`n## Schema x Wave`n`n"
$md += "| Schema | Total | Wave-1 | Wave-2 | Wave-3 | Wave-4 |`n|---|---:|---:|---:|---:|---:|`n"
foreach ($s in ($schemaWaveRows | Sort-Object Total -Descending)) {
    $md += "| $($s.Schema) | $($s.Total) | $($s.Wave1) | $($s.Wave2) | $($s.Wave3) | $($s.Wave4) |`n"
}

$md += "`n## First 40 Wave-1 Candidates`n`n"
$md += "| FullName | Strategy |`n|---|---|`n"
foreach ($p in $topWave1) {
    $md += "| $($p.FullName) | $($p.Strategy) |`n"
}

$md += "`n## First 40 Wave-4 Critical Candidates`n`n"
$md += "| FullName | Tx | Cursor | DynamicSQL | Crypto |`n|---|---|---|---|---|`n"
foreach ($p in $topCritical) {
    $md += "| $($p.FullName) | $($p.HasTransaction) | $($p.HasCursor) | $($p.HasDynamicSql) | $($p.HasCrypto) |`n"
}

$md += "`n## Outputs`n`n"
$md += "- $csvPath`n"
$md += "- $schemaSummaryPath`n"
$md += "- $mdPath`n"

Set-Content -Path $mdPath -Value $md -Encoding UTF8

Write-Host "Classification completed"
Write-Host "Total SPs: $($results.Count)"
Write-Host "CSV: $csvPath"
Write-Host "Schema summary: $schemaSummaryPath"
Write-Host "MD: $mdPath"

