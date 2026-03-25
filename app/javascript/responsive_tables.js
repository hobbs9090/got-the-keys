let switched = false;
let listenersBound = false;

const splitTable = ($, original) => {
  if (original.closest(".table-wrapper").length) {
    return;
  }

  original.wrap("<div class='table-wrapper' />");

  const copy = original.clone();
  copy.find("td:not(:first-child), th:not(:first-child)").css("display", "none");
  copy.removeClass("responsive");

  original.closest(".table-wrapper").append(copy);
  copy.wrap("<div class='pinned' />");
  original.wrap("<div class='scrollable' />");

  setCellHeights($, original, copy);
};

const unsplitTable = (original) => {
  if (!original.closest(".table-wrapper").length) {
    return;
  }

  original.closest(".table-wrapper").find(".pinned").remove();
  original.unwrap();
  original.unwrap();
};

const setCellHeights = ($, original, copy) => {
  const heights = [];

  original.find("tr").each(function(index) {
    $(this).find("th, td").each(function() {
      const height = $(this).outerHeight(true);
      heights[index] = Math.max(heights[index] || 0, height);
    });
  });

  copy.find("tr").each(function(index) {
    $(this).height(heights[index]);
  });
};

const updateTables = ($) => {
  const shouldSplit = $(window).width() < 767;

  if (shouldSplit && !switched) {
    switched = true;
    $("table.responsive").each(function() {
      splitTable($, $(this));
    });
    return;
  }

  if (!shouldSplit && switched) {
    switched = false;
    $("table.responsive").each(function() {
      unsplitTable($(this));
    });
  }
};

export const reflowResponsiveTables = ($) => {
  if (!listenersBound) {
    listenersBound = true;
    $(window).on("load.responsiveTables redraw.responsiveTables resize.responsiveTables", () => {
      updateTables($);
    });
  }

  updateTables($);
};

export const teardownResponsiveTables = ($) => {
  $("table.responsive").each(function() {
    unsplitTable($(this));
  });
  switched = false;
};
