---
status: accepted
---

# English-only builds strip localization at build time, not in a branch

ISP builds on SDK14.0 have a tight firmware flash budget, and localization is the largest
part of the delivered payload we can give up. Measured on real builds: 29,812 KB → 25,908 KB,
a 3,904 KB (3.81 MB) reduction out of ~29 MB — 1,608 KB of translated strings compiled into
`main.dart.js` plus 2,296 KB of fallback fonts. We produce these builds by having a script
delete the non-English ARB files and the CJK/Arabic/Thai fallback fonts before the build and
restore them after, exposed as a Jenkins build parameter — so English-only is a build
flavour, not a branch that has to be maintained.

This is short of the 5 MB the request asks for, and the remaining ~1.2 MB is not in
localization: the next candidates are `NOTICES` (1,488 KB) and `oui_database.json`
(1,440 KB), both of which need agreement outside this repo.

The flavour is selected by a `LOCALES` environment variable on `build_web.sh`, not by a
tenth positional parameter: unset or `all` builds byte-for-byte what it built before, so
every existing caller — Jenkins included — is untouched. The Jenkins freestyle job adds one
string parameter and no new shell step, because Jenkins exports build parameters as
environment variables; see [Jenkins wiring](../jenkins-english-only-build.md).

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

The strip is restored by an `EXIT` trap, which a `SIGKILL` (what a Jenkins abort escalates
to) would skip. On CI the restore buys nothing either way: the job wipes its workspace and
re-clones every build, and the payload is already in `build/web` by then, so a stripped
source tree cannot reach the next build — a fact worth re-checking before switching any job
to reusing its workspace. It exists for the developer who runs an English-only build in
their own working tree, where an unrestored strip means the next `git commit -a` commits the
deletion of 25 language packs.

`pubspec.yaml` is not in the path list that restore checks out of git, even though the strip
rewrites its `fonts:` block. A CI job stamps the version into the pubspec before building,
so checking the file out would silently revert that stamp — and the pre-strip gate, which
refuses to run when a restorable path has local changes, failed every CI build for exactly
that reason. Restore swaps in the committed `fonts:` block by line range instead, bounded by
the next key at two-space indent, leaving every other line — the version among them —
untouched. The gate still refuses when a *language pack* is edited, which is the case it was
built for.

Firmware image size is verified outside this repo. What this repo delivers and can prove
is the reduction in delivered payload, which `tools/measure_payload.sh` prints at the end
of every build.
