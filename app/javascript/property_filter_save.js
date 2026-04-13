const propertyFilterSaveHandlers = new WeakMap();

const FILTER_TO_SAVED = [
  ["sale_status", "sale_status"],
  ["q", "search_query"],
  ["town_city", "town_city"],
  ["min_bedrooms", "min_bedrooms"],
  ["min_price", "min_price"],
  ["max_price", "max_price"],
  ["sort", "sort"]
];

const appendHidden = (form, name, value) => {
  const input = document.createElement("input");
  input.type = "hidden";
  input.name = name;
  input.value = value;
  form.appendChild(input);
};

const submitSavedSearchFromFilters = (button) => {
  const filterForm = document.querySelector('[data-testid="property-filter-form"]');
  if (!filterForm) return;

  const url = button.dataset.saveSearchUrl;
  if (!url) return;

  const fd = new FormData(filterForm);
  const form = document.createElement("form");
  form.method = "post";
  form.action = url;

  const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content");
  if (token) {
    appendHidden(form, "authenticity_token", token);
  }

  FILTER_TO_SAVED.forEach(([filterName, savedName]) => {
    if (!fd.has(filterName)) return;
    const value = fd.get(filterName);
    if (value === "" || value === null) return;
    appendHidden(form, `saved_search[${savedName}]`, value);
  });

  const locale =
    button.dataset.savedSearchLocale ||
    (document.documentElement.lang || "en").split("-")[0].toLowerCase();
  appendHidden(form, "saved_search[locale]", locale);
  appendHidden(form, "saved_search[alerts_enabled]", "1");

  const scope = button.dataset.catalogueScope;
  if (scope) {
    appendHidden(form, "saved_search[catalogue_scope]", scope);
  }

  document.body.appendChild(form);
  form.submit();
};

const setupPropertyFilterSave = (button) => {
  if (propertyFilterSaveHandlers.has(button)) return;

  const handler = () => submitSavedSearchFromFilters(button);
  button.addEventListener("click", handler);
  propertyFilterSaveHandlers.set(button, handler);
};

export const bootPropertyFilterSave = () => {
  document.querySelectorAll("[data-property-filter-save]").forEach(setupPropertyFilterSave);
};

export const teardownPropertyFilterSave = () => {
  document.querySelectorAll("[data-property-filter-save]").forEach((button) => {
    const handler = propertyFilterSaveHandlers.get(button);
    if (!handler) return;
    button.removeEventListener("click", handler);
    propertyFilterSaveHandlers.delete(button);
  });
};
