import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jabhouy_l10n/jabhouy_l10n.dart';
import 'package:jabhouy_ui/jabhouy_ui.dart';

class _FakeSpeech implements SpeechService {
  _FakeSpeech({this.ok = true, this.khmer = true});

  final bool ok;
  final bool khmer;
  final locales = <String>[];
  void Function(String)? say;
  void Function()? stopped;

  @override
  Future<bool> supports(String localeId) async => khmer;

  @override
  Future<bool> start({
    required String localeId,
    required void Function(String text) onText,
    required void Function(double level) onLevel,
    required void Function() onStopped,
  }) async {
    locales.add(localeId);
    say = onText;
    stopped = onStopped;
    return ok;
  }

  @override
  Future<void> stop() async {}
}

void main() {
  late String? result;

  Future<void> open(WidgetTester tester, _FakeSpeech speech) async {
    result = 'untouched';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('km'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showVoiceSheet(
              context,
              service: speech,
              fieldLabel: 'ឈ្មោះ',
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('Khmer first; nothing is written until ប្រើអត្ថបទនេះ', (
    tester,
  ) async {
    final speech = _FakeSpeech();
    await open(tester, speech);
    expect(speech.locales, ['km-KH']);

    speech.say!('កាហ្វេ');
    await tester.pump();
    expect(result, 'untouched');

    await tester.tap(find.text('ប្រើអត្ថបទនេះ'));
    await tester.pumpAndSettle();
    expect(result, 'កាហ្វេ');
  });

  testWidgets('cancel returns nothing; EN restarts in English', (tester) async {
    final speech = _FakeSpeech();
    await open(tester, speech);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(speech.locales, ['km-KH', 'en-US']);

    speech.say!('milk');
    await tester.pump();
    await tester.tap(find.text('បោះបង់'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('no speech engine: says so and cannot confirm', (tester) async {
    await open(tester, _FakeSpeech(ok: false));

    expect(find.text('មិនអាចប្រើសំឡេងបានទេ'), findsOneWidget);
    final use = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(use.onPressed, isNull);
  });

  testWidgets('stopped listening: dot goes, tap listens again', (tester) async {
    final speech = _FakeSpeech();
    await open(tester, speech);
    expect(find.text('កំពុងស្តាប់…'), findsOneWidget);

    speech.stopped!();
    await tester.pump();
    expect(find.text('កំពុងស្តាប់…'), findsNothing);
    expect(find.text('ចុចដើម្បីស្តាប់ម្តងទៀត'), findsOneWidget);

    await tester.tap(find.text('ចុចដើម្បីស្តាប់ម្តងទៀត'));
    await tester.pumpAndSettle();
    expect(speech.locales, ['km-KH', 'km-KH']);
    expect(find.text('កំពុងស្តាប់…'), findsOneWidget);
  });

  testWidgets('no Khmer on the phone: starts in English, no toggle', (
    tester,
  ) async {
    final speech = _FakeSpeech(khmer: false);
    await open(tester, speech);
    expect(speech.locales, ['en-US']);
    expect(find.text('ខ្មែរ'), findsNothing);
  });

  testWidgets(
    'MicButton fills the field only after confirm; hidden without a scope',
    (tester) async {
      final speech = _FakeSpeech();
      var got = '';
      Widget app({required bool scoped}) {
        final mic = MicButton(fieldLabel: 'ឈ្មោះ', onText: (t) => got = t);
        return MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('km'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: scoped ? VoiceScope(service: speech, child: mic) : mic,
          ),
        );
      }

      await tester.pumpWidget(app(scoped: false));
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);

      await tester.pumpWidget(app(scoped: true));
      await tester.tap(find.byIcon(Icons.mic_none_rounded));
      await tester.pumpAndSettle();
      speech.say!('ទឹកក្រូច');
      await tester.pump();
      expect(got, '');
      await tester.tap(find.text('ប្រើអត្ថបទនេះ'));
      await tester.pumpAndSettle();
      expect(got, 'ទឹកក្រូច');
    },
  );
}
