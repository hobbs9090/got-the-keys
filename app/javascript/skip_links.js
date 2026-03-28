const skipLinkState = new WeakMap();

const targetFor = (skipLink) => {
  const href = skipLink.getAttribute("href");
  if (!href || !href.startsWith("#")) return null;

  return document.querySelector(href);
};

export const bootSkipLinks = () => {
  document.querySelectorAll(".skip-link[href^='#']").forEach((skipLink) => {
    if (skipLinkState.has(skipLink)) return;

    const handler = () => {
      const target = targetFor(skipLink);
      if (!target) return;

      window.setTimeout(() => {
        target.focus();
      }, 0);
    };

    skipLink.addEventListener("click", handler);
    skipLinkState.set(skipLink, handler);
  });
};

export const teardownSkipLinks = () => {
  document.querySelectorAll(".skip-link[href^='#']").forEach((skipLink) => {
    const handler = skipLinkState.get(skipLink);
    if (!handler) return;

    skipLink.removeEventListener("click", handler);
    skipLinkState.delete(skipLink);
  });
};
