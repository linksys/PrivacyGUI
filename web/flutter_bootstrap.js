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
//                                   a fresh random value per build, so the
//                                   service worker never invalidated and
//                                   returning clients could hold a stale bundle
//                                   across releases.
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
    // browsers to assets/chromium/canvaskit.js — which no longer exists — and
    // the loader has no 404 fallback, so the app never boots.
    canvasKitVariant: "full"
  },
  serviceWorkerSettings: {
    // Unquoted: the substitution supplies its own quotes (and a deprecation
    // notice comment). Wrapping this in quotes produces a syntax error.
    serviceWorkerVersion: {{flutter_service_worker_version}},
    // Ours. We ship web/service_worker.js; the tool's default would be
    // flutter_service_worker.js, which this project does not generate.
    serviceWorkerUrl: "service_worker.js"
  }
});
