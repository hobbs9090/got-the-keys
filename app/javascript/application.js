import "@hotwired/turbo-rails";

import { bootCarousels, teardownCarousels } from "./carousels";
import { bootModals, teardownModals } from "./modals";
import { bootNativeValidations, teardownNativeValidations } from "./native_validations";
import { bootPaginationScroll, teardownPaginationScroll } from "./pagination_scroll";
import { bootPropertyListingForms, teardownPropertyListingForms } from "./property_listing_form";
import { bootPropertySearchFilters, teardownPropertySearchFilters } from "./property_search_filters";
import { bootResponsiveTables, teardownResponsiveTables } from "./responsive_tables";
import { bootSkipLinks, teardownSkipLinks } from "./skip_links";
import { bootStatisticsCharts, teardownStatisticsCharts } from "./statistics_charts";
import { bootThemePreference, teardownThemePreference } from "./theme_preference";

const bootApplication = () => {
  bootThemePreference();
  bootCarousels();
  bootModals();
  bootNativeValidations();
  bootPaginationScroll();
  bootPropertyListingForms();
  bootPropertySearchFilters();
  bootResponsiveTables();
  bootSkipLinks();
  bootStatisticsCharts();
};

const teardownApplication = () => {
  teardownThemePreference();
  teardownCarousels();
  teardownModals();
  teardownNativeValidations();
  teardownPaginationScroll();
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
