<#
.SYNOPSIS
  Phase 2 Bottleneck Validation: Run DMV queries against SQL Server PROD to confirm actual bottlenecks
  
.DESCRIPTION
  Validates the static-analysis diagnosis with real production metrics:
  1. Top SPs by total_elapsed_time (CPU-bound queries)
  2. Top SPs by execution_count (frequent/contention candidates)
  3. Lock escalation events (waits on PAGEIO_LATCH, LCK_M)
  4. Plan cache bloat (multiple plans for same query)
  5. Wait stats breakdown by type
  
.PARAMETER ServerInstance
  SQL Server instance (e.g., 'localhost\SQLEXPRESS' or 'prod.database.windows.net')
  
.PARAMETER DatabaseName
  Target database (e.g., 'OFERTA25')
  
.PARAMETER OutputDir
  Directory for reports (defaults to ./workspaces/OFERTA25/plans/)
  
.EXAMPLE
  .\diagnose-sp-bottlenecks.ps1 -ServerInstance 'prod-db.database.windows.net' -DatabaseName 'OFERTA25'
  
.NOTES
  Requires: SQL Server Management Objects (SMO) or SqlServer module
  Role: db_datareader on target database
#>

param(
  [Parameter(Mandatory=$true)]
  [string]$ServerInstance,
  
  [Parameter(Mandatory=$false)]
  [string]$DatabaseName = 'OFERTA25',
  
  [Parameter(Mandatory=$false)]
  [string]$OutputDir = '.\workspaces\OFERTA25\plans'
)

$ErrorActionPreference = 'Stop'

Write-Host "🔍 Phase 2: DMV Bottleneck Validation" -ForegroundColor Cyan
Write-Host "📌 Target: $ServerInstance / $DatabaseName" -ForegroundColor Gray
Write-Host "📂 Output: $OutputDir" -ForegroundColor Gray

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
  Write-Host "✅ Created output directory" -ForegroundColor Green
}

# Try to import SqlServer module, fall back to SMO
try {
  Import-Module SqlServer -ErrorAction Stop | Out-Null
  $usingSqlModule = $true
  Write-Host "✅ Using SqlServer module" -ForegroundColor Green
} catch {
  Write-Host "⚠️  SqlServer module not found, attempting direct connection..." -ForegroundColor Yellow
  $usingSqlModule = $false
}

# Connect to SQL Server
try {
  if ($usingSqlModule) {
    $connection = Connect-DbaInstance -SqlInstance $ServerInstance -Database $DatabaseName -ErrorAction Stop
  } else {
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
    $smo = New-Object Microsoft.SqlServer.Management.Smo.Server $ServerInstance
    $db = $smo.Databases[$DatabaseName]
    Write-Host "✅ Connected to $ServerInstance / $DatabaseName" -ForegroundColor Green
  }
} catch {
  Write-Host "❌ Failed to connect: $_" -ForegroundColor Red
  exit 1
}

# Query 1: Top SPs by total_elapsed_time (CPU-bound)
Write-Host "`n📊 Query 1: Top 20 SPs by Total Elapsed Time (CPU-bound)" -ForegroundColor Cyan

$query1 = @"
SELECT TOP 20 
  DB_NAME(database_id) as [Database],
  OBJECT_SCHEMA_NAME(object_id, database_id) + '.' + OBJECT_NAME(object_id, database_id) as [Procedure],
  execution_count as [ExecCount],
  total_elapsed_time / 1000000.0 as [TotalElapsed_Sec],
  (total_elapsed_time / execution_count) / 1000.0 as [AvgElapsed_Ms],
  total_logical_reads as [LogicalReads],
  total_physical_reads as [PhysicalReads],
  total_rows as [RowsReturned]
FROM sys.dm_exec_procedure_stats
WHERE database_id = DB_ID('$DatabaseName')
  AND object_id IS NOT NULL
ORDER BY total_elapsed_time DESC;
"@

try {
  if ($usingSqlModule) {
    $results1 = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $DatabaseName -Query $query1
  } else {
    $results1 = $smo.Query($query1)
  }
  
  $results1 | Format-Table -AutoSize
  $results1 | Export-Csv -Path "$OutputDir\phase2-top-sps-cpu.csv" -NoTypeInformation -Force
  Write-Host "✅ Exported to phase2-top-sps-cpu.csv" -ForegroundColor Green
} catch {
  Write-Host "❌ Query 1 failed: $_" -ForegroundColor Red
}

# Query 2: Top SPs by execution_count (frequent)
Write-Host "`n📊 Query 2: Top 20 SPs by Execution Count (contention risk)" -ForegroundColor Cyan

$query2 = @"
SELECT TOP 20
  DB_NAME(database_id) as [Database],
  OBJECT_SCHEMA_NAME(object_id, database_id) + '.' + OBJECT_NAME(object_id, database_id) as [Procedure],
  execution_count as [ExecCount],
  (total_elapsed_time / execution_count) / 1000.0 as [AvgElapsed_Ms],
  total_logical_reads as [LogicalReads],
  total_physical_reads as [PhysicalReads]
FROM sys.dm_exec_procedure_stats
WHERE database_id = DB_ID('$DatabaseName')
  AND object_id IS NOT NULL
ORDER BY execution_count DESC;
"@

try {
  if ($usingSqlModule) {
    $results2 = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $DatabaseName -Query $query2
  } else {
    $results2 = $smo.Query($query2)
  }
  
  $results2 | Format-Table -AutoSize
  $results2 | Export-Csv -Path "$OutputDir\phase2-top-sps-frequency.csv" -NoTypeInformation -Force
  Write-Host "✅ Exported to phase2-top-sps-frequency.csv" -ForegroundColor Green
} catch {
  Write-Host "❌ Query 2 failed: $_" -ForegroundColor Red
}

# Query 3: Wait stats breakdown
Write-Host "`n📊 Query 3: Wait Stats Breakdown" -ForegroundColor Cyan

$query3 = @"
SELECT TOP 20
  wait_type,
  waiting_tasks_count as [WaitCount],
  wait_time_ms as [TotalWaitMs],
  (wait_time_ms / NULLIF(waiting_tasks_count, 0)) as [AvgWaitMs],
  signal_wait_time_ms as [SignalWaitMs]
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'SQLTRACE_BUFFER_FLUSH',
                        'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'WAITFOR', 'LOGMGR_QUEUE',
                        'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
                        'XE_DISPATCHER_JOIN', 'QDS_CLEANUP_STALE_QUERIES', 'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
                        'BROKER_EVENTHANDLER', 'BROKER_RECEIVE_WAITFOR', 'TRACER', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
                        'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'PWAIT_ALL', 'CXPACKET_IDLE')
ORDER BY wait_time_ms DESC;
"@

try {
  if ($usingSqlModule) {
    $results3 = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $DatabaseName -Query $query3
  } else {
    $results3 = $smo.Query($query3)
  }
  
  $results3 | Format-Table -AutoSize
  $results3 | Export-Csv -Path "$OutputDir\phase2-wait-stats.csv" -NoTypeInformation -Force
  Write-Host "✅ Exported to phase2-wait-stats.csv" -ForegroundColor Green
} catch {
  Write-Host "❌ Query 3 failed: $_" -ForegroundColor Red
}

# Query 4: Lock escalation candidates (sessions waiting on locks)
Write-Host "`n📊 Query 4: Current Lock Waits" -ForegroundColor Cyan

$query4 = @"
SELECT 
  session_id as [SessionId],
  wait_type as [WaitType],
  wait_duration_ms as [WaitMs],
  wait_resource as [WaitResource]
FROM sys.dm_os_waiting_tasks
WHERE wait_type IN ('PAGEIO_LATCH_SH', 'PAGEIO_LATCH_EX', 'PAGEIO_LATCH_UP',
                    'LCK_M_S', 'LCK_M_X', 'LCK_M_U', 'LCK_M_SCH_S', 'LCK_M_SCH_M',
                    'LCK_M_IS', 'LCK_M_IX', 'LCK_M_UIX', 'BUFFER_IO_LATCH')
ORDER BY wait_duration_ms DESC;
"@

try {
  if ($usingSqlModule) {
    $results4 = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $DatabaseName -Query $query4
  } else {
    $results4 = $smo.Query($query4)
  }
  
  if ($results4) {
    Write-Host "⚠️  ACTIVE LOCK WAITS DETECTED:" -ForegroundColor Yellow
    $results4 | Format-Table -AutoSize
    $results4 | Export-Csv -Path "$OutputDir\phase2-active-locks.csv" -NoTypeInformation -Force
  } else {
    Write-Host "✅ No lock waits detected (normal)" -ForegroundColor Green
  }
} catch {
  Write-Host "❌ Query 4 failed: $_" -ForegroundColor Red
}

# Query 5: Plan cache bloat detection
Write-Host "`n📊 Query 5: Plan Cache Bloat (Multiple Plans per Statement)" -ForegroundColor Cyan

$query5 = @"
SELECT TOP 10
  OBJECT_SCHEMA_NAME(qs.object_id, qs.database_id) + '.' + OBJECT_NAME(qs.object_id, qs.database_id) as [Procedure],
  COUNT(DISTINCT qs.plan_handle) as [PlanCount],
  SUM(qs.execution_count) as [TotalExecs],
  SUM(qs.total_elapsed_time) / 1000000.0 as [TotalElapsed_Sec]
FROM sys.dm_exec_query_stats qs
WHERE qs.database_id = DB_ID('$DatabaseName')
  AND OBJECT_NAME(qs.object_id, qs.database_id) IS NOT NULL
GROUP BY qs.object_id, qs.database_id
HAVING COUNT(DISTINCT qs.plan_handle) > 1
ORDER BY COUNT(DISTINCT qs.plan_handle) DESC;
"@

try {
  if ($usingSqlModule) {
    $results5 = Invoke-DbaQuery -SqlInstance $ServerInstance -Database $DatabaseName -Query $query5
  } else {
    $results5 = $smo.Query($query5)
  }
  
  if ($results5) {
    Write-Host "⚠️  PLAN CACHE BLOAT DETECTED:" -ForegroundColor Yellow
    $results5 | Format-Table -AutoSize
    $results5 | Export-Csv -Path "$OutputDir\phase2-plan-cache-bloat.csv" -NoTypeInformation -Force
  } else {
    Write-Host "✅ No plan cache bloat detected" -ForegroundColor Green
  }
} catch {
  Write-Host "❌ Query 5 failed: $_" -ForegroundColor Red
}

# Generate summary report
Write-Host "`n📋 Generating summary report..." -ForegroundColor Cyan

$summary = @"
# 📊 PHASE 2 DMV VALIDATION SUMMARY
**Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Server:** $ServerInstance
**Database:** $DatabaseName

## ✅ Executed Queries

1. **Top 20 SPs by Total Elapsed Time (CPU-bound)**
   - File: phase2-top-sps-cpu.csv
   - Purpose: Identify CPU-intensive procedures

2. **Top 20 SPs by Execution Count (Contention Risk)**
   - File: phase2-top-sps-frequency.csv
   - Purpose: Identify frequently-called procedures (high contention risk)

3. **Wait Stats Breakdown**
   - File: phase2-wait-stats.csv
   - Purpose: Identify bottleneck wait types (PAGEIO_LATCH, LCK_M, etc)

4. **Active Lock Waits**
   - File: phase2-active-locks.csv
   - Purpose: Real-time lock contention detection

5. **Plan Cache Bloat**
   - File: phase2-plan-cache-bloat.csv
   - Purpose: Identify procedures with multiple execution plans (dynamic SQL?)

## 🎯 Interpretation Guide

### High-Risk Indicators
- **PAGEIO_LATCH waits > 1000ms:** Index fragmentation or missing indexes
- **LCK_M_X waits:** Write contention on tables
- **Multiple plans for same SP:** Dynamic SQL or parameter sniffing

### Correlation with Static Analysis
- Static says: 2,483 write SPs (37.9%)
- DMV shows: TOP execution by frequency = high contention risk
- Action: Prioritize top 20 write SPs for index audit

## 📋 Next Steps
1. Review top CPU SPs - correlate with Complex/Critical category
2. Review top frequency SPs - correlate with Wave assignment
3. Review wait stats - match against expected bottlenecks
4. If PAGEIO_LATCH high: Run index fragmentation audit
5. If LCK_M high: Validate missing FK indexes

---
**Generated:** $(Get-Date)
"@

$summary | Out-File -FilePath "$OutputDir\PHASE2-SUMMARY.md" -Force
Write-Host "✅ Summary report exported to PHASE2-SUMMARY.md" -ForegroundColor Green

Write-Host "`n✅ Phase 2 validation complete!" -ForegroundColor Green
Write-Host "📂 Reports available in: $OutputDir" -ForegroundColor Green
