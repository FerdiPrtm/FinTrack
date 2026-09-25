import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../report.dart';
import '../theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final u = app.user;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(u?.name.characters.first.toUpperCase() ?? '?',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                title: Text(u?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(u?.email ?? '-', style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.table_chart, color: AppColors.primary),
                    title: const Text('Ekspor Laporan CSV'),
                    subtitle: const Text('Semua transaksi dompet aktif'),
                    onTap: () => _exportReport(context, 'csv'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                    title: const Text('Ekspor Laporan PDF'),
                    subtitle: const Text('Semua transaksi dompet aktif'),
                    onTap: () => _exportReport(context, 'pdf'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Data', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download, color: AppColors.primary),
                    title: const Text('Ekspor Backup (JSON)'),
                    subtitle: const Text('Simpan salinan seluruh data'),
                    onTap: () => _export(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.upload, color: AppColors.primary),
                    title: const Text('Restore dari Backup'),
                    subtitle: const Text('Tempel data JSON backup'),
                    onTap: () => _restore(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.expense),
                title: const Text('Keluar', style: TextStyle(color: AppColors.expense)),
                onTap: () async {
                  await app.logout();
                },
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'FinTrack MVP · data lokal\nv1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportReport(BuildContext context, String format) async {
    final app = AppState.instance;
    int mode = 0;
    DateTimeRange? range;
    const options = ['Semua transaksi', 'Bulan ini', '6 Bulan terakhir', 'Tanggal khusus'];

    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Ekspor Laporan ${format.toUpperCase()}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < options.length; i++)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(options[i], style: const TextStyle(fontSize: 14)),
                  trailing: mode == i
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : const Icon(Icons.circle_outlined, size: 20, color: AppColors.border),
                  onTap: () => setState(() => mode = i),
                ),
              if (mode == 3) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    range == null
                        ? 'Pilih rentang tanggal'
                        : '${range!.start.toString().substring(0, 10)} s.d. ${range!.end.toString().substring(0, 10)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () async {
                    final p = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: range,
                    );
                    if (p != null) setState(() => range = p);
                  },
                ),
                if (range == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Pilih rentang tanggal dulu',
                      style: TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: mode == 3 && range == null ? null : () => Navigator.pop(ctx, mode),
              child: const Text('Ekspor'),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;

    final now = DateTime.now();
    DateTime? from;
    DateTime? to;
    switch (chosen) {
      case 1: // bulan ini
        from = DateTime(now.year, now.month, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 2: // 6 bulan terakhir
        from = DateTime(now.year, now.month - 5, 1);
        to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 3: // rentang khusus
        final r = range!;
        from = DateTime(r.start.year, r.start.month, r.start.day);
        to = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59);
        break;
    }
    final tx = filterTransactions(app.transactions, from: from, to: to);
    final periodLabel = options[chosen];
    final bytes = format == 'csv'
        ? Uint8List.fromList(utf8.encode(csvReport(
            walletName: app.wallet?.name ?? 'Dompet',
            transactions: tx,
            categories: app.categories,
            periodLabel: periodLabel,
          )))
        : await pdfReport(
            walletName: app.wallet?.name ?? 'Dompet',
            transactions: tx,
            categories: app.categories,
            periodLabel: periodLabel,
          );
    final name = 'fintrack-${_safeFileName(app.wallet?.name ?? 'dompet')}';
    try {
      await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
        fileExtension: format,
        mimeType: format == 'csv' ? MimeType.csv : MimeType.pdf,
      );
      if (!context.mounted) return;
      final hint = kIsWeb
          ? 'Laporan berhasil diekspor — cek folder Unduhan browser'
          : defaultTargetPlatform == TargetPlatform.android
              ? 'Laporan berhasil diekspor — pilih lokasi & cek folder Downloads'
              : 'Laporan berhasil diekspor';
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(hint)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Gagal mengekspor: $e')));
    }
  }

  String _safeFileName(String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-').toLowerCase();

  Future<void> _export(BuildContext context) async {
    final json = await AppState.db.exportJson();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup JSON'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Salin teks di bawah, simpan di tempat aman.', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(content: Text('JSON disalin ke clipboard')));
              }
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Salin JSON'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore dari Backup'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          decoration: const InputDecoration(
            hintText: 'Tempel isi JSON backup di sini',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final text = controller.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppState.db.importJson(text);
      await AppState.instance.logout();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Backup dipulihkan. Silakan masuk kembali.')));
    } catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Restore gagal: $e')));
    }
  }
}