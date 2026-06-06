---
name: 'Optimizacion de Consultas y Planes'
description: 'Skill para tuning de consultas, planes e indices con pruebas de regresion'
---

# Optimizacion de Consultas y Planes

## Proposito
Reducir tiempo de respuesta y consumo de recursos de consultas criticas manteniendo resultados funcionales correctos.

## Entradas
- Consulta o stored procedure objetivo
- Plan de ejecucion (real o estimado)
- Metricas baseline (duracion, CPU, lecturas)

## Salidas
- Version optimizada de consulta
- Recomendaciones de indices
- Riesgos y pruebas de regresion
- Plan de despliegue incremental

## Pasos

### 1. Baseline
- Captura latencia P50/P95
- Captura CPU y logical reads

### 2. Analisis de plan
- Detecta table scans costosos
- Revisa key lookups repetitivos
- Identifica warnings (spills, memory grant)

### 3. Propuesta de optimizacion
- Reescritura SQL orientada a sargabilidad
- Ajuste de predicados y joins
- Indices sugeridos con columnas clave e incluidas

### 4. Pruebas de regresion
- Compara resultados funcionales
- Compara metricas antes/despues

### 5. Rollout
- Despliegue en staging
- Ventana controlada en produccion
- Monitoreo y rollback

## Checklist de Calidad
- [ ] Mejora de rendimiento cuantificada
- [ ] Sin cambios funcionales no deseados
- [ ] Estrategia de rollback definida
- [ ] Evidencia antes/despues documentada
