import 'package:drift/drift.dart';

import '../app/database.dart';
import '../transaksi/transaksi_model.dart';
import 'laporan_model.dart';

/// Agregat SQL untuk laporan. Tidak pernah memuat baris transaksi satu per satu (NFR-05).
class LaporanRepository {
  LaporanRepository(this._db);
  final GemiDatabase _db;

  Future<Ringkasan> ringkasan(String dari, String sampai) async {
    final t = _db.transactions, k = _db.categories;
    final total = t.amount.sum();
    final n = t.id.count();
    Expression<bool> rentang() => t.date.isBetweenValues(dari, sampai);

    final perJenis =
        await (_db.selectOnly(t)
              ..addColumns([t.type, total])
              ..where(
                rentang() & t.type.equalsValue(JenisTransaksi.transfer).not(),
              )
              ..groupBy([t.type]))
            .get();
    var masuk = 0, keluar = 0;
    for (final r in perJenis) {
      // selectOnly mengembalikan nilai mentah kolom (String), bukan enum.
      if (r.read(t.type) == JenisTransaksi.income.name) {
        masuk = r.read(total) ?? 0;
      }
      if (r.read(t.type) == JenisTransaksi.expense.name) {
        keluar = r.read(total) ?? 0;
      }
    }

    final perHari =
        await (_db.selectOnly(t)
              ..addColumns([t.date, total])
              ..where(rentang() & t.type.equalsValue(JenisTransaksi.expense))
              ..groupBy([t.date]))
            .get();

    final perKategori =
        await (_db.selectOnly(t).join([
                innerJoin(k, k.id.equalsExp(t.categoryId), useColumns: true),
              ])
              ..addColumns([total, n])
              ..where(rentang() & t.type.equalsValue(JenisTransaksi.expense))
              ..groupBy([k.id])
              ..orderBy([OrderingTerm.desc(total)]))
            .get();

    return Ringkasan(
      dari: dari,
      sampai: sampai,
      masuk: masuk,
      keluar: keluar,
      keluarPerHari: {
        for (final r in perHari) r.read(t.date)!: r.read(total) ?? 0,
      },
      keluarPerKategori: [
        for (final r in perKategori)
          KategoriTotal(
            kategori: r.readTable(k),
            total: r.read(total) ?? 0,
            jumlah: r.read(n) ?? 0,
          ),
      ],
    );
  }
}
