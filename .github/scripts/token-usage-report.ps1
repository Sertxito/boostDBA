param(
    [string]$TranscriptPath,
    [string]$SessionId,
    [string]$WorkspaceStorageRoot = (Join-Path $env:APPDATA 'Code\User\workspaceStorage'),
    [string]$JsonPath,
    [switch]$IncludeDebugLogs,
    [switch]$AppendHistory,
    [switch]$ShowWeeklySummary,
    [switch]$AppendDailyAggregate,
    [string]$DailyAggregateCsvPath,
    [switch]$AppendDailyAggregateMarkdown,
    [string]$DailyAggregateMdPath,
    [switch]$DailyCloseMode,
    [string]$DailyCloseTime = '23:55',
    [string]$ModelName = 'gpt-5.3-codex',
    [double]$InputCostPer1M = 0,
    [double]$OutputCostPer1M = 0,
    [ValidateSet('estimated_total_tokens_max','estimated_total_tokens_min','estimated_visible_tokens')]
    [string]$CostBasis = 'estimated_total_tokens_max'
)

$ErrorActionPreference = 'Stop'

function Resolve-TranscriptPath {
    param(
        [string]$ExplicitPath,
        [string]$Session,
        [string]$Root
    )

    if ($ExplicitPath) {
        if (-not (Test-Path $ExplicitPath)) {
            throw "Transcript no encontrado: $ExplicitPath"
        }
        return (Resolve-Path $ExplicitPath).Path
    }

    if (-not (Test-Path $Root)) {
        throw "Workspace storage no encontrado: $Root"
    }

    if ($Session) {
        $candidate = Get-ChildItem -Path $Root -Recurse -File -Filter "$Session.jsonl" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match 'GitHub\.copilot-chat\\transcripts' } |
            Select-Object -First 1
        if (-not $candidate) {
            throw "No se encontró transcript para SessionId=$Session"
        }
        return $candidate.FullName
    }

    $latest = Get-ChildItem -Path $Root -Recurse -File -Filter '*.jsonl' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match 'GitHub\.copilot-chat\\transcripts' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $latest) {
        throw "No se encontraron transcripts en $Root"
    }

    return $latest.FullName
}

function Get-PhaseFromText {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return 'Other' }

    $t = $Text.ToLowerInvariant()

    if ($t -match 'pandoc|export-report|docx|word|mermaid|mmdc|render|filter|chromium') { return 'ExportWord' }
    if ($t -match 'informe|document|resumen|cuantific|roadmap|ejecutivo|techlead|dba|reporte') { return 'Documentation' }
    if ($t -match 'read_file|grep_search|file_search|semantic_search|analizar|schema|dependenc|diagnos|review|auditoria') { return 'Analysis' }

    return 'Other'
}

function Add-ExactUsageFromLine {
    param(
        [string]$Line,
        [hashtable]$Usage
    )

    if ($Line -match '"prompt_tokens"\s*:\s*(\d+)') { $Usage.prompt += [int]$matches[1]; $Usage.found = $true }
    if ($Line -match '"completion_tokens"\s*:\s*(\d+)') { $Usage.completion += [int]$matches[1]; $Usage.found = $true }
    if ($Line -match '"input_tokens"\s*:\s*(\d+)') { $Usage.input += [int]$matches[1]; $Usage.found = $true }
    if ($Line -match '"output_tokens"\s*:\s*(\d+)') { $Usage.output += [int]$matches[1]; $Usage.found = $true }
}

function Get-SessionIdFromTranscriptPath {
    param([string]$Path)
    $m = [regex]::Match($Path, 'transcripts\\([^\\]+)\.jsonl$')
    if ($m.Success) { return $m.Groups[1].Value }
    return ''
}

function Get-EstimatedCost {
    param(
        [double]$InputTokens,
        [double]$OutputTokens,
        [double]$InputRatePer1M,
        [double]$OutputRatePer1M
    )

    if (($InputRatePer1M -le 0) -and ($OutputRatePer1M -le 0)) {
        return [PSCustomObject]@{ input_cost = 0.0; output_cost = 0.0; total_cost = 0.0; has_rates = $false }
    }

    $inCost = ($InputTokens / 1000000.0) * $InputRatePer1M
    $outCost = ($OutputTokens / 1000000.0) * $OutputRatePer1M
    return [PSCustomObject]@{
        input_cost = [math]::Round($inCost, 6)
        output_cost = [math]::Round($outCost, 6)
        total_cost = [math]::Round($inCost + $outCost, 6)
        has_rates = $true
    }
}

function Convert-ToDoubleSafe {
    param([object]$Value)

    if ($null -eq $Value) { return 0.0 }
    $s = [string]$Value
    if ([string]::IsNullOrWhiteSpace($s)) { return 0.0 }

    $styles = [System.Globalization.NumberStyles]::Float
    $invariant = [System.Globalization.CultureInfo]::InvariantCulture
    $current = [System.Globalization.CultureInfo]::CurrentCulture

    $d = 0.0
    if ([double]::TryParse($s, $styles, $invariant, [ref]$d)) { return $d }
    if ([double]::TryParse($s, $styles, $current, [ref]$d)) { return $d }

    # fallback: swap separators
    $s2 = $s -replace '\.', ','
    if ([double]::TryParse($s2, $styles, $current, [ref]$d)) { return $d }

    return 0.0
}

function Get-DailyAggregateRow {
    param(
        [string]$HistoryPath,
        [string]$DateKey
    )

    if (-not (Test-Path $HistoryPath)) {
        return $null
    }

    $rows = @(Get-Content $HistoryPath -Encoding UTF8 | Where-Object { $_ -match '\{' } | ForEach-Object {
        try { $_ | ConvertFrom-Json } catch { $null }
    } | Where-Object { $null -ne $_ })
    if ($rows.Count -eq 0) {
        return $null
    }

    $dayRows = @($rows | Where-Object {
        $_.timestamp -and ((Get-Date $_.timestamp).ToString('yyyy-MM-dd') -eq $DateKey)
    })

    if ($dayRows.Count -eq 0) {
        return $null
    }

    $sumVisible = ($dayRows | Measure-Object -Property estimated_visible_tokens -Sum).Sum
    $sumMin = ($dayRows | Measure-Object -Property estimated_total_tokens_min -Sum).Sum
    $sumMax = ($dayRows | Measure-Object -Property estimated_total_tokens_max -Sum).Sum
    $sumCost = 0.0
    foreach ($r in $dayRows) {
        $sumCost += Convert-ToDoubleSafe -Value $r.cost_total
    }

    $dailyRow = [PSCustomObject]@{
        date = $DateKey
        generated_at = (Get-Date).ToString('s')
        runs = $dayRows.Count
        total_visible_tokens = [math]::Round($sumVisible, 0)
        total_tokens_min = [math]::Round($sumMin, 0)
        total_tokens_max = [math]::Round($sumMax, 0)
        total_estimated_cost = [math]::Round($sumCost, 6)
    }

    return $dailyRow
}

function Write-DailyAggregateRow {
    param(
        [string]$DailyPath,
        [pscustomobject]$DailyRow
    )

    if ($null -eq $DailyRow) {
        return $null
    }

    $dir = Split-Path -Parent $DailyPath
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    if (Test-Path $DailyPath) {
        $dailyRow | Export-Csv -Path $DailyPath -NoTypeInformation -Append -Encoding UTF8
    } else {
        $DailyRow | Export-Csv -Path $DailyPath -NoTypeInformation -Encoding UTF8
    }

    return $DailyRow
}

function Write-DailyAggregateMarkdownRow {
    param(
        [string]$MarkdownPath,
        [pscustomobject]$DailyRow
    )

    if ($null -eq $DailyRow) {
        return
    }

    $dir = Split-Path -Parent $MarkdownPath
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }

    if (-not (Test-Path $MarkdownPath)) {
        @(
            '# Token Usage Daily Aggregate'
            ''
            '| Date | Generated At | Runs | Total Visible Tokens | Total Tokens Min | Total Tokens Max | Total Estimated Cost |'
            '|---|---|---:|---:|---:|---:|---:|'
        ) | Out-File -FilePath $MarkdownPath -Encoding UTF8
    }

    $line = "| $($DailyRow.date) | $($DailyRow.generated_at) | $($DailyRow.runs) | $($DailyRow.total_visible_tokens) | $($DailyRow.total_tokens_min) | $($DailyRow.total_tokens_max) | $($DailyRow.total_estimated_cost) |"
    Add-Content -Path $MarkdownPath -Value $line
}

function Test-IsAfterDailyCutoff {
    param([string]$Cutoff)

    $ts = [TimeSpan]::Zero
    if (-not [TimeSpan]::TryParse($Cutoff, [ref]$ts)) {
        throw "Formato DailyCloseTime invalido: $Cutoff (usa HH:mm, por ejemplo 23:55)"
    }

    return ((Get-Date).TimeOfDay -ge $ts)
}

function Test-DailyCsvHasDate {
    param(
        [string]$Path,
        [string]$DateKey
    )

    if (-not (Test-Path $Path)) { return $false }
    $rows = @(Import-Csv -Path $Path)
    if ($rows.Count -eq 0) { return $false }
    return ($rows | Where-Object { $_.date -eq $DateKey } | Select-Object -First 1) -ne $null
}

function Test-DailyMarkdownHasDate {
    param(
        [string]$Path,
        [string]$DateKey
    )

    if (-not (Test-Path $Path)) { return $false }
    $escapedDate = [regex]::Escape($DateKey)
    return (Select-String -Path $Path -Pattern ("^\|\s*" + $escapedDate + "\s*\|") -Quiet)
}

$TranscriptPath = Resolve-TranscriptPath -ExplicitPath $TranscriptPath -Session $SessionId -Root $WorkspaceStorageRoot

$totals = [ordered]@{ Analysis = 0; Documentation = 0; ExportWord = 0; Other = 0 }
$typeTotals = [ordered]@{ User = 0; Assistant = 0; Tool = 0 }
$usage = @{ prompt = 0; completion = 0; input = 0; output = 0; found = $false }

$lineCount = 0
$byteCount = 0

Get-Content -Path $TranscriptPath | ForEach-Object {
    $line = $_
    if ([string]::IsNullOrWhiteSpace($line)) { return }

    $lineCount++
    $lineBytes = [Text.Encoding]::UTF8.GetByteCount($line)
    $byteCount += $lineBytes
    $estimatedTokens = [math]::Ceiling($lineBytes / 4.0)

    Add-ExactUsageFromLine -Line $line -Usage $usage

    $obj = $null
    try {
        $obj = $line | ConvertFrom-Json -ErrorAction Stop
    } catch {
        $totals['Other'] += $estimatedTokens
        return
    }

    $phase = 'Other'
    switch -Regex ($obj.type) {
        '^user\.message$' {
            $typeTotals['User'] += $estimatedTokens
            $phase = Get-PhaseFromText -Text ([string]$obj.data.content)
        }
        '^assistant\.message$' {
            $typeTotals['Assistant'] += $estimatedTokens
            $txt = [string]$obj.data.content
            if ($obj.data.toolRequests) {
                $txt += ' ' + (($obj.data.toolRequests | ForEach-Object { $_.name + ' ' + $_.arguments }) -join ' ')
            }
            $phase = Get-PhaseFromText -Text $txt
        }
        '^tool\.execution_start$' {
            $typeTotals['Tool'] += $estimatedTokens
            $toolName = [string]$obj.data.toolName
            $argsJson = ''
            try { $argsJson = ($obj.data.arguments | ConvertTo-Json -Compress -Depth 8) } catch {}
            $phase = Get-PhaseFromText -Text ($toolName + ' ' + $argsJson)
        }
        '^tool\.execution_complete$' {
            $typeTotals['Tool'] += $estimatedTokens
            $phase = 'Other'
        }
        default {
            $phase = 'Other'
        }
    }

    $totals[$phase] += $estimatedTokens
}

if ($IncludeDebugLogs) {
    $sessionMatch = [regex]::Match($TranscriptPath, 'transcripts\\([^\\]+)\.jsonl$')
    if ($sessionMatch.Success) {
        $sid = $sessionMatch.Groups[1].Value
        $debugFiles = Get-ChildItem -Path $WorkspaceStorageRoot -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -match "GitHub\.copilot-chat\\debug-logs\\$([regex]::Escape($sid))" -and
                $_.Extension -in '.json', '.jsonl', '.log', '.txt'
            }

        foreach ($f in $debugFiles) {
            Get-Content -Path $f.FullName -ErrorAction SilentlyContinue | ForEach-Object {
                Add-ExactUsageFromLine -Line $_ -Usage $usage
            }
        }
    }
}

$estimatedTotal = ($totals.Values | Measure-Object -Sum).Sum
$estimatedWithOverheadMin = [math]::Round($estimatedTotal * 1.15)
$estimatedWithOverheadMax = [math]::Round($estimatedTotal * 1.35)
$resolvedSessionId = if ($SessionId) { $SessionId } else { Get-SessionIdFromTranscriptPath -Path $TranscriptPath }
$runTimestamp = (Get-Date).ToString('s')

# Si no hay tokens exactos en logs, aproximamos I/O para coste usando basis seleccionado.
$basisTokens = switch ($CostBasis) {
    'estimated_total_tokens_min' { $estimatedWithOverheadMin }
    'estimated_visible_tokens' { $estimatedTotal }
    default { $estimatedWithOverheadMax }
}

$inputForCost = if ($usage.found -and ($usage.input -gt 0 -or $usage.prompt -gt 0)) {
    if ($usage.input -gt 0) { $usage.input } else { $usage.prompt }
} else {
    [math]::Round($basisTokens * 0.85)
}

$outputForCost = if ($usage.found -and ($usage.output -gt 0 -or $usage.completion -gt 0)) {
    if ($usage.output -gt 0) { $usage.output } else { $usage.completion }
} else {
    [math]::Round($basisTokens * 0.15)
}

$cost = Get-EstimatedCost -InputTokens $inputForCost -OutputTokens $outputForCost -InputRatePer1M $InputCostPer1M -OutputRatePer1M $OutputCostPer1M

$result = [PSCustomObject]@{
    timestamp = $runTimestamp
    session_id = $resolvedSessionId
    model_name = $ModelName
    transcript_path = $TranscriptPath
    lines = $lineCount
    bytes = $byteCount
    estimated_visible_tokens = $estimatedTotal
    estimated_total_tokens_min = $estimatedWithOverheadMin
    estimated_total_tokens_max = $estimatedWithOverheadMax
    phase_analysis = $totals.Analysis
    phase_documentation = $totals.Documentation
    phase_exportword = $totals.ExportWord
    phase_other = $totals.Other
    source_user = $typeTotals.User
    source_assistant = $typeTotals.Assistant
    source_tool = $typeTotals.Tool
    exact_prompt_tokens = $usage.prompt
    exact_completion_tokens = $usage.completion
    exact_input_tokens = $usage.input
    exact_output_tokens = $usage.output
    exact_found = $usage.found
    cost_basis = $CostBasis
    cost_input_tokens = $inputForCost
    cost_output_tokens = $outputForCost
    cost_input_per_1m = $InputCostPer1M
    cost_output_per_1m = $OutputCostPer1M
    cost_input = $cost.input_cost
    cost_output = $cost.output_cost
    cost_total = $cost.total_cost
}

Write-Output "Transcript: $($result.transcript_path)"
Write-Output "Lines: $($result.lines)"
Write-Output "Bytes: $($result.bytes)"
Write-Output ""
Write-Output "Estimated tokens (visible payload): $($result.estimated_visible_tokens)"
Write-Output "Estimated tokens (with protocol/context overhead): $($result.estimated_total_tokens_min) - $($result.estimated_total_tokens_max)"
Write-Output ""
Write-Output "Breakdown by phase (estimated):"
Write-Output "- Analysis: $($result.phase_analysis)"
Write-Output "- Documentation: $($result.phase_documentation)"
Write-Output "- ExportWord: $($result.phase_exportword)"
Write-Output "- Other: $($result.phase_other)"
Write-Output ""
Write-Output "Breakdown by message source (estimated):"
Write-Output "- User: $($result.source_user)"
Write-Output "- Assistant: $($result.source_assistant)"
Write-Output "- Tool: $($result.source_tool)"
Write-Output ""

if ($result.exact_found) {
    Write-Output "Exact token counters found in logs:"
    Write-Output "- prompt_tokens: $($result.exact_prompt_tokens)"
    Write-Output "- completion_tokens: $($result.exact_completion_tokens)"
    Write-Output "- input_tokens: $($result.exact_input_tokens)"
    Write-Output "- output_tokens: $($result.exact_output_tokens)"
} else {
    Write-Output "Exact per-request token counters were not found in transcript/debug log format."
}

if ($cost.has_rates) {
    Write-Output ""
    Write-Output "Estimated cost ($ModelName, basis=$CostBasis):"
    Write-Output "- Input tokens for cost: $inputForCost"
    Write-Output "- Output tokens for cost: $outputForCost"
    Write-Output "- Input cost: $($result.cost_input)"
    Write-Output "- Output cost: $($result.cost_output)"
    Write-Output "- Total cost: $($result.cost_total)"
}

if ($JsonPath) {
    $dir = Split-Path -Parent $JsonPath
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
    $jsonLine = $result | ConvertTo-Json -Compress -Depth 5
    Add-Content -Path $JsonPath -Value $jsonLine -Encoding UTF8
    Write-Output ""
    Write-Output "Log JSON: $JsonPath"

    if ($AppendDailyAggregate) {
        $dailyPathResolved = if ($DailyAggregateCsvPath) { $DailyAggregateCsvPath } else { '.github/reports/token-usage-daily-aggregate.csv' }
        $todayKey = (Get-Date).ToString('yyyy-MM-dd')
        $canWriteDaily = $true

        if ($DailyCloseMode -and (-not (Test-IsAfterDailyCutoff -Cutoff $DailyCloseTime))) {
            $canWriteDaily = $false
            Write-Output ""
            Write-Output "Daily close mode: aun no se alcanza la hora de cierre ($DailyCloseTime)."
        }

        if ($canWriteDaily -and $DailyCloseMode -and (Test-DailyCsvHasDate -Path $dailyPathResolved -DateKey $todayKey)) {
            $canWriteDaily = $false
            Write-Output ""
            Write-Output "Daily close mode: ya existe fila para $todayKey en $dailyPathResolved."
        }

        $daily = $null
        if ($canWriteDaily) {
            $daily = Get-DailyAggregateRow -HistoryPath $JsonPath -DateKey $todayKey
            $daily = Write-DailyAggregateRow -DailyPath $dailyPathResolved -DailyRow $daily
        }

        if ($null -ne $daily) {
            Write-Output ""
            Write-Output "Daily aggregate appended: $dailyPathResolved"
            Write-Output "- Date: $($daily.date)"
            Write-Output "- Runs today: $($daily.runs)"
            Write-Output "- Total visible tokens today: $($daily.total_visible_tokens)"
            Write-Output "- Total estimated cost today: $($daily.total_estimated_cost)"
        }
    }

    if ($AppendDailyAggregateMarkdown) {
        $todayKey = (Get-Date).ToString('yyyy-MM-dd')
        $dailyMdPathResolved = if ($DailyAggregateMdPath) { $DailyAggregateMdPath } else { '.github/reports/token-usage-daily-aggregate.md' }

        $canWriteMdDaily = $true
        if ($DailyCloseMode -and (-not (Test-IsAfterDailyCutoff -Cutoff $DailyCloseTime))) {
            $canWriteMdDaily = $false
            Write-Output ""
            Write-Output "Daily close mode (md): aun no se alcanza la hora de cierre ($DailyCloseTime)."
        }

        if ($canWriteMdDaily -and $DailyCloseMode -and (Test-DailyMarkdownHasDate -Path $dailyMdPathResolved -DateKey $todayKey)) {
            $canWriteMdDaily = $false
            Write-Output ""
            Write-Output "Daily close mode (md): ya existe fila para $todayKey en $dailyMdPathResolved."
        }

        $dailyForMd = $null
        if ($canWriteMdDaily) {
            $dailyForMd = Get-DailyAggregateRow -HistoryPath $JsonPath -DateKey $todayKey
        }

        if ($null -ne $dailyForMd) {
            Write-DailyAggregateMarkdownRow -MarkdownPath $dailyMdPathResolved -DailyRow $dailyForMd
            Write-Output ""
            Write-Output "Daily aggregate markdown appended: $dailyMdPathResolved"
            Write-Output "- Date: $($dailyForMd.date)"
            Write-Output "- Runs today: $($dailyForMd.runs)"
            Write-Output "- Total visible tokens today: $($dailyForMd.total_visible_tokens)"
            Write-Output "- Total estimated cost today: $($dailyForMd.total_estimated_cost)"
        }
    }

    if ($ShowWeeklySummary -and (Test-Path $JsonPath)) {
        $rows = @(Get-Content $JsonPath -Encoding UTF8 | Where-Object { $_ -match '\{' } | ForEach-Object {
            try { $_ | ConvertFrom-Json } catch { $null }
        } | Where-Object { $null -ne $_ })
        if ($rows.Count -gt 0) {
            $last7 = @($rows | Where-Object {
                $_.timestamp -and ((Get-Date $_.timestamp) -ge (Get-Date).AddDays(-7))
            })

            if ($last7.Count -gt 0) {
                $sumVisible = ($last7 | Measure-Object -Property estimated_visible_tokens -Sum).Sum
                $sumMax = ($last7 | Measure-Object -Property estimated_total_tokens_max -Sum).Sum
                $sumCost = 0.0
                foreach ($r in $last7) {
                    $sumCost += Convert-ToDoubleSafe -Value $r.cost_total
                }

                Write-Output ""
                Write-Output "Weekly summary (last 7 days):"
                Write-Output "- Runs: $($last7.Count)"
                Write-Output "- Visible tokens: $([math]::Round($sumVisible,0))"
                Write-Output "- Estimated total tokens (max): $([math]::Round($sumMax,0))"
                Write-Output "- Total estimated cost: $([math]::Round($sumCost,6))"
            }
        }
    }
}
