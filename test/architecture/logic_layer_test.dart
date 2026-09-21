// The layering rule in docs/ARCHITECTURE_RESTRUCTURE.md says `logic/`
// imports no Flutter and no Drift. Dart has no way to express that, and
// the rule was decorative until this file: a use case can reach Flutter
// through four hops of barrel without anything complaining.
//
// So the closure is walked here instead. This is the enforcement.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Packages a `logic/` file may not reach, however indirectly.
const _banned = {'package:flutter', 'package:drift', 'dart:ui'};

/// Packages whose own contents are not walked.
///
/// `jabhouy_core` and `jabhouy_sync` run under `dart test`, which loads on
/// the plain Dart VM with no `dart:ui`. Their purity is already a failing
/// build if broken, so trusting them here is not a hole.
const _trusted = {'package:jabhouy_core', 'package:jabhouy_sync'};

final _importPattern = RegExp(
  r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""",
  multiLine: true,
);

void main() {
  test('nothing under logic/ can reach Flutter or Drift', () {
    final logicFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.path.contains('/logic/'))
        .toList();

    expect(
      logicFiles,
      isNotEmpty,
      reason: 'no logic/ folder found — has the layout changed?',
    );

    final violations = <String>[];

    for (final entry in logicFiles) {
      final seen = <String>{};
      final queue = <(String path, List<String> via)>[(entry.path, [])];

      while (queue.isNotEmpty) {
        final (path, via) = queue.removeLast();
        if (!seen.add(path)) continue;

        final file = File(path);
        if (!file.existsSync()) continue;

        for (final match in _importPattern.allMatches(file.readAsStringSync())) {
          final uri = match.group(1)!;
          final trail = [...via, path];

          if (_banned.any(uri.startsWith)) {
            violations.add(
              '${entry.path}\n    reaches $uri\n    via ${trail.join('\n        -> ')}',
            );
            continue;
          }

          if (_trusted.any(uri.startsWith)) continue;

          if (uri.startsWith('package:jabhouy/')) {
            queue.add(
              (uri.replaceFirst('package:jabhouy/', 'lib/'), trail),
            );
          } else if (!uri.startsWith('package:') && !uri.startsWith('dart:')) {
            // A relative import, resolved against the importing file.
            queue.add((
              File(path).parent.uri.resolve(uri).toFilePath(),
              trail,
            ));
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'logic/ must stay Flutter-free:\n\n${violations.join('\n\n')}',
    );
  });
}
