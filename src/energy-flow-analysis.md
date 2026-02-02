# Energy Flow Analysis

```js
// Define inputs directly
const qaFRR = view(Inputs.select([0.3, 0.4, 0.5, 0.6, 0.7], {
  label: "Share of capacity allocated to aFRR",
  value: 0.5,
  format: (d) => `${Math.round(d * 100)}%`
}));

const chargeHours = view(Inputs.select([1, 2, 3], {
  label: "Trading # charge hours",
  value: 2
}));

const dischargeHours = view(Inputs.select([1, 2, 3, 4], {
  label: "Trading # discharge hours",
  value: 2
}));
```

---

## Monthly Energy Flow

```js
// Load pre-aggregated monthly summaries

const allMonthlyFlows = await FileAttachment("data/monthly-flow-summaries.json").json();

// Calculate fixed y-axis domain from ALL scenarios

const maxTotal = d3.max(allMonthlyFlows, d => d.total);
const monthlyYDomain = [0, maxTotal];

// Filter for selected scenario

const monthlyData = allMonthlyFlows
  .filter(d => 
    d.Q_aFRR_pct === qaFRR &&
    d.n_charge_hours === chargeHours && 
    d.n_discharge_hours === dischargeHours
  )
  .map(d => ({
    ...d,
    month: new Date(d.month)
  }));

```

### Monthly Charging/Discharging by Flow Type

```js
Plot.plot({
  marginRight: 80,
  marginLeft: 80,
  marginTop: 40,
  height: 600,
  width: 1000,
  marks: [
    Plot.barY(monthlyData, {
      fx: "month",
      y: "total",
      fill: "direction",
      x: "direction",
      fy: "flowType",
      tip: true
    }),
    Plot.ruleY([0])
  ],
  fx: {
    label: "",
    ticks: d3.utcMonth.every(3)
  },
  y: {
    label: "MWh",
    domain: monthlyYDomain,
    grid: true
  },
  fy: {
    label: ""
  },
  color: {
    domain: ["Charging", "Discharging"],
    range: ["#4CAF50", "#FF5722"],
    legend: true
  },
  x : {
    label: null,
    tickFormat: () => "",
    ticks: []
  }
})
```

---

## Hourly Energy Flow

**Note:** This section displays data for the first week of January 2023 (01.01.2023 - 08.01.2023) as a sample.

```js
// Load pre-filtered first week data (2023-01-01 to 2023-01-08)
const allSchedules = await FileAttachment("data/energy-flow-first-week.json").json();

const schedules_filtered = allSchedules
  .filter(d => 
    d.Q_aFRR_pct === qaFRR &&
    d.n_charge_hours === chargeHours && 
    d.n_discharge_hours === dischargeHours
  )
  .map(d => ({
    ...d,
    datetime: new Date(d.datetime)
  }));

// Transform to long format for domain calculation

const flowsBreakdown = schedules_filtered.flatMap((d) => [
  {
    datetime: d.datetime,
    type: "Trading",
    value: d.trading_MW,
    model: d.dispatch_mode,
  },
  {
    datetime: d.datetime,
    type: "Balancing",
    value: d.aFRR_charge,
    model: d.dispatch_mode,
  },
  {
    datetime: d.datetime,
    type: "Balancing",
    value: -d.aFRR_discharge,
    model: d.dispatch_mode,
  },
  {
    datetime: d.datetime,
    type: "Restoration",
    value: d.restore_MW,
    model: d.dispatch_mode,
  },
  {
    datetime: d.datetime,
    type: "Imbalance",
    value: d.imbalance_MWh,
    model: d.dispatch_mode,
  },
]);

// Calculate shared y-axis domain from filtered data

const stackedTotals = d3.rollup(
  flowsBreakdown,
  (v) => ({
    positive: d3.sum(
      v.filter((d) => d.value > 0),
      (d) => d.value,
    ),
    negative: d3.sum(
      v.filter((d) => d.value < 0),
      (d) => d.value,
    ),
  }),
  (d) => `${d.datetime}-${d.model}`,
);

const allPositive = Array.from(stackedTotals.values()).map((d) => d.positive);
const allNegative = Array.from(stackedTotals.values()).map((d) => d.negative);
const hourlyYDomain = [Math.min(0, ...allNegative), Math.max(0, ...allPositive)];
```

### State of charge (SOC) by dispatch mode

Battery energy capacity: 100 MWh

```js
Plot.plot({
  marks: [
    // SOC lines by dispatch mode
    Plot.line(schedules_filtered, {
      x: "datetime",
      y: "SOC_end_MWh",
      stroke: "dispatch_mode",
      strokeWidth: 2,
      curve: "step-before",
    }),
    // Capacity bounds
    Plot.ruleY([100], { stroke: "red", strokeDasharray: "4 4" }),
    Plot.ruleY([0], { stroke: "blue", strokeDasharray: "4 4" }),
  ],
  x: {
    label: "",
  },
  y: {
    label: "State of Charge (MWh)",
    domain: [0, 105],
    grid: true,
  },
  color: {
    legend: true,
  },
  width: 1000,
  height: 500,
  marginLeft: 60,
  marginBottom: 40,
})
```

### Energy flows by dispatch mode

```js
const selectedFlowTypes = view(
  Inputs.checkbox(["Trading", "Balancing", "Restoration", "Imbalance"], {
    label: "Select flow types to show: ",
    value: ["Trading", "Balancing", "Restoration", "Imbalance"],
  }),
);
```

```js
// Prepare data for stacked bar chart

const flows_stacked = schedules_filtered
  .flatMap((d) => [
    {
      datetime: d.datetime,
      type: "Balancing",
      value: d.aFRR_charge,
      model: d.dispatch_mode,
    },
    {
      datetime: d.datetime,
      type: "Balancing",
      value: -d.aFRR_discharge,
      model: d.dispatch_mode,
    },
    {
      datetime: d.datetime,
      type: "Trading",
      value: d.trading_MW,
      model: d.dispatch_mode,
    },
    {
      datetime: d.datetime,
      type: "Restoration",
      value: d.restore_MW,
      model: d.dispatch_mode,
    },
    {
      datetime: d.datetime,
      type: "Imbalance",
      value: d.imbalance_MWh,
      model: d.dispatch_mode,
    },
  ])
  .filter((d) => selectedFlowTypes.includes(d.type));

const dateExtent = d3.extent(schedules_filtered, (d) => d.datetime);
const extHours = d3.timeHour.count(dateExtent[0], dateExtent[1]);
const hoursToDisplay =
  extHours / 24 <= 1 ? 3 : extHours / (24 * 7) <= 1 ? 12 : 24;
```

```js
Plot.plot({
  marks: [
    Plot.barY(flows_stacked, {
      x: "datetime",
      y: "value",
      fy: "model",
      fill: "type",
      tip: true,
      title: (d) => `${d.type}: ${d.value.toFixed(2)} MWh \nHour: ${d.datetime.getUTCHours()}`,
    }),
    Plot.ruleY([0]),
  ],
  x: {
    label: "",
    ticks: d3.utcHour.every(hoursToDisplay),
  },
  y: {
    label: "Energy Flow (MWh)",
    domain: hourlyYDomain,
    grid: true,
  },
  fy: {
    label: null,
  },
  color: {
    domain: ["Trading", "Balancing", "Restoration", "Imbalance"],
    range: ["#1f77b4", "#17becf", "#9467bd", "#ff7f0e"],
    legend: true,
  },
  width: 1000,
  height: 800,
  marginLeft: 60,
  marginRight: 70,
  marginBottom: 40,
})
```
