---
name: 'Onboarding Seguro y Fuente de Verdad'
description: 'Skill para arrancar un proyecto de BBDD desde cero con seguridad-first y fuente de verdad local'
---

# Onboarding Seguro y Fuente de Verdad

## Proposito
Preparar una sesion DBA completa sin exponer negocio, creando una fuente de verdad local reutilizable para no depender de conexiones continuas a la base de datos origen.

## Entradas
- Nombre del proyecto DBA
- Uno de estos origenes:
  - Connection string (solo para descubrimiento inicial)
  - Carpeta con esquemas/scripts SQL
  - Proyecto de base de datos (dacpac/sqlproj/scripts)

## Salidas
- Estructura local en `dba_<Proyecto>/` fuera del repo producto
- Manifest de fuente de verdad
- Perfil de conexion redacted
- Reporte preflight PASS/FAIL

## Flujo
1. Ejecutar wizard de arranque:
```powershell
pwsh -File .\scripts\run-dba360-wizard.ps1 -ProjectName "MiProyecto" -SchemaPath "C:\schemas"
```

2. Si necesitas conexión inicial:
```powershell
pwsh -File .\scripts\run-dba360-wizard.ps1 -ProjectName "MiProyecto" -ConnectionString "Server=...;Database=...;User Id=...;Password=...;"
```

3. Revisar el manifest generado:
- `../dba_<Proyecto>/fuente-de-verdad/manifest.json`

4. Si Preflight = FAIL, sanear antes de continuar.

La salida se crea como carpeta hermana del producto, por ejemplo `../dba_MiProyecto/`.

## Reglas
- Nunca persistir secretos en texto claro dentro del repo.
- La conexión se usa para bootstrap, no como dependencia permanente.
- Trabajar contra la carpeta `dba_<Proyecto>/` siempre que sea posible.
