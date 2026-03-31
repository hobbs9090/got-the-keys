let invalidHandler;
let resetHandler;

const supportsNativeValidation = (element) =>
  element instanceof window.HTMLInputElement ||
  element instanceof window.HTMLSelectElement ||
  element instanceof window.HTMLTextAreaElement;

const nativeValidationMessages = () => {
  const rawMessages = document.body?.dataset.nativeValidationMessages;
  if (!rawMessages) return {};

  try {
    return JSON.parse(rawMessages);
  } catch (_error) {
    return {};
  }
};

const interpolate = (template, replacements = {}) => {
  if (typeof template !== "string") return "";

  return Object.entries(replacements).reduce(
    (message, [key, value]) => message.split(`__${key.toUpperCase()}__`).join(String(value ?? "")),
    template
  );
};

const missingValueMessage = (element, messages) => {
  if (element.type === "checkbox") return messages.checkbox_required || messages.required || messages.invalid || "";
  if (element.type === "radio" || element.tagName === "SELECT") return messages.option_required || messages.required || messages.invalid || "";

  return messages.required || messages.invalid || "";
};

const validationMessageFor = (element, messages) => {
  const validity = element.validity;
  if (!validity || validity.valid) return "";

  if (validity.valueMissing) return missingValueMessage(element, messages);

  if (validity.typeMismatch) {
    if (element.type === "email") return messages.email || messages.invalid || "";
    if (element.type === "url") return messages.url || messages.invalid || "";
  }

  if (validity.tooShort) return interpolate(messages.too_short || messages.invalid || "", { min: element.minLength });
  if (validity.patternMismatch) return messages.pattern || messages.invalid || "";
  if (validity.rangeUnderflow) return interpolate(messages.range_underflow || messages.invalid || "", { min: element.getAttribute("min") || element.min });
  if (validity.rangeOverflow) return interpolate(messages.range_overflow || messages.invalid || "", { max: element.getAttribute("max") || element.max });
  if (validity.stepMismatch) return messages.step || messages.invalid || "";
  if (validity.badInput) return messages.number || messages.invalid || "";

  return messages.invalid || "";
};

const applyLocalizedValidationMessage = (event) => {
  const element = event.target;
  if (!supportsNativeValidation(element)) return;

  element.setCustomValidity("");

  const message = validationMessageFor(element, nativeValidationMessages());
  if (message) element.setCustomValidity(message);
};

const clearLocalizedValidationMessage = (event) => {
  const element = event.target;
  if (!supportsNativeValidation(element)) return;

  element.setCustomValidity("");
};

export const bootNativeValidations = () => {
  if (!invalidHandler) {
    invalidHandler = (event) => applyLocalizedValidationMessage(event);
    document.addEventListener("invalid", invalidHandler, true);
  }

  if (!resetHandler) {
    resetHandler = (event) => clearLocalizedValidationMessage(event);
    document.addEventListener("input", resetHandler, true);
    document.addEventListener("change", resetHandler, true);
  }
};

export const teardownNativeValidations = () => {
  if (invalidHandler) {
    document.removeEventListener("invalid", invalidHandler, true);
    invalidHandler = null;
  }

  if (resetHandler) {
    document.removeEventListener("input", resetHandler, true);
    document.removeEventListener("change", resetHandler, true);
    resetHandler = null;
  }
};
