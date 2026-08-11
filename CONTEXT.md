# Linksys Now UI

The Flutter web UI shipped inside router firmware. It runs from the router's own flash,
so its size competes directly with everything else in the firmware image.

## Language

### Payload

**Delivered payload**:
The subset of `flutter build web` output that is packaged into `/www/` on the router, and
therefore the only thing that consumes flash. Excludes build-time noise such as the SDK's
`canvaskit/` directory, which CI prunes. Roughly 29 MB as of SDK14.0 scoping.
_Avoid_: build output, `build/web` size, bundle size

**Build output**:
Everything `flutter build web` writes to `build/web/`, pruned material included. Over
twice the delivered payload, so it must never be quoted as a firmware size.

**Language pack**:
The per-locale unit of translated strings. Deleting an ARB file removes one; under
deferred loading each becomes its own file instead. Regional variants share their parent
language's pack (`zh_TW` ships with `zh`), so they cannot be selected independently.
_Avoid_: locale bundle, translation file

**Fallback font**:
A bundled font covering a script the primary font (NeueHaasGrotTextRound) does not: CJK,
Arabic, Thai, and extended Latin. Declared under `fonts:` rather than as a plain asset so
the engine registers it before the first frame and never probes the font CDN.

### Build flavours

**Retail build**:
The multi-region product. Ships every language pack and every fallback font.

**ISP build**:
A carrier-specific product with a narrower audience and a tighter flash budget. May ship
English only.

**English-only build**:
An ISP build with every language pack but English removed, and every fallback font but
extended Latin and Roboto removed. Produced by a build-time flag, not by a long-lived
branch.
_Avoid_: en-only fork, English fork

### Renderer

**CanvasKit variant**:
One of two interchangeable renderer builds. The *full* variant runs on every browser
because it carries its own image codecs and text-break logic; the *chromium* variant is
smaller because it borrows those from the browser. Both have always been part of the
delivered payload by design — the loader picks one at runtime, so only one is used per
session.
