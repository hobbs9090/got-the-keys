const confirmState = new WeakMap();

const syncButtonState = (container) => {
  const checkbox = container.querySelector("[data-account-delete-checkbox]");
  const button = container.querySelector("[data-account-delete-button]");
  if (!checkbox || !button) return;

  button.disabled = !checkbox.checked;
};

const bindConfirm = (container) => {
  if (confirmState.has(container)) return;

  const checkbox = container.querySelector("[data-account-delete-checkbox]");
  if (!checkbox) return;

  const handler = () => syncButtonState(container);
  checkbox.addEventListener("change", handler);
  confirmState.set(container, { checkbox, handler });
  checkbox.checked = false;
  syncButtonState(container);
};

export const bootAccountDeleteConfirm = () => {
  document.querySelectorAll("[data-account-delete-confirm]").forEach(bindConfirm);
};

export const teardownAccountDeleteConfirm = () => {
  document.querySelectorAll("[data-account-delete-confirm]").forEach((container) => {
    const state = confirmState.get(container);
    if (!state) return;

    state.checkbox.removeEventListener("change", state.handler);
    state.checkbox.checked = false;
    syncButtonState(container);
    confirmState.delete(container);
  });
};
