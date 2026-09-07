/// The gate's locale identity: one spelling, shared by every sweep (#1356).
///
/// ## Why this is a framework file and not three private copies
///
/// It was four. The three card sweeps each carried the same three lines, each
/// with a comment saying it matched the others; the chrome sweep instead called
/// `Locale.toLanguageTag()`, which spells the same locale `zh-TW` where the
/// others spell it `zh_TW`. Nothing was wrong per sweep, and the gate as a whole
/// had two vocabularies for one axis:
///
/// * The committed datasets disagree. `card.tsv` says `locale=zh_TW`, `chrome.tsv`
///   said `locale=zh-TW`, and a porter greps these ids by hand
///   (`doc/testing/overflow_baselines.md`).
/// * The allowlist compares tags. [OverflowRatchet.isAllowlisted] takes the tag
///   the sweep hands it and matches it against the locale list written in the
///   fixture, and `deadEntryFailure` compares the run's covered tag set the same
///   way. Only the card sweep consults the ratchet today; #1342 puts the chrome
///   sweep on the same runner, and a `zh-TW` from one sweep silently matching no
///   entry a human wrote as `zh_TW` is a failure that reads as "not deferred".
///
/// So the identity is defined once, here, and the sweeps import it.
///
/// ## Why the underscore form
///
/// Not because it is better — because it is what the fixture, the four committed
/// datasets and every existing test name already say. `zh_TW` is also the
/// `--dart-define=LOCALE=` vocabulary an operator types.
///
/// The country code is kept, rather than reduced to a language: regional variants
/// differ in label length (`fr` vs `fr_CA`, `pt` vs `pt_PT`), which is precisely
/// what these sweeps measure, so they have to stay distinct.
library;

import 'dart:ui' show Locale;

/// `en`, or `zh_TW` when the locale names a country.
String localeTag(Locale locale) {
  final country = locale.countryCode;
  return country == null || country.isEmpty
      ? locale.languageCode
      : '${locale.languageCode}_$country';
}
