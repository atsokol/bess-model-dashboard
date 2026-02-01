# Monthly Flow Analysis

```js
import {createSharedInputs, InputsHeader} from "./components/shared-inputs.js";
import {filterHourlySchedules} from "./components/shared-data.js";
```

```js
// Create shared inputs
const inputs = createSharedInputs();
```

${InputsHeader(inputs)}

```js
const qaFRR = view(inputs.qaFRR);
const chargeHours = view(inputs.chargeHours);
const dischargeHours = view(inputs.dischargeHours);
```

## Load Data

```js
// Load hourly schedules and filter for selected scenario
const allHourly = await FileAttachment("data/all_scenarios_hourly_schedules.parquet").parquet();
const schedules = filterHourlySchedules(allHourly, qaFRR, chargeHours, dischargeHours)
  .map(d => {
    const datetime = new Date(d.date);
    datetime.setHours(d.hour, 0, 0, 0);
    return {
      trading_MW: +d.trading_MW || 0,
      aFRR_charge: +d.aFRR_charge || 0,
      aFRR_discharge: +d.aFRR_discharge || 0,
      restore_MW: +d.restore_MW || 0,
      imbalance_MWh: +d.imbalance_MWh || 0,
      datetime: datetime,
      dispatch_mode: d.dispatch_mode
    };
  });
```

## Monthly Charging/Discharging by Flow Type

```js
// Aggregate data by month and flow type, separating charging and discharging
const monthlyFlows = schedules.reduce((acc, d) => {
  const month = d3.utcMonth(d.datetime);
  
  const flows = [
    {type: "Trading", value: d.trading_MW},
    {type: "Balancing", value: d.aFRR_charge},
    {type: "Balancing", value: -d.aFRR_discharge},
    {type: "Restoration", value: d.restore_MW}
  ];
  
  flows.forEach(flow => {
    if (flow.value > 0) {
      // Charging
      const key = `${month}-${flow.type}-Charging`;
      if (!acc[key]) {
        acc[key] = {month: month, flowType: flow.type, direction: "Charging", total: 0};
      }
      acc[key].total += flow.value;
    } else if (flow.value < 0) {
      // Discharging
      const key = `${month}-${flow.type}-Discharging`;
      if (!acc[key]) {
        acc[key] = {month: month, flowType: flow.type, direction: "Discharging", total: 0};
      }
      acc[key].total += Math.abs(flow.value);
    }
  });
  
  return acc;
}, {});

const monthlyData = Object.values(monthlyFlows);
```

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

