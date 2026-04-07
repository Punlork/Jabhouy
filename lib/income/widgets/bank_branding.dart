import 'package:flutter/material.dart';
import 'package:my_app/income/income.dart';

class BankBranding {
  const BankBranding({
    required this.primary,
    required this.logoBackground,
    this.logoAssetPath,
  });

  final String? logoAssetPath;
  final Color primary;
  final Color logoBackground;
}

BankBranding resolveBankBranding(BankApp bankApp, ColorScheme colorScheme) {
  return switch (bankApp) {
    BankApp.aba => const BankBranding(
        logoAssetPath: 'assets/banks/aba_logo.png',
        primary: Color(0xFF123B5D),
        logoBackground: Colors.white,
      ),
    BankApp.chipMong => const BankBranding(
        logoAssetPath: 'assets/banks/chip_mong_logo.png',
        primary: Color(0xFF008445),
        logoBackground: Colors.white,
      ),
    BankApp.acleda => const BankBranding(
        logoAssetPath: 'assets/banks/acleda_logo.png',
        primary: Color(0xFF0054A6),
        logoBackground: Colors.white,
      ),
    BankApp.unknown => BankBranding(
        primary: colorScheme.outline,
        logoBackground: colorScheme.surface,
      ),
  };
}

class BankLogoBadge extends StatelessWidget {
  const BankLogoBadge({
    required this.branding,
    this.size = 28,
    this.borderColor,
    super.key,
  });

  final BankBranding branding;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: branding.logoBackground,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: borderColor ?? colorScheme.outlineVariant,
        ),
      ),
      alignment: Alignment.center,
      child: branding.logoAssetPath == null
          ? Text(
              '?',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
            )
          : Padding(
              padding: EdgeInsets.all(size * 0.14),
              child: Image.asset(
                branding.logoAssetPath!,
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}
