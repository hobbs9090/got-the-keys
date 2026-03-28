import "@hotwired/turbo-rails";

import { bootCarousels, teardownCarousels } from "./carousels";
import { bootModals, teardownModals } from "./modals";
import { bootResponsiveTables, teardownResponsiveTables } from "./responsive_tables";
import { bootSkipLinks, teardownSkipLinks } from "./skip_links";
import { bootStatisticsCharts, teardownStatisticsCharts } from "./statistics_charts";

const bootApplication = () => {
  bootCarousels();
  bootModals();
  bootResponsiveTables();
  bootSkipLinks();
  bootStatisticsCharts();
};

const teardownApplication = () => {
  teardownCarousels();
  teardownModals();
  teardownResponsiveTables();
  teardownSkipLinks();
  teardownStatisticsCharts();
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootApplication, { once: true });
} else {
  bootApplication();
}

document.addEventListener("turbo:load", bootApplication);
document.addEventListener("turbo:before-cache", teardownApplication);
