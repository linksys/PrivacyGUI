// constitution.md §13.4: the provider layer handles `ServiceError` only. A
// timeout is no exception: it reaches a provider as a `TimeoutError`, raised where
// the timeout is — the mutation lock, the operation awaiter and the request
// throttler in `lib/core/usp/` — or by the provider's own `onTimeout`. A provider
// that names Dart's `TimeoutException` is either catching one of those sources
// untyped or keeping a deadline of its own as an exception (#1831).
//
// The rule, as this test reads it: no file under a `providers/` directory of
// `lib/page/`, at any depth, and no file under `lib/providers/`, names
// `TimeoutException` in code. Comments are blanked first, so a comment that
// explains the rule does not count. There is no allowlist.
//
// Outside it, each a known gap rather than an oversight:
// - A provider's `.timeout(...)` with no `onTimeout`, caught on the spot by a bare
//   `catch` that only degrades or logs (#1831, Out of scope). It throws a
//   `TimeoutException`, but never names it, and never lets it out.
// - Services and `lib/core/`, which may catch their own `.timeout()` (a SET whose
//   answer the disconnect it causes swallows).
// - Views, cards and widgets. §13.1 holds them to `ServiceError` too, but they
//   read errors from provider state rather than catching; none names
//   `TimeoutException` today.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The identifier `TimeoutException`, whole: not `TimeoutExceptionFoo`, not
/// `MyTimeoutException`.
final _timeoutException = RegExp(r'\bTimeoutException\b');

/// [source] with its comments blanked to spaces — `//` to end of line, and
/// `/* … */` — so a comment does not count. Newlines are kept, so a match's line
/// number is the line in the file. The same blanking as
/// `generated_types_only_in_services_test.dart`.
String _withoutComments(String source) => source
    .replaceAllMapped(RegExp(r'/\*[\s\S]*?\*/'),
        (m) => m[0]!.replaceAll(RegExp(r'[^\n]'), ' '))
    .replaceAllMapped(RegExp(r'//[^\n]*'), (m) => ' ' * m[0]!.length);

void main() {
  /// Every Dart file under a `providers/` directory of `lib/page/`, and under
  /// `lib/providers/`.
  List<File> providerFiles() => [
        ...Directory('lib/page')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.split('/').contains('providers')),
        ...Directory('lib/providers')
            .listSync(recursive: true)
            .whereType<File>(),
      ].where((f) => f.path.endsWith('.dart')).toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('the scan reaches the files it is meant to', () {
    // A guard that finds no files passes by construction. These are known to
    // exist, one per root and one nested; if one drops out the path filter is
    // wrong, not the code clean.
    final paths = providerFiles().map((f) => f.path).toSet();
    expect(paths, isNotEmpty);
    expect(
        paths, contains('lib/page/instant_setup/providers/pnp_notifier.dart'));
    expect(
        paths,
        contains(
            'lib/page/_shared/providers/usp_device_analytics_notifier.dart'));
    expect(paths, contains('lib/providers/auth/auth_provider.dart'));
  });

  test('no provider names TimeoutException in code', () {
    final offenders = <String>[];
    for (final f in providerFiles()) {
      final source = _withoutComments(f.readAsStringSync());
      for (final m in _timeoutException.allMatches(source)) {
        final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
        offenders.add('${f.path}:$line');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'constitution 13.4: a provider handles ServiceError only, so a '
          'timeout reaches it as a TimeoutError. Catch TimeoutError where the '
          'source already raises one (the mutation lock, the operation '
          'awaiter, the request throttler), or give your own `.timeout()` an '
          '`onTimeout` that throws TimeoutError or returns a value (#1831).\n'
          '${offenders.join('\n')}',
    );
  });

  test('a commented TimeoutException does not count, and code does', () {
    // The two halves of the matcher this guard rests on, checked on literals so
    // a regex edit that drifts either way fails here rather than silently.
    const commented = '''
// A bare `TimeoutException` used to escape here.
/* } on TimeoutException { */
final x = 1;
''';
    const code = '''
try {
  await f();
} on TimeoutException catch (e) {
''';
    // Another identifier that only contains the name, on either side.
    const prefixed = 'class MyTimeoutException {}';
    const suffixed = 'class TimeoutExceptionAdapter {}';
    expect(_timeoutException.hasMatch(_withoutComments(commented)), isFalse);
    expect(_timeoutException.hasMatch(_withoutComments(code)), isTrue);
    expect(_timeoutException.hasMatch(prefixed), isFalse);
    expect(_timeoutException.hasMatch(suffixed), isFalse);
  });
}
