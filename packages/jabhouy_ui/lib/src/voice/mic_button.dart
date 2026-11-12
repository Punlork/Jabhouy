import 'package:flutter/material.dart';
import 'package:jabhouy_ui/src/theme/app_tokens.dart';
import 'package:jabhouy_ui/src/voice/speech_service.dart';
import 'package:jabhouy_ui/src/voice/voice_sheet.dart';

/// Makes voice input available below it. The app puts one above the router
/// only when `Feature.voiceInput` is on, so no scope means no mic buttons.
class VoiceScope extends InheritedWidget {
  const VoiceScope({required this.service, required super.child, super.key});

  final SpeechService service;

  static SpeechService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VoiceScope>()?.service;

  @override
  bool updateShouldNotify(VoiceScope old) => service != old.service;
}

/// Mic for a free-text field (never a number field). Opens the voice sheet;
/// [onText] gets the text only after it was confirmed. Draws nothing without
/// a [VoiceScope].
class MicButton extends StatelessWidget {
  const MicButton({required this.fieldLabel, required this.onText, super.key});

  final String fieldLabel;
  final ValueChanged<String> onText;

  @override
  Widget build(BuildContext context) {
    final service = VoiceScope.maybeOf(context);
    if (service == null) return const SizedBox.shrink();
    // Not a stop for the keyboard's Next key.
    return ExcludeFocus(
      child: IconButton(
        onPressed: () async {
          final text = await showVoiceSheet(
            context,
            service: service,
            fieldLabel: fieldLabel,
          );
          if (text != null) onText(text);
        },
        icon: Icon(Icons.mic_none_rounded, color: context.tokens.textMuted),
      ),
    );
  }
}

/// The bordered search box the pickers use, with a [MicButton] that fills
/// it. Owns its controller so a stateless sheet can use it.
class MicSearchField extends StatefulWidget {
  const MicSearchField({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<MicSearchField> createState() => _MicSearchFieldState();
}

class _MicSearchFieldState extends State<MicSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(Icons.search_rounded, color: context.tokens.textMuted),
        suffixIcon: MicButton(
          fieldLabel: widget.hintText,
          onText: (text) {
            _controller.text = text;
            widget.onChanged(text);
          },
        ),
      ),
    );
  }
}
