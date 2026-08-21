/// The overflow allowlist ("ratchet"), keyed on `file:line` (#1341).
///
/// ## Why the key changed
///
/// Until #1341 the allowlist was keyed on the card sweep's own coordinates —
/// `card|widthLabel|tab`, optionally `@profile`. That key is a description of
/// *where the sweep was standing*, not of the defect, so every entry became
/// meaningless the moment a layout was rearranged: a card that gains a column
/// span, a threshold that moves, a tab that is added all invalidate the fixture
/// wholesale while the underlying overflow is untouched. A source location
/// survives all of it, and it is also the join column that makes golden CI's
/// advisory findings and this gate's verdicts one dataset
/// (`doc/testing/overflow_gate_architecture.md` §3.5 and §8).
///
/// The key is [OverflowIncident.site]. An incident whose creation location did
/// not resolve has a **null** site and therefore **can never be exempted**, no
/// matter what the fixture says — `"*"` on every site in the file does not cover
/// it. That is a deliberate consequence of the key choice and it is the safe
/// direction: an unresolvable location is a diagnostic the operator cannot act
/// on, so tolerating it would mean tolerating an overflow nobody can find. The
/// remedy is to fix the layout, or to make the location resolve (widget creation
/// tracking is on by default under `flutter test`).
///
/// ## What it is called
///
/// The architecture doc's §3.3 sketch writes `Ratchet.fromFixture(...)`. The
/// implementation is [OverflowRatchet], matching [OverflowIncident] and
/// `OverflowCell`: `Ratchet` alone is a very generic name to put in the test
/// tree's flat import namespace.
///
/// ## No version marker
///
/// A `"schemaVersion"` field was considered and rejected: the only thing it
/// could detect is a fixture written under the old key shape, and
/// [_validateSiteKey] detects that directly, from the data, with a message that
/// names the offending key. A marker would be a second thing to keep in sync and
/// a reader that trusted it would still have to validate the keys anyway. The
/// committed fixture is therefore byte-unchanged by #1341 — it holds
/// `{"tracking": {}, "allowlist": {}}`, and an empty allowlist means what it has
/// always meant: zero tolerance.
///
/// ## Loud, not silent
///
/// Every rejection below exists because the alternative — reading a key the
/// ratchet does not understand as "not allowlisted" — is how a stale exemption
/// becomes invisible: the gate stays green on the coordinate the author believed
/// they had exempted, and the dead-entry sweep never mentions the entry because
/// it never understood it. The old reader wrapped the whole load in
/// `catch (e) { print(...) }`; a printed warning in a 1,898-test run is not a
/// signal.
library;

import 'dart:convert';
import 'dart:io';

import 'incident.dart';

/// Where the committed fixture lives, relative to the app root that
/// `flutter test` runs in.
const String kKnownOverflowsFixturePath = 'test/fixtures/known_overflows.json';

/// The locale-set wildcard: "this site overflows in every locale", i.e. the
/// overflow is structural rather than text-length dependent.
const String kAnyLocale = '*';

/// Printed in place of a tracking note when a site has none.
///
/// The old default was `'baseline #1183'`, which was defensible while every
/// entry *was* #1183's debt and the key was a card. Under a site key a new
/// exemption can come from anywhere, and attributing it to #1183 by default
/// would be a fabricated citation.
const String kUntrackedNote = 'no "tracking" note in the fixture';

/// A fixture the ratchet refuses to read.
///
/// Separate from [FormatException] so a caller (and a test) can tell "the
/// allowlist is wrong" apart from any other parse failure in the same run.
class OverflowRatchetFormatException implements Exception {
  OverflowRatchetFormatException(this.message);

  final String message;

  @override
  String toString() => 'OverflowRatchetFormatException: $message';
}

/// The allowlist, plus the liveness it accumulates over one run.
///
/// Two responsibilities, and they are one object on purpose:
///
/// 1. **Consult** — is this incident, in this locale, exempt? ([consultCell])
/// 2. **Close** — did every exemption earn its keep? ([deadEntryFailure])
///
/// The second cannot be answered per cell, which is the whole design problem
/// #1341 had to solve. Under the old coordinate key it could: the exemption and
/// the cell were the same thing, so a clean cell whose own coordinate was listed
/// was provably a dead entry, and `_failIfDeadExemption` said so from inside that
/// cell. A site key breaks that identity — one site can be rendered by many
/// cells (anything in `ui_kit_library`, any shared row widget), so a site that
/// this cell renders cleanly may overflow in the next one. Judging deadness per
/// cell would therefore fail a clean cell for an entry that is alive elsewhere,
/// which is worse than not checking at all: it would push operators to delete
/// live exemptions.
///
/// So the verdict is taken **once, after the whole run**, over the union of every
/// site that overflowed anywhere — see [deadEntryFailure] for the guard that
/// keeps a *filtered* run from taking it, and for the one check this design
/// gives up.
class OverflowRatchet {
  OverflowRatchet._(this._allowlist, this._tracking, this.source);

  /// An allowlist that exempts nothing — zero tolerance.
  factory OverflowRatchet.empty({String source = _inMemorySource}) =>
      OverflowRatchet._(const {}, const {}, source);

  /// Reads the fixture at [path], or fails **closed** when it is absent.
  ///
  /// Absent means "nothing is exempt", which is the strict direction: every
  /// overflow fails, and no entry can be reported dead because there are none.
  /// It is also indistinguishable from today's committed fixture, so this cannot
  /// mask an exemption that exists. The path is still printed, because a wrong
  /// working directory otherwise looks exactly like a green gate.
  ///
  /// Content that *is* there but cannot be read throws — see
  /// [OverflowRatchetFormatException].
  factory OverflowRatchet.fromFixture([
    String path = kKnownOverflowsFixturePath,
  ]) {
    final file = File(path);
    if (!file.existsSync()) {
      // ignore: avoid_print
      print(
        '⚠️ No overflow allowlist at "$path" (cwd ${Directory.current.path}); '
        'running with zero tolerance and no dead-entry detection.',
      );
      return OverflowRatchet.empty(source: path);
    }
    return OverflowRatchet.fromJsonString(file.readAsStringSync(),
        source: path);
  }

  /// Parses [content] as the fixture document.
  ///
  /// Injected the same way and for the same reason as
  /// [OverflowIncident.parse]'s `runDirectory`: the ratchet's whole behaviour is
  /// then a pure function of a string, so #1341's oracle needs no checkout, no
  /// fixture file and no sweep.
  factory OverflowRatchet.fromJsonString(
    String content, {
    String source = _inMemorySource,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (e) {
      throw OverflowRatchetFormatException(
        '$source is not readable JSON: ${e.message}',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw OverflowRatchetFormatException(
        '$source must hold a JSON object with "tracking" and "allowlist" keys, '
        'not ${decoded.runtimeType}.',
      );
    }
    return OverflowRatchet.fromJson(decoded, source: source);
  }

  /// Builds a ratchet from an already-decoded document.
  factory OverflowRatchet.fromJson(
    Map<String, Object?> json, {
    String source = _inMemorySource,
  }) {
    final unknown = json.keys.where((k) => !_knownSections.contains(k)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw OverflowRatchetFormatException(
        '$source has unrecognised top-level key(s) ${_quoteAll(unknown)}. Only '
        '${_quoteAll(_knownSections)} are read, so anything else — a typo\'d '
        '"allow_list", a section from an older schema — is an exemption the '
        'gate silently would not honour.',
      );
    }

    final tracking = <String, String>{};
    final trackingSection = _sectionOf(json, 'tracking', source);
    for (final entry in trackingSection.entries) {
      _validateSiteKey(entry.key, section: 'tracking', source: source);
      final note = entry.value;
      if (note is! String || note.isEmpty) {
        throw OverflowRatchetFormatException(
          '$source: the "tracking" note for \'${entry.key}\' must be a '
          'non-empty string.',
        );
      }
      tracking[entry.key] = note;
    }

    final allowlist = <String, Set<String>>{};
    final allowSection = _sectionOf(json, 'allowlist', source);
    for (final entry in allowSection.entries) {
      _validateSiteKey(entry.key, section: 'allowlist', source: source);
      allowlist[entry.key] =
          _parseLocaleSet(entry.value, key: entry.key, source: source);
    }

    return OverflowRatchet._(allowlist, tracking, source);
  }

  /// `file:line` → the locale tags that overflow there, or `{'*'}`.
  final Map<String, Set<String>> _allowlist;

  /// `file:line` → why this exemption exists.
  ///
  /// Re-keyed on the site along with the allowlist, deliberately, rather than
  /// left card-keyed. Three reasons, in order of how much they cost to learn the
  /// hard way:
  ///
  /// * A site can be reached from several cards — anything in `ui_kit_library`,
  ///   any shared row — so a card-keyed note prints a *different* ticket
  ///   depending on which card happened to hit it, and the same defect gets two
  ///   notes that disagree.
  /// * "Remove the entry and its tracking note" is one lookup only if both hang
  ///   off one key. With two key spaces the note is what gets left behind, and a
  ///   note pointing at nothing is the dead entry the ratchet was built to
  ///   prevent, one level up.
  /// * The card sweep's is not the only family that will read this fixture
  ///   (#1342 onwards). `card` is not an axis the chrome family has.
  final Map<String, String> _tracking;

  /// Where this ratchet was loaded from, for messages: the fixture path, or
  /// [_inMemorySource] for a hand-built one.
  final String source;

  /// `file:line` → the locale tags that were *observed* overflowing there.
  ///
  /// Only significant incidents reach here, because only those can be exempted —
  /// see [consultCell].
  final Map<String, Set<String>> _observed = {};

  static const String _inMemorySource = '<in-memory allowlist>';
  static const List<String> _knownSections = ['tracking', 'allowlist'];

  /// A `file:line` key: a path ending in `.dart`, then a 1-based line.
  ///
  /// Loose about the path (a normalised path can be almost anything — see
  /// [normalizeOverflowSourcePath], which passes an unrecognised absolute path
  /// through unchanged) and strict about the shape, which is what tells a site
  /// apart from a leftover coordinate key. Line 0 is rejected because lines are
  /// 1-based: a `:0` would be a key that joins to nothing.
  ///
  /// The two exclusions are `|` and whitespace, and neither is decoration. `|`
  /// is the pre-#1341 coordinate's delimiter. Whitespace catches a
  /// hand-indented JSON key, which would join to nothing while reading as
  /// correct — at the price of a site under a checkout path containing a space,
  /// which is then un-exemptable and said so in [_validateSiteKey]. `@` is
  /// deliberately *not* excluded: it is legal in a path.
  static final RegExp _sitePattern = RegExp(r'^[^|\s]+\.dart:[1-9]\d*$');

  /// The sites this fixture exempts, sorted for deterministic messages.
  List<String> get sites => _allowlist.keys.toList()..sort();

  int get entryCount => _allowlist.length;

  bool get isEmpty => _allowlist.isEmpty;

  /// Whether [site] is exempt in [localeTag].
  ///
  /// Null [site] is never exempt — see the library comment for why that is the
  /// safe direction.
  bool isAllowlisted(String? site, String localeTag) {
    if (site == null) return false;
    final locales = _allowlist[site];
    if (locales == null) return false;
    return locales.contains(kAnyLocale) || locales.contains(localeTag);
  }

  /// The note explaining why [site] is exempt, or [kUntrackedNote].
  String trackingNote(String? site) =>
      (site == null ? null : _tracking[site]) ?? kUntrackedNote;

  /// Records every incident in [incidents] as live debt and returns the ones
  /// that are **not** exempt.
  ///
  /// Empty return = the cell is tolerated. A cell is only tolerated when *every*
  /// incident in it is exempt: "any" would let one known site launder a new
  /// overflow standing next to it, which is precisely the regression the gate
  /// exists to block.
  ///
  /// Recording and consulting are one call so they cannot diverge. Callers pass
  /// the **significant** incidents (above [kOverflowTolerancePx]) only —
  /// sub-tolerance noise is not something anyone exempts, and counting it as
  /// liveness would keep an entry alive on shaping jitter.
  List<OverflowIncident> consultCell(
    Iterable<OverflowIncident> incidents,
    String localeTag,
  ) {
    final blocking = <OverflowIncident>[];
    for (final incident in incidents) {
      final site = incident.site;
      if (site != null) {
        (_observed[site] ??= <String>{}).add(localeTag);
      }
      if (!isAllowlisted(site, localeTag)) blocking.add(incident);
    }
    return blocking;
  }

  /// The dead-entry verdict for a finished run, or null when there is none.
  ///
  /// Call this **once, after the last cell** — the whole run is the unit of
  /// judgement, because one site can be rendered by many cells.
  ///
  /// [localesCovered] is the locale tag set the run actually pumped.
  /// [coverageGaps] is every reason this run measured less than the full sweep,
  /// in the operator's own vocabulary (`--dart-define=LOCALE=…`, `MIN_SCREEN`,
  /// `run_overflow_test.sh --card`, a cell that threw before measuring). **A
  /// non-empty [coverageGaps] means no verdict at all**: a partial run cannot
  /// tell "this defect is fixed" from "this cell was not measured", and calling a
  /// live entry dead would send someone to delete a real exemption on the
  /// strength of a run that never looked. The guard lives here rather than at the
  /// call site so it cannot be forgotten by the next family to adopt the ratchet;
  /// [coverageSkipNote] is what tells the operator the closing direction was
  /// skipped.
  ///
  /// Four complaints, all falsifiable from what a full run observed:
  ///
  /// * **the whole entry** — no gated cell overflowed at that site;
  /// * **a listed locale tag** — the site still overflows, but not in that
  ///   locale;
  /// * **an over-broad `"*"`** — the site overflowed in a strict subset of the
  ///   locales the run covered, so the overflow is text-dependent, not
  ///   structural. This one rests on an assumption worth naming: that a widget's
  ///   *existence* in the tree does not depend on the locale, only its text
  ///   width does. That holds for every card in this sweep, and the message
  ///   prints the observed set so an operator can see the data rather than trust
  ///   the inference.
  /// * plus a locale tag the sweep does not run at all (`zh-TW` for `zh_TW`),
  ///   which is otherwise an exemption that can never match and can never die.
  ///
  /// ## What the old per-cell check caught and this does not
  ///
  /// `_failIfDeadExemption` fired on the **clean** path, so it could see a
  /// coordinate rendering cleanly. A site key cannot: the only thing an
  /// instrument built on `FlutterError.onError` observes is an overflow, so
  /// "site S was rendered here and fitted" is unobservable, and absence of an
  /// incident at S is indistinguishable from S never having been in the tree.
  /// Two consequences, both accepted:
  ///
  /// * **Granularity.** The old check named the exact clean coordinate; this one
  ///   names the site and the locales, and triage has to run
  ///   `./tool/run_overflow_test.sh -c <card> -d 2` to find which coordinate it
  ///   was. Deadness is no longer a property of a coordinate, so that is the
  ///   honest shape of the answer.
  /// * **Timing.** The old check failed the first clean cell, so it fired under a
  ///   single-card filtered run too. This one only fires on a full sweep. A
  ///   developer who fixes a card and re-runs `-c <card>` gets green and learns
  ///   about the leftover entry from the full gate (locally via
  ///   `flutter test --tags overflow`, or in CI). That is a later signal for the
  ///   same fact — and the alternative is a false "dead" verdict on a partial
  ///   run, which is a strictly worse error.
  String? deadEntryFailure({
    required Set<String> localesCovered,
    List<String> coverageGaps = const [],
  }) {
    if (coverageGaps.isNotEmpty) return null;
    if (_allowlist.isEmpty) return null;

    final complaints = <String>[];
    for (final site in sites) {
      final listed = _allowlist[site]!;
      final seen = _observed[site] ?? const <String>{};

      if (seen.isEmpty) {
        complaints.add(
          '$site — no gated cell overflowed there in this run. Delete the '
          'entry and its "tracking" note.',
        );
        continue;
      }

      final unknownTags = listed
          .where((tag) => tag != kAnyLocale && !localesCovered.contains(tag))
          .toList()
        ..sort();
      if (unknownTags.isNotEmpty) {
        complaints.add(
          '$site lists ${_quoteAll(unknownTags)}, which this sweep does not '
          'run. Locale tags are `_localeTag` form — `zh_TW`, `es_AR`, `pt_PT` — '
          'so a hyphenated or unknown tag exempts nothing and can never be '
          'reported dead either.',
        );
      }

      if (listed.contains(kAnyLocale)) {
        if (seen.length < localesCovered.length) {
          complaints.add(
            '$site is marked "*" — overflows in every locale — but only '
            '${seen.length} of ${localesCovered.length} covered locales '
            'overflowed there, so the overflow is text-dependent, not '
            'structural. Replace "*" with: ${_sorted(seen).join(', ')}.',
          );
        }
        continue;
      }

      final dead = listed.difference(seen).intersection(localesCovered);
      if (dead.isNotEmpty) {
        complaints.add(
          '$site — nothing overflowed there in ${_quoteAll(_sorted(dead))} '
          '(still overflowing in: ${_sorted(seen).join(', ')}). Remove those '
          'tags; delete the entry and its "tracking" note once the list '
          'empties.',
        );
      }
    }

    if (complaints.isEmpty) return null;
    return [
      'Dead exemption(s) in $source.',
      '',
      'This run measured every gated cell the sweep declares, so an allowlisted '
          'site that produced no significant overflow is an exemption whose '
          'defect is gone:',
      '',
      for (final complaint in complaints) '  * $complaint',
      '',
      'An exemption that outlives its defect is indistinguishable from tracked '
          'debt, which is how 46 stale coordinates came to be retired by hand '
          '(#1273) — so fixing a layout includes deleting its entry in the same '
          'change.',
      '',
      'Keys are `<file>:<line>`: the source location each incident\'s own report '
          'ends in ("… at lib/page/foo/bar.dart:47").',
    ].join('\n');
  }

  /// What to print when [coverageGaps] stopped [deadEntryFailure] from running,
  /// or null when there is nothing to say.
  ///
  /// Silent for an empty allowlist, which is the committed state: a green
  /// filtered run must stay as quiet as it is today, or the note becomes noise
  /// every `-c <card>` run prints and nobody reads.
  String? coverageSkipNote(List<String> coverageGaps) {
    if (coverageGaps.isEmpty || _allowlist.isEmpty) return null;
    return [
      'Dead-exemption detection skipped: this run measured less than the full '
          'sweep, so a site that did not overflow here may still overflow in a '
          'cell it left out.',
      for (final gap in coverageGaps) '  * $gap',
      '$entryCount allowlist entr${entryCount == 1 ? 'y' : 'ies'} went '
          'unchecked in the closing direction. Run the full sweep before '
          'deleting anything from $source.',
    ].join('\n');
  }

  /// The locale tags observed overflowing at [site] so far. Diagnostics.
  Set<String> observedLocalesAt(String site) =>
      Set.unmodifiable(_observed[site] ?? const <String>{});

  static Map<String, Object?> _sectionOf(
    Map<String, Object?> json,
    String name,
    String source,
  ) {
    final section = json[name];
    if (section == null) return const {};
    if (section is! Map<String, Object?>) {
      throw OverflowRatchetFormatException(
        '$source: "$name" must be a JSON object, not ${section.runtimeType}.',
      );
    }
    return section;
  }

  /// Throws unless [key] is a `file:line` site.
  ///
  /// The legacy shape gets its own message because it is the one an operator is
  /// most likely to be holding: `card|widthLabel|tab[@profile]` was the key from
  /// #1183 to #1341, and every closed ticket in that range quotes counts of it.
  static void _validateSiteKey(
    String key, {
    required String section,
    required String source,
  }) {
    if (_sitePattern.hasMatch(key)) return;
    // The tell is `|` alone, not `|` or `@`: every pre-#1341 key was
    // pipe-delimited (`card|widthLabel|tab`, the `@profile` only ever a suffix
    // on the last axis), whereas `@` on its own is legal in a file path. Keying
    // the paragraph on `@` made a rejected path print an accusation of being a
    // coordinate when it plainly was not.
    final diagnosis = key.contains('|')
        ? ' It is the pre-#1341 coordinate shape '
            '(`card|widthLabel|tab[@profile]`), which no longer matches '
            'anything: the ratchet keys on where the overflowing widget was '
            'created, not on where the sweep was standing when it saw it.'
        // Whitespace is named rather than left to the reader to spot, because
        // the two ways it gets in are both invisible: a hand-indented JSON key,
        // and a checkout path with a space in it that
        // [normalizeOverflowSourcePath] passed through unrecognised. The second
        // is a site the sweep really can emit and this really cannot exempt —
        // say so instead of implying the key was written wrong.
        : key.contains(RegExp(r'\s'))
            ? ' The key contains whitespace, which a site key may not: if it is '
                'padding, remove it; if the space is genuinely in the path, '
                'this entry cannot be expressed and the layout has to be fixed '
                '(or the file moved out from under the space).'
            : '';
    throw OverflowRatchetFormatException(
      '$source: "$section" key \'$key\' is not a `file:line` source location.'
      '$diagnosis '
      'Expected e.g. \'lib/page/dashboard/views/components/foo_card.dart:47\' — '
      'the location the failing incident\'s own report ends in '
      '("… at <file>:<line>"). Re-derive the entries from a full sweep rather '
      'than translating the old keys by hand; a coordinate does not carry which '
      'widget inside the card overflowed.',
    );
  }

  static Set<String> _parseLocaleSet(
    Object? value, {
    required String key,
    required String source,
  }) {
    if (value is! List) {
      throw OverflowRatchetFormatException(
        '$source: \'$key\' must map to a JSON array of locale tags (or '
        '["*"]), not ${value.runtimeType}.',
      );
    }
    final tags = <String>{};
    for (final tag in value) {
      if (tag is! String || tag.isEmpty) {
        throw OverflowRatchetFormatException(
          '$source: \'$key\' holds a non-string locale tag ($tag). Tags are '
          '`_localeTag` strings — `de`, `zh_TW` — or the single wildcard "*".',
        );
      }
      tags.add(tag);
    }
    if (tags.isEmpty) {
      throw OverflowRatchetFormatException(
        '$source: \'$key\' exempts no locale. An empty array is an entry that '
        'can only ever read as an exemption that is not one — delete the entry '
        'instead.',
      );
    }
    if (tags.contains(kAnyLocale) && tags.length > 1) {
      throw OverflowRatchetFormatException(
        '$source: \'$key\' mixes "*" with explicit tags '
        '(${_quoteAll(_sorted(tags))}). "*" already covers every locale, so the '
        'explicit tags are either redundant or the "*" is wrong — and the '
        'over-broad check cannot tell which was meant. Pick one.',
      );
    }
    return tags;
  }

  static List<String> _sorted(Iterable<String> values) =>
      values.toList()..sort();

  static String _quoteAll(Iterable<String> values) =>
      values.map((v) => '"$v"').join(', ');
}
