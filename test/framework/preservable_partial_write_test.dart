// `saveReadingBackAfterPartialWrite`: a save that wrote part of itself
// (UspPartialFailureError) reads the router back before its error is rethrown,
// through `confirmSaved`, so a read that fails too keeps the "read before you
// write again" rule (#1212). Without it, rows the failed save created stay on
// the page without their path, and the next save adds them again.

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/has_service_error.dart';
import 'package:privacy_gui/framework/has_unconfirmed_rows.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';

class _Status extends Equatable implements HasServiceError {
  const _Status({this.error});
  @override
  final ServiceError? error;
  @override
  List<Object?> get props => [error];
}

class _Value extends Equatable implements HasUnconfirmedRows {
  const _Value(this.text, {this.path});
  final String text;
  final String? path;
  @override
  bool get hasUnconfirmedRows => path == null;
  @override
  List<Object?> get props => [text, path];
}

class _State extends FeatureState<_Value, _Status> {
  const _State({required super.settings, required super.status});
  @override
  _State copyWith({Preservable<_Value>? settings, _Status? status}) => _State(
      settings: settings ?? this.settings, status: status ?? this.status);
  @override
  Map<String, dynamic> toMap() => {};
}

enum _Outcome { partial, complete }

class _Router {
  _Value value = const _Value('', path: 'Device.X.1.');
  bool readFails = false;
  _Outcome outcome = _Outcome.partial;
  int writes = 0;
  int reads = 0;
}

final _router = Provider((_) => _Router());

class _Page extends AutoDisposeNotifier<_State>
    with PreservableAutoDisposeNotifierMixin<_Value, _Status, _State> {
  @override
  _State build() {
    Future.microtask(() => fetch());
    return const _State(
      settings: Preservable(original: _Value(''), current: _Value('')),
      status: _Status(),
    );
  }

  @override
  Future<_State> save() => saveReadingBackAfterPartialWrite(super.save);

  @override
  Future<(_Value?, _Status?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final router = ref.read(_router);
    router.reads++;
    if (router.readFails) {
      return (null, const _Status(error: NetworkError(detail: 'read failed')));
    }
    return (router.value, const _Status());
  }

  /// An add the router created a row for, and then refused part of.
  @override
  Future<void> performSave() async {
    final router = ref.read(_router);
    router.writes++;
    if (router.outcome == _Outcome.complete) {
      throw const UspCompleteFailureError(summary: 'refused', failures: []);
    }
    router.value =
        _Value(state.current.text, path: 'Device.X.${router.writes + 1}.');
    throw const UspPartialFailureError(
        summary: 'partly refused', successPaths: [], failures: []);
  }

  void create(String text) =>
      state = state.copyWith(settings: state.settings.update(_Value(text)));
}

final _page = AutoDisposeNotifierProvider<_Page, _State>(_Page.new);

void main() {
  late ProviderContainer container;
  late _Router router;

  setUp(() async {
    container = ProviderContainer();
    container.listen(_page, (_, __) {});
    router = container.read(_router);
    await Future<void>.delayed(Duration.zero); // build()'s initial load
  });

  tearDown(() => container.dispose());

  test(
      'a save that wrote part of itself reads the router back and still '
      'throws its own error', () async {
    final notifier = container.read(_page.notifier)..create('new row');

    await expectLater(notifier.save(), throwsA(isA<UspPartialFailureError>()));

    expect(container.read(_page).current.path, 'Device.X.2.',
        reason: 'the page now holds the row the router created, with its path');
    expect(container.read(_page).isDirty, isFalse);
  });

  test(
      'when that read fails too, the next save reads the router first and '
      'does not add the row a second time', () async {
    final notifier = container.read(_page.notifier)..create('new row');
    router.readFails = true;

    await expectLater(notifier.save(), throwsA(isA<UspPartialFailureError>()),
        reason: 'the save\'s own error, not the read\'s');
    expect(router.writes, 1);

    await expectLater(notifier.save(), throwsA(isA<NetworkError>()));
    expect(router.writes, 1, reason: 'a second add is a duplicate row');
  });

  test('a save that wrote nothing is not read back, and keeps the edit',
      () async {
    router.outcome = _Outcome.complete;
    final notifier = container.read(_page.notifier)..create('new row');
    final readsBefore = router.reads;

    await expectLater(notifier.save(), throwsA(isA<UspCompleteFailureError>()));

    expect(router.reads, readsBefore);
    expect(container.read(_page).current, const _Value('new row'));
  });
}
