import 'package:speech_to_text/speech_to_text.dart';

/// Turns speech into text. The voice sheet talks to this, never to the
/// plugin, so tests give it a fake.
// ignore: one_member_abstracts — the seam is the point, not the member count.
abstract interface class SpeechService {
  /// Starts listening; [onText] gets the transcript so far and [onLevel] the
  /// volume from 0 to 1. False when the phone has no speech engine or the
  /// microphone was refused.
  Future<bool> start({
    required String localeId,
    required void Function(String text) onText,
    required void Function(double level) onLevel,
  });

  Future<void> stop();
}

/// The phone's own speech engine.
final class DeviceSpeechService implements SpeechService {
  final _speech = SpeechToText();

  @override
  Future<bool> start({
    required String localeId,
    required void Function(String text) onText,
    required void Function(double level) onLevel,
  }) async {
    if (!await _speech.initialize()) return false;
    await _speech.listen(
      onResult: (result) => onText(result.recognizedWords),
      // Android reports about -2 to 10, iOS other ranges; the wave only
      // needs a rough 0 to 1.
      onSoundLevelChange: (level) => onLevel(((level + 2) / 12).clamp(0, 1)),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.dictation,
      ),
    );
    return true;
  }

  @override
  Future<void> stop() => _speech.stop();
}
