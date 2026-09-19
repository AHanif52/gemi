import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/database.dart' show Kategori;
import '../app/format.dart';
import '../app/theme.dart';
import '../widgets/ribuan_formatter.dart';
import 'budget_controller.dart';
import 'budget_repository.dart';

/// /budget/ubah — plafon per kategori pengeluaran untuk satu bulan (FR-06).
class BudgetUbahScreen extends StatefulWidget {
  const BudgetUbahScreen({super.key, required this.bulan});
  final String bulan;

  @override
  State<BudgetUbahScreen> createState() => _BudgetUbahScreenState();
}

class _BudgetUbahScreenState extends State<BudgetUbahScreen> {
  List<Kategori>? _kategori;
  final _input = <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final repo = context.read<BudgetRepository>();
    final kategori = await repo.kategoriKeluar();
    final plafon = await repo.plafon(widget.bulan);
    if (!mounted) return;
    setState(() {
      _kategori = kategori;
      for (final k in kategori) {
        final p = plafon[k.id] ?? 0;
        _input[k.id] = TextEditingController(text: p == 0 ? '' : fmtRupiah(p))
          ..addListener(() => setState(() {}));
      }
    });
  }

  @override
  void dispose() {
    for (final c in _input.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _total => _input.values.fold(0, (a, c) => a + parseRupiah(c.text));

  Future<void> _simpan() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<BudgetController>().simpan(widget.bulan, {
      for (final e in _input.entries) e.key: parseRupiah(e.value.text),
    });
    nav.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Budget disimpan')));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        leadingWidth: 80,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      'Budget ${fmtBulan(widget.bulan, pendek: true)}',
                      style: t.titleLarge,
                    ),
                  ),
                  Text(
                    'Kosongkan kalau kategori tidak perlu dibatasi.',
                    style: t.bodySmall?.copyWith(color: g.ink2),
                  ),
                  const SizedBox(height: 16),
                  for (final k in _kategori ?? const <Kategori>[])
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Expanded(child: Text(k.name)),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              key: Key('budget.plafon.${k.id}'),
                              controller: _input[k.id],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                RibuanFormatter(),
                              ],
                              style: const TextStyle(
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                              decoration: InputDecoration(
                                hintText: 'Tanpa budget',
                                isDense: true,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: g.rule),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: ink),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Garis ganda ala pembukuan di bawah total (tokens .total).
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: ink),
                        bottom: BorderSide(
                          color: ink,
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total budget',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          fmtRupiah(_total),
                          key: const Key('budget.total'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                key: const Key('budget.simpan'),
                onPressed: _kategori == null ? null : _simpan,
                child: const Text('Simpan budget'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
