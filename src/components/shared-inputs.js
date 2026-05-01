import * as Inputs from "npm:@observablehq/inputs";

export function createSharedInputs() {
  // Get current values from URL or use defaults
  const getParam = (name, defaultValue) => {
    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      const value = params.get(name);
      if (value !== null) {
        return typeof defaultValue === 'string' ? value : parseFloat(value);
      }
    }
    return defaultValue;
  };

  // Update URL and persist to all navigation links
  const updateURL = (name, value) => {
    if (typeof window !== 'undefined') {
      const url = new URL(window.location);
      url.searchParams.set(name, value);
      window.history.replaceState({}, '', url);
      
      // Update all navigation links to preserve parameters
      document.querySelectorAll('nav a').forEach(link => {
        try {
          const linkUrl = new URL(link.href);
          linkUrl.searchParams.set(name, value);
          link.href = linkUrl.toString();
        } catch (e) {
          // Skip invalid URLs
        }
      });
    }
  };

  // Initialize navigation links with current parameters on load
  if (typeof window !== 'undefined') {
    setTimeout(() => {
      const currentParams = new URLSearchParams(window.location.search);
      document.querySelectorAll('nav a').forEach(link => {
        try {
          const linkUrl = new URL(link.href);
          currentParams.forEach((value, key) => {
            linkUrl.searchParams.set(key, value);
          });
          link.href = linkUrl.toString();
        } catch (e) {
          // Skip invalid URLs
        }
      });
    }, 100);
  }

  // Create inputs with change listeners to update URL immediately
  const chargeHours = Inputs.select([1, 2, 3], {
    label: "Trading # charge hours",
    value: getParam("chargeHours", 2)
  });
  chargeHours.addEventListener("input", () => updateURL("chargeHours", chargeHours.value));

  const dischargeHours = Inputs.select([1, 2, 3, 4], {
    label: "Trading # discharge hours",
    value: getParam("dischargeHours", 2)
  });
  dischargeHours.addEventListener("input", () => updateURL("dischargeHours", dischargeHours.value));

  const qaFRR = Inputs.select([0.3, 0.4, 0.5, 0.6, 0.7], {
    label: "Share of capacity allocated to aFRR",
    value: getParam("qaFRR", 0.5),
    format: (d) => `${Math.round(d * 100)}%`
  });
  qaFRR.addEventListener("input", () => updateURL("qaFRR", qaFRR.value));

  // Generate all Mondays from 2023-01-02 through end of data (2025-09-29)
  const _allMondays = [];
  const _d = new Date(Date.UTC(2023, 0, 2)); // first Monday of 2023
  const _dataEnd = new Date(Date.UTC(2025, 9, 1)); // past last data date
  while (_d < _dataEnd) {
    _allMondays.push(_d.toISOString().slice(0, 10));
    _d.setUTCDate(_d.getUTCDate() + 7);
  }

  const _weekFmt = (iso) => {
    const s = new Date(iso + "T00:00:00Z");
    const e = new Date(Date.UTC(s.getUTCFullYear(), s.getUTCMonth(), s.getUTCDate() + 6));
    const fmt = (d) => d.toLocaleDateString("en-GB", { month: "short", day: "numeric", timeZone: "UTC" });
    return `${fmt(s)} – ${fmt(e)}`;
  };

  const weekStart = Inputs.select(_allMondays, {
    label: "Week starting",
    value: getParam("weekStart", "2023-01-02"),
    format: _weekFmt
  });
  weekStart.addEventListener("input", () => updateURL("weekStart", weekStart.value));

  // Return the inputs and their values
  return {
    chargeHours,
    dischargeHours,
    qaFRR,
    // Reactive values that read current values
    get chargeHoursValue() {
      return chargeHours.value;
    },
    get dischargeHoursValue() {
      return dischargeHours.value;
    },
    get qaFRRValue() {
      return qaFRR.value; // Already in decimal format
    },
    weekStart,
    get weekStartValue() {
      return weekStart.value;
    }
  };
}

// Create the visual header component as a single unified panel
export function InputsHeader(inputs) {
  const container = document.createElement("div");
  container.className = "inputs-panel";
  container.style.cssText = "background: var(--theme-background-alt); padding: 1.25rem 1.5rem; margin: 0 0 2rem 0; border-radius: 8px; border: 1px solid var(--theme-foreground-faintest); box-shadow: 0 1px 3px rgba(0,0,0,0.05);";
  
  const title = document.createElement("div");
  title.style.cssText = "font-weight: 600; font-size: 0.875rem; color: var(--theme-foreground-muted); margin-bottom: 1rem; text-transform: uppercase; letter-spacing: 0.05em;";
  title.textContent = "Choose model parameters";
  
  const inputsGrid = document.createElement("div");
  inputsGrid.style.cssText = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; align-items: start;";
  
  inputsGrid.appendChild(inputs.chargeHours);
  inputsGrid.appendChild(inputs.dischargeHours);
  inputsGrid.appendChild(inputs.qaFRR);
  inputsGrid.appendChild(inputs.weekStart);
  
  container.appendChild(title);
  container.appendChild(inputsGrid);
  return container;
}
