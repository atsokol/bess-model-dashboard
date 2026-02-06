# Scenario Comparison


## Average Monthly Revenue vs aFRR Capacity Allocation

This chart compares all scenarios across different aFRR capacity allocations and trading hour configurations.

```js
// Load all monthly data

const allMonthly = await FileAttachment(
  "data/combined_monthly_summaries.parquet",
).parquet();

const monthlyArray = allMonthly.toArray();
```

```js
// Calculate average monthly revenue for each scenario

const scenarioData = d3
  .flatRollup(
    monthlyArray,
    (v) => ({
      grossRevenue: d3.mean(v, (d) => d.grand_total_eur_per_mw),
      netRevenue: d3.mean(v, (d) => d.net_revenue_eur_per_mw),
      pctProvided: d3.mean(v, (d) => +d.hours_provided / +d.hours_in_month),
      avgRestorationCost: d3.mean(v, (d) => d.IDM_total_eur_per_mw || 0),
    }),
    (d) => d.Q_aFRR_pct,
    (d) => d.n_charge_hours,
    (d) => d.n_discharge_hours,
    (d) => d.dispatch_mode,
    (d) => d.scenario_id,
  )
  .map(([Q_aFRR, n_charge, n_discharge, dispatch, scenario, dat]) => ({
    Q_aFRR,
    n_charge,
    n_discharge,
    dispatch,
    scenario,
    grossRevenue: dat.grossRevenue,
    netRevenue: dat.netRevenue,
    pctProvided: dat.pctProvided,
    avgRestorationCost: dat.avgRestorationCost,
    totalTradingHours: n_charge + n_discharge,
  }));

```

```js
// Calculate shared domain across both facets

const grossRevenueExtent = d3.extent(scenarioData, (d) => d.grossRevenue);
const netRevenueExtent = d3.extent(scenarioData, (d) => d.netRevenue);
const pctExtent = d3.extent(scenarioData, (d) => d.pctProvided);
```

### Gross revenue by share of capacity allocated to aFRR
```js
Plot.plot({
    marks: [
      Plot.dot(scenarioData, {
        x: "pctProvided",
        y: "grossRevenue",
        fx: "dispatch",
        stroke: "Q_aFRR",
        r: (d) => d.n_charge + d.n_discharge,
        tip: {
          format: {
            x: false,
            y: false,
            fill: false,
            r: false,
            fx: false,
          },
        },
        channels: {
          "aFRR % capacity:": (d) => d3.format(".0%")(d.Q_aFRR),
          "Trading hours:": (d) => `C${d.n_charge}D${d.n_discharge}`,
          Revenue: (d) => `€${d3.format(",.0f")(d.grossRevenue)}`,
          "% provided": (d) => d3.format(".1%")(d.pctProvided),
        },
      })
    ],
    x: {
      label: "aFRR service provided (%)",
      domain: pctExtent,
      tickFormat: d3.format(".0%"),
    },
    y: {
      label: "Monthly revenue (EUR / MW)",
      domain: grossRevenueExtent,
      grid: true,
      ticks: 10,
    },
    fx: {
      label: null,
    },
    color: {
      legend: true,
      type: "categorical",
      tickFormat: d3.format(".0%"),
    },
    r: {
      domain: [2, 8],
      range: [4, 8]
    },
    symbol: {legend: true},
    width: 1000,
    height: 500,
    marginLeft: 100,
    marginBottom: 60,
    caption: "Size of circle is proportionate to total trading hours"
  })
```

### Net revenue by share of capacity allocated to aFRR
```js
Plot.plot({
    marks: [
      Plot.dot(scenarioData, {
        x: "pctProvided",
        y: "netRevenue",
        fx: "dispatch",
        stroke: "Q_aFRR",
        r: (d) => d.n_charge + d.n_discharge,
        tip: {
          format: {
            x: false,
            y: false,
            fill: false,
            r: false,
            fx: false,
          },
        },
        channels: {
          "aFRR % capacity:": (d) => d3.format(".0%")(d.Q_aFRR),
          "Trading hours:": (d) => `C${d.n_charge}D${d.n_discharge}`,
          Revenue: (d) => `€${d3.format(",.0f")(d.netRevenue)}`,
          "% provided": (d) => d3.format(".1%")(d.pctProvided),
        },
      })
    ],
    x: {
      label: "aFRR service provided (%)",
      domain: pctExtent,
      tickFormat: d3.format(".0%"),
    },
    y: {
      label: "Monthly revenue (EUR / MW)",
      domain: netRevenueExtent,
      grid: true,
      ticks: 10,
    },
    fx: {
      label: null,
    },
    color: {
      legend: true,
      label: "Percentage of capacity allocated to aFRR",
      type: "categorical",
      tickFormat: d3.format(".0%"),
    },
    r: {
      type: "sqrt",
      domain: [2, 8],
      range: [4, 8]
    },
    width: 1000,
    height: 500,
    marginLeft: 100,
    marginBottom: 60,
    caption: "Size of circle is proportionate to total trading hours"
  })
```


## Restoration Cost vs Trading Hours

This chart shows the relationship between average monthly restoration cost and total trading hours.

```js
// Calculate restoration cost domain

const restorationExtent = d3.extent(scenarioData, (d) => d.avgRestorationCost);
const tradingHoursExtent = d3.extent(scenarioData, (d) => d.totalTradingHours);
```

```js
Plot.plot({
  marks: [
    Plot.dot(scenarioData, {
      x: "totalTradingHours",
      y: "avgRestorationCost",
      fx: "dispatch",
      fill: "Q_aFRR",
      r: 5,
      tip: {
        format: {
          x: false,
          y: false,
          fill: false,
        },
      },
      channels: {
        "aFRR % capacity:": (d) => d3.format(".0%")(d.Q_aFRR),
        "Trading hours:": (d) => `C${d.n_charge}D${d.n_discharge}`,
        "Restoration cost": (d) => `€${d3.format(",.0f")(d.avgRestorationCost)}`,
        Dispatch: "dispatch",
      },
    }),
    Plot.ruleY([0], { stroke: "black", strokeDasharray: "4 4" }),
  ],
  x: {
    label: "Total trading hours (charge + discharge)",
    domain: [2,3,4,5,6,7],
  },
  y: {
    label: "Monthly restoration cost (EUR / MW)",
    domain: restorationExtent,
    grid: true,
    ticks: 10
  },
  color: {
    legend: true,
    label: "Percentage of capacity allocated to aFRR",
    type: "categorical",
    tickFormat: d3.format(".0%")
  },
  width: 1000,
  height: 500,
  marginLeft: 100,
  marginBottom: 60,
})
```
