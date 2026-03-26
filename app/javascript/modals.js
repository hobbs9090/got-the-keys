const modalState = new WeakMap();
const triggerState = new WeakMap();
let escapeHandlerBound = false;

const closeModal = (modal, restoreFocus = true) => {
  const state = modalState.get(modal);
  if (!state) return;

  modal.hidden = true;
  modal.setAttribute("aria-hidden", "true");
  document.body.classList.remove("site-modal-open");
  state.lastTrigger?.setAttribute("aria-expanded", "false");

  if (restoreFocus && state.lastTrigger) {
    state.lastTrigger.focus();
  }
};

const openModal = (modal, trigger) => {
  const state = modalState.get(modal);
  if (!state) return;

  state.lastTrigger = trigger || null;
  state.lastTrigger?.setAttribute("aria-expanded", "true");
  modal.hidden = false;
  modal.setAttribute("aria-hidden", "false");
  document.body.classList.add("site-modal-open");

  window.requestAnimationFrame(() => {
    const focusTarget = modal.querySelector("[data-modal-close]") || modal.querySelector("a, button, input, select, textarea");
    focusTarget?.focus();
  });
};

const setupModal = (modal) => {
  if (modalState.has(modal)) return;

  const cleanup = [];
  const closeTargets = modal.querySelectorAll("[data-modal-close]");

  closeTargets.forEach((target) => {
    const handler = () => closeModal(modal);
    target.addEventListener("click", handler);
    cleanup.push([target, "click", handler]);
  });

  modalState.set(modal, { cleanup, lastTrigger: null });
};

const bindEscapeHandler = () => {
  if (escapeHandlerBound) return;

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;

    const openModalElement = Array.from(document.querySelectorAll("[data-modal]")).find((modal) => !modal.hidden);
    if (openModalElement) closeModal(openModalElement);
  });

  escapeHandlerBound = true;
};

export const bootModals = () => {
  bindEscapeHandler();
  document.querySelectorAll("[data-modal]").forEach(setupModal);

  document.querySelectorAll("[data-modal-trigger]").forEach((trigger) => {
    if (triggerState.has(trigger)) return;

    trigger.setAttribute("aria-controls", trigger.dataset.modalTrigger);
    trigger.setAttribute("aria-expanded", "false");
    trigger.setAttribute("aria-haspopup", "dialog");

    const handler = (event) => {
      event.preventDefault();
      const modal = document.getElementById(trigger.dataset.modalTrigger);
      if (modal) openModal(modal, trigger);
    };

    trigger.addEventListener("click", handler);
    triggerState.set(trigger, handler);
  });
};

export const teardownModals = () => {
  document.querySelectorAll("[data-modal]").forEach((modal) => {
    closeModal(modal, false);

    const state = modalState.get(modal);
    if (!state) return;

    state.cleanup.forEach(([element, eventName, handler]) => {
      element.removeEventListener(eventName, handler);
    });
    modalState.delete(modal);
  });

  document.querySelectorAll("[data-modal-trigger]").forEach((trigger) => {
    const handler = triggerState.get(trigger);
    if (!handler) return;

    trigger.removeEventListener("click", handler);
    triggerState.delete(trigger);
  });
};
