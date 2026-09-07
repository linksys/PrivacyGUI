/// Composed scenes for `usp_apps_view` (#1380, wave 4).
///
/// The page's data does not come from USP at all — `UspAppsService` reads
/// `/api/apps.json`, a static file lighttpd serves and `app_util.lua` rewrites on
/// every `opkg install`/`remove` — so there is no codegen model to build from and
/// no `test/mocks/test_data/[feature]_test_data.dart` builder to compose. The
/// shape below is the service's own parse contract: `apps` becomes
/// [AppCategory.system], `userApps` becomes [AppCategory.user], and the two lists
/// are concatenated in that order.
library;

import 'package:flutter/material.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:privacy_gui/page/apps/providers/usp_apps_notifier.dart';

/// The router shape every `page.apps` cell is measured against.
///
/// Six apps because that is what the grid needs to be a grid at both ends of the
/// sweep: `crossAxisCount` is 3 above the mobile breakpoint and 1 below it, so six
/// is two full desktop rows and six mobile ones. Fewer than four and the desktop
/// band never fills a row, which is the only band where a card's box is set by the
/// column count rather than by the screen.
///
/// The three badge states are all present and each is there for a layout reason,
/// not for coverage's sake — the badge shares the card's header `Row` with a 36px
/// icon tile under `spaceBetween`:
///
/// - `Files` is in [gateAppsRecentlyInstalled], so it paints the `New` badge;
/// - `Terminal` and `Analytics` are `AppCategory.user` and not recent, so they
///   paint `USER` — the wider of the two labels in most locales, and the one the
///   601px header-row budget in `page_surface_overflow_test.dart` runs against;
/// - the other three paint no badge, which is the widest the name below can be.
///
/// The names are deliberately ordinary. A 40-character app name would find an
/// overflow this page cannot actually have — `_AppGridCard` gives both the name
/// and the description `TextOverflow.ellipsis` — and would spend 234 cells
/// proving that an ellipsis works. What the sweep is here to find is the header
/// `Row` and the page's own title/`Store` row, and those are driven by the 26
/// locales, not by the fixture.
final gateAppsState = UspAppsState(
  apps: gateApps,
  recentlyInstalledNames: gateAppsRecentlyInstalled,
);

/// System apps first, then user apps — `UspAppsService._parseApps`' order.
final gateApps = <AppInfoUIModel>[
  const AppInfoUIModel(
    name: 'Files',
    description: 'Browse and share files on attached USB storage',
    link: 'http://192.168.1.1/files/',
    version: '1.2.0',
    iconData: Icons.folder,
    color: Colors.blueAccent,
    category: AppCategory.system,
  ),
  const AppInfoUIModel(
    name: 'VPN',
    description: 'WireGuard tunnels for remote access',
    link: 'http://192.168.1.1/vpn/',
    version: '0.9.4',
    iconData: Icons.vpn_key,
    color: Colors.tealAccent,
    category: AppCategory.system,
  ),
  const AppInfoUIModel(
    name: 'Storage',
    description: 'Disk usage and share permissions',
    link: 'http://192.168.1.1/storage/',
    version: '1.0.1',
    iconData: Icons.storage,
    color: Colors.indigoAccent,
    category: AppCategory.system,
  ),
  const AppInfoUIModel(
    name: 'Monitoring',
    description: 'Per-client throughput history',
    link: 'http://192.168.1.1/monitoring/',
    version: '2.1.0',
    iconData: Icons.monitor_heart,
    color: Colors.greenAccent,
    category: AppCategory.system,
  ),
  const AppInfoUIModel(
    name: 'Terminal',
    description: 'Shell access over the LAN',
    link: 'http://192.168.1.1/terminal/',
    version: '0.4.2',
    iconData: Icons.terminal,
    color: Colors.orangeAccent,
    category: AppCategory.user,
  ),
  const AppInfoUIModel(
    name: 'Analytics',
    description: 'Traffic breakdown by application',
    link: 'http://192.168.1.1/analytics/',
    version: '1.5.3',
    iconData: Icons.analytics,
    color: Colors.purpleAccent,
    category: AppCategory.user,
  ),
];

/// What `UspAppsState.isNew` answers true for.
///
/// One name, and it is a *system* app on purpose: `_AppGridCard` paints `USER`
/// only `if (app.category == AppCategory.user && !isNew)`, so putting the recent
/// name on a user app would hide one of the two badges behind the other and the
/// sweep would never render `USER` at all.
const gateAppsRecentlyInstalled = <String>{'Files'};

/// How many `AppBadge`s [gateApps] paints: one `New` and two `USER`.
///
/// Named because the 601px header-row guard iterates every badge in the grid
/// rather than the first card's, and a fixture edit that changed a category or the
/// recent name would otherwise silently shrink what that guard measures — which is
/// how it came to report `ar`'s 21.5px `New` badge as this page's worst case.
const gateAppsBadgeCount = 3;

/// The state the empty-list branch renders, kept for a future case.
///
/// Not swept today: an empty page is one centred icon and one line of text, so it
/// has no `Row` the gate could find anything in, and it would cost the same 234
/// cells as the populated one. Named here rather than inlined so that the reason
/// it is absent is written down where the fixture would go.
const gateAppsEmptyState = UspAppsState();
