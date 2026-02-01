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

```js
// Load hourly schedules and filter for selected scenario

const allHourly = await FileAttachment(
  "data/all_scenarios_hourly_schedules.parquet",
).parquet();

const hourlyArray = allHourly.toArray();

const schedules = hourlyArray.filter(d => 
  d.Q_aFRR_pct === qaFRR &&
  d.n_charge_hours === chargeHours && 
  d.n_discharge_hours === dischargeHours)
.map((d) => {
  const datetime = new Date(d.date);
  datetime.setHours(d.hour, 0, 0, 0);
  return {
    trading_MW: +d.trading_MW || 0,
    aFRR_charge: +d.aFRR_charge || 0,
    aFRR_discharge: +d.aFRR_discharge || 0,
    restore_MW: +d.restore_MW || 0,
    imbalance_MWh: +d.imbalance_MWh || 0,
    SOC_end_MWh: +d.SOC_end_MWh || 0,
    datetime: datetime,
    dispatch_mode: d.dispatch_mode,
  };
});
```

Select the time period to display:

```js
const dateExtent = d3.extent(schedules, (d) => d.datetime);

const startDate = view(
  Inputs.date({
    label: "Start Date",
    value: new Date("2023-01-01"),
  }),
);

const endDate = view(
  Inputs.date({
    label: "End Date",
    value: new Date("2023-01-08"),
  }),
);
```

```js
// Filter data based on selected date range

const schedules_filtered = schedules.filter(
  (d) => d.datetime >= startDate && d.datetime <= endDate,
);

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
const yDomain = [Math.min(0, ...allNegative), Math.max(0, ...allPositive)];
```

## State of Charge (SOC) Comparison

Battery energy capacity: 100 MWh

```js
const p1 = Plot.plot({
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
});

display(p1)
```

## Energy Flows Comparison

```js
const selectedFlowTypes = view(
  Inputs.checkbox(["Trading", "Balancing", "Restoration", "Imbalance"], {
    label: "Select flow types to show: ",
    value: ["Trading", "Balancing", "Restoration", "Imbalance"],
  }),
);
```

### Energy Flows by Dispatch Mode

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

const extHours = d3.timeHour.count(startDate, endDate);
const hoursToDisplay =
  extHours / 24 <= 1 ? 3 : extHours / (24 * 7) <= 1 ? 12 : 24;

```

```js
const p2 = Plot.plot({
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
    domain: yDomain,
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
});

display(p2)
```
