import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class NotificationDiagnosticEntry extends Equatable {
  const NotificationDiagnosticEntry({
    required this.timestamp,
    required this.source,
    required this.level,
    required this.message,
    this.metadata = const <String, dynamic>{},
  });

  factory NotificationDiagnosticEntry.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    final timestamp = switch (rawTimestamp) {
      final int value => DateTime.fromMillisecondsSinceEpoch(value).toLocal(),
      final String value => DateTime.tryParse(value)?.toLocal(),
      _ => null,
    };

    return NotificationDiagnosticEntry(
      timestamp: timestamp ?? DateTime.now(),
      source: map['source']?.toString() ?? 'unknown',
      level: map['level']?.toString() ?? 'info',
      message: map['message']?.toString() ?? '',
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const <String, dynamic>{},
    );
  }

  final DateTime timestamp;
  final String source;
  final String level;
  final String message;
  final Map<String, dynamic> metadata;

  String get timeLabel => DateFormat('HH:mm:ss').format(timestamp);

  String get metadataLabel {
    if (metadata.isEmpty) return '';
    return metadata.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }

  @override
  List<Object?> get props => [
        timestamp,
        source,
        level,
        message,
        metadata.entries
            .map((entry) => '${entry.key}:${entry.value}')
            .toList(growable: false),
      ];
}
