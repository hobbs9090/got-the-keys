const SCROLL_SELECTOR = "[data-scroll-into-view-on-load='true']";

export const bootAdminSecurityScroll = () => {
  const panel = document.querySelector(SCROLL_SELECTOR);
  if (!panel) return;

  panel.scrollIntoView({ behavior: "smooth", block: "start" });
};

export const teardownAdminSecurityScroll = () => {};
