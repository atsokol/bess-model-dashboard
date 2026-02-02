#!/bin/bash

# Use DuckDB CLI to filter first week data
duckdb -json << 'EOF'
SELECT 
  Q_aFRR_pct,
  n_charge_hours,
  n_discharge_hours,
  trading_MW,
  aFRR_charge,
  aFRR_discharge,
  restore_MW,
  imbalance_MWh,
  SOC_end_MWh,
  strftime(CAST(date AS TIMESTAMP) + INTERVAL (hour) HOUR, '%Y-%m-%dT%H:00:00.000Z') as datetime,
  dispatch_mode
FROM 'src/data/all_scenarios_hourly_schedules.parquet'
WHERE CAST(date AS DATE) >= '2023-01-01' AND CAST(date AS DATE) <= '2023-01-08'
ORDER BY date, hour, dispatch_mode;
EOF
