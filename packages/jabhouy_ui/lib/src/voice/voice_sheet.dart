import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/theme/text_theme.dart';
import 'package:jabhouy_ui/src/voice/speech_service.dart';
import 'package:jabhouy_ui/src/widget/app_sheet.dart';
import 'package:jabhouy_ui/src/widget/segmented_control.dart';

/// Voice input sheet (canvas ៦): the field's name, a ខ្មែរ/EN switch, a live
/// waveform and transcript. Returns the text only when the person taps
/// `ប្រើអត្ថបទនេះ`; cancelling or closing writes nothing.
Future<String?> showVoiceSheet(
  BuildContext context, {
  required SpeechService service,
  required String fieldLabel,
}) => showFitSheet<String>(
  context,
  builder: (_) => VoiceSheet(service: service, fieldLabel: fieldLabel),
);

class VoiceSheet extends StatefulWidget {
  const VoiceSheet({
    required this.service,
    required this.fieldLabel,
    super.key,
  });

  final SpeechService service;
  final String fieldLabel;

  @override
  State<VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<VoiceSheet> {
  static const _bars = 30;

  /// `km-KH` first (plan §5.6); the toggle restarts listening.
  String _locale = 'km-KH';
  bool _khmer = true;
  String _text = '';
  final _levels = List<double>.filled(_bars, 0, growable: true);
  bool _unavailable = false;
  bool _listening = true;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  Future<void> _begin() async {
    // Hide ខ្មែរ on a phone that cannot recognise it (plan §5.6).
    if (!await widget.service.supports('km-KH') && mounted) {
      setState(() {
        _khmer = false;
        _locale = 'en-US';
      });
    }
    await _listen();
  }

  Future<void> _listen() async {
    if (mounted) setState(() => _listening = true);
    final ok = await widget.service.start(
      localeId: _locale,
      onText: (text) {
        if (mounted) setState(() => _text = text);
      },
      onLevel: (level) {
        if (mounted) {
          setState(() {
            _levels
              ..removeAt(0)
              ..add(level);
          });
        }
      },
      onStopped: () {
        if (mounted) setState(() => _listening = false);
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
      fit: true,
      header: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.voiceSpeakingInto,
                  style: AppTextTheme.hint.copyWith(color: t.textMuted),
                ),
                Text(
                  widget.fieldLabel,
                  style: AppTextTheme.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (_khmer)
            SizedBox(
              width: 120,
              child: SegmentedControl<String>(
                options: const [('km-KH', 'ខ្មែរ'), ('en-US', 'EN')],
                selected: _locale,
                onChanged: _switch,
              ),
            ),
        ],
      ),
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
          const SizedBox(height: 16),
          if (_unavailable)
            Text(
              l10n.voiceUnavailable,
              textAlign: TextAlign.center,
              style: AppTextTheme.body.copyWith(color: t.dangerText),
            )
          else ...[
            // Tapping the stopped waveform listens again.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _listening ? null : _listen,
              child: Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: CustomPaint(
                      painter: _WavePainter(
                        _levels,
                        _listening ? t.textPrimary : t.border,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_listening) ...[
                        Icon(Icons.circle, size: 10, color: t.dangerText),
                        const SizedBox(width: 8),
                      ] else ...[
                        Icon(
                          Icons.mic_none_rounded,
                          size: 18,
                          color: t.textMuted,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _listening ? l10n.voiceListening : l10n.voiceRetry,
                        style: AppTextTheme.hint.copyWith(color: t.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _listening ? '$_text|' : _text,
              textAlign: TextAlign.center,
              style: AppTextTheme.body.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
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

/// Symmetric bars, newest volume on the right.
class _WavePainter extends CustomPainter {
  _WavePainter(this.levels, this.color);

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / levels.length;
    final paint = Paint()
      ..color = color
      ..strokeWidth = step * 0.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < levels.length; i++) {
      final half = (levels[i] * size.height / 2).clamp(2.0, size.height / 2);
      final x = step * (i + 0.5);
      canvas.drawLine(
        Offset(x, size.height / 2 - half),
        Offset(x, size.height / 2 + half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}
