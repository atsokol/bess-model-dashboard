#!/bin/bash

# Use DuckDB CLI to aggregate monthly data
duckdb -json << 'EOF'
-- Trading: sum positive values as Charging
SELECT 
  Q_aFRR_pct,
  n_charge_hours,
  n_discharge_hours,
  strftime(date_trunc('month', CAST(date AS DATE)), '%Y-%m-%dT00:00:00.000Z') as month,
  'Trading' as flowType,
  'Charging' as direction,
  SUM(trading_MW) as total
FROM 'src/data/all_scenarios_hourly_schedules.parquet'
WHERE trading_MW > 0
GROUP BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, date_trunc('month', CAST(date AS DATE))

UNION ALL

-- Trading: sum negative values as Discharging (take absolute)
SELECT 
  Q_aFRR_pct,
  n_charge_hours,
  n_discharge_hours,
  strftime(date_trunc('month', CAST(date AS DATE)), '%Y-%m-%dT00:00:00.000Z') as month,
  'Trading' as flowType,
  'Discharging' as direction,
  ABS(SUM(trading_MW)) as total
FROM 'src/data/all_scenarios_hourly_schedules.parquet'
WHERE trading_MW < 0
GROUP BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, date_trunc('month', CAST(date AS DATE))

UNION ALL

-- Balancing: sum aFRR_charge as Charging
SELECT 
  Q_aFRR_pct,
  n_charge_hours,
  n_discharge_hours,
  strftime(date_trunc('month', CAST(date AS DATE)), '%Y-%m-%dT00:00:00.000Z') as month,
  'Balancing' as flowType,
  'Charging' as direction,
  SUM(aFRR_charge) as total
FROM 'src/data/all_scenarios_hourly_schedules.parquet'
GROUP BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, date_trunc('month', CAST(date AS DATE))
HAVING SUM(aFRR_charge) > 0

UNION ALL

-- Balancing: sum aFRR_discharge as Discharging
SELECT 
  Q_aFRR_pct,
  n_charge_hours,
  n_discharge_hours,
  strftime(date_trunc('month', CAST(date AS DATE)), '%Y-%m-%dT00:00:00.000Z') as month,
  'Balancing' as flowType,
  'Discharging' as direction,
  SUM(aFRR_discharge) as total
FROM 'src/data/all_scenarios_hourly_schedules.parquet'
GROUP BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, date_trunc('month', CAST(date AS DATE))
HAVING SUM(aFRR_discharge) > 0

UNION ALL

-- Restoration: sum positive values as Charging
SELECT 
  Q_aFRR_pct,
  n_charge_hours,
  n_discharge_hours,
  strftime(date_trunc('month', CAST(date AS DATE)), '%Y-%m-%dT00:00:00.000Z') as month,
  'Restoration' as flowType,
  'Charging' as direction,
  SUM(restore_MW) as total
FROM 'src/data/all_scenarios_hourly_schedules.parquet'
WHERE restore_MW > 0
GROUP BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, date_trunc('month', CAST(date AS DATE))

UNION ALL

-- Restoration: sum negative values as Discharging (take absolute)
SELECT 
  Q_aFRR_pct,
  n_charge_hours,
  n_discharge_hours,
  strftime(date_trunc('month', CAST(date AS DATE)), '%Y-%m-%dT00:00:00.000Z') as month,
  'Restoration' as flowType,
  'Discharging' as direction,
  ABS(SUM(restore_MW)) as total
FROM 'src/data/all_scenarios_hourly_schedules.parquet'
WHERE restore_MW < 0
GROUP BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, date_trunc('month', CAST(date AS DATE))

ORDER BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, month, flowType, direction;
EOF
