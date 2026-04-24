const demoPerformanceSeedFormState = new WeakMap();

const storageKey = "gotthekeys-admin-performance-seed-form";

const readPersistedState = () => {
  try {
    const raw = window.sessionStorage.getItem(storageKey);
    return raw ? JSON.parse(raw) : {};
  } catch (_error) {
    return {};
  }
};

const writePersistedState = (next) => {
  try {
    window.sessionStorage.setItem(storageKey, JSON.stringify(next));
  } catch (_error) {
    // Ignore persistence failures (e.g. storage disabled).
  }
};

const setAiDependentDisabled = (state, isAiModeOff) => {
  state.batchSizeInput.disabled = isAiModeOff;
  state.modelInput.disabled = isAiModeOff;

  // Keep native constraint validation from flagging disabled fields.
  state.batchSizeInput.required = !isAiModeOff;
  state.modelInput.required = !isAiModeOff;
};

const updateAiModeDependentFields = (state) => {
  const aiModeValue = state.aiModeSelect.value.toString().trim().toLowerCase();
  const isAiModeOff = aiModeValue === "off";
  setAiDependentDisabled(state, isAiModeOff);
};

const applyPersistedStateToForm = (state) => {
  const persisted = readPersistedState();
  if (!persisted || typeof persisted !== "object") return;

  const persistedAiMode = persisted.ai_mode?.toString?.().trim().toLowerCase();
  const persistedBatchSize = persisted.batch_size?.toString?.();
  const persistedModel = persisted.model?.toString?.();

  if (persistedAiMode && ["off", "auto", "on"].includes(persistedAiMode)) {
    state.aiModeSelect.value = persistedAiMode;
  }

  if (persistedBatchSize) state.batchSizeInput.value = persistedBatchSize;
  if (persistedModel) state.modelInput.value = persistedModel;

  updateAiModeDependentFields(state);
};

const setupDemoPerformanceSeedForm = (form) => {
  if (demoPerformanceSeedFormState.has(form)) return;

  const aiModeSelect = form.querySelector('[data-testid="performance-seed-ai-mode"]');
  const batchSizeInput = form.querySelector('[data-testid="performance-seed-batch-size"]');
  const modelInput = form.querySelector('[data-testid="performance-seed-model"]');

  if (!aiModeSelect || !batchSizeInput || !modelInput) return;

  const state = { aiModeSelect, batchSizeInput, modelInput };
  const persistHandler = () => {
    writePersistedState({
      ai_mode: state.aiModeSelect.value,
      batch_size: state.batchSizeInput.value,
      model: state.modelInput.value
    });
  };

  const changeHandler = () => {
    updateAiModeDependentFields(state);
    persistHandler();
  };

  aiModeSelect.addEventListener("change", changeHandler);
  aiModeSelect.addEventListener("input", changeHandler);
  batchSizeInput.addEventListener("input", persistHandler);
  modelInput.addEventListener("input", persistHandler);
  demoPerformanceSeedFormState.set(form, { ...state, changeHandler, persistHandler });

  // Apply persisted selection (helps after refresh/redirect) and then
  // enforce disabled/enabled state based on AI mode.
  applyPersistedStateToForm(state);

  // In case nothing is persisted, still enforce correct initial disabled state.
  updateAiModeDependentFields(state);
};

export const bootAdminDemoPerformanceSeedForms = () => {
  document.querySelectorAll('[data-testid="performance-seed-form"]').forEach(setupDemoPerformanceSeedForm);
};

export const teardownAdminDemoPerformanceSeedForms = () => {
  document.querySelectorAll('[data-testid="performance-seed-form"]').forEach((form) => {
    const state = demoPerformanceSeedFormState.get(form);
    if (!state) return;

    state.aiModeSelect.removeEventListener("change", state.changeHandler);
    state.aiModeSelect.removeEventListener("input", state.changeHandler);
    state.batchSizeInput.removeEventListener("input", state.persistHandler);
    state.modelInput.removeEventListener("input", state.persistHandler);
    demoPerformanceSeedFormState.delete(form);
  });
};
