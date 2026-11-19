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

/// Mic for a free-text field (never a number field). Opens the voice sheet
/// and, once the text is confirmed, inserts it at [controller]'s cursor as
/// Gboard does, then calls [onChanged] with the field's new text. Draws
/// nothing without a [VoiceScope].
class MicButton extends StatelessWidget {
  const MicButton({
    required this.fieldLabel,
    required this.controller,
    this.onChanged,
    super.key,
  });

  final String fieldLabel;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

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
          if (text == null) return;
          controller.value = insertDictation(controller.value, text);
          onChanged?.call(controller.text);
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
          controller: _controller,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

/// [value] with [spoken] in place of its selection (the end when the field
/// was never focused), spaced from the words around it.
TextEditingValue insertDictation(TextEditingValue value, String spoken) {
  final text = value.text;
  final sel = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: text.length);
  final before = text.substring(0, sel.start);
  final after = text.substring(sel.end);
  final lead = before.isEmpty || before.trimRight() != before ? '' : ' ';
  final trail = after.isEmpty || after.trimLeft() != after ? '' : ' ';
  final inserted = '$lead$spoken$trail';
  return TextEditingValue(
    text: '$before$inserted$after',
    selection: TextSelection.collapsed(offset: sel.start + inserted.length),
  );
}
