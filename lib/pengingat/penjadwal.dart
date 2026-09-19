import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Seam ke plugin notifikasi supaya controller bisa dites tanpa platform channel.
abstract class Penjadwal {
  Future<void> siapkan();
  Future<void> batal();
  Future<void> jadwalHarian(
    DateTime pertama, {
    required String judul,
    required String isi,
  });
}

/// Implementasi produksi: flutter_local_notifications, jadwal harian inexact.
class PenjadwalNotifikasi implements Penjadwal {
  PenjadwalNotifikasi([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;
  static const _id = 1;

  @override
  Future<void> siapkan() async {
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

  @override
  Future<void> batal() => _plugin.cancel(id: _id);

  @override
  Future<void> jadwalHarian(
    DateTime pertama, {
    required String judul,
    required String isi,
  }) => _plugin.zonedSchedule(
    id: _id,
    title: judul,
    body: isi,
    scheduledDate: tz.TZDateTime.from(pertama, tz.local),
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
