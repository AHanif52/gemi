import 'package:flutter/material.dart';

// Sentuhan yang jatuh di dalam toast: di-set oleh Listener dalam toast (hit
// test dari daun ke akar, jadi selalu lebih dulu dari [TutupToastSaatSentuh]).
var _sentuhToast = false;

/// Toast dengan tombol Batalkan, 3 detik. Ditutup lebih cepat begitu user
/// menyentuh apa pun di luar toast (lihat [TutupToastSaatSentuh]).
/// Tombol ditaruh di content, bukan `action`, supaya ikut terdeteksi
/// (SnackBar.action tidak bisa dibungkus). Di layar lebar (>600) floating maks
/// 600 supaya tidak membentang selebar layar (M3); di HP fixed, FAB terangkat.
/// Saat TalkBack aktif toast bertahan sampai ditutup sendiri (swipe/aksi).
void toastBatalkan(
  ScaffoldMessengerState messenger,
  String pesan,
  VoidCallback onBatal,
) {
  final mq = MediaQuery.of(messenger.context);
  final lebar = mq.size.width > 600; // tablet/landscape
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      persist: mq.accessibleNavigation,
      behavior: lebar ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      margin: lebar
          ? EdgeInsets.symmetric(horizontal: (mq.size.width - 600) / 2)
          : null,
      // Tanpa `action`, SnackBar memberi padding vertikal 14; tombol 48dp
      // sudah cukup tinggi, jadi padding vertikal nol supaya tetap 48dp.
      padding: const EdgeInsets.only(left: 16, right: 8),
      content: Listener(
        onPointerDown: (_) => _sentuhToast = true,
        child: Row(
          children: [
            Expanded(child: Text(pesan)),
            Builder(
              builder: (ctx) => TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.inversePrimary,
                ),
                onPressed: () {
                  onBatal();
                  messenger.hideCurrentSnackBar();
                },
                child: const Text('Batalkan'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Pasang di MaterialApp.builder: sentuhan di luar toast langsung menutupnya,
/// supaya "Batalkan" tidak nyangkut lalu kepencet saat lanjut beraktivitas.
/// Tidak aktif saat pembaca layar (explore-by-touch akan menutup toast
/// sebelum sempat dibaca); di sana toast bertahan sampai di-swipe.
class TutupToastSaatSentuh extends StatelessWidget {
  const TutupToastSaatSentuh({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (_sentuhToast) {
          _sentuhToast = false;
          return;
        }
        if (MediaQuery.accessibleNavigationOf(context)) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: child,
    );
  }
}
