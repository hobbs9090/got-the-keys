const listingFormState = new WeakMap();

const rentalSaleStatus = "For Rent";

const toggleFurnishingField = (form) => {
  const state = listingFormState.get(form);
  if (!state) return;

  const showFurnishing = state.saleStatusSelect.value === rentalSaleStatus;

  state.furnishingField.hidden = !showFurnishing;
  state.furnishingField
    .querySelectorAll("input, select, textarea")
    .forEach((field) => {
      field.disabled = !showFurnishing;
    });
};

const setupListingForm = (form) => {
  if (listingFormState.has(form)) return;

  const saleStatusSelect = form.querySelector("[data-property-sale-status]");
  const furnishingField = form.querySelector("[data-property-furnishing-field]");

  if (!saleStatusSelect || !furnishingField) return;

  const changeHandler = () => toggleFurnishingField(form);
  saleStatusSelect.addEventListener("change", changeHandler);

  listingFormState.set(form, {
    saleStatusSelect,
    furnishingField,
    changeHandler
  });

  toggleFurnishingField(form);
};

export const bootPropertyListingForms = () => {
  document.querySelectorAll('[data-testid="property-listing-form"]').forEach(setupListingForm);
};

export const teardownPropertyListingForms = () => {
  document.querySelectorAll('[data-testid="property-listing-form"]').forEach((form) => {
    const state = listingFormState.get(form);
    if (!state) return;

    state.saleStatusSelect.removeEventListener("change", state.changeHandler);
    listingFormState.delete(form);
  });
};
