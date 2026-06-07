---
description: "Sincronización automática de tabla de tokens en cada commit"
---

# Token Usage Sync

## ✅ Status: COMPLETADO

## Cómo Funciona (Simple)

```
Copilot + skill token-usage-observability
  ↓
Lee transcripts desde AppData
  ↓
Actualiza token-usage-daily-aggregate.md DIRECTAMENTE
  ↓
git commit
  ↓
Pre-commit hook ejecuta la skill (asegura que MD esté fresco)
  ↓
MD se commitea ✅
```

## Archivos Trackeados

| Archivo | Propósito |
|---------|----------|
| `token-usage-daily-aggregate.md` | ✅ Tabla con totales diarios, SE COMMITEA |

**Eso es todo. Nada de CSV temporal, solo el MD.**

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
