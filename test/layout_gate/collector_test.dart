import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'collector.dart';
import 'incident.dart';

void main() {
  const overflowReport = 'A RenderFlex overflowed by 41 pixels on the right.';

  /// Runs [body] under the collector with a handler of our own installed
  /// outside it, and returns what reached that handler.
  Future<List<String>> forwardedBy(
    Future<void> Function(List<OverflowIncident> sink) body,
  ) async {
    final forwarded = <String>[];
    final saved = FlutterError.onError;
    FlutterError.onError =
        (details) => forwarded.add(details.exception.toString());
    try {
      await runWithOverflowCollection((sink) async {
        await body(sink);
        return null;
      });
    } finally {
      FlutterError.onError = saved;
    }
    return forwarded;
  }

  test('collects an overflow report instead of forwarding it', () async {
    List<OverflowIncident>? collected;
    final forwarded = await forwardedBy((sink) async {
      FlutterError.reportError(
        FlutterErrorDetails(exception: FlutterError(overflowReport)),
      );
      collected = List.of(sink);
    });

    expect(forwarded, isEmpty);
    expect(collected, hasLength(1));
    expect(collected!.single.pixels, 41);
  });

  test('forwards an error that is not an overflow', () async {
    List<OverflowIncident>? collected;
    final forwarded = await forwardedBy((sink) async {
      FlutterError.reportError(
        FlutterErrorDetails(exception: StateError('receive buffer overflowed')),
      );
      collected = List.of(sink);
    });

    expect(forwarded, hasLength(1),
        reason: 'it must still reach the handler that fails the test');
    expect(collected, isEmpty);
  });

  test('restores the previous handler when the body throws', () async {
    final saved = FlutterError.onError;
    void sentinel(FlutterErrorDetails details) {}
    FlutterError.onError = sentinel;
    try {
      await expectLater(
        runWithOverflowCollection<void>((sink) async => throw StateError('x')),
        throwsStateError,
      );
      expect(FlutterError.onError, same(sentinel));
    } finally {
      FlutterError.onError = saved;
    }
  });

  testWidgets('reads the site of a real overflow from the Flutter dump',
      (tester) async {
    final incidents = await runWithOverflowCollection((sink) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              child: Row(children: [SizedBox(width: 141, height: 10)]),
            ),
          ),
        ),
      );
      return List.of(sink);
    });

    expect(incidents, hasLength(1));
    expect(incidents.single.pixels, 41);
    expect(incidents.single.side, 'right');
    expect(incidents.single.widget, 'Row');
    expect(
      incidents.single.site,
      startsWith('test/layout_gate/collector_test.dart:'),
    );
  });
}
