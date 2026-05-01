#!/bin/bash

duckdb << 'EOF'
COPY (
  SELECT
    CAST(Q_aFRR_pct AS FLOAT) AS Q_aFRR_pct,
    CAST(n_charge_hours AS TINYINT) AS n_charge_hours,
    CAST(n_discharge_hours AS TINYINT) AS n_discharge_hours,
    dispatch_mode,
    CAST(date AS VARCHAR) AS date,
    CAST(hour AS TINYINT) AS hour,
    CAST(trading_MW AS FLOAT) AS trading_MW,
    CAST(aFRR_charge AS FLOAT) AS aFRR_charge,
    CAST(aFRR_discharge AS FLOAT) AS aFRR_discharge,
    CAST(restore_MW AS FLOAT) AS restore_MW,
    CAST(imbalance_MWh AS FLOAT) AS imbalance_MWh,
    CAST(SOC_end_MWh AS FLOAT) AS SOC_end_MWh
  FROM read_parquet('src/data/hourly_schedules/*.parquet')
  ORDER BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, dispatch_mode, date, hour
) TO '/dev/stdout' (FORMAT PARQUET, COMPRESSION ZSTD);
EOF
