let amountInputHandlers = [];

const offerAmountInputs = () => Array.from(document.querySelectorAll("[data-offer-amount-input]"));

const digitsOnly = (value) => value.replace(/[^\d]/g, "");

const formatWithCommas = (value) => {
  const digits = digitsOnly(value);
  if (!digits) return "";

  return Number.parseInt(digits, 10).toLocaleString("en-GB");
};

const parseAmount = (value) => {
  const digits = digitsOnly(value);
  if (!digits) return null;

  return Number.parseInt(digits, 10);
};

const formatInputValue = (input) => {
  input.value = formatWithCommas(input.value);
};

const stepInputValue = (input, direction) => {
  const step = Number.parseInt(input.dataset.offerAmountStep || "1000", 10);
  const currentValue = parseAmount(input.value) || 0;
  const nextValue = Math.max(0, currentValue + (step * direction));

  input.value = formatWithCommas(String(nextValue));
  input.dispatchEvent(new Event("input", { bubbles: true }));
};

export const bootOfferAmountInputs = () => {
  teardownOfferAmountInputs();

  offerAmountInputs().forEach((input) => {
    formatInputValue(input);

    const handleInput = () => formatInputValue(input);
    const handleKeydown = (event) => {
      if (event.key === "ArrowUp") {
        event.preventDefault();
        stepInputValue(input, 1);
      } else if (event.key === "ArrowDown") {
        event.preventDefault();
        stepInputValue(input, -1);
      }
    };

    input.addEventListener("input", handleInput);
    input.addEventListener("keydown", handleKeydown);
    amountInputHandlers.push({ input, handleInput, handleKeydown });
  });
};

export const teardownOfferAmountInputs = () => {
  amountInputHandlers.forEach(({ input, handleInput, handleKeydown }) => {
    input.removeEventListener("input", handleInput);
    input.removeEventListener("keydown", handleKeydown);
  });

  amountInputHandlers = [];
};
