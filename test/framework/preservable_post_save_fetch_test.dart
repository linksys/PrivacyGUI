// Who asked for the read decides what a failed one means (#1212, #1279).
//
// `performFetch` turns a failed read into a status, as every page does, because
// the initial load runs from `build()` with no caller to catch a throw (#1274).
// That is right for the two display reads and wrong for the third: after a
// save, the same status put an error page under the "saved" toast, for a write
// that had landed (#1279, re-run on DMZ 2026-10-21). 11 of 14 pages had it.
//
// The fixture is shaped like those pages: on failure `performFetch` returns
// `(null, status-with-error)`.

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/has_service_error.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';

class _Status extends Equatable implements HasServiceError {
  const _Status({this.isLoading = false, this.error});
  final bool isLoading;
  @override
  final ServiceError? error;
  @override
  List<Object?> get props => [isLoading, error];
}

class _Value extends Equatable {
  const _Value(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

class _State extends FeatureState<_Value, _Status> {
  const _State({required super.settings, required super.status});
  @override
  _State copyWith({Preservable<_Value>? settings, _Status? status}) => _State(
      settings: settings ?? this.settings, status: status ?? this.status);
  @override
  Map<String, dynamic> toMap() => {};
}

/// What the router holds, and whether the next read reaches it.
class _Router {
  _Value value = const _Value('before');
  bool readFails = false;
}

final _router = Provider((_) => _Router());

class _Page extends AutoDisposeNotifier<_State>
    with PreservableAutoDisposeNotifierMixin<_Value, _Status, _State> {
  @override
  _State build() {
    Future.microtask(() => fetch());
    return const _State(
      settings: Preservable(original: _Value(''), current: _Value('')),
      status: _Status(isLoading: true),
    );
  }

  @override
  Future<(_Value?, _Status?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final router = ref.read(_router);
    if (router.readFails) {
      return (null, const _Status(error: NetworkError(detail: 'read failed')));
    }
    return (router.value, const _Status());
  }

  @override
  Future<void> performSave() async => ref.read(_router).value = state.current;

  void edit(String text) =>
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

  group('a failed read after a save', () {
    test('throws SavedButUnconfirmedError carrying the read error', () async {
      final notifier = container.read(_page.notifier)..edit('after');
      router.readFails = true;

      Object? thrown;
      try {
        await notifier.save();
      } catch (e) {
        thrown = e;
      }

      expect(thrown, isA<SavedButUnconfirmedError>());
      expect((thrown as SavedButUnconfirmedError).cause, isA<NetworkError>());
    });

    test('leaves the page on what was written, clean, with no error', () async {
      final notifier = container.read(_page.notifier)..edit('after');
      router.readFails = true;

      await expectLater(notifier.save(), throwsA(anything));

      final state = container.read(_page);
      expect(state.status.error, isNull,
          reason: 'an error page under the "saved" toast is #1279');
      expect(state.current, const _Value('after'));
      expect(state.isDirty, isFalse);
    });

    test('a read that succeeds still replaces the page with the router',
        () async {
      final notifier = container.read(_page.notifier)..edit('after');

      final result = await notifier.save();

      expect(result.current, const _Value('after'));
      expect(result.status.error, isNull);
    });
  });

  group('a failed display read still lands on the status', () {
    test('the initial load', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(_router).readFails = true;
      c.listen(_page, (_, __) {});
      await Future<void>.delayed(Duration.zero);

      final state = c.read(_page);
      expect(state.status.error, isA<NetworkError>());
      expect(state.status.isLoading, isFalse);
    });

    test('pull-to-refresh (fetch with forceRemote) returns normally', () async {
      router.readFails = true;

      final state =
          await container.read(_page.notifier).fetch(forceRemote: true);

      expect(state.status.error, isA<NetworkError>());
    });
  });
}
