# 🚀 Boost DBA 360: Tu Equipo DBA Aumentado con IA

> *En SQL Server la deuda técnica crece silenciosamente: miles de stored procedures sin documentación, dependencias ocultas, cambios que rompen cosas que no esperabas. Boost DBA 360 es un sistema de IA que actúa como equipo DBA: analiza, diagnostica, cuantifica riesgo y guía modernización de forma segura.*

## ¿Qué es Boost DBA 360?

Boost DBA 360 es un **sistema agentico de IA** para operar, diagnosticar, optimizar y modernizar bases de datos SQL Server sin exfiltrar información sensible. Combina 17 agentes especializados con 17 skills reutilizables y una capa de conocimiento anti-alucinación para responder las preguntas clave de un DBA: Combina flujos de trabajo agenticos con habilidades especializadas para responder las preguntas clave de rendimiento, riesgo y evolución:

- **"Quiero arrancar y analizarlo todo desde cero"** → DBA 360 Orchestrator ← *empieza aquí*
- **"¿Qué se romperá si cambiamos esto?"** → Change Impact Assessor
- **"¿Cuáles procedimientos son realmente críticos?"** → DB Dependency Analyzer
- **"¿Cuál es la lógica de negocio real?"** → Legacy Logic Extractor
- **"¿Dónde está el cuello de botella?"** → Performance Bottleneck Analyzer
- **"¿Cómo optimizo esta consulta sin romper nada?"** → Query Optimizer
- **"¿Qué riesgos de seguridad/continuidad tenemos?"** → DBA Reliability & Security Advisor
- **"¿Por dónde empezamos a modernizar?"** → Modernization Orchestrator
- **"¿Quién documentará esto?"** → DB Documentation Generator

## Principio Clave: Análisis Completo Sin Exfiltrar Negocio

La propuesta de DB Boost es analizar una BBDD de extremo a extremo sin sacar fuera información sensible por defecto.

- Análisis local primero: el descubrimiento y la evaluación se hacen en el entorno origen.
- Mínimo dato necesario: se prioriza metadata, dependencias y métricas antes que SQL literal.
- Compartición controlada: cualquier salida externa debe pasar por saneado y validación.
- Seguridad por defecto: si algo no es necesario para el diagnóstico, no se comparte.

La seguridad va embebida en el [Orquestador DBA 360](agents/dba-360-orchestrator.agent.md) y en la skill [secure-onboarding](skills/secure-onboarding/SKILL.md): no es un paso manual, es parte del flujo de arranque.

## El Problema que Resolvemos

### La Realidad de las Bases de Datos Heredadas

```
15 años de capas acumuladas
    ↓
Miles de stored procedures
    ↓
Lógica de negocio dispersa por todas partes
    ↓
Dependencias implícitas que nadie comprende
    ↓
Miedo a hacer cualquier cambio
    ↓
La deuda técnica crece exponencialmente
```

**El Costo:**
- Semanas para implementar cambios simples
- Interrupciones frecuentes por modificaciones "inocentes"
- Sin documentación = conocimiento institucional en la cabeza de una persona
- Imposible modernizar: no sabes qué es crítico

**El Miedo:**
- "¿Si refactorizamos este procedimiento, qué se romperá?"
- "¿Podemos eliminar esto de forma segura? No ha sido modificado en 5 años"
- "¿Qué pasará si agregamos un índice nuevo?"
- "¿Quién es responsable de esta parte de la base de datos?"

## Nuestra Solución: Análisis Agentico

### Arquitectura DBA 360

```
┌──────────────────────────────────────────────────────────────────┐
│                   ORQUESTADOR DBA 360  🧭                        │
│     Onboarding · Preflight · Análisis · Derive · Informes        │
└──────────────────────────────────────────────────────────────────┘
       ↓            ↓            ↓            ↓            ↓
  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────┐
  │Dependen-│ │ Lógica  │ │Rendimien│ │Seguridad│ │Modernización│
  │cias e   │ │de Negoc.│ │to y     │ │y Gobier-│ │y Documenta- │
  │ Impacto │ │en SP    │ │Consultas│ │    no   │ │    ción     │
  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────────┘
       ↓            ↓            ↓            ↓            ↓
┌──────────────────────────────────────────────────────────────────┐
│                  SKILLS ESPECIALIZADAS                           │
│  secure-onboarding · database-analysis · dependency-impact       │
│  performance-diagnostics · query-optimization                    │
│  dba-governance · documentation-recovery                         │
└──────────────────────────────────────────────────────────────────┘
                    ↓            ↓            ↓
             ┌──────────┬────────────┬──────────────┐
             │  sys.*   │    DMVs    │ Query Store  │
             │ Catálogo │  Rendimien │  Planes y    │
             │ de objetos│  to vivo  │  estadísticas│
             └──────────┴────────────┴──────────────┘
```

## Agentes Especializados

### 0. **Orquestador DBA 360** 🧭 — *El Wizard de Entrada*
El punto de arranque. Inicializa el proyecto, crea la fuente de verdad local, ejecuta el preflight de seguridad y después orquesta el análisis completo o deriva al agente especializado que corresponda.

```
Usar cuando: "Inicializa mi proyecto" / "Haz una evaluación DBA completa desde cero"
Salida: fuente de verdad local + informe 360 + roadmap de acción
```

### 1. **Analizador de Dependencias de BD** 🔍
Descubre qué está realmente conectado a qué.

```
Entrada: Base de datos heredada de SQL Server
Salida: Mapas de dependencias, puntuaciones de criticidad, cadenas de impacto

Usar cuando: "¿Cuáles procedimientos son realmente críticos para la producción?"
Ejemplo: Mapea 47 procedimientos → identifica 3 núcleo, 12 utilidad, 32 candidatos para eliminar
```

### 2. **Extractor de Lógica Legacy** 📖
Extrae lógica de negocio enterrada de procedimientos.

```
Entrada: Stored procedures con lógica compleja
Salida: Documentación de reglas de negocio, especificaciones de algoritmos

Usar cuando: "¿Qué hace realmente este procedimiento de 500 líneas?"
Ejemplo: Descubre lógica de descuento duplicada en 3 procedimientos, sugiere consolidación
```

### 3. **Evaluador de Impacto de Cambios** ⚠️
Muestra qué se romperá antes de que lo rompas.

```
Entrada: Cambio propuesto en la base de datos
Salida: Análisis de radio de impacto, estrategia de pruebas, plan de reversión

Usar cuando: "¿Es seguro renombrar esta columna?"
Ejemplo: "154 objetos dependientes serán afectados. Riesgo: ALTO. Estrategia de pruebas: ..."
```

### 4. **Generador de Documentación de BD** 📝
Crea documentación faltante a partir de la realidad del código.

```
Entrada: Schema de base de datos y procedimientos
Salida: Diccionario de datos, especificaciones de procedimientos, diagramas de flujo de datos, runbooks

Usar cuando: "Necesitamos documentación pero nadie la escribió"
Ejemplo: Genera especificación completa a partir de un escaneo de 2 horas de la base de datos
```

### 5. **Orquestador de Modernización** 🎯
Controlador maestro de todo el viaje de DB Boost.

```
Entrada: Base de datos heredada + objetivos de modernización
Salida: Roadmap de modernización por fases con quick wins

Usar cuando: "Ayúdanos a modernizar esto de forma segura sin romper cosas"
Ejemplo: Prioriza 15 iniciativas de modernización en 4 trimestres
```

### 6. **Analizador de Cuellos de Botella** ⚡
Diagnostica lentitud en SQL Server con evidencia de waits, bloqueos y top consultas.

```
Entrada: síntoma (timeouts, CPU alta, bloqueos) + ventana temporal
Salida: top offenders priorizados, causa raíz probable, plan de mitigación

Usar cuando: "La BBDD va lenta a ciertas horas" / "Tenemos timeouts en producción"
```

### 7. **Optimizador de Consultas SQL** 🧠
Optimiza consultas, planes e índices con validación antes/después y control de riesgo.

```
Entrada: consulta o SP + métricas baseline
Salida: versión optimizada, índices sugeridos, checklist de regresión

Usar cuando: "Este SP tarda 40s" / "Necesito reducir CPU de reportes"
```

### 8. **Asesor DBA de Fiabilidad y Seguridad** 🔐
Evalúa riesgos de continuidad, permisos excesivos, hardening y recuperación.

```
Entrada: instancia SQL Server objetivo
Salida: hallazgos de riesgo priorizados, plan de remediación, checklist de continuidad

Usar cuando: "Auditoria DBA" / "¿Podemos recuperar la BD en menos de 1 hora?"
```

### 9. **Asesor de Mantenimiento Proactivo** 🔧
Detecta índices fragmentados, estadísticas obsoletas e índices sin uso, y genera el plan de mantenimiento.

```
Entrada: base de datos objetivo + umbrales configurables
Salida: lista priorizada de acciones + scripts de mantenimiento + schedule recomendado

Usar cuando: "¿Qué índices necesitan mantenimiento?" / "Los planes de ejecución empeoraron"
```

### 10. **Asesor de Capacity Planning** 📈
Analiza crecimiento histórico y proyecta necesidades de almacenamiento y recursos a futuro.

```
Entrada: instancia + horizonte de proyección (3/6/12 meses)
Salida: proyección de almacenamiento, riesgos de capacidad, configuración de autogrowth

Usar cuando: "¿Cuándo nos quedamos sin espacio?" / "Planifica el almacenamiento del próximo año"
```

### 11. **Asesor de Monitorización y Baseline** 📊
Establece qué es "normal" en el sistema y detecta desviaciones antes de que impacten a usuarios.

```
Entrada: instancia + ventana de baseline
Salida: baseline por franja horaria, anomalías detectadas, umbrales de alerta recomendados

Usar cuando: "¿Esto es normal o una anomalía?" / "Define umbrales de alerta para nuestra BD"
```

### 12. **Analizador de Jobs y Automatización SQL** ⚙️
Audita SQL Agent jobs: fallos, schedules en conflicto, jobs obsoletos y dependencias implícitas.

```
Entrada: instancia + ventana temporal
Salida: inventario de jobs, fallos, solapamientos, recomendaciones de reorganización

Usar cuando: "¿Qué jobs fallaron?" / "¿Hay jobs que se solapan y compiten por recursos?"
```

### 13. **Asesor de Alta Disponibilidad** 🏗️
Evalúa AlwaysOn, replicación y log shipping, calcula RTO/RPO real y genera runbook de failover.

```
Entrada: instancia con HA configurado + objetivos RTO/RPO
Salida: estado de réplicas, RPO/RTO alcanzable, gaps y runbook de failover

Usar cuando: "¿Nuestro AlwaysOn está bien?" / "¿Podemos hacer failover en menos de X minutos?"
```

### 14. **Generador de Scripts de Migración** 📝
Produce scripts de cambio de schema/datos con rollback explícito, validaciones y plan de despliegue.

```
Entrada: descripción del cambio + entornos objetivo
Salida: script de rollout + rollback + checklist go/no-go + estimación de ventana

Usar cuando: "Genera el script para este cambio con su rollback" / "Crea el plan de despliegue"
```

### 15. **Generador de Datos de Prueba** 🧪
Crea datos sintéticos realistas respetando constraints y relaciones, con anonimización de datos sensibles.

```
Entrada: schema objetivo + volumen + columnas sensibles
Salida: script de datos sintéticos + anonimización + validación de integridad

Usar cuando: "Genera datos de prueba para staging" / "Anonimiza este subconjunto de producción"
```

## Habilidades Reutilizables

### **database-analysis** 📊
Extrae schema, procedimientos, metadatos, estadísticas de ejecución. La base para todo análisis.

### **dependency-impact** 🔗
Mapea dependencias, analiza cadenas de impacto, identifica radio de impacto, calcula niveles de riesgo.

### **documentation-recovery** 📚
Genera diccionarios de datos, especificaciones de procedimientos, diagramas ER, documentación de linaje de datos.

### **performance-diagnostics** ⚡
Detecta cuellos de botella por CPU, IO, waits, bloqueos y regresiones de plan.

### **query-optimization** 🧠
Aplica tuning de SQL y estrategias de índices con validación de regresión.

### **dba-governance** 🔐
Audita seguridad, permisos, backup/restore y madurez operativa DBA.

### **human-in-the-loop** 👤
Compuerta de decisión humana: define qué puede hacer el agente solo (análisis, scripts), qué requiere confirmación y qué está bloqueado sin aprobación explícita (DROP, failover, cambios de seguridad en producción).

### **security-loop** 🔄
Compuerta de seguridad continua: se ejecuta en inicio, análisis y entrega. No es un paso único, es un loop embebido en cada fase.

### **cross-platform-validation** 🌐
Contrasta recomendaciones con documentación oficial (SQL Server, Azure SQL, PostgreSQL, AWS RDS, Cosmos DB) y mapea equivalencias entre plataformas.

### **secure-onboarding** 🛡️
Crea la fuente de verdad local, ejecuta preflight y bloquea exfiltración accidental de negocio.

### **proactive-maintenance** 🔧
Detecta fragmentación, estadísticas obsoletas e índices problemáticos con scripts de mantenimiento listos.

### **capacity-planning** 📈
Analiza tendencias de crecimiento y proyecta almacenamiento y recursos a 3/6/12 meses.

### **monitoring-baseline** 📊
Captura baseline de métricas, detecta anomalías y define umbrales de alerta ajustados a la realidad.

### **jobs-automation** ⚙️
Inventaría SQL Agent jobs, detecta fallos, solapamientos y jobs obsoletos con recomendaciones.

### **high-availability** 🏗️
Valida estado de AlwaysOn/replicación, calcula RTO/RPO real y genera runbooks de failover.

### **migration-scripting** 📝
Estructura estándar para scripts de migración seguros: transacción, rollback, pre/post checks.

### **test-data-generation** 🧪
Genera datos sintéticos respetando constraints y anonimiza subconjuntos de producción para testing.

## Estructura del Proyecto

```
BoostDBA/
├── agents/                              # Agentes especializados
│   ├── dba-360-orchestrator.agent.md
│   ├── db-dependency-analyzer.agent.md
│   ├── legacy-logic-extractor.agent.md
│   ├── change-impact-assessor.agent.md
│   ├── db-documentation-generator.agent.md
│   ├── performance-bottleneck-analyzer.agent.md
│   ├── query-optimizer.agent.md
│   ├── dba-reliability-security-advisor.agent.md
│   ├── modernization-orchestrator.agent.md
│   ├── proactive-maintenance-advisor.agent.md
│   ├── capacity-planning-advisor.agent.md
│   ├── monitoring-baseline-advisor.agent.md
│   ├── sql-agent-jobs-analyzer.agent.md
│   ├── high-availability-advisor.agent.md
│   ├── migration-script-generator.agent.md
│   ├── test-data-generator.agent.md
│   └── cross-platform-advisor.agent.md
│
├── skills/                              # Capacidades reutilizables
│   ├── secure-onboarding/               # onboarding + fuente de verdad + preflight
│   ├── database-analysis/               # extracción de schema y metadatos
│   ├── dependency-impact/               # dependencias y análisis de impacto
│   ├── documentation-recovery/          # generación de documentación
│   ├── performance-diagnostics/         # waits, bloqueos, top consultas
│   ├── query-optimization/              # tuning de SQL e índices
│   ├── dba-governance/                  # seguridad, backups y continuidad
│   ├── proactive-maintenance/           # índices, estadísticas, fragmentación
│   ├── capacity-planning/               # crecimiento y proyecciones de almacenamiento
│   ├── monitoring-baseline/             # baseline, anomalías y umbrales de alerta
│   ├── jobs-automation/                 # SQL Agent jobs, fallos y schedules
│   ├── high-availability/               # AlwaysOn, replicación, RTO/RPO
│   ├── migration-scripting/             # scripts de migración con rollback
│   ├── test-data-generation/            # datos sintéticos y anonimización
│   ├── security-loop/                   # compuerta de seguridad continua por fase
│   ├── human-in-the-loop/               # compuerta de decisión humana en acciones de impacto
│   └── cross-platform-validation/       # validación contra docs oficiales multi-plataforma
│
├── examples/                            # Casos de estudio con SQL real ejecutable
│   └── legacy-sql-server/
│       ├── erp-database.sql            # BD ERP heredada: 47 SPs, deuda técnica real
│       ├── analysis-queries.sql         # Queries de análisis listas para ejecutar
│       └── README.md                    # Guía del caso de estudio
│
├── templates/                           # Plantillas reutilizables para cada entregable
│   ├── modernization/
│   │   ├── migration-plan.md           # Plan de modernización por fases (Quick Wins → Cutover)
│   │   ├── impact-analysis-template.md # Análisis de impacto de cambio propuesto
│   │   └── documentation-template.md   # Documentación de BD: tablas, SPs, relaciones
│   └── reports/
│       ├── dba-360-assessment-template.md
│       ├── performance-bottleneck-report-template.md
│       ├── security-reliability-audit-template.md
│       ├── proactive-maintenance-report-template.md
│       ├── capacity-planning-report-template.md
│       ├── monitoring-baseline-report-template.md
│       ├── jobs-automation-report-template.md
│       ├── high-availability-report-template.md
│       ├── modernization-report-template.md
│       └── dependency-impact-report-template.md
│
├── knowledge/                           # Base de conocimiento DBA de referencia
│   ├── specs/
│   │   ├── agent-behavioral-spec.md    # Reglas anti-alucinacion: evidencia, confianza, limites
│   │   └── session-framing-guide.md    # Como encuadrar sesiones DBA para maxima precision
│   ├── references/
│   │   └── official-docs.md            # SQL Server, Azure SQL, PostgreSQL, AWS RDS, Cosmos DB
│   └── patterns/                        # 13 anti-patrones individuales (uno por archivo)
│       ├── README.md                    # Índice por categoría: mantenibilidad, rendimiento, seguridad...
│       ├── logica-negocio-dispersa.md
│       ├── dependencias-implicitas.md
│       ├── cursores-vs-set-based.md
│       ├── dynamic-sql-sin-parametrizar.md
│       └── ...                          # y 9 más
│
├── scripts/                             # Scripts de automatización
│   ├── run-dba360-wizard.ps1           # ★ Punto de entrada: inicializa dba_<Proyecto>/ externo
│   ├── bootstrap-source-of-truth.ps1   # Crea estructura fuente-de-verdad/ y manifest.json
│   └── security-preflight.ps1          # Preflight de seguridad (detecta secretos, datos sensibles)
│
└── README.md                            # Este archivo
```

## Cómo Empezar: 3 Pasos

### 1️⃣ Arranca el Wizard de Onboarding

Ejecutar desde PowerShell:

```powershell
pwsh -File .\scripts\run-dba360-wizard.ps1 -ProjectName "MiProyecto" -SchemaPath "C:\tus-esquemas"
```

O si tienes una connection string:

```powershell
pwsh -File .\scripts\run-dba360-wizard.ps1 -ProjectName "MiProyecto" -ConnectionString "Server=...;Database=...;User Id=...;Password=...;"
```

**Qué hace el wizard:**
- Crea la carpeta `dba_MiProyecto/` fuera del producto (hermana de BoostDBA)
- Importa esquemas y crea la fuente de verdad local
- Ejecuta preflight de seguridad (detecta secretos, datos sensibles)
- Genera manifest para trabajar sin depender de conexión continua

> **¿Qué es `dba_<Proyecto>/`?**  
> Carpeta de trabajo del cliente, fuera del producto Boost DBA. Contiene: `fuente-de-verdad/` (esquemas y manifest), `reports/` (informes generados), `plans/` (roadmaps), `logs/` (trazabilidad).

---

### 2️⃣ Abre el Orquestador DBA 360 en tu IDE

En VS Code con Copilot, selecciona el agente **[DBA 360 Orchestrator](agents/dba-360-orchestrator.agent.md)** y pregunta:

> *"Haz una evaluación DBA 360 sobre dba_MiProyecto"*

El orquestador:
- Lee la fuente de verdad local
- Analiza dependencias, lógica de negocio, rendimiento, seguridad
- Genera informe ejecutivo con top 5 acciones priorizadas
- Propone roadmap de modernización por fases

---

### 3️⃣ Usa los agentes especializados según necesites

A partir de ahora, la fuente de verdad local es tu verdad: sin conexión continua, sin riesgo de exfiltración. Elige el agente por pregunta concreta:

| Necesito... | Agente |
|-------------|--------|
| Entender dependencias y qué es crítico | [db-dependency-analyzer](agents/db-dependency-analyzer.agent.md) |
| Saber qué hace un SP por dentro | [legacy-logic-extractor](agents/legacy-logic-extractor.agent.md) |
| Saber el impacto de un cambio antes de hacerlo | [change-impact-assessor](agents/change-impact-assessor.agent.md) |
| Encontrar por qué va lento / hay timeouts | [performance-bottleneck-analyzer](agents/performance-bottleneck-analyzer.agent.md) |
| Optimizar una consulta sin romper nada | [query-optimizer](agents/query-optimizer.agent.md) |
| Auditoría de seguridad, backups y continuidad | [dba-reliability-security-advisor](agents/dba-reliability-security-advisor.agent.md) |
| Documentar la BBDD automáticamente | [db-documentation-generator](agents/db-documentation-generator.agent.md) |
| Plan completo de modernización | [modernization-orchestrator](agents/modernization-orchestrator.agent.md) |
| Comparar con otra plataforma / validar contra docs oficiales | [cross-platform-advisor](agents/cross-platform-advisor.agent.md) |
| Evaluación integral desde cero | [dba-360-orchestrator](agents/dba-360-orchestrator.agent.md) |
| Índices fragmentados / estadísticas obsoletas | [proactive-maintenance-advisor](agents/proactive-maintenance-advisor.agent.md) |
| ¿Cuándo nos quedamos sin espacio? | [capacity-planning-advisor](agents/capacity-planning-advisor.agent.md) |
| ¿Esto es normal o una anomalía? | [monitoring-baseline-advisor](agents/monitoring-baseline-advisor.agent.md) |
| Jobs fallidos / schedules en conflicto | [sql-agent-jobs-analyzer](agents/sql-agent-jobs-analyzer.agent.md) |
| Estado de AlwaysOn / RTO-RPO real | [high-availability-advisor](agents/high-availability-advisor.agent.md) |
| Generar script de cambio con rollback | [migration-script-generator](agents/migration-script-generator.agent.md) |
| Datos de prueba para staging/dev | [test-data-generator](agents/test-data-generator.agent.md) |

## Stack Técnico

- **Plataforma**: SQL Server 2016+
- **Análisis**: Vistas de catálogo (`sys.*`), DMVs, Query Store
- **IA**: Agentes LLM especializados por dominio DBA
- **Salidas**: Markdown, JSON, diagramas Mermaid, plantillas de informe

## Ejemplos Incluidos

### BD ERP Legacy — Caso de Estudio Completo
Ubicación: [examples/legacy-sql-server/](examples/legacy-sql-server/)

Una base de datos SQL Server realista en producción desde 2005 que acumula todos los problemas típicos: código muerto, lógica duplicada, dependencias ocultas, valores hardcoded y documentación inexistente. Perfecta para probar Boost DBA desde cero sin tocar tu BD real.

| Fichero | Qué contiene |
|---------|-------------|
| [erp-database.sql](examples/legacy-sql-server/erp-database.sql) | 47 SPs, 5 tablas, dependencias ocultas y deuda técnica intencional |
| [analysis-queries.sql](examples/legacy-sql-server/analysis-queries.sql) | Queries de análisis `sys.*` y DMVs listas para ejecutar |
| [README.md](examples/legacy-sql-server/README.md) | Guía del caso: qué encontrarás y qué debería detectar cada agente |

## Plantillas de Entregables

Úsalas directamente como output de cada sesión de análisis.

### Modernización
| Plantilla | Cuándo usarla |
|-----------|--------------|
| [migration-plan.md](templates/modernization/migration-plan.md) | Planificar modernización por fases con Quick Wins, hitos y criterios de éxito |
| [impact-analysis-template.md](templates/modernization/impact-analysis-template.md) | Documentar el impacto de un cambio propuesto antes de ejecutarlo |
| [documentation-template.md](templates/modernization/documentation-template.md) | Generar documentación completa de tablas, SPs y relaciones |

### Informes Ejecutivos DBA
| Plantilla | Agente que la genera |
|-----------|---------------------|
| [dba-360-assessment-template.md](templates/reports/dba-360-assessment-template.md) | dba-360-orchestrator |
| [performance-bottleneck-report-template.md](templates/reports/performance-bottleneck-report-template.md) | performance-bottleneck-analyzer |
| [security-reliability-audit-template.md](templates/reports/security-reliability-audit-template.md) | dba-reliability-security-advisor |
| [proactive-maintenance-report-template.md](templates/reports/proactive-maintenance-report-template.md) | proactive-maintenance-advisor |
| [capacity-planning-report-template.md](templates/reports/capacity-planning-report-template.md) | capacity-planning-advisor |
| [monitoring-baseline-report-template.md](templates/reports/monitoring-baseline-report-template.md) | monitoring-baseline-advisor |
| [jobs-automation-report-template.md](templates/reports/jobs-automation-report-template.md) | sql-agent-jobs-analyzer |
| [high-availability-report-template.md](templates/reports/high-availability-report-template.md) | high-availability-advisor |
| [modernization-report-template.md](templates/reports/modernization-report-template.md) | modernization-orchestrator |
| [dependency-impact-report-template.md](templates/reports/dependency-impact-report-template.md) | change-impact-assessor |

## Base de Conocimiento

### [Especificaciones de Comportamiento](knowledge/specs/)

Dos documentos que evitan alucinaciones y mantienen el foco en cada sesion:

**[agent-behavioral-spec.md](knowledge/specs/agent-behavioral-spec.md)** — Reglas obligatorias para todos los agentes:
- Sin evidencia, sin afirmacion: cada hallazgo cita la query/DMV que lo produjo
- Niveles de confianza explícitos: ALTA / MEDIA / BAJA / SIN DATOS
- Limites declarados: SQL dinamico, dependencias runtime, historia previa
- Separacion estricta de hecho vs interpretacion vs recomendacion
- Escalado HITL obligatorio cuando la confianza es baja y el impacto es alto

**[session-framing-guide.md](knowledge/specs/session-framing-guide.md)** — Como encuadrar cada sesion DBA:
- Plantilla de contexto inicial (plataforma, entorno, objetivo, restricciones)
- Modos de sesion: Diagnostico / Recomendacion / Planificacion / Revision
- Senales de que la sesion esta perdiendo el foco y como reencuadrar
- Como cerrar correctamente para no perder contexto entre sesiones

### [Anti-Patrones Comunes](knowledge/patterns/README.md)
13 patrones de deuda técnica organizados por categoría, cada uno con ejemplos SQL reales, queries de detección y estrategia de modernización:
- **Mantenibilidad**: lógica dispersa, valores hardcoded, procedimientos monolíticos
- **Rendimiento**: cursores, índices faltantes, parameter sniffing
- **Estabilidad**: transacciones sin cierre, tablas sin PK
- **Trazabilidad**: dependencias implícitas, triggers en cascada, sin auditoría
- **Seguridad**: dynamic SQL sin parametrizar (OWASP A03)

### [Referencias Oficiales](knowledge/references/official-docs.md)
Fuentes de verdad oficiales por plataforma para validar recomendaciones antes de emitirlas:
- **SQL Server**: DMVs, Query Store, índices, seguridad, AlwaysOn, SQL Agent
- **Azure SQL**: Intelligent QP, auto-tuning, Defender, geo-replication, Hyperscale
- **AWS RDS / Aurora**: Performance Insights, Multi-AZ, IAM auth, Aurora Global
- **PostgreSQL**: EXPLAIN, pg_stat_statements, autovacuum, Patroni, Row Security
- **Cosmos DB**: Partitioning, Request Units, indexing policies, consistency levels

## Recursos

- [Agentes](agents/)
- [Habilidades](skills/)
- [Plantillas de Informe DBA](templates/reports/)
- [Caso de Estudio ERP](examples/legacy-sql-server/README.md)
- [Patrones de Modernización](knowledge/patterns/)

---

*Trae tu BBDD. Abre el orquestador. El resto lo hace él.*

