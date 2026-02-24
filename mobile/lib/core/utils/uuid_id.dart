import 'dart:math';

final Random _uuidRandom = Random.secure();

String newUuidV4() {
  final bytes = List<int>.generate(16, (_) => _uuidRandom.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx

  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).toList(growable: false);
  return '${h[0]}${h[1]}${h[2]}${h[3]}-'
      '${h[4]}${h[5]}-'
      '${h[6]}${h[7]}-'
      '${h[8]}${h[9]}-'
      '${h[10]}${h[11]}${h[12]}${h[13]}${h[14]}${h[15]}';
}
