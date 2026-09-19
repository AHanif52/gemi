import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemi/app/database.dart';
import 'package:gemi/backup/backup_repository.dart';
import 'package:gemi/backup/backup_service.dart';
import 'package:gemi/kantong/kantong_model.dart';
import 'package:gemi/kategori/kategori_model.dart';
import 'package:gemi/transaksi/transaksi_model.dart';

void main() {
  test('enkripsi bolak-balik; passphrase salah ditolak; file asing ditolak', () async {
    final s = BackupService();
    final isi = {'version': 1, 'accounts': [{'id': 1, 'name': 'BCA'}]};
    final file = await s.enkripsi(isi, 'rahasia-banget');
    expect(file, isNot(contains('BCA')));
    expect(await s.dekripsi(file, 'rahasia-banget'), isi);
    await expectLater(() => s.dekripsi(file, 'salah'), throwsA(isA<PassphraseSalah>()));
    await expectLater(() => s.dekripsi('{"x":1}', 'a'), throwsFormatException);
    await expectLater(() => s.dekripsi('bukan json', 'a'), throwsFormatException);
  });

  test('dump lalu restore ke DB kosong: isi identik, id dipertahankan (1.0: tanpa selisih data)', () async {
    final a = GemiDatabase(NativeDatabase.memory());
    final bca = await a.into(a.accounts).insert(AccountsCompanion.insert(name: 'BCA', type: JenisKantong.bank, initialBalance: 4250000));
    final gopay = await a.into(a.accounts).insert(AccountsCompanion.insert(name: 'GoPay', type: JenisKantong.emoney, initialBalance: 85000));
    final makan = (await a.select(a.categories).get()).first.id;
    await a.into(a.categories).insert(CategoriesCompanion.insert(name: 'Kopi', type: JenisKategori.expense, color: 2, isHidden: const Value(true)));
    await a.into(a.transactions).insert(TransactionsCompanion.insert(type: JenisTransaksi.expense, amount: 32000, accountId: gopay, categoryId: Value(makan), date: '2026-09-18', note: const Value('Nasi padang')));
    await a.into(a.transactions).insert(TransactionsCompanion.insert(type: JenisTransaksi.transfer, amount: 100000, accountId: bca, toAccountId: Value(gopay), date: '2026-09-17'));
    await a.into(a.budgets).insert(BudgetsCompanion.insert(categoryId: makan, month: '2026-09', amount: 1500000));

    final dump = await BackupRepository(a).dump();
    expect((dump['accounts'] as List).first, containsPair('initial_balance', 4250000)); // nama field = kolom SQL
    expect(dump['exported_at'], isA<String>());

    final b = GemiDatabase(NativeDatabase.memory());
    await BackupRepository(b).restore(dump);
    final dumpB = await BackupRepository(b).dump();
    for (final k in ['accounts', 'categories', 'transactions', 'budgets']) {
      expect(dumpB[k], dump[k], reason: k);
    }
    expect((await BackupRepository(b).hitung()), (2, 2));

    await expectLater(() => BackupRepository(b).restore({'version': 99}), throwsFormatException);
    await a.close();
    await b.close();
  });
}

// pastikan enum kategori ter-import untuk companion di atas

