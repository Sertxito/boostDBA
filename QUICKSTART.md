---
name: 'Guía de Inicio Rápido'
---

# Inicio Rápido

La documentación principal está centralizada en [README.md](README.md).

Usa este flujo:

1. Ejecuta el wizard de arranque:

```powershell
pwsh -File .\scripts\run-dba360-wizard.ps1 -ProjectName "MiProyecto" -SchemaPath "C:\schemas"
```

2. Lanza el orquestador DBA 360 sobre `dba_MiProyecto/` (carpeta creada por el wizard fuera del repo).

3. Trabaja con plantillas de informe en [templates/reports](templates/reports).
