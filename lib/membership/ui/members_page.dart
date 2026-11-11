import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/membership/data/current_shop.dart';
import 'package:jabhouy/membership/data/membership_api.dart';
import 'package:jabhouy/membership/ui/shop_switcher_sheet.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openMembers(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const MembersPage()));

/// Invite & members (canvas ១៨, owner only): pick a role, make a code to
/// show as QR or share, and manage who is in the Shop.
class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _api = getIt<MembershipApi>();
  final _shop = getIt<CurrentShop>();
  MemberRole _inviteRole = MemberRole.viewer;
  ShopInvite? _invite;
  bool _inviting = false;
  late Future<Result<List<ShopMember>>> _members = _api.members(_shop.id!);

  String get _shopName =>
      _shop.shops
          .where((s) => s.id == _shop.id)
          .map((s) => s.name)
          .firstOrNull ??
      '';

  void _reload() => setState(() => _members = _api.members(_shop.id!));

  Future<void> _makeInvite() async {
    setState(() => _inviting = true);
    final result = await _api.createInvite(_shop.id!, _inviteRole);
    if (!mounted) return;
    setState(() {
      _inviting = false;
      if (result case Ok(:final value)) _invite = value;
    });
    if (result is Err) {
      showErrorSnackBar(context, AppLocalizations.of(context).membershipFailed);
    }
  }

  Future<void> _share(ShopInvite invite) => SharePlus.instance.share(
    ShareParams(
      text: AppLocalizations.of(context)
          .inviteShareText(_shopName, invite.code),
    ),
  );

  Future<void> _copy(ShopInvite invite) async {
    await Clipboard.setData(ClipboardData(text: invite.code));
    if (!mounted) return;
    showSuccessSnackBar(context, AppLocalizations.of(context).inviteCopied);
  }

  Future<bool> _confirm(String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message, style: AppTextTheme.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _act(ShopMember member) async {
    final l10n = AppLocalizations.of(context);
    final other = member.role == MemberRole.editor
        ? MemberRole.viewer
        : MemberRole.editor;
    final action = await showFitSheet<_Action>(
      context,
      builder: (context) => AppSheet(
        fit: true,
        title: member.displayName,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: Text(l10n.memberSetRole(roleLabel(l10n, other))),
              onTap: () => Navigator.pop(context, _Action.setRole),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(l10n.memberTransfer),
              onTap: () => Navigator.pop(context, _Action.transfer),
            ),
            ListTile(
              leading: Icon(
                Icons.person_remove_outlined,
                color: context.tokens.dangerText,
              ),
              title: Text(
                l10n.memberRemove,
                style: TextStyle(color: context.tokens.dangerText),
              ),
              onTap: () => Navigator.pop(context, _Action.remove),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    final shopId = _shop.id!;
    final Result<void> result;
    switch (action) {
      case _Action.setRole:
        result = await _api.setRole(shopId, member.userId, other);
      case _Action.transfer:
        if (!await _confirm(
          l10n.memberTransferConfirm(member.displayName),
          l10n.memberTransfer,
        )) {
          return;
        }
        result = await _api.setRole(shopId, member.userId, MemberRole.owner);
      case _Action.remove:
        if (!await _confirm(
          l10n.memberRemoveConfirm(member.displayName),
          l10n.memberRemove,
        )) {
          return;
        }
        result = await _api.remove(shopId, member.userId);
    }
    if (!mounted) return;
    if (result is Err) {
      showErrorSnackBar(context, l10n.membershipFailed);
      return;
    }
    if (action == _Action.transfer) {
      // No longer the owner: this screen is not theirs any more.
      await _shop.refresh();
      if (mounted) context.goNamed(AppRoutes.home);
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final invite = _invite;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(centerTitle: false, title: Text(l10n.settingsMembers)),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Card(
                title: l10n.inviteTitle,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.inviteRole,
                        style: AppTextTheme.label.copyWith(
                          color: t.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedControl<MemberRole>(
                        options: [
                          (MemberRole.viewer, l10n.roleViewer),
                          (MemberRole.editor, l10n.roleEditor),
                        ],
                        selected: _inviteRole,
                        // The role is part of the code, so a new role needs a new code.
                        onChanged: (role) => setState(() {
                          _inviteRole = role;
                          _invite = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (invite == null)
                        FilledButton(
                          onPressed: _inviting ? null : _makeInvite,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSizes.buttonHeight,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: _inviting
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.inviteGenerate),
                        )
                      else ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            // White behind the QR in dark mode too, or scanners miss it.
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(data: invite.code, size: 200),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _copy(invite),
                          child: Text(
                            invite.code.split('').join(' '),
                            textAlign: TextAlign.center,
                            style: AppTextTheme.headline.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${roleLabel(l10n, invite.role)} · ${l10n.inviteExpires}',
                          textAlign: TextAlign.center,
                          style: AppTextTheme.hint.copyWith(color: t.textMuted),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => _share(invite),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSizes.buttonHeight,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(l10n.inviteShare),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _Card(
                title: l10n.members,
                child: FutureBuilder<Result<List<ShopMember>>>(
                  future: _members,
                  builder: (context, snapshot) => switch (snapshot.data) {
                    null => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    Err() => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.membershipFailed,
                        style: AppTextTheme.body.copyWith(color: t.dangerText),
                      ),
                    ),
                    Ok(:final value) => Column(
                      children: [
                        for (final (i, m) in value.indexed) ...[
                          if (i > 0) Divider(height: 1, color: t.divider),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: t.surfaceSubtle,
                              child: Text(
                                m.displayName.characters.firstOrNull ?? '?',
                                style: AppTextTheme.body.copyWith(
                                  color: t.textPrimary,
                                ),
                              ),
                            ),
                            title: Text(
                              m.userId == _shop.userId
                                  ? '${m.displayName} (${l10n.memberYou})'
                                  : m.displayName,
                              style: AppTextTheme.body.copyWith(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              roleLabel(l10n, m.role),
                              style: AppTextTheme.hint.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                            // The owner is changed only by handing the Shop over.
                            trailing: m.role == MemberRole.owner
                                ? null
                                : Icon(
                                    Icons.more_horiz_rounded,
                                    color: t.textMuted,
                                  ),
                            onTap: m.role == MemberRole.owner
                                ? null
                                : () => _act(m),
                          ),
                        ],
                      ],
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Action { setRole, transfer, remove }

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            title,
            style: AppTextTheme.label.copyWith(
              color: t.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Material(
          color: t.surface,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          child: child,
        ),
      ],
    );
  }
}
