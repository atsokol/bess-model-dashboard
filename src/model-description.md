# Model Description

## Overview

This document describes the Battery Energy Storage System (BESS) optimization model for Ukraine's electricity market.

## Model Components

### Energy Storage System
- **Capacity**: Battery storage capacity in MWh
- **Power Rating**: Maximum charge/discharge rate in MW
- **Efficiency**: Round-trip efficiency of the storage system

### Market Participation
- **Day-Ahead Market**: Energy trading with hourly price signals
- **Balancing Market**: Frequency regulation and reserve services
- **Ancillary Services**: Grid support and voltage regulation

## Optimization Strategy

The model optimizes battery operations to maximize revenue while respecting:
- State of charge constraints
- Power limits
- Market rules and regulations
- Battery degradation considerations

## Data Sources

- Historical electricity prices
- Grid demand patterns
- Weather data (for renewable energy correlation)
- Market clearing prices

## Results

The model produces optimized schedules showing:
- Hourly charge/discharge decisions
- Expected revenue streams
- Monthly performance metrics
- Energy flow analysis

## Balancing Energy Flows

This visualization combines hourly waterfall bars showing cumulative balancing energy with minute-by-minute aFRR (automatic Frequency Restoration Reserve) line data.

```js
const hoursData = await FileAttachment("./data/hours.csv").csv({typed: true});
const minutesData = await FileAttachment("./data/minutes.csv").csv({typed: true});
```

```js
  // Convert minute data to fractional hours
  const minuteDataProcessed = minutesData.map(d => ({
    ...d,
    hourFraction: (new Date(d.timestamp) - new Date("2024-01-12T00:00:00Z")) / 3600000
  }));

```

```js
 Plot.plot({
    title: "aFRR Energy Flow: minute to hourly conversion",
    width: 1000,
    height: 400,
    marginLeft: 60,
    marginRight: 60,
    marginBottom: 40,
    x: {
      label: "Hour of Day",
      domain: [0, 24],
      ticks: 24
    },
    y: {
      grid: true,
      label: "↑ Cumulative Energy (MWh)"
    },
    fy: {
      label: "Power (MW) ↓"
    },
    color: {
      domain: ["Positive", "Negative", "Minute Data"],
      range: ["#649334", "#cc392b", "#1f77b4"]
    },
    marks: [
      // Waterfall bars (hourly) - left y-axis
      Plot.rect(hoursData, {
        x1: "hour",
        x2: d => d.hour + 1,
        y1: "low",
        y2: "high",
        fill: "lightgreen",
        opacity: 0.6
      }),
      
      // Zero line for waterfall
      Plot.ruleY([0], {stroke: "#000", strokeDasharray: "1,2"}),
      
      // Line chart (minute data)
      Plot.line(minuteDataProcessed, {
        x: "hourFraction",
        y: "traj",
        stroke: "steelblue",
        strokeWidth: 2,
        opacity: 0.9,
      })
    ]
  })
```

The chart shows:
- **Waterfall bars** (hourly): Cumulative net aFRR energy throughout the day
- **Line overlay** (minute): Real-time aFRR power fluctuations
- **Green bars**: Positive balancing energy (charging/upward regulation)
- **Red bars**: Negative balancing energy (discharging/downward regulation)


