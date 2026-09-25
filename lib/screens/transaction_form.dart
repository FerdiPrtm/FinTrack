import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? existing;

  const TransactionForm({super.key, this.existing});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late String _type;
  late int _categoryId;
  late TextEditingController _amount;
  late TextEditingController _note;
  late String _date;

  @override
  void initState() {
    super.initState();
    _type = widget.existing?.type ?? 'expense';
    _categoryId = widget.existing?.categoryId ?? 0;
    _amount = TextEditingController(
      text: widget.existing == null ? '' : formatThousands(widget.existing!.amount),
    );
    _note = TextEditingController(text: widget.existing?.note ?? '');
    _date = widget.existing?.date ?? todayIso();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Category> _cats() {
    return AppState.instance.categories.where((c) => c.type == _type).toList();
  }

  int _pickCategory() {
    final list = _cats();
    for (final c in list) {
      if (c.id == _categoryId) return c.id!;
    }
    return list.isNotEmpty ? list.first.id! : 0;
  }

  Future<void> _pickDate() async {
    final d = DateTime.parse(_date);
    final picked = await showDatePicker(
      context: context,
      initialDate: d,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    final app = AppState.instance;
    final amount = int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      _snack('Nominal tidak valid');
      return;
    }
    final catId = _pickCategory();
    if (catId == 0) {
      _snack('Tambahkan kategori dulu');
      return;
    }
    final note = _note.text.trim();
    final tx = widget.existing;
    if (tx == null) {
      await app.addTransaction(
        categoryId: catId,
        type: _type,
        amount: amount,
        note: note,
        date: _date,
      );
    } else {
      await app.updateTransaction(Transaction(
        id: tx.id,
        walletId: tx.walletId,
        categoryId: catId,
        type: _type,
        amount: amount,
        note: note,
        date: _date,
        createdAt: tx.createdAt,
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addCategory() async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Kategori Baru'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nama kategori'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    final id = await AppState.instance.addCategory(name: name, icon: 'tag', type: _type);
    if (mounted) setState(() => _categoryId = id);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    final edit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(edit ? 'Edit Transaksi' : 'Tambah Transaksi')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final cats = _cats();
          final catId = _pickCategory();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Keluar'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: 'income', label: Text('Masuk'), icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _categoryId = 0;
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Nominal (Rp)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey(catId),
                initialValue: catId == 0 ? null : catId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final c in cats)
                    DropdownMenuItem(
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
                onChanged: (v) => setState(() => _categoryId = v ?? 0),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Buat kategori baru'),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _note,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text('Tanggal: ${formatDate(_date)}'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                child: Text(edit ? 'Simpan Perubahan' : 'Simpan Transaksi'),
              ),
            ],
          );
        },
      ),
    );
  }
}