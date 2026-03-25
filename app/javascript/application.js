import "@hotwired/turbo-rails";
import $ from "jquery";
import Foundation from "foundation-sites";
import "what-input";

import { reflowResponsiveTables, teardownResponsiveTables } from "./responsive_tables";

window.$ = $;
window.jQuery = $;
window.Foundation = Foundation;

const clearNonEssentialInputPersistence = () => {
  if (document.body?.dataset.whatpersist !== "false") return;

  try {
    window.sessionStorage.removeItem("what-input");
    window.sessionStorage.removeItem("what-intent");
  } catch (error) {
    // Ignore storage access errors in restricted browser contexts.
  }
};

const bootFoundation = () => {
  clearNonEssentialInputPersistence();
  $(document).foundation();
  reflowResponsiveTables($);
};

document.addEventListener("turbo:load", bootFoundation);

document.addEventListener("turbo:before-cache", () => {
  teardownResponsiveTables($);
  $(".reveal-overlay").remove();
  $("body").removeClass("is-reveal-open");
});
