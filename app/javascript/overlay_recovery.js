const cookieConsentCookieName = "gotthekeys_cookie_consent";

const cookieConsentRecorded = () =>
  document.cookie
    .split(";")
    .map((value) => value.trim())
    .some((value) => value.startsWith(`${cookieConsentCookieName}=`));

const resetModalOverlayState = () => {
  document.body.classList.remove("site-modal-open");

  document.querySelectorAll("[data-modal]").forEach((modal) => {
    if (modal.getAttribute("aria-hidden") === "false") {
      modal.hidden = true;
      modal.setAttribute("aria-hidden", "true");
    }
  });
};

const resetCookieBannerState = () => {
  if (!cookieConsentRecorded()) return;

  document.querySelectorAll(".cookie-banner").forEach((banner) => {
    banner.remove();
  });
};

const recoverOverlayState = () => {
  resetModalOverlayState();
  resetCookieBannerState();
};

let lifecycleHandlersBound = false;

const bindLifecycleHandlers = () => {
  if (lifecycleHandlersBound) return;

  const handler = () => recoverOverlayState();

  window.addEventListener("pageshow", handler);
  window.addEventListener("focus", handler);
  document.addEventListener("turbo:load", handler);
  document.addEventListener("turbo:before-render", handler);

  lifecycleHandlersBound = true;
};

export const bootOverlayRecovery = () => {
  recoverOverlayState();
  bindLifecycleHandlers();
};

export const teardownOverlayRecovery = () => {
  recoverOverlayState();
};
