import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../pengaturan/pengaturan_repository.dart';

/// FR-17: notifikasi lokal tiap hari pada [jam] kalau hari itu belum ada transaksi.
/// Tanpa server. Dijadwalkan ulang setiap transaksi berubah: kalau hari ini sudah
/// mencatat, jadwal mulai besok; jadwal berulang harian sampai dijadwalkan ulang.
class PengingatController extends ChangeNotifier {
  PengingatController(this._setelan, [FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final PengaturanRepository _setelan;
  final FlutterLocalNotificationsPlugin _plugin;

  static const _kunciAktif = 'pengingat_aktif', _kunciJam = 'pengingat_jam';
  static const _id = 1;

  bool _aktif = true;
  String _jam = '21:00'; // HH:MM

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

  Future<void>? _persiapan;

  /// Sekali saja walau dipanggil paralel (listener transaksi bisa menembak berkali-kali).
  Future<void> _siapkan() => _persiapan ??= _siapkanSekali();

  Future<void> _siapkanSekali() async {
    tzdata.initializeTimeZones();
    // Android butuh ID zona IANA. Tanpa package tambahan: pakai Etc/GMT dari offset lokal
    // (tanda dibalik: WIB +7 = "Etc/GMT-7"). Semua zona Indonesia offset jam bulat.
    // ponytail: zona setengah jam (mis. India) dibulatkan; ganti ke flutter_timezone kalau perlu.
    final jam = DateTime.now().timeZoneOffset.inMinutes ~/ 60;
    tz.setLocalLocation(
      tz.getLocation(
        jam == 0 ? 'Etc/GMT' : 'Etc/GMT${jam > 0 ? '-' : '+'}${jam.abs()}',
      ),
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
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
    await _siapkan();
    await _plugin.cancel(id: _id);
    if (!_aktif) return;
    final t = berikutnya(
      sekarang: DateTime.now(),
      jam: _jam,
      adaTransaksiHariIni: adaTransaksiHariIni,
    );
    await _plugin.zonedSchedule(
      id: _id,
      title: 'Gemi',
      body: 'Belum ada transaksi hari ini. Ada pengeluaran yang belum dicatat?',
      scheduledDate: tz.TZDateTime.from(t, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pengingat',
          'Pengingat harian',
          channelDescription:
              'Mengingatkan mencatat kalau hari itu belum ada transaksi',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Tidak perlu izin exact alarm; meleset beberapa menit tidak masalah.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
