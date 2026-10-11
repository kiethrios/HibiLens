(function () {
  "use strict";

  const assetsBase = new URL("./", document.currentScript.src);
  const fallbackAppStoreURL =
    "https://apps.apple.com/us/app/hibi-lens/id6792243095?l=en-US";
  const campaigns = Object.freeze({
    youtube:
      "https://apps.apple.com/app/apple-store/id6792243095?pt=128362381&ct=youtube&mt=8",
    instagram:
      "https://apps.apple.com/app/apple-store/id6792243095?pt=128362381&ct=instagram&mt=8",
  });
  const qrFiles = Object.freeze({
    youtube: "app-store-qr-youtube.png",
    instagram: "app-store-qr-instagram.png",
  });
  const fallbackQRFile = "app-store-qr-en.png";

  function acquisitionSource(search) {
    const source = new URLSearchParams(search).get("src");
    return Object.prototype.hasOwnProperty.call(campaigns, source)
      ? source
      : null;
  }

  function sourceAwareLanguageHref(href, source) {
    if (!source) return href;
    const separator = href.includes("?") ? "&" : "?";
    return `${href}${separator}src=${encodeURIComponent(source)}`;
  }

  const source = acquisitionSource(window.location.search);
  const appStoreURL = source ? campaigns[source] : fallbackAppStoreURL;
  const qrFile = source ? qrFiles[source] : fallbackQRFile;

  document.querySelectorAll("[data-app-store-cta]").forEach((element) => {
    element.href = appStoreURL;
  });
  document.querySelectorAll("[data-app-store-qr]").forEach((element) => {
    element.src = new URL(qrFile, assetsBase).href;
  });
  document.querySelectorAll("[data-language-link]").forEach((element) => {
    element.href = sourceAwareLanguageHref(element.getAttribute("href"), source);
  });
})();
