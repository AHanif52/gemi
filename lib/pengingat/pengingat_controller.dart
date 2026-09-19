import 'package:flutter/foundation.dart';

import '../pengaturan/pengaturan_repository.dart';
import 'penjadwal.dart';

/// FR-17: notifikasi lokal tiap hari pada [jam] kalau hari itu belum ada transaksi.
/// Tanpa server. Dijadwalkan ulang setiap transaksi berubah: kalau hari ini sudah
/// mencatat, jadwal mulai besok; jadwal berulang harian sampai dijadwalkan ulang.
class PengingatController extends ChangeNotifier {
  PengingatController(this._setelan, this._penjadwal);
  final PengaturanRepository _setelan;
  final Penjadwal _penjadwal;

  static const _kunciAktif = 'pengingat_aktif', _kunciJam = 'pengingat_jam';
  static const isiNotifikasi =
      'Belum ada transaksi hari ini. Ada pengeluaran yang belum dicatat?';

  bool _aktif = true;
  String _jam = '21:00'; // HH:MM
  Future<void>? _persiapan;

  bool get aktif => _aktif;
  String get jam => _jam;
  String get keterangan => _aktif
      ? 'Setiap ${_jam.replaceAll(':', '.')} kalau belum ada transaksi'
      : 'Mati';

  Future<void> muat() async {
    _aktif = (await _setelan.baca(_kunciAktif) ?? '1') == '1';
    _jam = await _setelan.baca(_kunciJam) ?? '21:00';
    notifyListeners();
  }

  Future<void> setAktif(bool v, {required bool adaTransaksiHariIni}) async {
    _aktif = v;
    notifyListeners();
    await _setelan.tulis(_kunciAktif, v ? '1' : '0');
    await jadwalkan(adaTransaksiHariIni: adaTransaksiHariIni);
  }

  Future<void> setJam(String hhmm, {required bool adaTransaksiHariIni}) async {
    _jam = hhmm;
    notifyListeners();
    await _setelan.tulis(_kunciJam, hhmm);
    await jadwalkan(adaTransaksiHariIni: adaTransaksiHariIni);
  }

  /// Hitung waktu pengingat berikutnya (murni, bisa dites).
  static DateTime berikutnya({
    required DateTime sekarang,
    required String jam,
    required bool adaTransaksiHariIni,
  }) {
    final h = int.parse(jam.substring(0, 2)),
        m = int.parse(jam.substring(3, 5));
    var t = DateTime(sekarang.year, sekarang.month, sekarang.day, h, m);
    if (adaTransaksiHariIni || !t.isAfter(sekarang)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  Future<void> jadwalkan({required bool adaTransaksiHariIni}) async {
    // Sekali saja walau dipanggil paralel (listener transaksi bisa menembak berkali-kali).
    await (_persiapan ??= _penjadwal.siapkan());
    await _penjadwal.batal();
    if (!_aktif) return;
    await _penjadwal.jadwalHarian(
      berikutnya(
        sekarang: DateTime.now(),
        jam: _jam,
        adaTransaksiHariIni: adaTransaksiHariIni,
      ),
      judul: 'Gemi',
      isi: isiNotifikasi,
    );
  }
}
