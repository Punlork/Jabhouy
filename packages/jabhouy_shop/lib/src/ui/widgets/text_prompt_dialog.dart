import 'package:flutter/material.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';

/// Asks for one line of text; null when dismissed.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  String? hintText,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextPromptDialog(title: title, hintText: hintText),
);

/// Owns its controller: the field stays on screen while the dialog
/// animates out, so the caller must not dispose it on pop.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({required this.title, this.hintText});

  final String title;
  final String? hintText;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}
