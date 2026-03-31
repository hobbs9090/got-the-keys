const paginationScrollStorageKey = "gotthekeys-pagination-scroll";

let paginationScrollClickHandler;
let paginationScrollCompletionTimer;

const currentLocationKey = () => `${window.location.pathname}${window.location.search}`;

const locationKeyFor = (href) => {
  const url = new URL(href, window.location.origin);
  return `${url.pathname}${url.search}`;
};

const storePendingPaginationScroll = (href) => {
  try {
    window.sessionStorage.setItem(paginationScrollStorageKey, locationKeyFor(href));
  } catch (_error) {
  }
};

const consumePendingPaginationScroll = () => {
  try {
    const pendingLocation = window.sessionStorage.getItem(paginationScrollStorageKey);
    if (pendingLocation !== currentLocationKey()) return false;

    window.sessionStorage.removeItem(paginationScrollStorageKey);
    return true;
  } catch (_error) {
    return false;
  }
};

const preferredScrollBehavior = () => {
  if (window.matchMedia?.("(prefers-reduced-motion: reduce)").matches) return "auto";

  return "smooth";
};

const handlePaginationClick = (event) => {
  if (event.defaultPrevented) return;
  if (event.button !== 0) return;
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;

  const link = event.target.closest("[data-pagination-scroll-nav] a[href]");
  if (!link) return;
  if (link.target && link.target !== "_self") return;
  if (link.hasAttribute("download")) return;

  const url = new URL(link.href, window.location.origin);
  if (url.origin !== window.location.origin) return;

  storePendingPaginationScroll(link.href);
};

const completePaginationScroll = (behavior) => {
  window.clearTimeout(paginationScrollCompletionTimer);

  paginationScrollCompletionTimer = window.setTimeout(() => {
    document.documentElement.dataset.paginationScrollState = "complete";
  }, behavior === "smooth" ? 450 : 0);
};

const restorePaginationScroll = () => {
  delete document.documentElement.dataset.paginationScrollState;

  if (!consumePendingPaginationScroll()) return;

  const target = document.querySelector("[data-pagination-scroll-target]");
  if (!target) return;

  const behavior = preferredScrollBehavior();
  document.documentElement.dataset.paginationScrollState = "running";

  window.requestAnimationFrame(() => {
    window.requestAnimationFrame(() => {
      target.scrollIntoView({ behavior, block: "start", inline: "nearest" });
      completePaginationScroll(behavior);
    });
  });
};

export const bootPaginationScroll = () => {
  if (!paginationScrollClickHandler) {
    paginationScrollClickHandler = (event) => handlePaginationClick(event);
    document.addEventListener("click", paginationScrollClickHandler);
  }

  restorePaginationScroll();
};

export const teardownPaginationScroll = () => {
  window.clearTimeout(paginationScrollCompletionTimer);
  paginationScrollCompletionTimer = null;
  delete document.documentElement.dataset.paginationScrollState;

  if (!paginationScrollClickHandler) return;

  document.removeEventListener("click", paginationScrollClickHandler);
  paginationScrollClickHandler = null;
};
