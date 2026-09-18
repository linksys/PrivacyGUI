import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/localization/supported_locales_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The account block of the General Settings popup: legal links and sign-out.
///
/// Extracted from `GeneralSettingsWidget` by #1497 so that
/// `SurfaceStrategy.accountActions()` can name it. The mode question it used to
/// carry — an inverted `GlobalConfig.remote` gate ANDed with `isLoggedIn` — has
/// split in two:
/// which mode has an account block at all is the strategy's, and whether there is
/// a session to sign out of is this widget's, watched here rather than passed in
/// so the popup no longer reads `authProvider` for a block it may not render.
///
/// Returns [SizedBox.shrink] when logged out, which is the same nothing the
/// collection-`if` produced. The surrounding gaps and divider are inside this
/// widget on purpose: they belong to the block, and leaving them in the parent
/// would have left a divider and 24px of air above the version line for a
/// logged-out user.
class AccountActionsSection extends ConsumerWidget {
  const AccountActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(
        authProvider.select((state) => state.value?.isLoggedIn ?? false));
    if (!isLoggedIn) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGap.md(),
        const AppDivider(),
        AppGap.md(),

        // Legal links as compact row
        _buildLegalLinks(context, ref),
        AppGap.lg(),

        // Logout
        SizedBox(
          width: double.infinity,
          child: AppButton.dangerOutline(
            label: loc(context).logout,
            onTap: () {
              logger.i('[Auth]: The user manually logs out');
              ref
                  .read(authProvider.notifier)
                  .logout(cause: EndCause.userRequested);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegalLinks(BuildContext context, WidgetRef ref) {
    // The normalized locale, not the raw setting: an English-only build reading a
    // leftover `ja` would open linksys.com/jp/… for a user whose picker is hidden.
    //
    // Watched, not read: this runs inside the popup's builder, so a language
    // change while the popup is open has to reach the links. The picker's own
    // `ref.read` is correct by contrast — it sits in an onTap callback.
    final locale = ref.watch(activeLocaleProvider);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        AppButton.text(
          label: loc(context).termsOfService,
          size: AppButtonSize.small,
          onTap: () => gotoOfficialWebUrl(linkTerms, locale: locale),
        ),
        AppButton.text(
          label: loc(context).thirdPartyLicenses,
          size: AppButtonSize.small,
          onTap: () => gotoOfficialWebUrl(linkThirdParty, locale: locale),
        ),
        AppButton.text(
          label: loc(context).privacyAndSecurity,
          size: AppButtonSize.small,
          onTap: () => gotoOfficialWebUrl(linkPrivacy, locale: locale),
        ),
      ],
    );
  }
}
