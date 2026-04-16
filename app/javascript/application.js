import "@hotwired/turbo-rails";

import { bootAppointmentSlotPickers, teardownAppointmentSlotPickers } from "./appointment_slot_picker";
import { bootCarousels, teardownCarousels } from "./carousels";
import { bootModals, teardownModals } from "./modals";
import { bootNativeValidations, teardownNativeValidations } from "./native_validations";
import { bootPaginationScroll, teardownPaginationScroll } from "./pagination_scroll";
import { bootPropertyListingForms, teardownPropertyListingForms } from "./property_listing_form";
import { bootPropertySearchFilters, teardownPropertySearchFilters } from "./property_search_filters";
import { bootPropertyFilterSave, teardownPropertyFilterSave } from "./property_filter_save";
import { bootAccountDeleteConfirm, teardownAccountDeleteConfirm } from "./account_delete_confirm";
import { bootResponsiveTables, teardownResponsiveTables } from "./responsive_tables";
import { bootSkipLinks, teardownSkipLinks } from "./skip_links";
import { bootStatisticsCharts, teardownStatisticsCharts } from "./statistics_charts";
import { bootThemePreference, teardownThemePreference } from "./theme_preference";
import { bootAdminSecurityScroll, teardownAdminSecurityScroll } from "./admin_security_scroll";
import { bootAdminDemoPerformanceSeedForms, teardownAdminDemoPerformanceSeedForms } from "./admin_demo_performance_seed_form";

const bootApplication = () => {
  bootThemePreference();
  bootAdminSecurityScroll();
  bootAdminDemoPerformanceSeedForms();
  bootAppointmentSlotPickers();
  bootCarousels();
  bootModals();
  bootNativeValidations();
  bootPaginationScroll();
  bootPropertyListingForms();
  bootPropertySearchFilters();
  bootPropertyFilterSave();
  bootAccountDeleteConfirm();
  bootResponsiveTables();
  bootSkipLinks();
  bootStatisticsCharts();
};

const teardownApplication = () => {
  teardownThemePreference();
  teardownAdminSecurityScroll();
  teardownAdminDemoPerformanceSeedForms();
  teardownAppointmentSlotPickers();
  teardownCarousels();
  teardownModals();
  teardownNativeValidations();
  teardownPaginationScroll();
  teardownPropertyListingForms();
  teardownPropertySearchFilters();
  teardownPropertyFilterSave();
  teardownAccountDeleteConfirm();
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
