import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/format.dart';
import '../pengaturan/pengaturan_repository.dart';
import 'backup_repository.dart';
import 'backup_service.dart';

/// Info backup terakhir + aksi buat/pulihkan (FR-14).
class BackupController extends ChangeNotifier {
  BackupController(this._repo, this._service, this._setelan);
  final BackupRepository _repo;
  final BackupService _service;
  final PengaturanRepository _setelan;

  static const _kunciTerakhir = 'backup_terakhir'; // ISO datetime
  static const _kunciRingkas = 'backup_ringkas'; // "112 transaksi, 4 kantong"

  DateTime? terakhir;
  String? ringkas;

  Future<void> muat() async {
    final t = await _setelan.baca(_kunciTerakhir);
    terakhir = t == null ? null : DateTime.tryParse(t);
    ringkas = await _setelan.baca(_kunciRingkas);
    notifyListeners();
  }

  /// "Belum pernah backup" / "Backup terakhir hari ini" / "... 3 hari lalu" (BRD: ingatkan tiap 30 hari).
  String get keterangan {
    final t = terakhir;
    if (t == null) return 'Belum pernah backup';
    final hari = DateTime.now().difference(t).inDays;
    if (hari == 0) return 'Backup terakhir hari ini';
    return hari >= 30
        ? 'Backup terakhir $hari hari lalu, saatnya backup lagi'
        : 'Backup terakhir $hari hari lalu';
  }

  /// Enkripsi seluruh data, tulis ke file sementara, buka share sheet. True kalau pengguna memilih tujuan.
  Future<bool> buat(String passphrase) async {
    if (passphrase.length < 8) {
      throw ArgumentError('backup.buat: passphrase minimal 8 karakter');
    }
    final isi = await _repo.dump();
    final file = await _service.enkripsi(isi, passphrase);
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/gemi-backup-${hariIni()}.json');
    await f.writeAsString(file, flush: true);
    final hasil = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(f.path, mimeType: 'application/json')],
        subject: 'Backup Gemi ${hariIni()}',
      ),
    );
    // File sementara dihapus setelah share sheet tutup; penerima sudah menyalin isinya.
    try {
      await f.delete();
    } on FileSystemException {
      /* sudah tidak ada, tidak masalah */
    }
    if (hasil.status == ShareResultStatus.dismissed) return false;
    final (n, k) = await _repo.hitung();
    await _setelan.tulis(_kunciTerakhir, DateTime.now().toIso8601String());
    await _setelan.tulis(_kunciRingkas, '$n transaksi, $k kantong');
    await muat();
    return true;
  }

  /// Baca file, dekripsi, timpa penuh. Lempar FormatException / PassphraseSalah ke layar.
  Future<void> pulihkan(XFile file, String passphrase) async {
    final isi = await _service.dekripsi(
      utf8.decode(await file.readAsBytes()),
      passphrase,
    );
    await _repo.restore(isi);
  }
}
