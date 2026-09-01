(function () {
  "use strict";

  const STORAGE_KEY = "hibiLensLocale";
  const SUPPORTED = new Set(["en", "zh-Hans"]);
  const FALLBACK_APP_STORE_URL =
    "https://apps.apple.com/us/app/hibi-lens/id6792243095?l=en-US";
  const APP_STORE_CAMPAIGNS = Object.freeze({
    youtube:
      "https://apps.apple.com/app/apple-store/id6792243095?pt=128362381&ct=youtube&mt=8",
    instagram:
      "https://apps.apple.com/app/apple-store/id6792243095?pt=128362381&ct=instagram&mt=8",
  });
  const APP_STORE_QR = Object.freeze({
    youtube: "./assets/app-store-qr-youtube.png",
    instagram: "./assets/app-store-qr-instagram.png",
  });
  const FALLBACK_APP_STORE_QR = "./assets/app-store-qr-en.png";
  const payload = JSON.parse(document.getElementById("locale-data").textContent);
  const toggles = document.querySelectorAll("[data-language-toggle]");

  function acquisitionSource(search) {
    const source = new URLSearchParams(search).get("src");
    return Object.prototype.hasOwnProperty.call(APP_STORE_CAMPAIGNS, source)
      ? source
      : null;
  }

  function applyAppStoreRouting(search) {
    const source = acquisitionSource(search);
    const href = source ? APP_STORE_CAMPAIGNS[source] : FALLBACK_APP_STORE_URL;
    const qr = source ? APP_STORE_QR[source] : FALLBACK_APP_STORE_QR;

    document.querySelectorAll("[data-app-store-cta]").forEach((element) => {
      element.href = href;
    });
    document.querySelectorAll("[data-app-store-qr]").forEach((element) => {
      element.src = qr;
    });
  }

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

    applyAppStoreRouting(window.location.search);
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
