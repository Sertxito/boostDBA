---
name: 'Token Usage Observability'
description: 'Trazar transcripts y debug logs de Copilot Chat para estimar/capturar consumo de tokens y desglosarlo por fase'
---

# Token Usage Observability

## Proposito
Reutilizar siempre el mismo flujo para medir gasto de tokens por sesion y por fase:
- Analysis
- Documentation
- ExportWord
- Other

Tambien intenta extraer contadores exactos (`prompt_tokens`, `completion_tokens`, `input_tokens`, `output_tokens`) desde transcript/debug logs cuando existan.

## Scripts asociados
- `.github/scripts/token-usage-report.ps1` - Motor principal: lee transcripts, actualiza MD
- `.github/scripts/token-daily-close.ps1` - Wrapper simplificado para cierre diario
- `.github/scripts/pre-commit-token-sync.ps1` - (Deprecated - no se usa)
- `.git/hooks/pre-commit` - Hook que ejecuta la skill antes de cada commit

## Arquitectura: Qué Existe y Qué Se Commitea

```
AppData/transcripts (local, no tracked)
  ↓
skill lee 
  ↓
Actualiza token-usage-daily-aggregate.md DIRECTAMENTE
  ↓
git commit
  ↓
pre-commit hook ejecuta la skill
  ↓
MD se commitea ✅
```

**Lo importante:**
- ❌ NO hay CSV temporal
- ✅ Solo existe el MD
- ✅ El MD se commitea
- ✅ El hook asegura que esté fresco antes de cada commit

## Setup Inicial (Solo Primera Vez)
```powershell
# Instalar pre-commit hook (se ejecutará automáticamente antes de cada commit)
.\.github\scripts\setup-token-hook.ps1
```

Después de esto: **Cada commit que toque token-usage-history.csv actualizará el MD automáticamente**

## Uso rapido
```powershell
# 1) Ultima sesion encontrada automaticamente
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1

# 2) Sesion concreta
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 -SessionId "5d329c67-4503-4c77-a945-504b43c5720b"

# 3) Transcript explicito
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 -TranscriptPath "C:\...\transcripts\<id>.jsonl"

# 4) Incluir debug logs + export CSV
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 -SessionId "<id>" -IncludeDebugLogs -CsvPath ".github/reports/token-usage.csv"

# 5) Historico (append) + resumen semanal
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-CsvPath ".github/reports/token-usage-history.csv" `
	-AppendHistory `
	-ShowWeeklySummary

# 6) Estimacion de coste por modelo (si defines tarifas por 1M tokens)
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-CsvPath ".github/reports/token-usage-history.csv" `
	-AppendHistory `
	-ModelName "gpt-5.3-codex" `
	-InputCostPer1M 5.00 `
	-OutputCostPer1M 15.00 `
	-CostBasis estimated_total_tokens_max

# 7) Acumulado diario append-only (fecha + uso total del dia)
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-CsvPath ".github/reports/token-usage-history.csv" `
	-AppendHistory `
	-AppendDailyAggregate `
	-DailyAggregateCsvPath ".github/reports/token-usage-daily-aggregate.csv"

# 8) Acumulado diario en tabla Markdown (mas legible para seguimiento)
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-CsvPath ".github/reports/token-usage-history.csv" `
	-AppendHistory `
	-AppendDailyAggregateMarkdown `
	-DailyAggregateMdPath ".github/reports/token-usage-daily-aggregate.md"

# 9) Cierre diario automatico: solo una fila final del dia (a partir de hora de corte)
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-CsvPath ".github/reports/token-usage-history.csv" `
	-AppendHistory `
	-AppendDailyAggregateMarkdown `
	-DailyAggregateMdPath ".github/reports/token-usage-daily-aggregate.md" `
	-DailyCloseMode `
	-DailyCloseTime "23:55"

# 10) Flujo simple para equipo (sin scheduler): comando unico de cierre
powershell -ExecutionPolicy Bypass -File .github/scripts/token-daily-close.ps1

# 11) Flujo simple con parametros opcionales
powershell -ExecutionPolicy Bypass -File .github/scripts/token-daily-close.ps1 `
	-ModelName "gpt-5.3-codex" `
	-InputCostPer1M 5 `
	-OutputCostPer1M 15 `
	-DailyCloseTime "23:55"
```

## Salida esperada
- Estimacion visible de tokens
- Estimacion con overhead de protocolo/contexto
- Desglose por fase
- Desglose por origen (User/Assistant/Tool)
- Contadores exactos si los logs los exponen
- CSV opcional
- Historico CSV (append)
- Resumen semanal (runs/tokens/coste)
- Estimacion de coste configurable por modelo
- Acumulado diario append-only (una nueva fila por ejecucion con el total del dia)
- Acumulado diario en Markdown (tabla append-only)
- Modo cierre diario: evita duplicados y guarda solo al llegar la hora de corte
- Wrapper de cierre diario para uso simple dentro de Boost (un solo comando)

## Notas
- Si no hay contadores exactos en logs, el resultado es estimado (trazable por bytes).
- El script evita fallar si faltan logs exactos: siempre devuelve reporte.
- Para coste, si no hay input/output exactos en logs, usa una aproximacion 85/15 sobre `CostBasis`.
