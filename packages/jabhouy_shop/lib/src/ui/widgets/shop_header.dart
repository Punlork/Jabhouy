import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

class ShopHeader extends StatelessWidget {
  const ShopHeader({
    required this.onSettingsPressed,
    required this.onSearchChanged,
    required this.searchController,
    required this.hasFilter,
    this.onFilterPressed,
    this.onScanPressed,
    this.searchHintText,
    super.key,
  });
  final VoidCallback onSettingsPressed;
  final ValueChanged<String?> onSearchChanged;

  /// Null hides the filter button (the shop tab filters with chips).
  final VoidCallback? onFilterPressed;

  /// Null hides the scan button (other tabs, or the flag off).
  final VoidCallback? onScanPressed;
  final TextEditingController searchController;
  final bool hasFilter;
  final String? searchHintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: _SearchBar(
        hasFilter: hasFilter,
        controller: searchController,
        onChanged: onSearchChanged,
        onFilterPressed: onFilterPressed,
        onScanPressed: onScanPressed,
        onSettingsPressed: onSettingsPressed,
        searchHintText: searchHintText,
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Canvas ១: a 48 × 54 target around a 24 px gear.
    return IconButton(
      onPressed: onPressed,
      tooltip: AppLocalizations.of(context).settings,
      icon: const Icon(Icons.settings_outlined, size: 24),
      color: Theme.of(context).colorScheme.onSurface,
      constraints: const BoxConstraints.tightFor(width: 48, height: 54),
    );
  }
}

/// Canvas ១: a 54 px search field and scan button, 16 px corners.
const _fieldHeight = 54.0;
const _fieldRadius = 16.0;

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onSettingsPressed,
    required this.hasFilter,
    this.onFilterPressed,
    this.onScanPressed,
    this.searchHintText,
  });
  final TextEditingController controller;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onScanPressed;
  final VoidCallback onSettingsPressed;
  final bool hasFilter;
  final String? searchHintText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: _fieldHeight,
      child: Row(
        children: [
          Expanded(
            // A Row would leave the field at its natural height.
            child: SizedBox.fromSize(
              size: const Size.fromHeight(_fieldHeight),
              child: CustomTextFormField(
                controller: controller,
                hintText: searchHintText ?? l10n.searchItems,
                labelText: '',
                prefixIcon: Icons.search,
                onChanged: onChanged,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                action: TextInputAction.search,
                showClearButton: true,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                useCustomBorder: false,
                decoration: InputDecoration(
                  prefixIconColor: colorScheme.onSurfaceVariant,
                  // The field only grows to its text and padding, so pad it to 54.
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w300,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_fieldRadius),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_fieldRadius),
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_fieldRadius),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_fieldRadius),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh,
                ),
              ),
            ),
          ),
          if (onScanPressed case final onScanPressed?) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: l10n.scanTitle,
              child: IconButton(
                onPressed: onScanPressed,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                style: IconButton.styleFrom(
                  foregroundColor: colorScheme.surface,
                  backgroundColor: colorScheme.onSurface,
                  fixedSize: const Size.square(_fieldHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_fieldRadius),
                  ),
                ),
              ),
            ),
          ],
          if (onFilterPressed case final onFilterPressed?) ...[
            const SizedBox(width: 8),
            IconButtonWidget(
              svgAsset: AppAssets.actionFilter,
              color: hasFilter
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              backgroundColor: hasFilter
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHigh,
              tooltip: l10n.filterItems,
              onPressed: onFilterPressed,
              colorScheme: colorScheme,
            ),
          ],
          const SizedBox(width: 8),
          _SettingsButton(onPressed: onSettingsPressed),
        ],
      ),
    );
  }
}
