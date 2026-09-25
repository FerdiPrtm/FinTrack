import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'transaction_form.dart';

Future<void> showTxDetail(BuildContext context, Transaction tx) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => _TxDetailSheet(tx: tx),
  );
}

class _TxDetailSheet extends StatelessWidget {
  final Transaction tx;
  const _TxDetailSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    Category? cat;
    for (final c in app.categories) {
      if (c.id == tx.categoryId) {
        cat = c;
        break;
      }
    }
    final color = tx.type == 'income' ? AppColors.income : AppColors.expense;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(iconOf(cat?.icon, tx.type), size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '${tx.type == 'income' ? '+' : '-'}${formatRp(tx.amount)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(cat?.name ?? 'Kategori', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              formatDate(tx.date),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            if (tx.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(tx.note, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TransactionForm(existing: tx)),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.expense),
                    onPressed: () => _confirmDelete(context, tx),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Transaction tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: Text('${formatRp(tx.amount)} akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AppState.instance.deleteTransaction(tx);
    }
  }
}