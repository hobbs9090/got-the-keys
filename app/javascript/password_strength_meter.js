let passwordStrengthHandlers = [];

const passwordInputs = () => Array.from(document.querySelectorAll("[data-password-strength-input]"));

const scorePassword = (value) => {
  let score = 0;

  if (value.length >= 10) score += 1;
  if (value.length >= 14) score += 1;
  if (/[a-z]/.test(value) && /[A-Z]/.test(value)) score += 1;
  if (/\d/.test(value)) score += 1;
  if (/[^A-Za-z0-9]/.test(value)) score += 1;

  return Math.min(score, 4);
};

export const bootPasswordStrengthMeters = () => {
  teardownPasswordStrengthMeters();

  passwordInputs().forEach((input) => {
    const meter = document.querySelector(`[data-password-strength-meter="${input.id}"]`);
    const label = document.querySelector(`[data-password-strength-label="${input.id}"]`);
    if (!meter || !label) return;

    const labels = JSON.parse(input.dataset.passwordStrengthLabels || "[]");
    const handleInput = () => {
      const score = scorePassword(input.value);
      meter.value = score;
      label.textContent = labels[score] || "";
      meter.dataset.strength = String(score);
    };

    input.addEventListener("input", handleInput);
    handleInput();

    passwordStrengthHandlers.push({ input, handleInput });
  });
};

export const teardownPasswordStrengthMeters = () => {
  passwordStrengthHandlers.forEach(({ input, handleInput }) => {
    input.removeEventListener("input", handleInput);
  });

  passwordStrengthHandlers = [];
};
