# Energy Flow Analysis

```js
// Load battery optimization schedules
const schedule_opt = await FileAttachment("data/optimized_schedule.csv").csv({typed: true});
const schedule_rct = await FileAttachment("data/reactive_schedule.csv").csv({typed: true});
```

```js
// Parse dates and add datetime field
const optimized = schedule_opt.map(d => {
  const datetime = new Date(d.date);
  datetime.setHours(d.hour, 0, 0, 0);
  return {
    trading_MW: +d.trading_MW || 0,
    net_aFRR: +d.net_aFRR || 0,
    restore_MW: +d.restore_MW || 0,
    imbalance_MWh: +d.imbalance_MWh || 0,
    SOC_end_MWh: +d.SOC_end_MWh || 0,
    datetime: datetime
  };
});

const reactive = schedule_rct.map(d => {
  const datetime = new Date(d.date);
  datetime.setHours(d.hour, 0, 0, 0);
  return {
    trading_MW: +d.trading_MW || 0,
    net_aFRR: +d.net_aFRR || 0,
    restore_MW: +d.restore_MW || 0,
    imbalance_MWh: +d.imbalance_MWh || 0,
    SOC_end_MWh: +d.SOC_end_MWh || 0,
    datetime: datetime
  };
});
```

Select the time period to display:

```js
const dateExtent = d3.extent([...optimized, ...reactive], d => d.datetime);

const startDate = view(Inputs.date({
  label: "Start Date",
  value: new Date("2023-01-01")
}));

const endDate = view(Inputs.date({
  label: "End Date", 
  value: new Date("2023-01-08")
}));
```

```js
// Filter data based on selected date range
const optimized_filtered = optimized.filter(d => d.datetime >= startDate && d.datetime <= endDate);
const reactive_filtered = reactive.filter(d => d.datetime >= startDate && d.datetime <= endDate);

// Transform to long format for domain calculation (using FILTERED data)
const flowsBreakdown = [
  ...reactive_filtered.flatMap(d => [
    {datetime: d.datetime, type: "Trading", value: d.trading_MW, model: "Reactive"},
    {datetime: d.datetime, type: "Balancing", value: d.net_aFRR, model: "Reactive"},
    {datetime: d.datetime, type: "Restoration", value: d.restore_MW, model: "Reactive"},
    {datetime: d.datetime, type: "Imbalance", value: d.imbalance_MWh, model: "Reactive"}
  ]),
  ...optimized_filtered.flatMap(d => [
    {datetime: d.datetime, type: "Trading", value: d.trading_MW, model: "Optimized"},
    {datetime: d.datetime, type: "Balancing", value: d.net_aFRR, model: "Optimized"},
    {datetime: d.datetime, type: "Restoration", value: d.restore_MW, model: "Optimized"},
    {datetime: d.datetime, type: "Imbalance", value: d.imbalance_MWh, model: "Optimized"}
  ])
];

// Calculate shared y-axis domain from filtered data
const stackedTotals = d3.rollup(
  flowsBreakdown,
  v => ({
    positive: d3.sum(v.filter(d => d.value > 0), d => d.value),
    negative: d3.sum(v.filter(d => d.value < 0), d => d.value)
  }),
  d => `${d.datetime}-${d.model}`
);
const allPositive = Array.from(stackedTotals.values()).map(d => d.positive);
const allNegative = Array.from(stackedTotals.values()).map(d => d.negative);
const yDomain = [Math.min(0, ...allNegative), Math.max(0, ...allPositive)];
```

## State of Charge (SOC) Comparison

Battery capacity: 150 MWh

```js
Plot.plot({
  marks: [
    // SOC lines
    Plot.line(reactive_filtered, {
    x: "datetime",
    y: "SOC_end_MWh",
    stroke: "#E63946",
    strokeWidth: 2,
    curve: "step-before"
    }),
    Plot.line(optimized_filtered, {
      x: "datetime",
      y: "SOC_end_MWh",
      stroke: "#06A77D",
      strokeWidth: 2,
      curve: "step-before"
    }),
    // Capacity bounds
    Plot.ruleY([150], {stroke: "red", strokeDasharray: "4 4"}),
    Plot.ruleY([0], {stroke: "blue", strokeDasharray: "4 4"}),
  ],
  x: {
    label: ""
  },
  y: {
    label: "State of Charge (MWh)",
    domain: [0, 155],
    grid: true
  },
  width: 1000,
  height: 500,
  marginLeft: 60
})
```

## Energy Flows Comparison

```js
const selectedFlowTypes = view(Inputs.checkbox(
  ["Trading", "Balancing", "Restoration", "Imbalance"],
  {
    label: "Select flow types to show: ",
    value: ["Trading", "Balancing", "Restoration", "Imbalance"]
  }
));
```

### Reactive Model

```js
// Prepare data for stacked bar chart
const flows_reactive = reactive_filtered.flatMap(d => [
  {datetime: d.datetime, type: "Trading", value: d.trading_MW},
  {datetime: d.datetime, type: "Balancing", value: d.net_aFRR},
  {datetime: d.datetime, type: "Restoration", value: d.restore_MW},
  {datetime: d.datetime, type: "Imbalance", value: d.imbalance_MWh}
]).filter(d => selectedFlowTypes.includes(d.type));

const extHours = d3.timeHour.count(startDate, endDate)

const hoursToDisplay = extHours / 24 <= 1 ? 3 : extHours / (24 * 7) <= 1 ? 12 : 24;
```

```js
Plot.plot({
  marks: [
    Plot.barY(flows_reactive, {
      x: "datetime",
      y: "value",
      fill: "type",
      tip: true,
      title: d => `${d.type}: ${d.value.toFixed(2)} MWh`
    }),
    Plot.ruleY([0])
  ],
  x: {
    label: "",
    ticks: d3.utcHour.every(hoursToDisplay)
  },
  y: {
    label: "Energy Flow (MWh)",
    domain: yDomain,
    grid: true
  },
  color: {
    domain: ["Trading", "Balancing", "Restoration", "Imbalance"],
    range: ["#1f77b4", "#17becf", "#9467bd", "#ff7f0e"],
    legend: true
  },
  width: 1000,
  height: 400,
  marginLeft: 60
})
```

### Optimized Model

```js
// Prepare data for stacked bar chart
const flows_optimized = optimized_filtered.flatMap(d => [
  {datetime: d.datetime, type: "Trading", value: d.trading_MW},
  {datetime: d.datetime, type: "Balancing", value: d.net_aFRR},
  {datetime: d.datetime, type: "Restoration", value: d.restore_MW},
  {datetime: d.datetime, type: "Imbalance", value: d.imbalance_MWh}
]).filter(d => selectedFlowTypes.includes(d.type));
```

```js
Plot.plot({
  marks: [
    Plot.barY(flows_optimized, {
      x: "datetime",
      y: "value",
      fill: "type",
      tip: true,
      title: d => `${d.type}: ${d.value.toFixed(2)} MWh`
    }),
    Plot.ruleY([0])
  ],
  x: {
    label: "",
    ticks: d3.utcHour.every(hoursToDisplay)
  },
  y: {
    label: "Energy Flow (MWh)",
    domain: yDomain,
    grid: true
  },
  color: {
    domain: ["Trading", "Balancing", "Restoration", "Imbalance"],
    range: ["#1f77b4", "#17becf", "#9467bd", "#ff7f0e"],
    legend: true
  },
  width: 1000,
  height: 400,
  marginLeft: 60
})
```


