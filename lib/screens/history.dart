import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tx_detail.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _type = 'semua';
  int? _categoryId;
  int? _month; // 0..11, atau null = semua bulan
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final list = app.transactions.where((t) {
          if (_type != 'semua' && t.type != _type) return false;
          if (_categoryId != null && t.categoryId != _categoryId) return false;
          if (_month != null) {
            final d = DateTime.parse(t.date);
            if (d.month != _month) return false;
          }
          if (_search.isNotEmpty && !t.note.toLowerCase().contains(_search.toLowerCase())) return false;
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Cari catatan',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _categoryId,
                      isDense: true,
                      decoration: const InputDecoration(labelText: 'Kategori', isDense: true),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Semua kategori')),
                        for (final c in app.categories)
                          DropdownMenuItem<int?>(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(iconOf(c.icon, c.type), size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      initialValue: _month,
                      isDense: true,
                      decoration: const InputDecoration(labelText: 'Bulan', isDense: true),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Semua bulan')),
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem<int?>(value: m, child: Text(_monthName(m))),
                      ],
                      onChanged: (v) => setState(() => _month = v),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _chip(label: 'Semua', selected: _type == 'semua', onTap: () => setState(() => _type = 'semua')),
                  _chip(label: 'Masuk', selected: _type == 'income', onTap: () => setState(() => _type = 'income')),
                  _chip(label: 'Keluar', selected: _type == 'expense', onTap: () => setState(() => _type = 'expense')),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.inbox,
                      title: 'Tidak ada transaksi',
                      subtitle: 'Coba ubah filter atau tambah transaksi baru',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 8, color: Colors.transparent),
                      itemBuilder: (context, i) {
                        final tx = list[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: TransactionTile(
                              tx: tx,
                              category: _categoryFor(app, tx),
                              onTap: () => showTxDetail(context, tx),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Category _categoryFor(AppState app, Transaction tx) {
    for (final c in app.categories) {
      if (c.id == tx.categoryId) return c;
    }
    return Category(id: 0, walletId: null, name: 'Kategori', icon: 'tag', type: tx.type, isDefault: false);
  }

  String _monthName(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[m - 1];
  }

  Widget _chip({required String label, required bool selected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}