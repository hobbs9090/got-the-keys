import "@hotwired/turbo-rails";

import { bootModals, teardownModals } from "./modals";
import { bootNativeValidations, teardownNativeValidations } from "./native_validations";
import { bootPropertyListingForms, teardownPropertyListingForms } from "./property_listing_form";
import { bootThemePreference, teardownThemePreference } from "./theme_preference";
import { bootAdminSecurityScroll, teardownAdminSecurityScroll } from "./admin_security_scroll";
import { bootAdminDemoPerformanceSeedForms, teardownAdminDemoPerformanceSeedForms } from "./admin_demo_performance_seed_form";

const bootApplication = () => {
  bootThemePreference();
  bootAdminSecurityScroll();
  bootAdminDemoPerformanceSeedForms();
  bootModals();
  bootNativeValidations();
  bootPropertyListingForms();
};

const teardownApplication = () => {
  teardownThemePreference();
  teardownAdminSecurityScroll();
  teardownAdminDemoPerformanceSeedForms();
  teardownModals();
  teardownNativeValidations();
  teardownPropertyListingForms();
};

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootApplication, { once: true });
} else {
  bootApplication();
}

document.addEventListener("turbo:load", bootApplication);
document.addEventListener("turbo:before-cache", teardownApplication);
