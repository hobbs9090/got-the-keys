import "@hotwired/turbo-rails";

import { bootCarousels, teardownCarousels } from "./carousels";
import { bootModals, teardownModals } from "./modals";
import { bootResponsiveTables, teardownResponsiveTables } from "./responsive_tables";
import { bootStatisticsCharts, teardownStatisticsCharts } from "./statistics_charts";

const bootApplication = () => {
  bootCarousels();
  bootModals();
  bootResponsiveTables();
  bootStatisticsCharts();
};

const teardownApplication = () => {
  teardownCarousels();
  teardownModals();
  teardownResponsiveTables();
  teardownStatisticsCharts();
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootApplication, { once: true });
} else {
  bootApplication();
}

document.addEventListener("turbo:load", bootApplication);
document.addEventListener("turbo:before-cache", teardownApplication);
