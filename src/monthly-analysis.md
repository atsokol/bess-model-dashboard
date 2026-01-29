# Monthly Flow Analysis

## Load Data

```js
const schedule_opt = await FileAttachment("data/optimized_schedule.csv").csv({typed: true});

const optimized = schedule_opt.map(d => {
  const datetime = new Date(d.date);
  datetime.setHours(d.hour, 0, 0, 0);
  return {
    trading_MW: +d.trading_MW || 0,
    net_aFRR: +d.net_aFRR || 0,
    restore_MW: +d.restore_MW || 0,
    imbalance_MWh: +d.imbalance_MWh || 0,
    datetime: datetime
  };
});
```

## Monthly Charging/Discharging by Flow Type

```js
// Aggregate data by month and flow type, separating charging and discharging
const monthlyFlows = optimized.reduce((acc, d) => {
  const month = d3.utcMonth(d.datetime);
  
  const flows = [
    {type: "Trading", value: d.trading_MW},
    {type: "Balancing", value: d.net_aFRR},
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
    label: "Month",
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

