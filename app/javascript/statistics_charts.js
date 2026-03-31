let chartElements = [];
let googleChartsPromise;
let resizeHandler;
let themeChangeHandler;

const cssVariable = (name, fallback = "") => {
  const value = window.getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  return value || fallback;
};

const mergeTextStyle = (style, color) => ({
  ...(style || {}),
  color
});

const themedChartOptions = (options) => {
  const headingColor = cssVariable("--color-heading", "#10213f");
  const mutedColor = cssVariable("--color-muted", "#5b6477");
  const inkColor = cssVariable("--color-ink", "#1d2433");
  const lineColor = cssVariable("--color-line", "rgba(26, 36, 51, 0.1)");

  const themedOptions = {
    ...options,
    backgroundColor: "transparent",
    colors: options.colors || [
      cssVariable("--color-primary", "#1457d6"),
      cssVariable("--color-accent", "#ff7a18"),
      cssVariable("--color-secondary", "#0f8b8d"),
      cssVariable("--color-success", "#117d57")
    ]
  };

  if (themedOptions.legend !== "none") {
    themedOptions.legend = {
      ...(typeof options.legend === "object" ? options.legend : {}),
      textStyle: mergeTextStyle(options.legend?.textStyle, mutedColor)
    };
  }

  themedOptions.titleTextStyle = mergeTextStyle(options.titleTextStyle, headingColor);
  themedOptions.tooltip = {
    ...(typeof options.tooltip === "object" ? options.tooltip : {}),
    textStyle: mergeTextStyle(options.tooltip?.textStyle, inkColor)
  };

  if (options.hAxis) {
    themedOptions.hAxis = {
      ...options.hAxis,
      textStyle: mergeTextStyle(options.hAxis.textStyle, mutedColor),
      titleTextStyle: mergeTextStyle(options.hAxis.titleTextStyle, headingColor),
      gridlines: {
        ...(options.hAxis.gridlines || {}),
        color: options.hAxis.gridlines?.color || lineColor
      }
    };
  }

  if (options.vAxis) {
    themedOptions.vAxis = {
      ...options.vAxis,
      textStyle: mergeTextStyle(options.vAxis.textStyle, mutedColor),
      titleTextStyle: mergeTextStyle(options.vAxis.titleTextStyle, headingColor),
      gridlines: {
        ...(options.vAxis.gridlines || {}),
        color: options.vAxis.gridlines?.color || lineColor
      }
    };
  }

  return themedOptions;
};

const chartPackageFor = (type) => {
  switch (type) {
    case "geo":
      return "geochart";
    case "gauge":
      return "gauge";
    default:
      return "corechart";
  }
};

const loadGoogleCharts = (packages) => {
  if (googleChartsPromise) return googleChartsPromise;

  googleChartsPromise = new Promise((resolve, reject) => {
    const existing = document.querySelector('script[data-google-charts-loader="true"]');

    const onReady = () => {
      window.google.charts.load("current", { packages: Array.from(packages) });
      window.google.charts.setOnLoadCallback(resolve);
    };

    if (window.google?.charts) {
      onReady();
      return;
    }

    const script = existing || document.createElement("script");
    script.src = "https://www.gstatic.com/charts/loader.js";
    script.async = true;
    script.dataset.googleChartsLoader = "true";
    script.addEventListener("load", onReady, { once: true });
    script.addEventListener("error", () => reject(new Error("Unable to load Google Charts")), { once: true });

    if (!existing) document.head.appendChild(script);
  });

  return googleChartsPromise;
};

const buildChart = (element) => {
  const data = JSON.parse(element.dataset.chartData || "[]");
  const options = themedChartOptions(JSON.parse(element.dataset.chartOptions || "{}"));
  const chartData = window.google.visualization.arrayToDataTable(data);

  switch (element.dataset.chartType) {
    case "bar":
      return new window.google.visualization.BarChart(element).draw(chartData, options);
    case "geo":
      return new window.google.visualization.GeoChart(element).draw(chartData, options);
    case "gauge":
      return new window.google.visualization.Gauge(element).draw(chartData, options);
    default:
      return new window.google.visualization.PieChart(element).draw(chartData, options);
  }
};

const drawCharts = () => {
  chartElements.forEach((element) => buildChart(element));
};

export const bootStatisticsCharts = async () => {
  chartElements = Array.from(document.querySelectorAll("[data-statistics-chart]"));
  if (chartElements.length === 0) return;

  const packages = new Set(chartElements.map((element) => chartPackageFor(element.dataset.chartType)));

  try {
    await loadGoogleCharts(packages);
    drawCharts();
  } catch (_error) {
    return;
  }

  if (!resizeHandler) {
    resizeHandler = () => {
      if (chartElements.length > 0) drawCharts();
    };
    window.addEventListener("resize", resizeHandler);
  }

  if (!themeChangeHandler) {
    themeChangeHandler = () => {
      if (chartElements.length > 0) drawCharts();
    };
    document.addEventListener("theme:change", themeChangeHandler);
  }
};

export const teardownStatisticsCharts = () => {
  chartElements = [];

  if (resizeHandler) {
    window.removeEventListener("resize", resizeHandler);
    resizeHandler = null;
  }

  if (themeChangeHandler) {
    document.removeEventListener("theme:change", themeChangeHandler);
    themeChangeHandler = null;
  }
};
