import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `run_generate_loc_snapshots.sh`'s locale loop: one failing locale must
/// not cost the other 25 (#1477).
///
/// ## Why this shells out instead of asserting on the file's text
///
/// The defect is control flow, not wording. `set -e` plus a bare `$FLUTTER test`
/// inside the loop means the *first* non-zero exit aborts the script, and the
/// remaining locales are never attempted — a one-page crash turns a 26-locale
/// generation into one locale of output, with no report and nothing saying so. A
/// grep for the accumulation idiom would pass the moment that idiom appears
/// anywhere in the file; only running it proves the loop continues.
///
/// So this copies the shipped script into a temp directory, puts a fake `fvm` on
/// `PATH`, and reads back what the script did. Nothing is stubbed inside the
/// script: the file under test is byte-for-byte the one CI runs — asserted, not
/// assumed — and only its environment is fake.
///
/// The fake satisfies the script's own detection, which needs `fvm` on `PATH`
/// **and** a `.fvmrc` in the working directory, so the temp directory gets both.
/// Every invocation is appended to a log and the stub fails for exactly one
/// locale, which is the whole experiment.
///
/// ## What the loop must do, and why each part is asserted
///
/// - **Every locale is attempted.** The regression this exists for. Generation is
///   the expensive half and the input to every baseline refresh; losing the tail
///   of the list silently is the failure mode.
/// - **A failure still fails the run.** Resilient is not the same as quiet: a
///   partial refresh that exits 0 is worse than a loud abort, because the next
///   step trusts it.
/// - **The failed locales are named.** A non-zero exit says "something"; what a
///   reader needs is which locales have to be re-run.
/// - **The gallery report still runs.** It is how the output gets reviewed, and
///   `run_golden_verify.sh` already builds its own report on a failing run.
/// - **The single-file branch is untouched.** `-f` is one file and one exit code;
///   there is no list to be resilient about.
///
/// ## Mutation ledger (measured, not assumed)
///
/// - Restoring the loop body to a bare `$FLUTTER test …` under `set -e` — the
///   shape this shipped as — fails 3: `every locale is attempted even after one
///   fails` (the run stops at `es`, so `ja` never reaches the log), `the locales
///   that failed are named`, and `the gallery report still runs when a locale
///   failed`.
/// - Swallowing the failure instead (`|| true`, no accumulator) fails 2: `a
///   failing locale still fails the run` and `the locales that failed are named`.
/// - Dropping only the summary line fails 1: `the locales that failed are named`.
void main() {
  const script = 'run_generate_loc_snapshots.sh';

  late Directory temp;
  late File log;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('gen_loc_resilience');
    log = File('${temp.path}/invocations.log')..writeAsStringSync('');

    // The file under test, copied rather than reimplemented.
    File(script).copySync('${temp.path}/$script');
    // `.fvmrc` only has to exist — the stub is what answers.
    File('${temp.path}/.fvmrc').writeAsStringSync('{"flutter":"3.47.2"}\n');

    final bin = Directory('${temp.path}/bin')..createSync();
    final stub = File('${bin.path}/fvm');
    // Logs what it was asked to do, and fails for one locale only. `$*` rather
    // than `$@` because the match is on the joined command line.
    stub.writeAsStringSync('''
#!/bin/bash
echo "\$*" >> "\$STUB_LOG"
case "\$*" in
  *locales=es*) exit 1 ;;
esac
exit 0
''');
    Process.runSync('chmod', ['+x', stub.path]);
  });

  tearDown(() => temp.deleteSync(recursive: true));

  ProcessResult run(List<String> args) => Process.runSync(
        'bash',
        [script, ...args],
        workingDirectory: temp.path,
        environment: {
          'PATH': '${temp.path}/bin:${Platform.environment['PATH']}',
          'STUB_LOG': log.path,
        },
      );

  /// The locales the script actually invoked `flutter test` for, in order.
  List<String> localesAttempted() => [
        for (final line in log.readAsLinesSync())
          if (line.contains('--dart-define=locales='))
            line
                .split('--dart-define=locales=')
                .last
                .split(RegExp(r'\s'))
                .first,
      ];

  /// Matches a summary line that names [locale] as one of the failures. Dart's
  /// `RegExp` has no inline `(?i)`, so the flag is a named argument.
  RegExp failedLocales(String locale) =>
      RegExp('failed locales?.*\\b$locale\\b', caseSensitive: false);

  test('the script under test is the shipped one', () {
    // The point of copying instead of reimplementing: if these ever diverge,
    // every assertion below is about a file nobody runs.
    expect(
      File('${temp.path}/$script').readAsStringSync(),
      File(script).readAsStringSync(),
    );
  });

  test('every locale is attempted even after one fails', () {
    run(['-l', 'en,es,ja', '-s', '480']);

    expect(localesAttempted(), ['en', 'es', 'ja'],
        reason: 'es failed; en ran before it and ja must still run after it — '
            'each locale is independent work, and generation is the expensive '
            'half');
  });

  test('a failing locale still fails the run', () {
    final result = run(['-l', 'en,es,ja', '-s', '480']);

    expect(result.exitCode, isNot(0),
        reason: 'a partial refresh that exits 0 is worse than a loud abort, '
            'because whatever runs next trusts it');
  });

  test('the locales that failed are named', () {
    final result = run(['-l', 'en,es,ja', '-s', '480']);
    final output = '${result.stdout}${result.stderr}';

    expect(output, matches(failedLocales('es')),
        reason: 'a non-zero exit says something went wrong; the reader needs '
            'to know which locales have to be re-run');
    expect(output, isNot(matches(failedLocales('ja'))),
        reason: 'and only those — ja succeeded');
  });

  test('the gallery report still runs when a locale failed', () {
    run(['-l', 'en,es,ja', '-s', '480']);

    expect(log.readAsStringSync(),
        contains('dart run test_scripts/generate_gallery_report.dart'),
        reason: 'the report is how the output gets reviewed, and '
            'run_golden_verify.sh already builds its own on a failing run');
  });

  test('a clean run exits 0 and names nothing', () {
    final result = run(['-l', 'en,ja', '-s', '480']);
    final output = '${result.stdout}${result.stderr}';

    expect(localesAttempted(), ['en', 'ja']);
    expect(result.exitCode, 0);
    expect(output,
        isNot(matches(RegExp('failed locales?', caseSensitive: false))));
  });

  test('the single-file branch keeps one file and one exit code', () {
    // `-f` has no list to be resilient about: the caller asked for one file and
    // wants its verdict.
    final result =
        run(['-f', 'test/golden_test/some_view_test.dart', '-l', 'es']);

    expect(result.exitCode, isNot(0));
    expect(log.readAsLinesSync().where((l) => l.startsWith('flutter test')),
        hasLength(1));
    expect(
        log.readAsStringSync(), isNot(contains('generate_gallery_report.dart')),
        reason:
            'the -f branch exits with the file\'s own status, as it always has');
  });
}
