// Service worker for the Linksys PWA. flutter_bootstrap.js registers it on every
// page load (serviceWorkerUrl), and the loader waits up to 4 s for it to
// activate before it starts the app. It caches nothing.
//
// It must not import the build's flutter_service_worker.js. That file is a
// cleanup worker that unregisters itself and reloads every page it controls;
// imported here, it reloaded the page on every load (#1623). The full account
// is the #1623 group in test/web/canvaskit_variant_test.dart, which also guards
// this file.
//
// No fetch handler. The old wrapper had none either, so this keeps today's
// install behaviour rather than changing it. Desktop Chrome 154 fired
// beforeinstallprompt for this manifest with no handler; Android and the DU
// models were not measured. If they need one, see the note on that check in
// the test before adding it.

// Activate as soon as it is installed, instead of waiting for every tab still
// running an older worker to close.
self.addEventListener('install', () => {
  self.skipWaiting();
});

// Take control of pages that are already open, so they do not keep the
// previous worker.
self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
});
