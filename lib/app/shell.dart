import 'package:flutter/material.dart';

import '../beranda/beranda_screen.dart';
import '../budget/budget_screen.dart';
import '../transaksi/transaksi_list_screen.dart';
import '../widgets/ikon_gemi.dart';
import 'theme.dart';

/// Empat tab utama + tombol tambah (BRD: Navigasi utama). Laporan menyusul.
class Shell extends StatefulWidget {
  const Shell({super.key, this.tab = 0});
  final int tab;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _tab = widget.tab;

  static const _layar = [
    BerandaScreen(),
    TransaksiListScreen(),
    BudgetScreen(),
    _Menyusul('Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    final g = context.gemi;
    final ink = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: _layar[_tab],
      floatingActionButton: _tab == 2
          ? null
          : FloatingActionButton(
              key: const Key('transaksi.tambah'),
              onPressed: () => Navigator.pushNamed(context, '/transaksi/baru'),
              backgroundColor: ink,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? ink : g.ink3,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => TextStyle(
              fontSize: 12,
              color: s.contains(WidgetState.selected) ? ink : g.ink3,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w500
                  : null,
            ),
          ),
          destinations: const [
            NavigationDestination(
              key: Key('nav.beranda'),
              icon: IkonTab(IkonGemi.beranda),
              label: 'Beranda',
            ),
            NavigationDestination(
              key: Key('nav.transaksi'),
              icon: IkonTab(IkonGemi.transaksi),
              label: 'Transaksi',
            ),
            NavigationDestination(
              key: Key('nav.budget'),
              icon: IkonTab(IkonGemi.budget),
              label: 'Budget',
            ),
            NavigationDestination(
              key: Key('nav.laporan'),
              icon: IkonTab(IkonGemi.laporan),
              label: 'Laporan',
            ),
          ],
        ),
      ),
    );
  }
}

class _Menyusul extends StatelessWidget {
  const _Menyusul(this.judul);
  final String judul;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(judul)),
    body: Center(
      child: Text('Menyusul', style: TextStyle(color: context.gemi.ink2)),
    ),
  );
}
