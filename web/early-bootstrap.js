// early-bootstrap.js
// Extracted inline scripts for CSP compliance (removes need for 'unsafe-inline' in script-src)
// These scripts must run synchronously before body renders.

(function () {
  'use strict';

  // 1. PWA install prompt early capture
  window.deferredBeforeInstallPromptEvent = null;
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    window.deferredBeforeInstallPromptEvent = e;
    console.log('PWA: Early capture of beforeinstallprompt');
  });

  // 2. Theme detection and application
  var appSettingsString = window.localStorage.getItem('flutter.AppSettings');

  if (appSettingsString) {
    try {
      var settings = JSON.parse(JSON.parse(appSettingsString));
      var themeMode = settings.themeMode;
      if (themeMode === 'system') {
        var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        document.documentElement.setAttribute('data-theme', prefersDark ? 'dark' : 'light');
      } else {
        document.documentElement.setAttribute('data-theme', themeMode);
      }
    } catch (error) {
      console.error('app settings parse error: ', error);
    }
  } else {
    console.log('app settings not found, by system');
    var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.setAttribute('data-theme', prefersDark ? 'dark' : 'light');
  }

  // 3. Splash screen removal utility
  window.removeSplashFromWeb = function () {
    var splash = document.getElementById('splash');
    var branding = document.getElementById('splash-branding');
    if (splash) splash.remove();
    if (branding) branding.remove();
    document.body.style.background = 'transparent';
  };
})();
