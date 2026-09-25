import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  bool _last6Months = false;

  static const _colors = [
    Color(0xFF0F766E), Color(0xFF16A34A), Color(0xFFF59E0B),
    Color(0xFF3B82F6), Color(0xFFEF4444), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFF97316),
  ];

  List<Transaction> _pieTransactions(AppState app) {
    final now = DateTime.now();
    return app.transactions.where((t) {
      if (t.type != 'expense') return false;
      final d = DateTime.parse(t.date);
      if (_last6Months) {
        final sixMonthsAgo = DateTime(now.year, now.month - 5);
        return !d.isBefore(sixMonthsAgo);
      }
      return d.year == now.year && d.month == now.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final pie = _pieTransactions(app);
        final groups = <int, ({String name, String icon, int total})>{};
        for (final t in pie) {
          final cat = _catFor(app, t.categoryId);
          final g = groups[t.categoryId];
          groups[t.categoryId] = (
            name: cat?.name ?? 'Lainnya',
            icon: cat?.icon ?? 'tag',
            total: (g?.total ?? 0) + t.amount,
          );
        }
        final pieList = groups.values.toList()..sort((a, b) => b.total.compareTo(a.total));
        final pieTotal = pieList.fold(0, (s, g) => s + g.total);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pengeluaran per Kategori',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Bulan ini')),
                            ButtonSegment(value: true, label: Text('6 Bulan')),
                          ],
                          selected: {_last6Months},
                          onSelectionChanged: (s) => setState(() => _last6Months = s.first),
                          showSelectedIcon: false,
                          style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: pieList.isEmpty
                          ? const Center(child: Text('Belum ada data', style: TextStyle(color: AppColors.textSecondary)))
                          : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 44,
                                startDegreeOffset: -90,
                                sections: [
                                  for (var i = 0; i < pieList.length; i++)
                                    PieChartSectionData(
                                      value: pieList[i].total.toDouble(),
                                      color: _colors[i % _colors.length],
                                      radius: 60,
                                      title: '${(pieList[i].total / pieTotal * 100).round()}%',
                                      titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    for (final g in pieList)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(iconOf(g.icon, 'expense'), size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                g.name,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatRp(g.total),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Arus Kas per Bulan',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 200, child: _monthBarChart(app)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Category? _catFor(AppState app, int id) {
    for (final c in app.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _monthBarChart(AppState app) {
    final now = DateTime.now();
    final byMonth = <int, ({int income, int expense})>{};
    for (var i = 0; i < 6; i++) {
      final d = DateTime(now.year, now.month - i);
      final key = d.year * 100 + d.month;
      byMonth[key] = (income: 0, expense: 0);
    }
    for (final t in app.transactions) {
      final d = DateTime.parse(t.date);
      final key = d.year * 100 + d.month;
      if (!byMonth.containsKey(key)) continue;
      final m = byMonth[key]!;
      if (t.type == 'income') {
        byMonth[key] = (income: m.income + t.amount, expense: m.expense);
      } else {
        byMonth[key] = (income: m.income, expense: m.expense + t.amount);
      }
    }
    final keys = byMonth.keys.toList()..sort();

    return BarChart(
      BarChartData(
        maxY: byMonth.values.fold<double>(0, (m, v) => v.expense > v.income ? v.expense.toDouble() : v.income.toDouble()) * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gi, rod, roi) {
              final v = rod.toY.round();
              return BarTooltipItem(
                formatRp(v),
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                final key = keys[v.toInt()];
                final d = DateTime(key ~/ 100, key % 100);
                const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(names[d.month - 1], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < keys.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: byMonth[keys[i]]!.expense.toDouble(),
                  color: AppColors.expense,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                BarChartRodData(
                  toY: byMonth[keys[i]]!.income.toDouble(),
                  color: AppColors.income,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}