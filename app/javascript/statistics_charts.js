let chartElements = [];
let googleChartsPromise;
let resizeHandler;

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
  const options = JSON.parse(element.dataset.chartOptions || "{}");
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
};

export const teardownStatisticsCharts = () => {
  chartElements = [];

  if (resizeHandler) {
    window.removeEventListener("resize", resizeHandler);
    resizeHandler = null;
  }
};
