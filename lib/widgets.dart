import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

class CategoryAvatar extends StatelessWidget {
  final Category category;
  final double radius;

  const CategoryAvatar({super.key, required this.category, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final color = category.type == 'income' ? AppColors.income : AppColors.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(iconOf(category.icon, category.type), color: color, size: radius * 1.3),
    );
  }
}

class BalanceCard extends StatefulWidget {
  final int balance;
  final int income;
  final int expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _obscured = false;

  @override
  Widget build(BuildContext context) {
    final balance = widget.balance;
    final income = widget.income;
    final expense = widget.expense;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF115E59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Saldo Total',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (!_obscured && balance < 0) ...[
                const SizedBox(width: 6),
                const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFFCA5A5)),
              ],
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _obscured ? 'Tampilkan saldo' : 'Sembunyikan saldo',
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _obscured ? 'Rp •••••' : formatRp(balance),
            style: TextStyle(
              color: _obscured ? Colors.white : (balance < 0 ? const Color(0xFFFCA5A5) : Colors.white),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(icon: Icons.south, label: 'Masuk (bulan ini)', value: income, color: const Color(0xFF86EFAC)),
              const SizedBox(width: 24),
              _miniStat(icon: Icons.north, label: 'Keluar (bulan ini)', value: expense, color: const Color(0xFFFCA5A5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatRp(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction tx;
  final Category category;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = tx.type == 'income' ? AppColors.income : AppColors.expense;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CategoryAvatar(category: category),
      title: Text(
        category.name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        tx.note.isEmpty ? formatDate(tx.date) : '${tx.note} · ${formatDate(tx.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        '${tx.type == 'income' ? '+' : '-'}${formatRp(tx.amount)}',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}