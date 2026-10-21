// Every Preservable page's status lets the framework see a failed read
// (#1212, #1279).
//
// The decision guarded: after a save, `_PreservableDelegate.confirmSaved()`
// reads the router back and, when that read fails, keeps the page on what was
// written and throws `SavedButUnconfirmedError`. It finds the read's error
// through `HasServiceError` on the status `performFetch` returned. A status
// that carries an `error` but does not implement it still compiles, and the
// delegate then falls back to applying the failed status — the "saved" toast
// over an error page that 11 of 14 pages had.
//
// How it could silently revert: a new settings page copies an existing status
// class's shape, `final ServiceError? error;` and all, but not its `implements`
// clause. Nothing fails until the bench shows an error page after a save.
// A source scan because the target is a page that has not been written.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _mixinUse = RegExp(
  r'Preservable(?:AutoDispose)?NotifierMixin<\s*\w+\s*,\s*(\w+)\s*,',
);

void main() {
  List<File> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('each Preservable status with an error field implements HasServiceError',
      () {
    final files = dartFiles();
    final sources = {for (final f in files) f.path: f.readAsStringSync()};

    final statusTypes = <String>{
      for (final entry in sources.entries)
        if (!entry.key.startsWith('lib/framework/'))
          for (final m in _mixinUse.allMatches(entry.value)) m.group(1)!,
    };
    // Measured 2026-10-21: 14 status types across 15 notifiers (MAC Filter and
    // Instant Privacy share MacFilterStatus). A scan that finds far fewer has
    // stopped matching, not run out of pages.
    expect(statusTypes.length, greaterThanOrEqualTo(14),
        reason: 'the mixin-use pattern no longer matches; fix _mixinUse');

    final offenders = <String>[];
    for (final type in statusTypes) {
      final decl = RegExp('class $type\\b[^{]*\\{');
      final hits = [
        for (final entry in sources.entries)
          if (decl.hasMatch(entry.value)) (entry.key, entry.value),
      ];
      expect(hits, hasLength(1), reason: 'expected one declaration of $type');
      final (path, source) = hits.single;
      final match = decl.firstMatch(source)!;
      final header = match.group(0)!;
      // The class body only, not the whole file: a file can declare more than
      // one class, and another's `error` field must not satisfy this one.
      final next = RegExp(r'\n(?:abstract |final |sealed )*class ')
          .firstMatch(source.substring(match.end));
      final body = source.substring(
          match.end, next == null ? source.length : match.end + next.start);
      final hasError = body.contains(RegExp(r'ServiceError\?\s+error;'));
      expect(hasError, isTrue,
          reason: '$type ($path) has no `ServiceError? error` field — a page '
              'whose status cannot carry a read error needs a look, not an '
              'exemption');
      if (!header.contains('HasServiceError')) offenders.add('$type ($path)');
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These statuses carry a read error the Preservable delegate '
          'cannot see, so a failed post-save read puts an error page under '
          'the "saved" toast (#1212, #1279). Add `implements HasServiceError` '
          'and `@override` on the `error` field.',
    );
  });
}
