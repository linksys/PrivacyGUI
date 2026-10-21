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
import 'package:privacy_gui/framework/has_unconfirmed_rows.dart';
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

/// One row, DMZ-shaped: [path] is the router's instance path, null until the
/// router has created the row.
class _Value extends Equatable implements HasUnconfirmedRows {
  const _Value(this.text, {this.path = 'Device.X.1.'});
  const _Value.created(this.text) : path = null;
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

/// What the router holds, and whether the next read reaches it.
class _Router {
  _Value value = const _Value('before');
  bool readFails = false;

  /// Writes the router counted: a second add of the same row is the
  /// duplicate the save-after-unconfirmed gate exists to stop.
  int writes = 0;

  /// What a read returns, when it differs from what was written — the router
  /// normalising a value, or assigning a path to a row it created.
  _Value Function(_Value written)? answer;
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
    final answer = router.answer;
    return (
      answer == null ? router.value : answer(router.value),
      const _Status()
    );
  }

  @override
  Future<void> performSave() async {
    final router = ref.read(_router);
    router.writes++;
    final written = state.current;
    router.value = written.path == null
        ? _Value(written.text, path: 'Device.X.${router.writes}.')
        : written;
  }

  void edit(String text) => state = state.copyWith(
      settings: state.settings.update(_Value(text, path: state.current.path)));

  /// A row the router does not have yet — DMZ turned on with no entry.
  void create(String text) => state =
      state.copyWith(settings: state.settings.update(_Value.created(text)));
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

    test(
        'a read that succeeds replaces the page with what the router holds, '
        'not with what was written', () async {
      final notifier = container.read(_page.notifier)..edit('after');
      router.answer = (_) => const _Value('router-normalised');

      final result = await notifier.save();

      expect(result.current, const _Value('router-normalised'));
      expect(result.status.error, isNull);
    });
  });

  // #1212 second review: after an ADD whose read-back failed, the written
  // state lacks the path the router assigned. Saving it again adds the row a
  // second time (DMZ, static routes, DHCP reservations, IPv6 port service).
  group('a save after an unconfirmed add', () {
    test('reads the router first, and does not write while it cannot',
        () async {
      final notifier = container.read(_page.notifier)..create('dmz-on');
      router.readFails = true;
      await expectLater(notifier.save(), throwsA(anything));
      expect(router.writes, 1);

      notifier.edit('dmz-on, .251');
      await expectLater(
          notifier.save(), throwsA(isA<SavedButUnconfirmedError>()));

      expect(router.writes, 1, reason: 'a second add is a duplicate row');
    });

    test(
        'once the router can be read: the page shows its rows, the edit made '
        'against the pathless row is not written, and the next save updates '
        'the row the first one created', () async {
      final notifier = container.read(_page.notifier)..create('dmz-on');
      router.readFails = true;
      await expectLater(notifier.save(), throwsA(anything));

      router.readFails = false;
      notifier.edit('dmz-on, .251');
      // The framework cannot map a pathless row onto the one the router made,
      // so it shows the router's rows and asks for the change again.
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
      expect(router.writes, 1);
      expect(container.read(_page).current.path, 'Device.X.1.');

      notifier.edit('dmz-on, .251');
      await notifier.save();

      expect(router.writes, 2);
      expect(router.value.path, 'Device.X.1.',
          reason: 'updated the row the first save created — not a second add');
    });

    test(
        'an unconfirmed update (the row has its path) does not block the next '
        'save', () async {
      final notifier = container.read(_page.notifier)..edit('after');
      router.readFails = true;
      await expectLater(notifier.save(), throwsA(anything));

      notifier.edit('after again');
      await expectLater(notifier.save(), throwsA(anything));

      expect(router.writes, 2);
    });
  });

  group('confirmSavedRetrying', () {
    test('stops retrying once the page is gone', () async {
      final notifier = container.read(_page.notifier)..edit('after');
      router.readFails = true;
      await expectLater(notifier.save(), throwsA(anything));
      var attempts = 0;
      var active = true;

      await expectLater(
        notifier.confirmSavedRetrying(
          attempts: 5,
          interval: Duration.zero,
          before: () async {
            attempts++;
            active = false; // the user leaves during the first attempt
          },
          isActive: () => active,
        ),
        throwsA(isA<SavedButUnconfirmedError>()),
      );

      expect(attempts, 1, reason: 'no reads for a page nobody is on');
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
      expect(state.status.isLoading, isFalse);
    });
  });
}
