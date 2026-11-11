// `pushNamedPastUnsavedChanges`, the entry verb for opening one editable page
// from another (linksys/PrivacyGUI#1433).
//
// The defect it exists for: a page with unsaved changes that pushes another
// editable page stays dirty underneath it, so leaving the pair later raises the
// child's unsaved-changes prompt and then a second one for a page that is not
// on screen. The verb asks at the entry instead — Go back, Discard changes or
// Save — so the parent is never dirty under a child.
//
// The pages are stubs, but the router, `LinksysRoute`'s exit guard and both
// dialogs are the real ones, so what is asserted is what the user would see.

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

class _Value extends Equatable {
  const _Value();
  @override
  List<Object?> get props => [];
}

/// An editable page's notifier, reduced to what the entry verb and the exit
/// guard read: whether it is dirty, and a revert that is counted.
class _Editor implements PreservableContract<_Value, _Value> {
  bool dirty = false;
  int reverts = 0;

  @override
  bool isDirty() => dirty;

  @override
  void revert() {
    reverts++;
    dirty = false;
  }

  @override
  Future<(_Value?, _Value?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) =>
      throw UnimplementedError('not read by the entry verb');

  @override
  Future<void> performSave() =>
      throw UnimplementedError('the page passes its own save flow');
}

/// The English copy this file matches on, from `app_en.arb`.
const _promptTitle = 'You have unsaved changes on this page';

Finder _button(String identifier) => find.byWidgetPredicate(
      (w) => w is AppButton && w.identifier == identifier,
      description: "AppButton(identifier: '$identifier')",
    );

class _Harness {
  final parent = _Editor();
  final child = _Editor();
  int saves = 0;

  /// What the parent's own save flow reports: true when it saved and the
  /// child may open.
  bool saveResult = true;
  bool canSave = true;

  /// Open the child with a bare `pushNamed`, as both entries did before #1433.
  bool plainPush = false;

  late final _parentProvider = Provider<PreservableContract>((_) => parent);
  late final _childProvider = Provider<PreservableContract>((_) => child);

  Future<bool> _save() async {
    saves++;
    if (saveResult) parent.dirty = false;
    return saveResult;
  }

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/parent',
      routes: [
        GoRoute(
          path: '/elsewhere',
          name: 'elsewhere',
          builder: (_, __) => const Scaffold(body: Text('Elsewhere')),
        ),
        LinksysRoute(
          path: '/parent',
          name: 'parent',
          preservableProvider: _parentProvider,
          builder: (context, _) => Scaffold(
            body: Column(children: [
              const Text('Parent'),
              ElevatedButton(
                key: const Key('open'),
                onPressed: () => plainPush
                    ? context.pushNamed('child')
                    : context.pushNamedPastUnsavedChanges(
                        'child',
                        parent: parent,
                        save: _save,
                        canSave: canSave,
                      ),
                child: const Text('Open'),
              ),
            ]),
          ),
          routes: [
            LinksysRoute(
              path: 'child',
              name: 'child',
              preservableProvider: _childProvider,
              builder: (context, _) => Scaffold(
                body: Column(children: [
                  const Text('Child'),
                  ElevatedButton(
                    key: const Key('leave'),
                    onPressed: () => context.goNamed('elsewhere'),
                    child: const Text('Leave'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp.router(
        theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tapOpen(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('NavigationExtension - pushNamedPastUnsavedChanges', () {
    testWidgets('a parent with unsaved changes asks before opening the child',
        (tester) async {
      final h = _Harness()..parent.dirty = true;
      await h.pump(tester);

      await h.tapOpen(tester);

      expect(find.text(_promptTitle), findsOneWidget);
      expect(_button('unsaved-open-go-back'), findsOneWidget);
      expect(_button('unsaved-open-discard'), findsOneWidget);
      expect(_button('unsaved-open-save'), findsOneWidget);
      expect(find.text('Child'), findsNothing,
          reason: 'nothing may open before the answer');
    });

    testWidgets('a parent with nothing unsaved opens the child without asking',
        (tester) async {
      final h = _Harness();
      await h.pump(tester);

      await h.tapOpen(tester);

      expect(find.text(_promptTitle), findsNothing);
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('Discard changes reverts the parent, then opens the child',
        (tester) async {
      final h = _Harness()..parent.dirty = true;
      await h.pump(tester);
      await h.tapOpen(tester);

      await tester.tap(_button('unsaved-open-discard'));
      await tester.pumpAndSettle();

      expect(find.text(_promptTitle), findsNothing);
      expect(h.parent.reverts, 1);
      expect(h.saves, 0);
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('Save runs the parent\'s save, then opens the child',
        (tester) async {
      final h = _Harness()..parent.dirty = true;
      await h.pump(tester);
      await h.tapOpen(tester);

      await tester.tap(_button('unsaved-open-save'));
      await tester.pumpAndSettle();

      expect(find.text(_promptTitle), findsNothing);
      expect(h.saves, 1);
      expect(h.parent.reverts, 0, reason: 'saved changes are not reverted');
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('a save that does not succeed leaves the user on the parent',
        (tester) async {
      final h = _Harness()
        ..parent.dirty = true
        ..saveResult = false;
      await h.pump(tester);
      await h.tapOpen(tester);

      await tester.tap(_button('unsaved-open-save'));
      await tester.pumpAndSettle();

      expect(h.saves, 1);
      expect(find.text('Child'), findsNothing);
      expect(find.text('Parent'), findsOneWidget);
      expect(h.parent.isDirty(), isTrue,
          reason: 'the changes are still there to save again');
    });

    testWidgets('Go back closes the prompt and changes nothing',
        (tester) async {
      final h = _Harness()..parent.dirty = true;
      await h.pump(tester);
      await h.tapOpen(tester);

      await tester.tap(_button('unsaved-open-go-back'));
      await tester.pumpAndSettle();

      expect(find.text(_promptTitle), findsNothing);
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child'), findsNothing);
      expect(h.parent.reverts, 0);
      expect(h.saves, 0);
      expect(h.parent.isDirty(), isTrue);
    });

    testWidgets('dismissing the prompt is the same as Go back', (tester) async {
      final h = _Harness()..parent.dirty = true;
      await h.pump(tester);
      await h.tapOpen(tester);

      await tester.tapAt(const Offset(4, 4)); // the barrier, outside the dialog
      await tester.pumpAndSettle();

      expect(find.text(_promptTitle), findsNothing);
      expect(find.text('Child'), findsNothing);
      expect(h.parent.reverts, 0);
      expect(h.saves, 0);
    });

    testWidgets('Save is disabled when the parent could not save',
        (tester) async {
      final h = _Harness()
        ..parent.dirty = true
        ..canSave = false;
      await h.pump(tester);
      await h.tapOpen(tester);

      final save = tester.widget<AppButton>(_button('unsaved-open-save'));
      expect(save.onTap, isNull);
      expect(tester.widget<AppButton>(_button('unsaved-open-discard')).onTap,
          isNotNull,
          reason: 'the other two answers stay available');
      expect(tester.widget<AppButton>(_button('unsaved-open-go-back')).onTap,
          isNotNull);
    });
  });

  // The three steps in #1433's "The defect": change the parent, open the child,
  // change the child, then leave both with a replacing verb (a nav-rail item).
  group(
      'NavigationExtension - leaving a child opened from a changed parent '
      '(#1433)', () {
    /// The exit prompt `LinksysRoute` raises, from `app_en.arb`.
    const exitPromptBody =
        'Navigating away from this page will discard any inputs.';

    Future<void> changeChildAndLeave(WidgetTester tester, _Harness h) async {
      expect(find.text('Child'), findsOneWidget);
      h.child.dirty = true;
      await tester.tap(find.byKey(const Key('leave')));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'asks once, for the child, because the parent was settled at '
        'the entry', (tester) async {
      final h = _Harness()..parent.dirty = true;
      await h.pump(tester);
      await h.tapOpen(tester);
      await tester.tap(_button('unsaved-open-discard'));
      await tester.pumpAndSettle();

      await changeChildAndLeave(tester, h);
      expect(find.text(exitPromptBody), findsOneWidget,
          reason: 'the child\'s own exit prompt');
      await tester.tap(_button('unsaved-discard'));
      await tester.pumpAndSettle();

      expect(find.text(exitPromptBody), findsNothing,
          reason: 'no second prompt for the parent');
      expect(find.text('Elsewhere'), findsOneWidget);
      expect(h.child.reverts, 1);
      expect(h.parent.reverts, 1, reason: 'reverted once, at the entry');
    });

    testWidgets('a bare pushNamed asked a second time, for the hidden parent',
        (tester) async {
      final h = _Harness()
        ..parent.dirty = true
        ..plainPush = true;
      await h.pump(tester);
      await h.tapOpen(tester);
      expect(find.text(_promptTitle), findsNothing,
          reason: 'a push runs no exit guard, so nothing asked here');

      await changeChildAndLeave(tester, h);
      await tester.tap(_button('unsaved-discard'));
      await tester.pumpAndSettle();

      // go_router asks every exiting route before it navigates, so the second
      // prompt is raised over the child, about a parent that is offstage.
      expect(find.text(exitPromptBody), findsOneWidget,
          reason: 'the parent\'s prompt, for a page that is not on screen');
      expect(find.text('Child'), findsOneWidget);
      expect(find.text('Parent'), findsNothing,
          reason: 'the page being asked about is not visible');
      await tester.tap(_button('unsaved-discard'));
      await tester.pumpAndSettle();
      expect(find.text('Elsewhere'), findsOneWidget);
    });
  });
}
