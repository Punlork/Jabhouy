import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';
import 'package:jabhouy_ui/src/voice/speech_service.dart';
import 'package:jabhouy_ui/src/widget/app_sheet.dart';
import 'package:jabhouy_ui/src/widget/segmented_control.dart';

/// Voice input sheet (canvas ៦): the field's name, a ខ្មែរ/EN switch, a live
/// level bar and transcript. Returns the text only when the person taps
/// `ប្រើអត្ថបទនេះ`; cancelling or closing writes nothing.
Future<String?> showVoiceSheet(
  BuildContext context, {
  required SpeechService service,
  required String fieldLabel,
}) => showAppSheet<String>(
  context,
  builder: (_, controller) => VoiceSheet(
    service: service,
    fieldLabel: fieldLabel,
    scrollController: controller,
  ),
);

class VoiceSheet extends StatefulWidget {
  const VoiceSheet({
    required this.service,
    required this.fieldLabel,
    this.scrollController,
    super.key,
  });

  final SpeechService service;
  final String fieldLabel;
  final ScrollController? scrollController;

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  /// `km-KH` first (plan §5.6); the toggle restarts listening.
  String _locale = 'km-KH';
  String _text = '';
  double _level = 0;
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  Future<void> _listen() async {
    final ok = await widget.service.start(
      localeId: _locale,
      onText: (text) {
        if (mounted) setState(() => _text = text);
      },
      onLevel: (level) {
        if (mounted) setState(() => _level = level);
      },
    );
    if (!ok && mounted) setState(() => _unavailable = true);
  }

  Future<void> _switch(String locale) async {
    await widget.service.stop();
    setState(() {
      _locale = locale;
      _text = '';
      _unavailable = false;
    });
    await _listen();
  }

  @override
  void dispose() {
    widget.service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.tokens;
    return AppSheet(
      scrollController: widget.scrollController,
      title: l10n.voiceSpeakingInto(widget.fieldLabel),
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _text.trim()),
              child: Text(l10n.voiceUse),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedControl<String>(
            options: const [('km-KH', 'ខ្មែរ'), ('en-US', 'EN')],
            selected: _locale,
            onChanged: _switch,
          ),
          const SizedBox(height: 24),
          if (_unavailable)
            Text(
              l10n.voiceUnavailable,
              style: AppTextTheme.body.copyWith(color: t.dangerText),
            )
          else ...[
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: t.dangerText),
                const SizedBox(width: 8),
                Text(
                  l10n.voiceListening,
                  style: AppTextTheme.hint.copyWith(color: t.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _level, minHeight: 6),
            const SizedBox(height: 24),
            Text(
              _text,
              style: AppTextTheme.body.copyWith(
                fontSize: 22,
                color: t.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
