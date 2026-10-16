import 'dart:math';

final _random = Random.secure();

/// A UUIDv7 made on the phone: 48 bits of Unix milliseconds, then random
/// bits, so ids sort by creation time and never need the server.
String newId() {
  final ms = DateTime.now().millisecondsSinceEpoch;
  final bytes = [
    for (var shift = 40; shift >= 0; shift -= 8) (ms >> shift) & 0xff,
    for (var i = 0; i < 10; i++) _random.nextInt(256),
  ];
  bytes[6] = 0x70 | (bytes[6] & 0x0f); // version 7
  bytes[8] = 0x80 | (bytes[8] & 0x3f); // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
