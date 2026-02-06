# Revenues

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
// Load monthly data and filter for selected scenario

const allMonthly = await FileAttachment(
  "data/combined_monthly_summaries.parquet",
).parquet();
const monthlyArray = allMonthly.toArray();

const scenarioMonthly = monthlyArray
  .filter(
    (d) =>
      d.Q_aFRR_pct === qaFRR &&
      d.n_charge_hours === chargeHours &&
      d.n_discharge_hours === dischargeHours,
  )
  .map((d) => ({
    month: new Date(d.month),
    dispatch_mode: d.dispatch_mode,
    model: d.dispatch_mode === "optimized" ? "Optimized" : "Reactive",
    total_revenue: +d.grand_total_eur_per_mw || 0,
    net_revenue: +d.net_revenue_eur_per_mw || 0,
    aFRR: +d.aFRR_total_eur_per_mw || 0,
    balancing: +d.balancing_total_eur_per_mw || 0,
    IDM: +d.IDM_total_eur_per_mw || 0,
    trading: +d.trading_total_eur_per_mw || 0,
    imbalance: +d.imbalance_total_eur_per_mw || 0,
    degradation: +d.degradation_cost_eur_per_mw || 0,
    hours_provided_pct: +d.hours_provided / +d.hours_in_month,
  }));

// Prepare data for revenue breakdown chart

const revenueBreakdown = scenarioMonthly.flatMap((d) => [
  { month: d.month, component: "aFRR", value: d.aFRR, model: d.model },
  {
    month: d.month,
    component: "Balancing",
    value: d.balancing,
    model: d.model,
  },
  { month: d.month, component: "Restoration", value: d.IDM, model: d.model },
  { month: d.month, component: "Trading", value: d.trading, model: d.model },
  {
    month: d.month,
    component: "Imbalance",
    value: d.imbalance,
    model: d.model,
  },
]);

const netRevenueBreakdown = scenarioMonthly.flatMap((d) => [
  { month: d.month, component: "aFRR", value: d.aFRR, model: d.model },
  {
    month: d.month,
    component: "Balancing",
    value: d.balancing,
    model: d.model,
  },
  { month: d.month, component: "Restoration", value: d.IDM, model: d.model },
  { month: d.month, component: "Trading", value: d.trading, model: d.model },
  {
    month: d.month,
    component: "Imbalance",
    value: d.imbalance,
    model: d.model,
  },
  {
    month: d.month,
    component: "Degradation",
    value: -d.degradation,
    model: d.model,
  },
]);

```

## Annual gross revenue breakdown

```js
// Calculate months per year for adjustment factor
const monthsPerYear = d3.rollup(
  scenarioMonthly,
  (v) => new Set(v.map((d) => d.month.getTime())).size,
  (d) => d.month.getFullYear(),
);

// Aggregate gross revenue by year, model, and component with adjustment
const yearlyGrossAggregated = d3.rollup(
  revenueBreakdown,
  (v) => {
    const sum = d3.sum(v, (d) => d.value);
    const year = v[0].month.getFullYear();
    const adjustmentFactor = 12 / (monthsPerYear.get(year) || 12);
    return sum * adjustmentFactor;
  },
  (d) => d.month.getFullYear(),
  (d) => d.model,
  (d) => d.component,
);

// Flatten to array for plotting
const yearlyGrossData = Array.from(yearlyGrossAggregated, ([year, models]) =>
  Array.from(models, ([model, components]) =>
    Array.from(components, ([component, value]) => ({
      year,
      model,
      component,
      value
    }))
  )
).flat(2);

// Calculate totals for each year-model combination
const totalGrossData = Array.from(
  d3.rollup(
    yearlyGrossData,
    (v) => d3.sum(v, (d) => d.value),
    (d) => d.year,
    (d) => d.model,
  ),
  ([year, models]) =>
    Array.from(models, ([model, total]) => ({ year, model, total }))
).flat();
```

```js
Plot.plot({
    marks: [
      Plot.barY(yearlyGrossData, {
        x: "model",
        y: "value",
        fill: "component",
        fx: "year",
        tip: {
          format: {
            y: d3.format(",.0f"),
            fx: false,
          },
          channels: {
            "Year:": (d) => String(d.year)
          },
        },
      }),
      Plot.dot(totalGrossData, {
        x: "model",
        y: "total",
        fx: "year",
        fill: "white",
        stroke: "black",
        strokeWidth: 2,
        r: 5,
      }),
      Plot.text(totalGrossData, {
        x: "model",
        y: "total",
        fx: "year",
        text: (d) => `${(d.total / 1000).toFixed(0)}k`,
        dy: 13,
        fontSize: 11,
        fontWeight: "bold",
        fill: "white",
      }),
      Plot.ruleY([0]),
    ],
    x: {
      label: "",
      tickFormat: (d) => d.toString(),
    },
    fx: {
      label: null,
      tickFormat: (d) => d.toString(),
    },
    y: {
      label: "Gross Revenue (EUR)",
      grid: true
    },
    color: {
      domain: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
      range: ["#2ca02c", "#17becf", "#9467bd", "#1f77b4", "#ff7f0e"],
      legend: true,
    },
    width: 1000,
    height: 400,
    marginLeft: 80,
    marginBottom: 40,
    caption:
      "Note: 2025 data is for 9 months. Annual total adjusted for comparison",
  })
```

## Annual net revenue breakdown

```js
// Aggregate net revenue by year, model, and component with adjustment

const yearlyNetAggregated = d3.rollup(
  netRevenueBreakdown,
  (v) => {
    const sum = d3.sum(v, (d) => d.value);
    const year = v[0].month.getFullYear();
    const adjustmentFactor = 12 / (monthsPerYear.get(year) || 12);
    return sum * adjustmentFactor;
  },
  (d) => d.month.getFullYear(),
  (d) => d.model,
  (d) => d.component,
);

// Flatten to array for plotting

const yearlyNetData = Array.from(yearlyNetAggregated, ([year, models]) =>
  Array.from(models, ([model, components]) =>
    Array.from(components, ([component, value]) => ({
      year,
      model,
      component,
      value
    }))
  )
).flat(2);

// Calculate totals for each year-model combination

const totalNetData = Array.from(
  d3.rollup(
    yearlyNetData,
    (v) => d3.sum(v, (d) => d.value),
    (d) => d.year,
    (d) => d.model,
  ),
  ([year, models]) =>
    Array.from(models, ([model, total]) => ({ year, model, total }))
).flat();
```

```js
Plot.plot({
    marks: [
      Plot.barY(yearlyNetData, {
        x: "model",
        y: "value",
        fill: "component",
        fx: "year",
        tip: {
          format: {
            y: d3.format(",.0f"),
            fx: false,
          },
          channels: {
            "Year:": (d) => String(d.year)
          },
        },
      }),
      Plot.dot(totalNetData, {
        x: "model",
        y: "total",
        fx: "year",
        fill: "white",
        stroke: "black",
        strokeWidth: 2,
        r: 5,
      }),
      Plot.text(totalNetData, {
        x: "model",
        y: "total",
        fx: "year",
        text: (d) => `${(d.total / 1000).toFixed(0)}k`,
        dy: 13,
        fontSize: 11,
        fontWeight: "bold",
        fill: "white",
      }),
      Plot.ruleY([0]),
    ],
    x: {
      label: "",
      tickFormat: (d) => d.toString(),
    },
    fx: {
      label: null,
      tickFormat: (d) => d.toString(),
    },
    y: {
      label: "Net Revenue (EUR)",
      grid: true
    },
    color: {
      domain: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance", "Degradation"],
      range: ["#2ca02c", "#17becf", "#9467bd", "#1f77b4", "#ff7f0e", "#d62728"],
      legend: true,
    },
    width: 1000,
    height: 400,
    marginLeft: 80,
    marginBottom: 40,
    caption:
      "Note: 2025 data is for 9 months. Annual total adjusted for comparison",
  })
```

## Monthly revenues

```js
Plot.plot({
    marks: [
      Plot.line(scenarioMonthly, {
        x: "month",
        y: "total_revenue",
        stroke: "model",
        strokeWidth: 2,
        curve: "catmull-rom",
        tip: true,
      }),
      Plot.ruleY([0]),
    ],
    x: {
      label: "",
      ticks: d3.utcMonth.every(3),
    },
    y: {
      label: "Monthly Revenue (EUR)",
      grid: true,
      tickFormat: d3.format(",.0f")
    },
    color: {
      domain: ["Reactive", "Optimized"],
      range: ["#E63946", "#06A77D"],
      legend: true,
    },
    width: 1000,
    height: 400,
    marginLeft: 80,
    marginBottom: 40,
  })
```

## Hours aFRR service provided

```js
Plot.plot({
    marks: [
      Plot.line(scenarioMonthly, {
        x: "month",
        y: "hours_provided_pct",
        stroke: "model",
        strokeWidth: 2,
        curve: "catmull-rom",
        tip: true,
      }),
    ],
    x: {
      label: "",
      ticks: d3.utcMonth.every(3),
    },
    y: {
      label: "Pct provided",
      tickFormat: (d) => d3.format(".0%")(d),
      grid: true,
    },
    color: {
      domain: ["Reactive", "Optimized"],
      range: ["#E63946", "#06A77D"],
      legend: true,
    },
    width: 1000,
    height: 400,
    marginLeft: 80,
    marginBottom: 40,
  })
```

## Monthly revenues breakdown by component

```js
const selectedComponents = view(
  Inputs.checkbox(
    ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
    {
      label: "Select revenue sources to show: ",
      value: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
    },
  ),
);
```

```js
// Calculate shared y-axis domain from ALL data (stacked totals per month/model)
// Handle positive and negative stacking separately

const stackedTotals = d3.rollup(
  revenueBreakdown,
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
  (d) => `${d.month}-${d.model}`,
);
const allPositive = Array.from(stackedTotals.values()).map((d) => d.positive);
const allNegative = Array.from(stackedTotals.values()).map((d) => d.negative);
const revenueDomain = [
  Math.min(0, ...allNegative),
  Math.max(0, ...allPositive),
];

// Filter revenue breakdown by selected components

const filteredRevenueBreakdown = revenueBreakdown.filter((d) =>
  selectedComponents.includes(d.component),
);

```

```js
Plot.plot({
  marginBottom: 40,
  marginRight: 70,
  marks: [
    Plot.barY(
      filteredRevenueBreakdown,
      {
        x: "month",
        y: "value",
        fy: "model",
        fill: "component",
        tip: {
          format: {
            y: d3.format(",.0f"),
            fy: true,
          }
        }
      },
    ),
    Plot.ruleY([0]),
  ],
  x: {
    label: "",
    ticks: d3.utcMonth.every(3),
  },
  y: {
    label: "Revenue (EUR)",
    domain: revenueDomain,
    grid: true,
  },
  color: {
    domain: ["aFRR", "Balancing", "Restoration", "Trading", "Imbalance"],
    range: ["#2ca02c", "#17becf", "#9467bd", "#1f77b4", "#ff7f0e"],
    legend: true,
  },
  fy: {
    label: ""
  },
  width: 1000,
  height: 800,
  marginLeft: 80,
})
```
