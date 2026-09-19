import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

import 'kunci_repository.dart';

/// State kunci aplikasi (FR-16): PIN 4 angka, biometrik sebagai jalan cepat,
/// kunci otomatis saat ke background, jeda 30 detik berlipat setelah 5 kali salah.
class KunciController extends ChangeNotifier with WidgetsBindingObserver {
  KunciController(this._repo, {LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication() {
    WidgetsBinding.instance.addObserver(this);
  }

  final KunciRepository _repo;
  final LocalAuthentication _auth;

  static const pilihanOtomatis = [0, 60, 300]; // detik; 0 = segera
  static const maksGagal = 5;
  static const jedaAwal = Duration(seconds: 30);

  bool _siap = false;
  bool _aktif = false;
  bool _biometrik = false;
  bool _bisaBiometrik = false;
  int _otomatis = 60;
  bool _terkunci = false;
  int _gagal = 0;
  DateTime? _jedaSampai;
  DateTime? _keBelakang;

  bool get siap => _siap;
  bool get aktif => _aktif;
  bool get biometrik => _biometrik;
  bool get bisaBiometrik => _bisaBiometrik;
  int get otomatis => _otomatis;
  bool get terkunci => _terkunci;
  int get gagal => _gagal;

  /// Sisa jeda; null kalau tidak sedang dijeda.
  Duration? get sisaJeda {
    final j = _jedaSampai;
    if (j == null) return null;
    final sisa = j.difference(DateTime.now());
    return sisa.isNegative ? null : sisa;
  }

  String get keterangan => !_aktif
      ? 'Mati'
      : 'PIN${_biometrik ? ' + biometrik' : ''}, kunci otomatis ${labelOtomatis(_otomatis).toLowerCase()}';

  static String labelOtomatis(int detik) => switch (detik) {
    0 => 'Segera',
    60 => '1 menit',
    _ => '${detik ~/ 60} menit',
  };

  Future<void> muat() async {
    _aktif = await _repo.baca('aktif') == '1' && await _repo.adaPin;
    _biometrik = await _repo.baca('biometrik') == '1';
    _otomatis = int.tryParse(await _repo.baca('otomatis') ?? '') ?? 60;
    _gagal = int.tryParse(await _repo.baca('gagal') ?? '') ?? 0;
    final jeda = int.tryParse(await _repo.baca('jedaSampai') ?? '');
    _jedaSampai = jeda == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(jeda);
    try {
      _bisaBiometrik =
          await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      _bisaBiometrik = false;
    }
    _terkunci = _aktif; // buka dingin selalu terkunci
    _siap = true;
    notifyListeners();
  }

  /// Simpan PIN baru (buat atau ubah) dan nyalakan kunci.
  Future<void> aturPin(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw ArgumentError('kunci.aturPin: PIN harus 4 angka');
    }
    await _repo.simpanPin(pin);
    await _repo.tulis('aktif', '1');
    _aktif = true;
    await _resetGagal();
    notifyListeners();
  }

  Future<void> matikan() async {
    await _repo.hapusPin();
    await _repo.tulis('aktif', '0');
    _aktif = false;
    _terkunci = false;
    await _resetGagal();
    notifyListeners();
  }

  Future<void> aturBiometrik(bool v) async {
    _biometrik = v;
    await _repo.tulis('biometrik', v ? '1' : '0');
    notifyListeners();
  }

  Future<void> aturOtomatis(int detik) async {
    _otomatis = detik;
    await _repo.tulis('otomatis', '$detik');
    notifyListeners();
  }

  /// Kunci sekarang (dipakai "Coba layar kunci").
  void kunci() {
    if (!_aktif) return;
    _terkunci = true;
    notifyListeners();
  }

  /// Cek PIN. False kalau salah atau masih dijeda; jeda dicatat ke settings
  /// supaya restart aplikasi tidak menghapusnya.
  Future<bool> buka(String pin) async {
    if (sisaJeda != null) return false;
    if (await _repo.cocok(pin)) {
      _terkunci = false;
      await _resetGagal();
      notifyListeners();
      return true;
    }
    _gagal++;
    await _repo.tulis('gagal', '$_gagal');
    if (_gagal >= maksGagal) {
      // 5 salah: 30 detik; tiap salah berikutnya berlipat: 60, 120, ...
      final kali = 1 << (_gagal - maksGagal);
      _jedaSampai = DateTime.now().add(jedaAwal * kali);
      await _repo.tulis('jedaSampai', '${_jedaSampai!.millisecondsSinceEpoch}');
    }
    notifyListeners();
    return false;
  }

  Future<bool> bukaBiometrik() async {
    if (!_aktif || !_biometrik || !_bisaBiometrik) return false;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Buka Gemi',
        biometricOnly: true,
      );
      if (!ok) return false;
    } catch (_) {
      return false;
    }
    _terkunci = false;
    await _resetGagal();
    notifyListeners();
    return true;
  }

  Future<void> _resetGagal() async {
    _gagal = 0;
    _jedaSampai = null;
    await _repo.tulis('gagal', '0');
    await _repo.tulis('jedaSampai', '');
  }

  // Kunci otomatis: catat saat ke background, bandingkan saat kembali.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_aktif) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _keBelakang ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final t = _keBelakang;
      _keBelakang = null;
      if (t != null &&
          !_terkunci &&
          DateTime.now().difference(t).inSeconds >= _otomatis) {
        _terkunci = true;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
