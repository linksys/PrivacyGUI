// THIS FILE IS A TEMPLATE. The three {{...}} placeholders below are filled in
// by `flutter build web` — it reads this committed file and substitutes into it
// (WebTemplate.withSubstitutions). Do NOT replace one with the value you see in
// build/web/flutter_bootstrap.js.
//
// That is not a hypothetical warning. All three had been replaced with literals,
// and because the substitution then had nothing to do, the shipped loader stopped
// being refreshed by any SDK upgrade. The tell was that
// `cmp web/flutter_bootstrap.js build/web/flutter_bootstrap.js` reported the two
// files IDENTICAL — for a template, that means it is not one. Three things had
// silently frozen (#1316):
//
//   flutter_js                      an embedded, minified 3.27-era flutter.js,
//                                   identifiable by its `navigator.agent==="Edg/"`
//                                   test — not a real property, so that Edge
//                                   branch never fired. 3.44+ replaced it with
//                                   navigator.userAgent.includes("Edg/").
//   flutter_build_config            engineRevision pinned to
//                                   cf56914b326edb0ccb123ffdc60f00060bd513fa,
//                                   which is neither 3.44.0's engine nor 3.47.0's,
//                                   and no wasmHashes at all (3.47 emits them and
//                                   instantiate_wasm.js reads them for
//                                   Cross-Origin Storage).
//   flutter_service_worker_version  a constant "3346174710" where the build puts
//                                   a fresh value per build. Currently INERT for
//                                   this project — see the note under
//                                   serviceWorkerVersion below for the measurement
//                                   and its expiry date. It is restored because it
//                                   is the tool's value to fill, not because it
//                                   was breaking anything.
//
// Guarded by test/web/canvaskit_variant_test.dart, which asserts the placeholders
// are here and that none of the values above is written by hand.
//
// The placeholders are named without braces throughout this comment on purpose:
// the substitution is a plain regex over the whole file and rewrites every
// double-braced name it matches, comments included. A name it does not recognise
// survives verbatim instead, so writing one here would ship a stray token into
// build/web/flutter_bootstrap.js.
//
// The `config:` and `serviceWorkerSettings.serviceWorkerUrl` values below are
// OURS, not the tool's. Nothing substitutes them, and #1281 depends on two of
// them — keep them across any upgrade.
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    // Offline-first fonts are eager-loaded via pubspec fonts: (CJK/non-Latin
    // subsets + Roboto), so everything the UI needs renders without network.
    // fontFallbackBaseUrl stays on the CDN so that when online, code points
    // outside the bundled subsets (e.g. rare user-typed CJK) can still be
    // fetched on demand (A+). Offline, these simply don't load — the bundled
    // fonts already cover all interface text.
    fontFallbackBaseUrl: "https://fonts.gstatic.com/s/",
    // OFFLINE-CRITICAL — do not remove or change. This is the only reason
    // CanvasKit resolves locally: buildConfig above has no useLocalCanvasKit,
    // so without this line the loader falls back to
    // https://www.gstatic.com/flutter-canvaskit/<engineRevision>/ and the GUI
    // white-screens with no WAN. Guarded by
    // test/web/canvaskit_variant_test.dart.
    canvasKitBaseUrl: "./assets/",
    // Pins every browser to the "full" CanvasKit build so only one variant
    // ships (#1281). Without this, capability detection routes Chromium-based
    // browsers to a variant subdirectory that this repo does not ship, and the
    // loader has no 404 fallback, so the app never boots.
    //
    // Under 3.47 that is now TWO wrong destinations, not one: the loader checks
    // `variant !== "full"` first and only then picks between
    // assets/webparagraph/ (if preferWebParagraph and the browser has
    // TextCluster) and assets/chromium/. Both are reachable only through that
    // one negated check, which is why this single line still covers both — but
    // anyone who deletes it is now opening two holes. The SDK does ship both
    // (3.47's wasmHashes lists webparagraph/canvaskit.wasm and
    // chromium/canvaskit.wasm); we vendor neither.
    canvasKitVariant: "full"
  },
  serviceWorkerSettings: {
    // Unquoted: the substitution supplies its own quotes (and a deprecation
    // notice comment). Wrapping this in quotes produces a syntax error.
    //
    // INERT for this project as configured, measured against the loader we
    // actually ship — 3.47.2's bin/cache/flutter_web_sdk/flutter_js/flutter.js,
    // which is what the flutter_js placeholder above substitutes (named without
    // braces here for the reason that comment gives). That file destructures the
    // value exactly once, and both of its uses are dead here:
    //
    //   let {serviceWorkerVersion: r,
    //        serviceWorkerUrl: i = m(`flutter_service_worker.js?v=${r}`)} = e
    //   ... .register(c).then(l => this._getNewServiceWorker(l, r))
    //   _getNewServiceWorker(e, s) { ... if (e.active.scriptURL.endsWith(s)) ... }
    //
    // The `?v=` URL is a DEFAULT, so supplying serviceWorkerUrl below skips it;
    // and the only other consumption is endsWith(version) against that same URL,
    // which has no `?v=` query, so it is false for every value — frozen or fresh
    // — and registration.update() runs on every load either way.
    //
    // Expiry, both halves of it: this holds only while serviceWorkerUrl below is
    // overridden (the tool's default URL embeds the version, so removing the
    // override makes it load-bearing immediately), and only while the SDK's
    // flutter.js consumes it this way. Re-measure on a pin bump rather than
    // trusting this paragraph — `grep -c serviceWorkerVersion` on that file
    // returns 1 today, and a second occurrence means the reasoning changed. That
    // file is a precached artifact, so `flutter precache --web` first.
    serviceWorkerVersion: {{flutter_service_worker_version}},
    // Ours, and it does more than rename the file. web/service_worker.js
    // importScripts the generated flutter_service_worker.js (the build DOES emit
    // it — 784 bytes, and identical in 3.44 and 3.47) and adds skipWaiting +
    // clients.claim on top, which is what the PWA install prompt needs.
    //
    // Setting this key at all also changes registration: the loader registers
    // unconditionally when a custom URL is given, whereas the default path first
    // checks getRegistration() and does nothing if there is none. It logs
    // flutter/flutter#156910 ("loading the service worker using Flutter
    // bootstrap is deprecated") for exactly that reason, so this line is a known
    // future migration and not a settled decision.
    serviceWorkerUrl: "service_worker.js"
  }
});
