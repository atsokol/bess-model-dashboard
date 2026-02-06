#!/bin/bash

duckdb -json <<EOF
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
    CAST(date + INTERVAL (hour) HOUR AS VARCHAR) AS datetime,
    dispatch_mode
FROM read_parquet('src/data/hourly_schedules/*.parquet')
WHERE date >= DATE '2023-01-01' AND date <= DATE '2023-01-08'
ORDER BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, date, hour;
EOF
