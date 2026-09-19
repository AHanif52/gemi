import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/pengingat/pengingat_controller.dart';

void main() {
  final pagi = DateTime(2026, 9, 19, 9, 0);
  final malam = DateTime(2026, 9, 19, 21, 30);

  test('belum ada transaksi & jam belum lewat: hari ini', () {
    expect(PengingatController.berikutnya(sekarang: pagi, jam: '21:00', adaTransaksiHariIni: false), DateTime(2026, 9, 19, 21, 0));
  });

  test('sudah ada transaksi hari ini: besok', () {
    expect(PengingatController.berikutnya(sekarang: pagi, jam: '21:00', adaTransaksiHariIni: true), DateTime(2026, 9, 20, 21, 0));
  });

  test('jam sudah lewat: besok', () {
    expect(PengingatController.berikutnya(sekarang: malam, jam: '21:00', adaTransaksiHariIni: false), DateTime(2026, 9, 20, 21, 0));
  });

  test('lintas bulan', () {
    expect(PengingatController.berikutnya(sekarang: DateTime(2026, 9, 30, 22), jam: '21:00', adaTransaksiHariIni: false), DateTime(2026, 10, 1, 21, 0));
  });
}
