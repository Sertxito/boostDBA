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
- ✅ No existe flujo intermedio tabular para tokens
- ✅ Existe JSON local + MD versionado
- ✅ El MD se commitea
- ✅ El hook asegura que esté fresco antes de cada commit

## Setup Inicial (Solo Primera Vez)
```powershell
# Instalar pre-commit hook (se ejecutará automáticamente antes de cada commit)
.\.github\scripts\setup-token-hook.ps1
```

Después de esto: **Cada commit actualizará el MD automáticamente**

## Uso rapido
```powershell
# 1) Ultima sesion encontrada automaticamente
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1

# 2) Sesion concreta
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 -SessionId "<id>"

# 3) Transcript explicito
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 -TranscriptPath "C:\...\transcripts\<id>.jsonl"

# 4) Con log JSON + resumen semanal
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-JsonPath ".github/reports/token-usage-history.json" `
	-AppendHistory `
	-ShowWeeklySummary

# 5) Con estimacion de coste
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-JsonPath ".github/reports/token-usage-history.json" `
	-AppendHistory `
	-ModelName "gpt-5.3-codex" `
	-InputCostPer1M 5.00 `
	-OutputCostPer1M 15.00 `
	-CostBasis estimated_total_tokens_max

# 6) Acumulado diario en tabla Markdown
powershell -ExecutionPolicy Bypass -File .github/scripts/token-usage-report.ps1 `
	-IncludeDebugLogs `
	-JsonPath ".github/reports/token-usage-history.json" `
	-AppendHistory `
	-AppendDailyAggregateMarkdown `
	-DailyAggregateMdPath ".github/reports/token-usage-daily-aggregate.md"

# 7) Flujo simple para equipo (un solo comando)
powershell -ExecutionPolicy Bypass -File .github/scripts/token-daily-close.ps1

# 8) Con modelo y costes custom
powershell -ExecutionPolicy Bypass -File .github/scripts/token-daily-close.ps1 `
	-ModelName "gpt-5.3-codex" `
	-InputCostPer1M 5 `
	-OutputCostPer1M 15
```

## Salida esperada
- Estimacion visible de tokens
- Estimacion con overhead de protocolo/contexto
- Desglose por fase
- Desglose por origen (User/Assistant/Tool)
- Contadores exactos si los logs los exponen
- Log JSON local (append, gitignored)
- Resumen semanal (runs/tokens/coste)
- Estimacion de coste configurable por modelo
- Acumulado diario append-only (una nueva fila por ejecucion con el total del dia)
- Acumulado diario en Markdown (tabla append-only)
- Wrapper de cierre diario para uso simple dentro de Boost (un solo comando)

## Notas
- Si no hay contadores exactos en logs, el resultado es estimado (trazable por bytes).
- El script evita fallar si faltan logs exactos: siempre devuelve reporte.
- Para coste, si no hay input/output exactos en logs, usa una aproximacion 85/15 sobre `CostBasis`.
