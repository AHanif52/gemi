import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Enkripsi/dekripsi file backup. Murni Dart, tanpa jaringan.
/// Format file (JSON): {gemi:1, kdf:{argon2id, salt, memory, iterations, parallelism}, nonce, mac, data}.
/// Kunci turunan passphrase lewat Argon2id; isi dienkripsi AES-256-GCM.
class BackupService {
  static const versiFile = 1;
  // ponytail: parameter Argon2id konservatif supaya HP menengah < 2 detik;
  // naikkan memory kalau perangkat target terbukti lebih kuat.
  static const _memoryKb = 32 * 1024, _iterations = 3, _parallelism = 1;

  Future<SecretKey> _kunci(
    String passphrase,
    List<int> salt, {
    int memory = _memoryKb,
    int iterations = _iterations,
    int parallelism = _parallelism,
  }) => Argon2id(
    memory: memory,
    iterations: iterations,
    parallelism: parallelism,
    hashLength: 32,
  ).deriveKeyFromPassword(password: passphrase, nonce: salt);

  Future<String> enkripsi(Map<String, Object?> isi, String passphrase) async {
    final r = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => r.nextInt(256)));
    final kunci = await _kunci(passphrase, salt);
    final aes = AesGcm.with256bits();
    final box = await aes.encrypt(
      utf8.encode(jsonEncode(isi)),
      secretKey: kunci,
    );
    return jsonEncode({
      'gemi': versiFile,
      'kdf': {
        'name': 'argon2id',
        'salt': base64Encode(salt),
        'memory': _memoryKb,
        'iterations': _iterations,
        'parallelism': _parallelism,
      },
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'data': base64Encode(box.cipherText),
    });
  }

  /// Lempar [FormatException] kalau bukan file Gemi, [PassphraseSalah] kalau MAC gagal.
  Future<Map<String, Object?>> dekripsi(String file, String passphrase) async {
    final Object? raw;
    try {
      raw = jsonDecode(file);
    } on FormatException {
      throw const FormatException('backup: bukan file JSON');
    }
    if (raw is! Map || raw['gemi'] != versiFile) {
      throw const FormatException('backup: bukan file backup Gemi versi ini');
    }
    final kdf = raw['kdf'] as Map;
    final kunci = await _kunci(
      passphrase,
      base64Decode(kdf['salt'] as String),
      memory: kdf['memory'] as int,
      iterations: kdf['iterations'] as int,
      parallelism: kdf['parallelism'] as int,
    );
    final box = SecretBox(
      base64Decode(raw['data'] as String),
      nonce: base64Decode(raw['nonce'] as String),
      mac: Mac(base64Decode(raw['mac'] as String)),
    );
    try {
      final bytes = await AesGcm.with256bits().decrypt(box, secretKey: kunci);
      return jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    } on SecretBoxAuthenticationError {
      throw PassphraseSalah();
    }
  }
}

class PassphraseSalah implements Exception {}
