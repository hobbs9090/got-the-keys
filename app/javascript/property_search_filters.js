const propertySearchFilterState = new WeakMap();

const updatePriceLabels = (form) => {
  const state = propertySearchFilterState.get(form);
  if (!state) return;

  const useRentalLabels = state.saleStatusSelect.value === state.rentalSaleStatusValue;

  state.minPriceLabel.textContent = useRentalLabels ? state.minPriceLabel.dataset.rentalLabel : state.minPriceLabel.dataset.defaultLabel;
  state.maxPriceLabel.textContent = useRentalLabels ? state.maxPriceLabel.dataset.rentalLabel : state.maxPriceLabel.dataset.defaultLabel;
  state.minPriceInput.placeholder = useRentalLabels ? state.minPriceInput.dataset.rentalPlaceholder : state.minPriceInput.dataset.defaultPlaceholder;
  state.maxPriceInput.placeholder = useRentalLabels ? state.maxPriceInput.dataset.rentalPlaceholder : state.maxPriceInput.dataset.defaultPlaceholder;
};

const setupPropertySearchFilters = (form) => {
  if (propertySearchFilterState.has(form)) return;

  const saleStatusSelect = form.querySelector("[data-property-search-sale-status]");
  const minPriceLabel = form.querySelector("[data-property-search-min-price-label]");
  const maxPriceLabel = form.querySelector("[data-property-search-max-price-label]");
  const minPriceInput = form.querySelector("[data-property-search-min-price-input]");
  const maxPriceInput = form.querySelector("[data-property-search-max-price-input]");

  if (!saleStatusSelect || !minPriceLabel || !maxPriceLabel || !minPriceInput || !maxPriceInput) return;

  const rentalSaleStatusValue = saleStatusSelect.dataset.propertySearchRentalValue;
  if (!rentalSaleStatusValue) return;

  const changeHandler = () => updatePriceLabels(form);
  saleStatusSelect.addEventListener("change", changeHandler);

  const state = {
    saleStatusSelect,
    minPriceLabel,
    maxPriceLabel,
    minPriceInput,
    maxPriceInput,
    rentalSaleStatusValue,
    changeHandler
  };

  propertySearchFilterState.set(form, state);

  form.dataset.propertySearchFiltersReady = "true";
  updatePriceLabels(form);
};

export const bootPropertySearchFilters = () => {
  document.querySelectorAll("[data-property-search-filters]").forEach(setupPropertySearchFilters);
};

export const teardownPropertySearchFilters = () => {
  document.querySelectorAll("[data-property-search-filters]").forEach((form) => {
    const state = propertySearchFilterState.get(form);
    if (!state) return;

    state.saleStatusSelect.removeEventListener("change", state.changeHandler);
    delete form.dataset.propertySearchFiltersReady;
    propertySearchFilterState.delete(form);
  });
};
