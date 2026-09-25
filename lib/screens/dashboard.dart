import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tx_detail.dart';

class DashboardTab extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const DashboardTab({super.key, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (app.wallet == null) {
          return const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Belum ada dompet',
            subtitle: 'Buat dompet baru dari menu dompet di atas',
          );
        }
        final recent = app.transactions.take(5).toList();
        return RefreshIndicator(
          onRefresh: () => app.refreshWallet(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              BalanceCard(
                balance: app.totalBalance,
                income: app.monthIncome,
                expense: app.monthExpense,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const SizedBox(
                  height: 140,
                  child: EmptyState(
                    icon: Icons.add_card,
                    title: 'Belum ada transaksi',
                    subtitle: 'Tekan tombol + untuk mencatat',
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < recent.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                          TransactionTile(
                            tx: recent[i],
                            category: _categoryFor(app, recent[i]),
                            onTap: () => showTxDetail(context, recent[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
}