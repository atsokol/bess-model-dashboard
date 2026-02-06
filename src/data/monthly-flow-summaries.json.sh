#!/bin/bash

duckdb -json <<EOF
SELECT 
    Q_aFRR_pct,
    n_charge_hours,
    n_discharge_hours,
    CAST(date_trunc('month', date) AS VARCHAR) AS month,
    flowType,
    direction,
    SUM(total) AS total
FROM (
    -- Trading flows
    SELECT 
        Q_aFRR_pct,
        n_charge_hours,
        n_discharge_hours,
        date,
        'Trading' AS flowType,
        CASE 
            WHEN trading_MW > 0 THEN 'Charging'
            ELSE 'Discharging'
        END AS direction,
        ABS(trading_MW) AS total
    FROM read_parquet('src/data/combined_hourly_schedules.parquet')
    WHERE trading_MW != 0

    UNION ALL

    -- Balancing - Charging
    SELECT 
        Q_aFRR_pct,
        n_charge_hours,
        n_discharge_hours,
        date,
        'Balancing' AS flowType,
        'Charging' AS direction,
        aFRR_charge AS total
    FROM read_parquet('src/data/combined_hourly_schedules.parquet')
    WHERE aFRR_charge > 0

    UNION ALL

    -- Balancing - Discharging
    SELECT 
        Q_aFRR_pct,
        n_charge_hours,
        n_discharge_hours,
        date,
        'Balancing' AS flowType,
        'Discharging' AS direction,
        aFRR_discharge AS total
    FROM read_parquet('src/data/combined_hourly_schedules.parquet')
    WHERE aFRR_discharge > 0

    UNION ALL

    -- Restoration flows
    SELECT 
        Q_aFRR_pct,
        n_charge_hours,
        n_discharge_hours,
        date,
        'Restoration' AS flowType,
        CASE 
            WHEN restore_MW > 0 THEN 'Charging'
            ELSE 'Discharging'
        END AS direction,
        ABS(restore_MW) AS total
    FROM read_parquet('src/data/combined_hourly_schedules.parquet')
    WHERE restore_MW != 0
)
GROUP BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, month, flowType, direction
ORDER BY Q_aFRR_pct, n_charge_hours, n_discharge_hours, month, flowType, direction;
EOF
