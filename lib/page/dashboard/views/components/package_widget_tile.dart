import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/widgets/package_widget_renderer.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// One dashboard tile for a card that came from a router package.
///
/// Resolves [itemId] against [packageWidgetLoaderProvider] and renders the
/// template, or the "unknown widget" placeholder while there is no template for
/// it — a card whose package was uninstalled, or one whose template has not
/// arrived yet.
///
/// ## Why it resolves the template itself (#1395)
///
/// The lookup used to be a `ref.read` in the page's `itemBuilder`, with a
/// `ref.watch` at the top of the page's `build` to bring the page back when the
/// templates landed. That pairing worked on 0.9.1 and stopped working on 2.3.1,
/// which caches what `itemBuilder` returned (`dashboard_item_widget.dart:487`)
/// and invalidates it only when the item's content signature or measured
/// dimensions change. A page rebuild is neither, so the placeholder a tile was
/// built with became the placeholder it kept: the templates arrive over HTTP a
/// moment after the grid is laid out, so on every load the package cards would
/// read "unknown widget" until the user happened to move or resize one.
///
/// Reading the provider *inside* the tile puts the dependency below that cache
/// boundary, where an element rebuilds without its parent's permission. Same
/// boundary, same reason as [EditModeAffordance].
class PackageWidgetTile extends ConsumerWidget {
  const PackageWidgetTile({super.key, required this.itemId});

  /// The layout item's id, which for a package card is its widget id.
  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `select`, not a whole-value watch: this is per card, and the loader
    // republishes the whole map on every 30-second poll.
    final template = ref.watch(
      packageWidgetLoaderProvider.select((s) => s.valueOrNull?[itemId]),
    );

    if (template == null) {
      return AppCard(
        child: Center(
          child: AppText.bodyMedium(loc(context).unknownWidget(itemId)),
        ),
      );
    }

    return PackageWidgetRenderer(template: template, showHeader: true);
  }
}
