# Query Optimization Framework — OFERTA25

**Scope:** 6.554 SPs | SQL Server 2017 | .NET 8 Dapper/EF stack  
**Objetivo:** Reducir tiempo de respuesta y consumo de recursos sin cambios funcionales

---

## Flujo de 4 Scripts

```
01-capture-baseline.sql        → Extrae métricas actuales (CPU, reads, waits)
        ↓
02-index-recommendations.sql   → Genera DDL de índices faltantes, redundantes, fragmentados
        ↓  [Aplicas el cambio aquí: índice, rewrite SP, o hint QS]
03-golden-file-regression.ps1  → Captura antes y valida que el output no cambió
        ↓
04-staged-rollout.ps1          → Orquesta DEV → STAGING → PROD con confirmación manual
```

---

## Uso Rápido

### Optimizar un SP paso a paso

```powershell
cd c:\repo\BoostDBA

# 1. Captura golden file (resultado esperado) en PROD
.\.github\scripts\query-optimization\03-golden-file-regression.ps1 `
  -Mode capture `
  -SpName 'bi.AccionesFormativasPlanFormacion_S' `
  -ServerInstance 'prod-db'

# 2. Revisa recomendaciones de índices en SSMS
#    → Abre 02-index-recommendations.sql y ejecuta en OFERTA25

# 3. Aplica el cambio en DEV primero

# 4. Valida que el output no cambió
.\.github\scripts\query-optimization\03-golden-file-regression.ps1 `
  -Mode validate `
  -SpName 'bi.AccionesFormativasPlanFormacion_S' `
  -ServerInstance 'dev-db'

# 5. Rollout completo a PROD
.\.github\scripts\query-optimization\04-staged-rollout.ps1 `
  -SpName 'bi.AccionesFormativasPlanFormacion_S' `
  -Stage all `
  -ProdServer 'prod-db'
```

---

## Scripts en Detalle

### `01-capture-baseline.sql`
Ejecutar en SSMS contra OFERTA25. Captura:
- Top 30 SPs por CPU, Elapsed y Frecuencia
- Planes regresionados (Query Store)
- Wait stats (PAGEIO_LATCH, LCK_M, etc.)
- Spills a TEMPDB
- Key lookups costosos
- Estadísticas obsoletas (>7 días)

**Cuándo:** Antes de CUALQUIER cambio. Guarda el output como `baseline-YYYYMMDD.csv`

---

### `02-index-recommendations.sql`
Genera DDL listo para revisar y aplicar:
- **Missing indexes** ordenados por ImpactScore
- **FK sin índice** (principal causa de lock escalation)
- **Índices duplicados/redundantes** (candidatos a DROP)
- **Índices no usados** (overhead en escrituras)
- **Fragmentación** (REBUILD vs REORGANIZE)

**⚠️ Regla:** Nunca aplicar en bloque. Revisar uno a uno, aplicar con `ONLINE=ON`.

---

### `03-golden-file-regression.ps1`
Compara outputs funcionales de un SP:

| Mode | Acción |
|------|--------|
| `capture` | Ejecuta SP y guarda resultado en JSON (golden file) |
| `validate` | Ejecuta SP actual, compara vs golden. Exit 0=pass, 1=fail |
| `report` | Muestra info del golden file sin ejecutar |

**Salida golden:** `workspaces/OFERTA25/tests/golden/{sp_name}.golden.json`

Detecta:
- Schema changes (columnas añadidas/quitadas)
- Row count differences
- Value differences (con tolerancia numérica configurable)
- NULL vs no-NULL

---

### `04-staged-rollout.ps1`
Orquesta el despliegue seguro en 5 etapas:

| Stage | Acción | Entorno |
|-------|--------|---------|
| 0 | Captura baseline + métricas DMV | PROD |
| 1 | Regresión funcional | DEV |
| 2 | Regresión + rendimiento | STAGING |
| 3 | Deploy con confirmación manual (`CONFIRMO`) | PROD |
| 4 | Monitor 24h post-deploy (comparar vs baseline) | PROD |

**Rollback:** Si Stage 3 falla, el script muestra pasos de rollback y sale con código 1.

---

## Patrones de Optimización Prioritarios

### 1. Índice FK faltante (Quick Win, 30 min)
```sql
-- Antes: Full scan en DELETE/UPDATE porque FK no indexada
-- Detección: script 02 sección "FOREIGN KEYS SIN ÍNDICE"

-- Fix:
CREATE NONCLUSTERED INDEX [IX_T_PLANFORMACION_FK_ConvocatoriaId]
ON dbo.T_PLANFORMACION (ConvocatoriaId)
WITH (ONLINE=ON, FILLFACTOR=90);

-- Validar: Ejecutar script 03 validate después de crear el índice
```

### 2. Key Lookup → Covering Index (2-4h)
```sql
-- Antes: NC index lookup + clustered key lookup (2 reads por fila)
-- Detección: script 01 sección "KEY LOOKUPS"

-- Fix: Añadir columnas frecuentemente JOINed a INCLUDE
CREATE NONCLUSTERED INDEX [IX_T_FORMACION_PlanId_Covering]
ON dbo.T_FORMACION (PlanId)
INCLUDE (Nombre, FechaInicio, Estado, CentroId)  -- columnas del SELECT
WITH (ONLINE=ON, FILLFACTOR=85);
```

### 3. Estadísticas obsoletas (15 min)
```sql
-- Detección: script 01 sección "ESTADÍSTICAS OBSOLETAS"
-- Fix:
UPDATE STATISTICS dbo.T_PLANFORMACION WITH FULLSCAN;
-- O para toda la BD:
EXEC sp_updatestats;
```

### 4. Parameter Sniffing (Variable en PROD)
```sql
-- Síntoma: SP rápido en DEV, lento en PROD con mismos datos
-- Fix opción A: OPTIMIZE FOR UNKNOWN
CREATE OR ALTER PROCEDURE bi.ReportePlan @planId INT
AS
    SELECT ... FROM dbo.T_PLANFORMACION WHERE PlanId = @planId
    OPTION (OPTIMIZE FOR (@planId UNKNOWN));

-- Fix opción B: Query Store → forzar plan bueno
-- 1. Identifica plan_id del plan bueno en QS
-- 2. Fuerza ese plan:
EXEC sys.sp_query_store_force_plan @query_id = 1234, @plan_id = 5678;
```

### 5. Sargability — predicados no-sargables (1-2h por query)
```sql
-- ❌ No-sargable (full scan aunque exista índice)
WHERE YEAR(FechaCreacion) = 2025
WHERE CONVERT(VARCHAR, PlanId) = '1001'
WHERE Nombre LIKE '%Plan%'
WHERE LEN(Descripcion) > 100

-- ✅ Sargable (usa el índice)
WHERE FechaCreacion >= '2025-01-01' AND FechaCreacion < '2026-01-01'
WHERE PlanId = 1001
WHERE Nombre LIKE 'Plan%'  -- solo prefix
WHERE Descripcion > REPLICATE('a', 100)
```

---

## Checklist de Calidad (por SP optimizado)

- [ ] Baseline capturado antes del cambio (script 01)
- [ ] Golden file creado (script 03 capture)
- [ ] Índice/rewrite aplicado en DEV
- [ ] Validación funcional pass (script 03 validate, Stage 1)
- [ ] Validación en staging pass (Stage 2)
- [ ] DDL de cambio revisado por DBA
- [ ] Ventana de mantenimiento acordada con OPS
- [ ] Deploy en PROD con confirmación manual (Stage 3)
- [ ] Monitor 24h post-deploy (Stage 4)
- [ ] Métricas antes/después documentadas en reporte

---

## Métricas de Éxito

| Indicador | Target | Cómo medir |
|-----------|--------|------------|
| AvgElapsed_ms | -20% mínimo | script 04 Stage 4 |
| AvgLogicalReads | -30% mínimo | sys.dm_exec_procedure_stats |
| Lock timeouts/día | < 5 | sys.dm_os_waiting_tasks alert |
| PAGEIO_LATCH waits | < 100ms avg | script 01 sección wait stats |
| Regressions detected | 0 | script 03 validate exit code |

---

## Rollback Manual

Si un cambio causa regresión en PROD:

```sql
-- Rollback de índice
DROP INDEX [IX_nombre] ON schema.Tabla;

-- Rollback de SP rewrite
-- Restaurar desde fuente de verdad:
-- workspaces/OFERTA25/fuente-de-verdad/schema/db.sql

-- Rollback de Query Store plan forzado
EXEC sys.sp_query_store_unforce_plan @query_id = 1234, @plan_id = 5678;

-- Rollback de UPDATE STATISTICS (no hay rollback directo)
-- → Usar sp_updatestats para regenerar con datos actuales
```

---

## Estructura de Archivos

```
.github/scripts/query-optimization/
├── 01-capture-baseline.sql          ← Ejecutar en SSMS
├── 02-index-recommendations.sql     ← Revisar y aplicar DDL
├── 03-golden-file-regression.ps1    ← capture | validate | report
├── 04-staged-rollout.ps1            ← Orquestador completo
└── README.md                        ← Este archivo

workspaces/OFERTA25/tests/golden/
└── {schema}_{sp_name}.golden.json   ← Golden files (no comitear sin review)

workspaces/OFERTA25/plans/optimization-reports/
└── {sp_name}-rollout-{date}.md      ← Reporte de cada optimización
```

---

**Próximos SPs priorizados (Wave-1, mayor frecuencia):**  
Obtener de `workspaces/OFERTA25/plans/full-db-sp-classification.csv`  
Filtrar: `Category = CRUD AND Wave = Wave-1`  
Ordenar por: frecuencia real (Phase 2 DMV → `phase2-top-sps-frequency.csv`)
