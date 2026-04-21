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
    const wrapper = input.closest("[data-testid='offer-amount-stepper']");
    const increaseButton = wrapper?.querySelector("[data-offer-amount-increase]");
    const decreaseButton = wrapper?.querySelector("[data-offer-amount-decrease]");

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
    const handleIncreaseClick = () => {
      stepInputValue(input, 1);
      input.focus();
    };
    const handleDecreaseClick = () => {
      stepInputValue(input, -1);
      input.focus();
    };

    input.addEventListener("input", handleInput);
    input.addEventListener("keydown", handleKeydown);
    increaseButton?.addEventListener("click", handleIncreaseClick);
    decreaseButton?.addEventListener("click", handleDecreaseClick);
    amountInputHandlers.push({
      input,
      increaseButton,
      decreaseButton,
      handleInput,
      handleKeydown,
      handleIncreaseClick,
      handleDecreaseClick
    });
  });
};

export const teardownOfferAmountInputs = () => {
  amountInputHandlers.forEach(({
    input,
    increaseButton,
    decreaseButton,
    handleInput,
    handleKeydown,
    handleIncreaseClick,
    handleDecreaseClick
  }) => {
    input.removeEventListener("input", handleInput);
    input.removeEventListener("keydown", handleKeydown);
    increaseButton?.removeEventListener("click", handleIncreaseClick);
    decreaseButton?.removeEventListener("click", handleDecreaseClick);
  });

  amountInputHandlers = [];
};
