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
import { bootThemePreference, teardownThemePreference } from "./theme_preference";

const bootApplication = () => {
  bootThemePreference();
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
};

const teardownApplication = () => {
  teardownThemePreference();
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
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootApplication, { once: true });
} else {
  bootApplication();
}

document.addEventListener("turbo:load", bootApplication);
document.addEventListener("turbo:before-cache", teardownApplication);
