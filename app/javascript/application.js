import "@hotwired/turbo-rails";
import $ from "jquery";
import Foundation from "foundation-sites";
import "what-input";

import { reflowResponsiveTables, teardownResponsiveTables } from "./responsive_tables";

window.$ = $;
window.jQuery = $;
window.Foundation = Foundation;

const bootFoundation = () => {
  $(document).foundation();
  reflowResponsiveTables($);
};

document.addEventListener("turbo:load", bootFoundation);

document.addEventListener("turbo:before-cache", () => {
  teardownResponsiveTables($);
  $(".reveal-overlay").remove();
  $("body").removeClass("is-reveal-open");
});
