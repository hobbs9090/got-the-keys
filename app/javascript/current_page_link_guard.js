let currentPageLinkGuardHandler;

const isPlainLeftClick = (event) =>
  event.button === 0 &&
  !event.metaKey &&
  !event.ctrlKey &&
  !event.shiftKey &&
  !event.altKey;

const samePathname = (a, b) => {
  const left = new URL(a, window.location.origin);
  const right = new URL(b, window.location.origin);
  return left.pathname === right.pathname;
};

export const bootCurrentPageLinkGuard = () => {
  if (currentPageLinkGuardHandler) return;

  currentPageLinkGuardHandler = (event) => {
    const target = event.target instanceof Element ? event.target : event.target?.parentElement;
    const link = target?.closest?.("a[href]");
    if (!link) return;
    if (!isPlainLeftClick(event)) return;
    if (link.target && link.target !== "_self") return;
    if (link.hasAttribute("download")) return;
    if (link.dataset.turboMethod || link.dataset.method) return;

    const isAriaCurrentPage = link.getAttribute("aria-current") === "page";
    const isHomeBrandCurrent =
      link.dataset.testid === "home-link" &&
      samePathname(window.location.href, link.href);

    if (!isAriaCurrentPage && !isHomeBrandCurrent) return;
    if (isAriaCurrentPage && !samePathname(window.location.href, link.href)) return;

    event.preventDefault();
  };

  document.addEventListener("click", currentPageLinkGuardHandler);
};

export const teardownCurrentPageLinkGuard = () => {
  if (!currentPageLinkGuardHandler) return;
  document.removeEventListener("click", currentPageLinkGuardHandler);
  currentPageLinkGuardHandler = null;
};

