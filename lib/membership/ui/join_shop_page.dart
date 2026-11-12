import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jabhouy/app/app.dart';
import 'package:jabhouy/membership/data/current_shop.dart';
import 'package:jabhouy/membership/data/membership_api.dart';
import 'package:jabhouy/membership/ui/shop_switcher_sheet.dart';
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_shop/jabhouy_shop.dart';
import 'package:jabhouy_sync/jabhouy_sync.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

Future<void> openJoinShop(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const JoinShopPage()));

/// Join shop (canvas ១៧): scan the owner's QR or type the 6-character code.
class JoinShopPage extends StatefulWidget {
  const JoinShopPage({super.key});

  static const codeLength = 6;

  @override
  State<JoinShopPage> createState() => _JoinShopPageState();
}

class _JoinShopPageState extends State<JoinShopPage> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final scanned = await scanBarcode(context);
    if (scanned == null || !mounted) return;
    _code.text = _clean(scanned);
    if (_code.text.length == JoinShopPage.codeLength) await _join();
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await getIt<MembershipApi>().accept(_code.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        await getIt<CurrentShop>().refresh();
        if (!mounted) return;
        showSuccessSnackBar(context, l10n.joinSuccess(value.name));
        await openShop(context, value.id);
      case Err(:final error):
        setState(() {
          _busy = false;
          _error = switch (error) {
            ShopApiException(code: 'invite_expired') => l10n.joinExpired,
            ShopApiException(code: 'invite_used') => l10n.joinUsed,
            ShopApiException(code: 'already_member') => l10n.joinAlreadyMember,
            ShopApiException(code: 'invite_not_found' || 'invalid') =>
              l10n.joinInvalid,
            _ => l10n.membershipFailed,
          };
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    final complete = _code.text.length == JoinShopPage.codeLength;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(centerTitle: false, title: Text(l10n.shopJoin)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Material(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              child: InkWell(
                onTap: _busy ? null : _scan,
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                child: SizedBox(
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 72,
                        color: t.textPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.joinScan,
                        style: AppTextTheme.body.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: t.divider)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.authOr,
                    style: AppTextTheme.hint.copyWith(color: t.textMuted),
                  ),
                ),
                Expanded(child: Divider(color: t.divider)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.joinCode,
              style: AppTextTheme.label.copyWith(
                color: t.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _CodeBoxes(controller: _code, focusNode: _focus, enabled: !_busy),
            const SizedBox(height: 10),
            if (_error != null)
              Text(
                _error!,
                style: AppTextTheme.hint.copyWith(color: t.dangerText),
              )
            else
              Text(
                l10n.joinCodeHint,
                style: AppTextTheme.hint.copyWith(color: t.textMuted),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: complete && !_busy ? _join : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                shape: const StadiumBorder(),
              ),
              child: _busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.shopJoinBtn),
            ),
          ],
        ),
      ),
    );
  }
}

/// Letters and digits only, uppercase, at most the code's length: what a
/// typed, pasted or scanned code is reduced to.
String _clean(String text) {
  final code = text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
  return code.length > JoinShopPage.codeLength
      ? code.substring(0, JoinShopPage.codeLength)
      : code;
}

/// Six boxes over one invisible field: typing advances, backspace goes
/// back, and a pasted code fills them all.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.enabled,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([controller, focusNode]),
          builder: (context, _) {
            final text = controller.text;
            return Row(
              children: [
                for (var i = 0; i < JoinShopPage.codeLength; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 0.85,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: focusNode.hasFocus && i == text.length
                                ? 2
                                : 1,
                            color: focusNode.hasFocus && i == text.length
                                ? t.textPrimary
                                : t.border,
                          ),
                        ),
                        child: Text(
                          i < text.length ? text[i] : '',
                          style: AppTextTheme.headline.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              showCursor: false,
              keyboardType: TextInputType.visiblePassword,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (_, next) => TextEditingValue(
                    text: _clean(next.text),
                    selection: TextSelection.collapsed(
                      offset: _clean(next.text).length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
