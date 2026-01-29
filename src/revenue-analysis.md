# Revenue Analysis

## Load Data

```js
const schedule_opt = await FileAttachment("data/optimized_monthly.csv").csv({typed: true});
const schedule_rct = await FileAttachment("data/reactive_monthly.csv").csv({typed: true});
```

```js
const optimized = schedule_opt.map(d => ({
  month: new Date(d.month),
  total_revenue: +d.grand_total_eur_per_mw || 0,
  aFRR: +d.aFRR_total_eur_per_mw || 0,
  balancing: +d.balancing_total_eur_per_mw || 0,
  IDM: +d.IDM_total_eur_per_mw || 0,
  trading: +d.trading_total_eur_per_mw || 0,
  imbalance: +d.imbalance_total_eur_per_mw || 0,
  model: "Optimized"
}));

const reactive = schedule_rct.map(d => ({
  month: new Date(d.month),
  total_revenue: +d.grand_total_eur_per_mw || 0,
  aFRR: +d.aFRR_total_eur_per_mw || 0,
  balancing: +d.balancing_total_eur_per_mw || 0,
  IDM: +d.IDM_total_eur_per_mw || 0,
  trading: +d.trading_total_eur_per_mw || 0,
  imbalance: +d.imbalance_total_eur_per_mw || 0,
  model: "Reactive"
}));

// Combine both datasets for plotting
const combined = [...optimized, ...reactive];

// Prepare data for revenue breakdown chart
const revenueBreakdown = optimized.flatMap(d => [
  {month: d.month, component: "aFRR", value: d.aFRR, model: "Optimized"},
  {month: d.month, component: "Balancing", value: d.balancing, model: "Optimized"},
  {month: d.month, component: "Restoration", value: d.IDM, model: "Optimized"},
  {month: d.month, component: "Trading", value: d.trading, model: "Optimized"},
  {month: d.month, component: "Imbalance", value: d.imbalance, model: "Optimized"}
]).concat(reactive.flatMap(d => [
  {month: d.month, component: "aFRR", value: d.aFRR, model: "Reactive"},
  {month: d.month, component: "Balancing", value: d.balancing, model: "Reactive"},
  {month: d.month, component: "Restoration", value: d.IDM, model: "Reactive"},
  {month: d.month, component: "Trading", value: d.trading, model: "Reactive"},
  {month: d.month, component: "Imbalance", value: d.imbalance, model: "Reactive"}
]));
```

## Annual Revenues

```js
// Calculate revenue by year, model, and component
const yearlyRevenueBreakdown = revenueBreakdown.map(d => ({
  year: d.month.getFullYear(),
  model: d.model,
  component: d.component,
  value: d.value
}));

const yearlyAggregated = d3.rollup(
  yearlyRevenueBreakdown,
  v => d3.sum(v, d => d.value),
  d => d.year,
  d => d.model,
  d => d.component
);

// Transform to flat array
const yearlyData = [];
for (const [year, models] of yearlyAggregated) {
  for (const [model, components] of models) {
    for (const [component, value] of components) {
      yearlyData.push({year: year, model: model, component: component, value: value});
    }
  }
}

// Calculate totals for each year-model combination
const yearlyTotals = d3.rollup(
  yearlyData,
  v => d3.sum(v, d => d.value),
  d => d.year,
  d => d.model
);

const totalData = [];
for (const [year, models] of yearlyTotals) {
  for (const [model, total] of models) {
    totalData.push({year: year, model: model, total: total});
  }
}
```

```js
Plot.plot({
  marks: [
    Plot.barY(yearlyData, {
      x: "model",
      y: "value",
      fill: "component",
      fx: "year",
      tip: true
    }),
    Plot.dot(totalData, {
      x: "model",
      y: "total",
      fx: "year",
      fill: "white",
      stroke: "black",
      strokeWidth: 2,
      r: 5
    }),
    Plot.text(totalData, {
      x: "model",
      y: "total",
      fx: "year",
      text: d => `${(d.total / 1000).toFixed(0)}k`,
      dy: -15,
      fontSize: 11,
      fontWeight: "bold"
    }),
    Plot.ruleY([0])
  ],
  x: {
    label: "",
    tickFormat: d => d.toString()
  },
  fx: {
    label: null,
    tickFormat: d => d.toString()
  },
  y: {
    label: "EUR / MW",
    grid: true
  },
  color: {
    domain: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
    range: ["#2ca02c", "#17becf", "#9467bd", "#1f77b4", "#ff7f0e"],
    legend: true
  },
  width: 1000,
  height: 400,
  marginLeft: 80
})
```

## Monthly Revenues

```js
Plot.plot({
  marks: [
    Plot.line(reactive, {
      x: "month",
      y: "total_revenue",
      stroke: "#E63946",
      strokeWidth: 2,
      tip: true
    }),
    Plot.line(optimized, {
      x: "month",
      y: "total_revenue",
      stroke: "#06A77D",
      strokeWidth: 2,
      tip: true
    }),
    Plot.ruleY([0])
  ],
  x: {
    label: "Month",
    ticks: d3.utcMonth.every(3)
  },
  y: {
    label: "EUR / MW",
    grid: true
  },
  color: {
    domain: ["Reactive", "Optimized"],
    range: ["#E63946", "#06A77D"],
    legend: true
  },
  width: 1000,
  height: 400,
  marginLeft: 80
})
```

## Monthly Revenues Breakdown by Component

```js
const selectedComponents = view(Inputs.checkbox(
  ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
  {
    label: "Select revenue sources to show: ",
    value: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"]
  }
));
```

```js
// Calculate shared y-axis domain from ALL data (stacked totals per month/model)
// Handle positive and negative stacking separately
const stackedTotals = d3.rollup(
  revenueBreakdown,
  v => ({
    positive: d3.sum(v.filter(d => d.value > 0), d => d.value),
    negative: d3.sum(v.filter(d => d.value < 0), d => d.value)
  }),
  d => `${d.month}-${d.model}`
);
const allPositive = Array.from(stackedTotals.values()).map(d => d.positive);
const allNegative = Array.from(stackedTotals.values()).map(d => d.negative);
const revenueDomain = [Math.min(0, ...allNegative), Math.max(0, ...allPositive)];

// Filter revenue breakdown by selected components
const filteredRevenueBreakdown = revenueBreakdown.filter(d => selectedComponents.includes(d.component));
```

### Reactive Model

```js
Plot.plot({
  marks: [
    Plot.barY(filteredRevenueBreakdown.filter(d => d.model === "Reactive"), {
      x: "month",
      y: "value",
      fill: "component",
      tip: true
    }),
    Plot.ruleY([0])
  ],
  x: {
    label: "Month",
    ticks: d3.utcMonth.every(3)
  },
  y: {
    label: "EUR / MW",
    domain: revenueDomain,
    grid: true
  },
  color: {
    domain: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
    range: ["#2ca02c", "#17becf", "#9467bd", "#1f77b4", "#ff7f0e"],
    legend: true
  },
  width: 1000,
  height: 400,
  marginLeft: 80
})
```

### Optimized Model

```js
Plot.plot({
  marks: [
    Plot.barY(filteredRevenueBreakdown.filter(d => d.model === "Optimized"), {
      x: "month",
      y: "value",
      fill: "component",
      tip: true
    }),
    Plot.ruleY([0])
  ],
  x: {
    label: "Month",
    ticks: d3.utcMonth.every(3)
  },
  y: {
    label: "EUR / MW",
    domain: revenueDomain,
    grid: true,
  },
  color: {
    domain: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
    range: ["#2ca02c", "#17becf", "#9467bd", "#1f77b4", "#ff7f0e"],
    legend: true
  },
  width: 1000,
  height: 400,
  marginLeft: 80
})
```
