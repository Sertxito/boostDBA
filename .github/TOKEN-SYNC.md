---
description: "Sincronización automática de tabla de tokens en cada commit"
---

# Token Usage Sync

## ✅ Status: COMPLETADO

## Cómo Funciona

Cada conversación con un agente (este modo, el Orquestador DBA, etc.) genera un transcript `.jsonl` que Copilot guarda automáticamente en:
```
%APPDATA%\Code\User\workspaceStorage\<hash>\GitHub.copilot-chat\transcripts\<session-id>.jsonl
```

El script lee ese fichero, estima tokens por bytes de contenido y clasifica cada mensaje por fase:
- **Analysis** → uso de herramientas (`read_file`, `grep_search`, `schema`...)
- **Documentation** → generación de informes, resúmenes, roadmaps...
- **ExportWord** → conversiones con pandoc, mermaid, docx...
- **Other** → el resto

```
Conversación en curso → transcript .jsonl en AppData (automático)
  ↓
token-usage-report.ps1 lee el transcript
  ↓
Estima tokens (bytes/4) y clasifica por fase
  ↓
Escribe entrada en token-usage-history.json (log local)
  ↓
Añade fila en token-usage-daily-aggregate.md
  ↓
git commit → hook repite el proceso para que el MD esté fresco
  ↓
MD se commitea ✅
```

## Archivos Trackeados

| Archivo | Propósito |
|---------|----------|
| `token-usage-daily-aggregate.md` | ✅ Tabla con totales diarios + acumulado de sesión (tokens/coste), SE COMMITEA |
| `token-usage-history.json` | Log local gitignored, no va a git |

---

## Pre-Commit Hook (LOCAL - ACTIVO ✅)

**Ya instalado. Funciona automáticamente.**

Cada `git commit`:
1. Hook ejecuta automáticamente
2. Ejecuta la skill para asegurar que el MD está al día
3. Agrega MD al staging automáticamente
4. Commit se envía con MD sincronizado

---

## Manual desde Terminal

```powershell
.\.github\scripts\token-daily-close.ps1
```

Los datos de tokens se guardan en:
- `.github/reports/token-usage-history.json` (log local, gitignored)
- `.github/reports/token-usage-daily-aggregate.md` (tabla visible, versionada, con coste y acumulado de sesión)

---

## Para El Equipo

**Solo saben:**
> "Cada commit actualiza la tabla de tokens automáticamente. Solo commitea normalmente."

---

## Archivos del Sistema

- `.git/hooks/pre-commit` - Hook bash (✅ INSTALADO)
- `.github/scripts/token-usage-report.ps1` - Skill principal
- `.github/scripts/token-daily-close.ps1` - Wrapper manual
- `.github/skills/token-usage-observability/SKILL.md` - Skill documentation

---

**TL;DR:** Hook ejecuta skill antes de cada commit → MD se actualiza → se commitea. Limpio y simple.
