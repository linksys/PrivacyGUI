---
status: accepted
---

# English-only builds strip localization at build time, not in a branch

ISP builds on SDK14.0 have a tight firmware flash budget, and localization is the largest
part of the delivered payload we can give up: 1.65 MB of translated strings compiled into
`main.dart.js` plus 2.23 MB of fallback fonts, 3.88 MB in total out of ~29 MB. We produce
these builds by having a script delete the non-English ARB files and the CJK/Arabic/Thai
fallback fonts before the build and restore them after, exposed as a Jenkins build
parameter — so English-only is a build flavour, not a branch that has to be maintained.

The flavour is selected by a `LOCALES` environment variable on `build_web.sh`, not by a
tenth positional parameter: unset or `all` builds byte-for-byte what it built before, so
every existing caller — Jenkins included — is untouched, and the Jenkins job adds one
parameter that sets it.

## Considered Options

**Deferred localization loading** (`use-deferred-loading` in `l10n.yaml`), which compiles
each locale into its own `.part.js` file so packaging can ship a subset. Measured: it
moves 1.65 MB out of `main.dart.js` but the part files land in the same directory, making
the delivered payload 72 KB *larger* when all locales ship. It only saves flash once the
files are deleted — which is what stripping already does, and stripping keeps
`lookupAppLocalizations` synchronous, where deferred loading turns it into a `Future` and
breaks existing callers.

**On-demand language packs from the cloud.** Technically available — dart2js exposes a
`self.dartDeferredLibraryLoader` hook that can be overridden to fetch part files from
anywhere, and `web/early-bootstrap.js` already loads early enough to install it. Rejected
because it saves no flash over deleting the files, it fails in the router's most common
situation (a LAN client with no WAN configured, e.g. during PnP setup), it would give up
the offline-first guarantee that motivated declaring fonts under `fonts:` in the first
place, and it needs cloud hosting, CORS and a CSP relaxation this repo cannot deliver
alone.

**A long-lived English-only branch.** Rejected: `app_en.arb` changes with nearly every
feature, so a branch that deletes its 25 siblings pays a merge conflict on every sync
with the development branch. A script pays nothing and can regenerate the flavour from
any commit.

## Consequences

The English-only build cannot render scripts the remaining fonts do not cover, so
user-supplied non-Latin text (a CJK SSID, a device name) shows as tofu when the router is
offline. `fontFallbackBaseUrl` still points at the font CDN, so it renders when the client
has internet.

`FallbackFontResolver` is deliberately left untouched, so in an English-only build it
returns family names that are no longer registered. This costs nothing: the engine's
fallback manager keys off unresolved *code points*, not invalid family names, and a code
point with no local coverage takes the same CDN path either way — the resolver returning
`null` would not change a single request. Do not add a build flag to teach the resolver
which fonts survived; there is nothing for it to buy, and it would introduce a second
source of truth alongside the strip script.

The settings popup omits the language picker when only one language pack shipped, decided
by the parent (`GeneralSettingsWidget`) rather than the tile hiding itself, because the
tile sits in a fixed-height `SizedBox` that would otherwise leave a 44px hole.

Firmware image size is verified outside this repo. What this repo delivers and can prove
is the reduction in delivered payload, which `tools/measure_payload.sh` prints at the end
of every build.
