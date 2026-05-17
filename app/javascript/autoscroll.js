export const bootAutoscroll = () => {
  const target = document.querySelector("[data-autoscroll]");
  if (target) {
    target.scrollIntoView({ behavior: "smooth", block: "start" });
  }
};
