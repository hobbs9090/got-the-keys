import "@hotwired/turbo-rails";

import { bootCarousels, teardownCarousels } from "./carousels";
import { bootModals, teardownModals } from "./modals";
import { bootPropertyListingForms, teardownPropertyListingForms } from "./property_listing_form";
import { bootPropertySearchFilters, teardownPropertySearchFilters } from "./property_search_filters";
import { bootResponsiveTables, teardownResponsiveTables } from "./responsive_tables";
import { bootSkipLinks, teardownSkipLinks } from "./skip_links";
import { bootStatisticsCharts, teardownStatisticsCharts } from "./statistics_charts";

const bootApplication = () => {
  bootCarousels();
  bootModals();
  bootPropertyListingForms();
  bootPropertySearchFilters();
  bootResponsiveTables();
  bootSkipLinks();
  bootStatisticsCharts();
};

const teardownApplication = () => {
  teardownCarousels();
  teardownModals();
  teardownPropertyListingForms();
  teardownPropertySearchFilters();
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
