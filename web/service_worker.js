// Custom service worker loader for Linksys PWA
// This file acts as a wrapper around the auto-generated flutter_service_worker.js
// to ensure we satisfy PWA requirements while maintaining Flutter's asset caching.

// Import the auto-generated service worker
importScripts('flutter_service_worker.js');

// Force immediate activation when a new SW is installed
self.addEventListener('install', (event) => {
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    // Claim any clients immediately, so the new SW controls the page ASAP
    event.waitUntil(clients.claim());
});
