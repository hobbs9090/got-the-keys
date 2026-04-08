const modalState = new WeakMap();
const triggerState = new WeakMap();
let escapeHandlerBound = false;
let lifecycleHandlersBound = false;
const focusableSelector = [
  "a[href]:not([tabindex='-1'])",
  "button:not([disabled]):not([tabindex='-1'])",
  "input:not([disabled]):not([type='hidden']):not([tabindex='-1'])",
  "select:not([disabled]):not([tabindex='-1'])",
  "textarea:not([disabled]):not([tabindex='-1'])",
  "[tabindex]:not([tabindex='-1'])"
].join(", ");

const focusableElementsFor = (modal) =>
  Array.from(modal.querySelectorAll(focusableSelector)).filter(
    (element) => !element.hidden && element.getAttribute("aria-hidden") !== "true" && element.offsetParent !== null
  );

const focusFirstElement = (modal) => {
  const focusTarget = focusableElementsFor(modal)[0] || modal.querySelector(".site-modal__dialog");
  focusTarget?.focus();
};

const resetModalDomState = () => {
  document.body.classList.remove("site-modal-open");

  document.querySelectorAll("[data-modal]").forEach((modal) => {
    modal.hidden = true;
    modal.setAttribute("aria-hidden", "true");

    const state = modalState.get(modal);
    state?.lastTrigger?.setAttribute("aria-expanded", "false");
  });
};

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
  focusFirstElement(modal);

  window.setTimeout(() => {
    focusFirstElement(modal);
  }, 40);
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

  const keydownHandler = (event) => {
    if (event.key !== "Tab") return;

    const focusable = focusableElementsFor(modal);
    if (focusable.length === 0) {
      event.preventDefault();
      modal.querySelector(".site-modal__dialog")?.focus();
      return;
    }

    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    const activeElement = document.activeElement;

    if (event.shiftKey) {
      if (activeElement === first || !modal.contains(activeElement)) {
        event.preventDefault();
        last.focus();
      }

      return;
    }

    if (activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  };

  modal.addEventListener("keydown", keydownHandler);
  cleanup.push([modal, "keydown", keydownHandler]);

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

const bindLifecycleHandlers = () => {
  if (lifecycleHandlersBound) return;

  const resetHandler = () => resetModalDomState();

  window.addEventListener("beforeunload", resetHandler);
  window.addEventListener("pagehide", resetHandler);
  window.addEventListener("pageshow", resetHandler);
  document.addEventListener("turbo:visit", resetHandler);
  document.addEventListener("turbo:before-cache", resetHandler);
  document.addEventListener("turbo:before-render", resetHandler);
  document.addEventListener("submit", resetHandler, true);

  lifecycleHandlersBound = true;
};

export const bootModals = () => {
  resetModalDomState();
  bindEscapeHandler();
  bindLifecycleHandlers();
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
  resetModalDomState();

  document.querySelectorAll("[data-modal]").forEach((modal) => {
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
