import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'dashboard.dart';
import 'history.dart';
import 'settings.dart';
import 'stats.dart';
import 'transaction_form.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardTab(onSeeAll: () => setState(() => _index = 1)),
      const HistoryTab(),
      const StatsTab(),
      const SettingsTab(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: _WalletSwitcher(onChanged: (_) => setState(() {})),
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 3
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              tooltip: 'Tambah transaksi',
              onPressed: () async {
                if (AppState.instance.wallet == null) {
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(const SnackBar(content: Text('Buat dompet dulu dari menu dompet di atas')));
                  return;
                }
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TransactionForm()),
                );
              },
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ringkasan'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Statistik'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}

class _WalletSwitcher extends StatelessWidget {
  const _WalletSwitcher({required this.onChanged});

  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final w = app.wallet;
    return Row(
      children: [
        Expanded(
          child: Tooltip(
            message: 'Ganti dompet',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showWalletSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        w?.name ?? 'Pilih Dompet',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showWalletSheet(BuildContext context) async {
    final app = AppState.instance;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListenableBuilder(
        listenable: app,
        builder: (ctx, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Dompet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  for (final Wallet w in app.wallets)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.wallet, color: AppColors.primary),
                      title: Text(w.name),
                      trailing: w.id == app.walletId
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () async {
                        await app.openWallet(w.id);
                        onChanged(w.name);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final name = await _promptNewWallet(context);
                      if (name != null && name.isNotEmpty) {
                        await app.createWallet(name);
                        onChanged(name);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Buat Dompet Baru'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _promptNewWallet(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Dompet Baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama dompet'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }
}