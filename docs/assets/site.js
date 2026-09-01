(function () {
  "use strict";

  const STORAGE_KEY = "hibiLensLocale";
  const SUPPORTED = new Set(["en", "zh-Hans"]);
  const payload = JSON.parse(document.getElementById("locale-data").textContent);
  const toggles = document.querySelectorAll("[data-language-toggle]");

  function storedLocale() {
    try {
      const value = localStorage.getItem(STORAGE_KEY);
      return SUPPORTED.has(value) ? value : null;
    } catch (error) {
      return null;
    }
  }

  function browserLocale() {
    const hasUsableLanguages =
      Array.isArray(navigator.languages) &&
      navigator.languages.length > 0 &&
      navigator.languages.some((value) => typeof value === "string");
    const languages = hasUsableLanguages
      ? navigator.languages
      : [navigator.language || "en"];
    return languages.some(
      (value) =>
        typeof value === "string" && value.toLowerCase().startsWith("zh")
    )
      ? "zh-Hans"
      : "en";
  }

  function applyLocale(locale, persist) {
    const dictionary = payload[locale];
    document.documentElement.lang = locale;

    document.querySelectorAll("[data-i18n]").forEach((element) => {
      element.textContent = dictionary[element.dataset.i18n];
    });
    document.querySelectorAll("[data-i18n-href]").forEach((element) => {
      element.href = dictionary[element.dataset.i18nHref];
    });
    document.querySelectorAll("[data-i18n-src]").forEach((element) => {
      element.src = dictionary[element.dataset.i18nSrc];
    });
    document.querySelectorAll("[data-i18n-alt]").forEach((element) => {
      element.alt = dictionary[element.dataset.i18nAlt];
    });
    document.querySelectorAll("[data-i18n-aria-label]").forEach((element) => {
      element.setAttribute(
        "aria-label",
        dictionary[element.dataset.i18nAriaLabel]
      );
    });

    if (persist) {
      try {
        localStorage.setItem(STORAGE_KEY, locale);
      } catch (error) {
        // The selected locale still applies when storage is unavailable.
      }
    }
  }

  let locale = storedLocale() || browserLocale();
  applyLocale(locale, false);

  toggles.forEach((toggle) => {
    toggle.addEventListener("click", () => {
      locale = locale === "en" ? "zh-Hans" : "en";
      applyLocale(locale, true);
    });
  });
})();
