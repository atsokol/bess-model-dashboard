---
toc: false
---

<div class="hero">
  <h1>Ukraine BESS revenue model</h1>
</div>



```js
// Load monthly data for revenue analysis
const allMonthly = await FileAttachment(
  "data/combined_monthly_summaries.parquet",
).parquet();
const monthlyArray = allMonthly.toArray();

// Default scenario parameters
const qaFRR = 0.5;
const chargeHours = 2;
const dischargeHours = 2;

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
// Calculate scenario comparison data
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

const netRevenueExtent = d3.extent(scenarioData, (d) => d.netRevenue);
const pctExtent = d3.extent(scenarioData, (d) => d.pctProvided);
```

---

## Annual gross revenue breakdown

<div class="card">
${Plot.plot({
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
  })}
</div>

---

## Net revenue across all scenarios

<div class="card">
${Plot.plot({
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
    stroke: {
      legend: true,
      label: "Percentage of capacity allocated to aFRR",
      type: "categorical",
      tickFormat: d3.format(".0%"),
    },
    r: {
      legend: true,
      label: "Total trading hours (charge + discharge)",
      domain: [2, 8],
      range: [4, 8]
    },
    width: 1000,
    height: 500,
    marginLeft: 100,
    marginBottom: 60,
    caption: "Size of circle is proportionate to total trading hours"
  })}
</div>


<style>

.hero {
  display: flex;
  flex-direction: column;
  align-items: center;
  font-family: var(--sans-serif);
  margin: 4rem 0 8rem;
  text-wrap: balance;
  text-align: center;
}

.hero h1 {
  margin: 1rem 0;
  padding: 1rem 0;
  max-width: none;
  font-size: 14vw;
  font-weight: 900;
  line-height: 1;
  background: linear-gradient(30deg, var(--theme-foreground-focus), currentColor);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

@media (min-width: 640px) {
  .hero h1 {
    font-size: 90px;
  }
}

</style>
