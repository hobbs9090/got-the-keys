let currentPageLinkGuardHandler;

const isPlainLeftClick = (event) =>
  event.button === 0 &&
  !event.metaKey &&
  !event.ctrlKey &&
  !event.shiftKey &&
  !event.altKey;

const normalizeUrl = (url) => {
  const normalized = new URL(url, window.location.origin);
  normalized.hash = "";
  return normalized.toString();
};

export const bootCurrentPageLinkGuard = () => {
  if (currentPageLinkGuardHandler) return;

  currentPageLinkGuardHandler = (event) => {
    const link = event.target.closest?.('a[aria-current="page"]');
    if (!link) return;
    if (!isPlainLeftClick(event)) return;
    if (link.target && link.target !== "_self") return;
    if (link.hasAttribute("download")) return;
    if (link.dataset.turboMethod || link.dataset.method) return;

    const currentUrl = normalizeUrl(window.location.href);
    const linkUrl = normalizeUrl(link.href);
    if (currentUrl !== linkUrl) return;

    event.preventDefault();
  };

  document.addEventListener("click", currentPageLinkGuardHandler);
};

export const teardownCurrentPageLinkGuard = () => {
  if (!currentPageLinkGuardHandler) return;
  document.removeEventListener("click", currentPageLinkGuardHandler);
  currentPageLinkGuardHandler = null;
};

