# Gemi

Aplikasi keuangan pribadi untuk Android. Offline penuh, tanpa akun, tanpa server — semua data tersimpan di HP dan dienkripsi.

## Fitur

- **Kantong** — dompet/rekening: saldo awal, penyesuaian saldo, transaksi per kantong.
- **Transaksi** — pemasukan, pengeluaran, transfer antar kantong; cari per catatan/kategori/kantong dan rentang tanggal.
- **Kategori** — kelola kategori pemasukan dan pengeluaran sendiri.
- **Budget** — plafon bulanan per kategori, sisa budget tampil saat mengisi transaksi.
- **Laporan** — harian, mingguan, bulanan; grafik batang dan donat; ekspor CSV bulanan lewat share sheet.
- **Backup & restore** — file JSON terenkripsi passphrase.
- **Kunci aplikasi** — PIN 4 angka + biometrik, kunci otomatis, jeda berlipat setelah salah.
- **Privasi** — sembunyikan semua nominal (`••••••`), blokir screenshot (`FLAG_SECURE`).
- **Pengingat** — notifikasi harian lokal untuk mencatat.
- **Tampilan** — mode terang/gelap/sistem, hari awal minggu Senin/Minggu.

## Stack

- Flutter 3.47 / Dart 3.13
- [drift](https://pub.dev/packages/drift) di atas SQLite, dibundel sebagai **SQLCipher** (AES-256); kunci DB disimpan di Android Keystore lewat `flutter_secure_storage`
- `provider` untuk state, `local_auth` untuk biometrik, `flutter_local_notifications` untuk pengingat, `cryptography` untuk enkripsi backup

## Struktur

```
lib/
  main.dart        # wiring provider + route
  app/             # database (drift), tema, shell tab bar, format angka
  widgets/         # komponen bersama (keypad, hero, baris, toast, ...)
  kantong/  transaksi/  kategori/  budget/  laporan/
  backup/   kunci/      pengingat/ pengaturan/ tampilan/
test/              # unit + widget test, alur end-to-end di memori
integration_test/  # alur yang sama dijalankan di emulator/HP
```

Tiap folder fitur berisi `*_model.dart` (tabel drift), `*_repository.dart` (query), `*_controller.dart` (state), `*_screen.dart` (UI).

## Menjalankan

Butuh Flutter SDK + Android toolchain (lihat `../SETUP.md`).

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generate database.g.dart setelah ubah skema
flutter run
```

Test:

```sh
flutter test                              # unit + widget
flutter test integration_test -d <device> # alur end-to-end di emulator/HP
```

Build rilis:

```sh
flutter build apk --split-per-abi
```

## Catatan

- Skema DB masih versi 1: ubah skema = hapus app dari HP (belum ada migrasi). Lihat komentar di `lib/app/database.dart`.
- Backup Android otomatis dimatikan supaya DB terenkripsi tidak bocor ke cloud; pakai fitur Backup di dalam app.
- Desain dan prototipe HTML ada di `../design/`.
