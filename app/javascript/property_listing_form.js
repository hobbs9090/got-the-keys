const listingFormState = new WeakMap();

const rentalSaleStatus = "For Rent";
const freeholdTenure = "freehold";

const toggleFieldGroup = (fields, visible) => {
  fields.forEach((container) => {
    container.hidden = !visible;
    container.querySelectorAll("input, select, textarea").forEach((field) => {
      field.disabled = !visible;
    });
  });
};

const tenureIsFreehold = (value) => value.toString().trim().toLowerCase() === freeholdTenure;

const toggleListingFields = (form) => {
  const state = listingFormState.get(form);
  if (!state) return;

  const isRental = state.saleStatusSelect.value === rentalSaleStatus;
  const showLeaseLength = isRental || !tenureIsFreehold(state.tenureField.value);

  toggleFieldGroup([state.furnishingField], isRental);
  toggleFieldGroup(state.rentalOnlyFields, isRental);
  toggleFieldGroup([state.leaseLengthField], showLeaseLength);
};

const setupListingForm = (form) => {
  if (listingFormState.has(form)) return;

  const saleStatusSelect = form.querySelector("[data-property-sale-status]");
  const furnishingField = form.querySelector("[data-property-furnishing-field]");
  const tenureField = form.querySelector("[data-property-tenure]");
  const leaseLengthField = form.querySelector("[data-property-lease-length-field]");
  const rentalOnlyFields = Array.from(form.querySelectorAll("[data-property-rental-only-field]"));

  if (!saleStatusSelect || !furnishingField || !tenureField || !leaseLengthField) return;

  const changeHandler = () => toggleListingFields(form);
  saleStatusSelect.addEventListener("change", changeHandler);
  tenureField.addEventListener("input", changeHandler);

  listingFormState.set(form, {
    saleStatusSelect,
    furnishingField,
    tenureField,
    leaseLengthField,
    rentalOnlyFields,
    changeHandler
  });

  toggleListingFields(form);
};

export const bootPropertyListingForms = () => {
  document.querySelectorAll('[data-testid="property-listing-form"]').forEach(setupListingForm);
};

export const teardownPropertyListingForms = () => {
  document.querySelectorAll('[data-testid="property-listing-form"]').forEach((form) => {
    const state = listingFormState.get(form);
    if (!state) return;

    state.saleStatusSelect.removeEventListener("change", state.changeHandler);
    state.tenureField.removeEventListener("input", state.changeHandler);
    listingFormState.delete(form);
  });
};
