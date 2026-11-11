import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/membership/data/current_shop.dart';
import 'package:jabhouy/membership/ui/join_shop_page.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

/// The label for [role] used on every membership screen.
String roleLabel(AppLocalizations l10n, MemberRole role) => switch (role) {
  MemberRole.owner => l10n.roleOwner,
  MemberRole.editor => l10n.roleEditor,
  MemberRole.viewer => l10n.roleViewer,
};

/// Back to Home, working in [shopId]. Home rebuilds its lists for the new
/// Shop (it listens to [CurrentShop]); the pull brings that Shop up to date.
Future<void> openShop(BuildContext context, String shopId) async {
  context.goNamed(AppRoutes.home);
  await getIt<CurrentShop>().switchTo(shopId);
  unawaited(getIt<SyncCoordinator>().syncNow());
}

/// Settings → Switch shop: the user's own Shop and the ones they joined
/// (canvas ១២, decision 36), plus a way to join another.
Future<void> showShopSwitcher(BuildContext context) {
  // Fresh from the server, so a just-joined Shop or a removal shows.
  unawaited(getIt<CurrentShop>().refresh());
  return showFitSheet<void>(
    context,
    builder: (_) => _ShopSwitcherSheet(host: context),
  );
}

class _ShopSwitcherSheet extends StatelessWidget {
  const _ShopSwitcherSheet({required this.host});

  /// The page that opened the sheet: still mounted after the sheet closes,
  /// so navigation goes through it.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final current = getIt<CurrentShop>();

    return ListenableBuilder(
      listenable: current,
      builder: (context, _) => AppSheet(
        fit: true,
        title: l10n.shopSwitch,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final shop in current.shops)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.surfaceSubtle,
                  child: Icon(Icons.storefront_outlined, color: t.textPrimary),
                ),
                title: Text(
                  shop.name,
                  style: AppTextTheme.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  roleLabel(l10n, shop.role),
                  style: AppTextTheme.hint.copyWith(color: t.textMuted),
                ),
                trailing: shop.id == current.id
                    ? Icon(Icons.check_rounded, color: t.textPrimary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (shop.id != current.id) unawaited(openShop(host, shop.id));
                },
              ),
            Divider(height: 1, color: t.divider),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: t.surfaceSubtle,
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: t.textPrimary,
                ),
              ),
              title: Text(
                l10n.shopJoin,
                style: AppTextTheme.body.copyWith(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.shopJoinSub,
                style: AppTextTheme.hint.copyWith(color: t.textMuted),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: t.textMuted),
              onTap: () {
                Navigator.pop(context);
                unawaited(openJoinShop(host));
              },
            ),
          ],
        ),
      ),
    );
  }
}
