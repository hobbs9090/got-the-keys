const listingFormState = new WeakMap();

const rentalSaleStatus = "For Rent";
const freeholdTenure = "freehold";

const toggleFieldGroup = (fields, visible) => {
  fields.forEach((container) => {
    if (visible) {
      container.removeAttribute("hidden");
      container.style.removeProperty("display");
    } else {
      container.setAttribute("hidden", "");
      // `.form-grid__checkbox { display: flex }` overrides the `[hidden]` UA rule; force collapse.
      container.style.display = "none";
    }
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
  const showLeaseLength = !tenureIsFreehold(state.tenureField.value);
  const showPetsAllowed = isRental && !tenureIsFreehold(state.tenureField.value);

  toggleFieldGroup([state.furnishingField], isRental);
  toggleFieldGroup(state.rentalOnlyFields, isRental);
  toggleFieldGroup([state.leaseLengthField], showLeaseLength);
  toggleFieldGroup([state.petsAllowedField], showPetsAllowed);
};

const setupListingForm = (form) => {
  if (listingFormState.has(form)) return;

  const saleStatusSelect = form.querySelector("[data-property-sale-status]");
  const furnishingField = form.querySelector("[data-property-furnishing-field]");
  const tenureField = form.querySelector("[data-property-tenure]");
  const leaseLengthField = form.querySelector("[data-property-lease-length-field]");
  const rentalOnlyFields = Array.from(form.querySelectorAll("[data-property-rental-only-field]"));
  const petsAllowedField = form.querySelector("[data-property-pets-allowed-field]");

  if (!saleStatusSelect || !furnishingField || !tenureField || !leaseLengthField || !petsAllowedField) return;

  const changeHandler = () => toggleListingFields(form);
  saleStatusSelect.addEventListener("change", changeHandler);
  tenureField.addEventListener("change", changeHandler);

  listingFormState.set(form, {
    saleStatusSelect,
    furnishingField,
    tenureField,
    leaseLengthField,
    petsAllowedField,
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
    state.tenureField.removeEventListener("change", state.changeHandler);
    listingFormState.delete(form);
  });
};
