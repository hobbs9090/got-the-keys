const lazyMapSelector = "[data-lazy-map]";
const lazyMapTriggerSelector = "[data-lazy-map-trigger]";

const loadedMaps = new WeakSet();
let listening = false;

const buildMapFrame = (container) => {
  const src = container.dataset.mapSrc;
  if (!src) return null;

  const iframe = document.createElement("iframe");
  iframe.src = src;
  iframe.title = container.dataset.mapTitle || "Location map";
  iframe.width = "100%";
  iframe.height = "320";
  iframe.loading = "lazy";
  iframe.tabIndex = -1;
  iframe.setAttribute("frameborder", "0");
  iframe.setAttribute("scrolling", "no");
  iframe.setAttribute("marginheight", "0");
  iframe.setAttribute("marginwidth", "0");

  return iframe;
};

const loadMap = (container) => {
  if (loadedMaps.has(container)) return;

  const iframe = buildMapFrame(container);
  if (!iframe) return;

  container.replaceChildren(iframe);
  container.classList.add("property-location-map__frame--loaded");
  loadedMaps.add(container);
};

const onMapTriggerClick = (event) => {
  const trigger = event.target.closest(lazyMapTriggerSelector);
  if (!trigger) return;

  const container = trigger.closest(lazyMapSelector);
  if (!container) return;

  event.preventDefault();
  loadMap(container);
};

export const bootPropertyMaps = () => {
  if (listening) return;

  document.addEventListener("click", onMapTriggerClick);
  listening = true;
};

export const teardownPropertyMaps = () => {
  if (!listening) return;

  document.removeEventListener("click", onMapTriggerClick);
  listening = false;
};
