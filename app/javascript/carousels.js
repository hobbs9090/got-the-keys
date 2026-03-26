const carouselState = new WeakMap();
const AUTOPLAY_INTERVAL = 6000;

const activateSlide = (carousel, nextIndex) => {
  const state = carouselState.get(carousel);
  if (!state) return;

  state.index = (nextIndex + state.slides.length) % state.slides.length;
  state.track.style.transform = `translateX(-${state.index * 100}%)`;

  state.slides.forEach((slide, index) => {
    const active = index === state.index;
    slide.classList.toggle("is-active", active);
    slide.setAttribute("aria-hidden", active ? "false" : "true");
  });

  state.bullets.forEach((bullet, index) => {
    const active = index === state.index;
    bullet.classList.toggle("is-active", active);
    bullet.setAttribute("aria-current", active ? "true" : "false");
  });
};

const stopAutoplay = (carousel) => {
  const state = carouselState.get(carousel);
  if (!state?.timer) return;

  window.clearInterval(state.timer);
  state.timer = null;
};

const startAutoplay = (carousel) => {
  const state = carouselState.get(carousel);
  if (!state || state.autoPlay !== "true" || state.slides.length < 2 || state.timer) return;

  state.timer = window.setInterval(() => {
    activateSlide(carousel, state.index + 1);
  }, AUTOPLAY_INTERVAL);
};

const setupCarousel = (carousel) => {
  if (carouselState.has(carousel)) return;

  const slides = Array.from(carousel.querySelectorAll("[data-carousel-slide]"));
  const bullets = Array.from(carousel.querySelectorAll("[data-carousel-bullet]"));
  const previousButton = carousel.querySelector("[data-carousel-prev]");
  const nextButton = carousel.querySelector("[data-carousel-next]");
  const track = carousel.querySelector(".hero-carousel__track");

  if (slides.length === 0 || !track) return;

  const state = {
    autoPlay: carousel.dataset.autoPlay,
    bullets,
    cleanup: [],
    index: slides.findIndex((slide) => slide.classList.contains("is-active")),
    pointerInteracted: false,
    slides,
    track,
    timer: null
  };

  if (state.index < 0) {
    state.index = 0;
  }

  carouselState.set(carousel, state);

  if (previousButton) {
    const handler = () => activateSlide(carousel, state.index - 1);
    previousButton.addEventListener("click", handler);
    state.cleanup.push([previousButton, "click", handler]);
  }

  if (nextButton) {
    const handler = () => activateSlide(carousel, state.index + 1);
    nextButton.addEventListener("click", handler);
    state.cleanup.push([nextButton, "click", handler]);
  }

  bullets.forEach((bullet, index) => {
    const handler = () => activateSlide(carousel, index);
    bullet.addEventListener("click", handler);
    state.cleanup.push([bullet, "click", handler]);
  });

  const pointerMoveHandler = () => {
    state.pointerInteracted = true;
    stopAutoplay(carousel);
  };
  carousel.addEventListener("pointermove", pointerMoveHandler);
  state.cleanup.push([carousel, "pointermove", pointerMoveHandler]);

  const focusInHandler = () => stopAutoplay(carousel);
  carousel.addEventListener("focusin", focusInHandler);
  state.cleanup.push([carousel, "focusin", focusInHandler]);

  const pointerLeaveHandler = () => {
    if (state.pointerInteracted) {
      startAutoplay(carousel);
    }
  };
  carousel.addEventListener("pointerleave", pointerLeaveHandler);
  state.cleanup.push([carousel, "pointerleave", pointerLeaveHandler]);

  const focusOutHandler = () => startAutoplay(carousel);
  carousel.addEventListener("focusout", focusOutHandler);
  state.cleanup.push([carousel, "focusout", focusOutHandler]);

  activateSlide(carousel, state.index);
  startAutoplay(carousel);
};

export const bootCarousels = () => {
  document.querySelectorAll("[data-carousel]").forEach(setupCarousel);
};

export const teardownCarousels = () => {
  document.querySelectorAll("[data-carousel]").forEach((carousel) => {
    const state = carouselState.get(carousel);
    if (!state) return;

    stopAutoplay(carousel);
    state.cleanup.forEach(([element, eventName, handler]) => {
      element.removeEventListener(eventName, handler);
    });
    carouselState.delete(carousel);
  });
};
