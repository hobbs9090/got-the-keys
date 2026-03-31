const themePreferenceStorageKey = "gotthekeys-theme-preference";
const validThemePreferences = new Set(["light", "dark", "system"]);

let systemThemeMediaQuery;
let systemThemeChangeHandler;
let themePreferenceChangeHandler;

const normalizeThemePreference = (value) => (validThemePreferences.has(value) ? value : "system");

const readStoredThemePreference = () => {
  try {
    return normalizeThemePreference(window.localStorage.getItem(themePreferenceStorageKey));
  } catch (_error) {
    return "system";
  }
};

const systemTheme = () => {
  if (!window.matchMedia) return "light";

  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
};

const syncThemeControls = (preference) => {
  document.querySelectorAll("[data-theme-preference-select]").forEach((select) => {
    select.value = preference;
  });

  document.querySelectorAll("[data-theme-toggle]").forEach((toggle) => {
    const select = toggle.querySelector("[data-theme-preference-select]");
    const selectedLabel = select?.selectedOptions?.[0]?.textContent?.trim() || preference;
    const summary = toggle.querySelector("[data-theme-preference-summary]");
    const summaryLabel = toggle.querySelector("[data-theme-preference-label]");
    const toggleLabel = toggle.dataset.themeToggleLabel || "Theme";

    if (summaryLabel) summaryLabel.textContent = selectedLabel;
    if (summary) summary.setAttribute("aria-label", `${toggleLabel}: ${selectedLabel}`);

    toggle.querySelectorAll("[data-theme-preference-option]").forEach((option) => {
      const isActive = option.dataset.themePreferenceOption === preference;
      option.classList.toggle("is-active", isActive);
      option.setAttribute("aria-pressed", isActive ? "true" : "false");
    });
  });
};

const dispatchThemeChange = (preference, resolvedTheme) => {
  if (typeof window.CustomEvent !== "function") return;

  try {
    document.dispatchEvent(
      new window.CustomEvent("theme:change", {
        detail: {
          preference,
          resolvedTheme
        }
      })
    );
  } catch (_error) {
  }
};

export const applyThemePreference = (value, { persist = false } = {}) => {
  const preference = normalizeThemePreference(value);
  const resolvedTheme = preference === "system" ? systemTheme() : preference;

  document.documentElement.dataset.themePreference = preference;
  document.documentElement.dataset.theme = resolvedTheme;
  document.documentElement.style.colorScheme = resolvedTheme;

  if (persist) {
    try {
      window.localStorage.setItem(themePreferenceStorageKey, preference);
    } catch (_error) {
    }
  }

  syncThemeControls(preference);
  dispatchThemeChange(preference, resolvedTheme);

  return resolvedTheme;
};

const updateSystemThemePreference = () => {
  if (document.documentElement.dataset.themePreference !== "system") return;

  applyThemePreference("system");
};

const bindSystemThemeListener = () => {
  if (systemThemeMediaQuery || !window.matchMedia) return;

  systemThemeMediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
  systemThemeChangeHandler = () => updateSystemThemePreference();

  if (typeof systemThemeMediaQuery.addEventListener === "function") {
    systemThemeMediaQuery.addEventListener("change", systemThemeChangeHandler);
  } else if (typeof systemThemeMediaQuery.addListener === "function") {
    systemThemeMediaQuery.addListener(systemThemeChangeHandler);
  }
};

const markThemeTogglesReady = () => {
  document.querySelectorAll("[data-theme-toggle]").forEach((element) => {
    element.dataset.themeToggleReady = "true";
  });
};

const bindThemePreferenceListener = () => {
  if (themePreferenceChangeHandler) return;

  themePreferenceChangeHandler = (event) => {
    const option = event.target.closest?.("[data-theme-preference-option]");
    if (option) {
      event.preventDefault();
      applyThemePreference(option.dataset.themePreferenceOption, { persist: true });
      option.closest("details")?.removeAttribute("open");
      return;
    }

    const select = event.target.closest?.("[data-theme-preference-select]");
    if (!select) return;

    applyThemePreference(select.value, { persist: true });
  };

  document.addEventListener("click", themePreferenceChangeHandler);
  document.addEventListener("change", themePreferenceChangeHandler);
};

export const bootThemePreference = () => {
  bindSystemThemeListener();
  bindThemePreferenceListener();

  const preference = readStoredThemePreference();
  applyThemePreference(preference);

  markThemeTogglesReady();
  document.documentElement.dataset.themeReady = "true";
};

export const teardownThemePreference = () => {
  document.querySelectorAll("[data-theme-toggle]").forEach((element) => {
    delete element.dataset.themeToggleReady;
  });
};
