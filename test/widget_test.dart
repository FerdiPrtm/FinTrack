import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' hide Transaction;

import 'package:fintrack/db.dart';
import 'package:fintrack/models.dart';
import 'package:fintrack/report.dart';
import 'package:fintrack/theme.dart';
import 'package:fintrack/widgets.dart';

void main() {
  group('ThousandsInputFormatter', () {
    final f = ThousandsInputFormatter();

    TextEditingValue v(String text) => TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

    void expectFormat(String input, String expected) {
      final out = f.formatEditUpdate(v(''), v(input));
      expect(out.text, expected, reason: 'input "$input"');
    }

    test('sisipan titik ribuan saat mengetik', () {
      expectFormat('5', '5');
      expectFormat('50', '50');
      expectFormat('500', '500');
      expectFormat('5000', '5.000');
      expectFormat('50000', '50.000');
      expectFormat('500000', '500.000');
      expectFormat('5000000', '5.000.000');
    });

    test('hapus karakter menyisakan format yang benar', () {
      expectFormat('50.00', '5.000');
    });
  });

  test('formatThousands & formatRp', () {
    expect(formatThousands(5000000), '5.000.000');
    expect(formatThousands(999), '999');
    expect(formatRp(-50000), '-Rp 50.000');
  });

  testWidgets('BalanceCard menampilkan label periode & peringatan saat saldo negatif', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BalanceCard(balance: -5000, income: 0, expense: 5000)),
    ));
    expect(find.text('Masuk (bulan ini)'), findsOneWidget);
    expect(find.text('Keluar (bulan ini)'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('ikon mata menyembunyikan lalu menampilkan saldo', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BalanceCard(balance: 1500000, income: 1200000, expense: 300000)),
    ));
    expect(find.text('Rp 1.500.000'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.text('Rp •••••'), findsOneWidget);
    expect(find.text('Rp 1.500.000'), findsNothing);
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();
    expect(find.text('Rp 1.500.000'), findsOneWidget);
  });

  test('laporan CSV berisi ringkasan + baris transaksi', () async {
    final tx = [
      Transaction(id: 1, walletId: 1, categoryId: 1, amount: 50000, type: 'expense', note: 'Makan, siang', date: '2026-09-25', createdAt: 0),
      Transaction(id: 2, walletId: 1, categoryId: 2, amount: 2000000, type: 'income', note: 'Gaji', date: '2026-09-01', createdAt: 0),
    ];
    final cats = [
      Category(id: 1, walletId: 1, name: 'Makan', icon: 'restaurant', type: 'expense', isDefault: true),
      Category(id: 2, walletId: 1, name: 'Gaji', icon: 'payments', type: 'income', isDefault: true),
    ];
    final csv = csvReport(walletName: 'Pribadi', transactions: tx, categories: cats);
    expect(csv, contains('Total Masuk,2000000'));
    expect(csv, contains('Total Keluar,50000'));
    expect(csv, contains('Saldo,1950000'));
    expect(csv, contains('2026-09-01,Masuk,Gaji,2000000,Gaji'));
    expect(csv, contains('"Makan, siang"'));
    final pdf = await pdfReport(walletName: 'Pribadi', transactions: tx, categories: cats);
    expect(pdf, isNotEmpty);
    expect(pdf.length, greaterThan(1000));
  });

  test('filterTransactions memfilter rentang tanggal', () {
    final tx = [
      Transaction(id: 1, walletId: 1, categoryId: 1, amount: 1000, type: 'expense', note: '', date: '2026-08-31', createdAt: 0),
      Transaction(id: 2, walletId: 1, categoryId: 1, amount: 1000, type: 'expense', note: '', date: '2026-09-01', createdAt: 0),
      Transaction(id: 3, walletId: 1, categoryId: 1, amount: 1000, type: 'expense', note: '', date: '2026-09-30', createdAt: 0),
      Transaction(id: 4, walletId: 1, categoryId: 1, amount: 1000, type: 'expense', note: '', date: '2026-10-01', createdAt: 0),
    ];
    final out = filterTransactions(tx,
        from: DateTime(2026, 9, 1), to: DateTime(2026, 9, 30, 23, 59, 59));
    expect(out.map((t) => t.id).toList(), [2, 3]);
  });

  late FinDb db;

  setUp(() async {
    db = await FinDb.open(
      factory: databaseFactoryMemory,
      path: 'test-${DateTime.now().microsecondsSinceEpoch}.db',
    );
  });

  tearDown(() => db.db.close());

  final date = DateTime.now().toIso8601String().substring(0, 10);

  Future<int> addExpense(FinDb d, int walletId, String cat) async {
    final cats = await d.categoriesForWallet(walletId);
    final c = cats.firstWhere((c) => c.type == 'expense' && c.name == cat);
    return d.addTransaction(
      walletId: walletId,
      categoryId: c.id!,
      type: 'expense',
      amount: 50000,
      note: 'n',
      date: date,
    );
  }

  test('register -> walet otomatis -> login kembali berhasil', () async {
    expect(await db.register(name: 'Andi', email: 'A@x.com', password: 'rahasia123'), isNull);
    expect(await db.register(name: 'Andi', email: 'a@x.com', password: 'rahasia123'), isNotNull,
        reason: 'email duplikat harus ditolak (case-insensitive)');

    final u = await db.login(email: 'a@x.com', password: 'rahasia123');
    expect(u, isNotNull);
    expect(await db.login(email: 'a@x.com', password: 'salah'), isNull);

    final wallets = await db.walletsOf(u!.id);
    expect(wallets, hasLength(1), reason: 'wallet pribadi auto-dibuat saat register');
  });

  test('saldo & jumlah masuk/keluar dihitung benar (money ok)', () async {
    await db.register(name: 'Andi', email: 'a@x.com', password: 'rahasia123');
    final u = await db.login(email: 'a@x.com', password: 'rahasia123');
    final w = (await db.walletsOf(u!.id)).first;

    final cats = await db.categoriesForWallet(w.id);
    final gaji = cats.firstWhere((c) => c.type == 'income' && c.name == 'Gaji');
    await db.addTransaction(
      walletId: w.id,
      categoryId: gaji.id!,
      type: 'income',
      amount: 1000000,
      note: '',
      date: date,
    );
    final tid2 = await addExpense(db, w.id, 'Makan');
    await addExpense(db, w.id, 'Makan');
    await addExpense(db, w.id, 'Transport');

    final txs = await db.transactionsOf(w.id);
    int income = 0, expense = 0;
    for (final t in txs) {
      if (t.type == 'income') {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    expect(income, 1000000);
    expect(expense, 150000);
    expect(txs, hasLength(4));

    await db.updateTransaction(Transaction(
      id: tid2,
      walletId: w.id,
      categoryId: gaji.id!,
      type: 'income',
      amount: 999,
      note: 'ubah',
      date: date,
      createdAt: 0,
    ));
    final changed = await db.transactionsOf(w.id);
    expect(changed.firstWhere((t) => t.id == tid2).amount, 999);
    expect(changed.firstWhere((t) => t.id == tid2).type, 'income');
  });

  test('backup json -> restore -> data identik', () async {
    await db.register(name: 'Andi', email: 'a@x.com', password: 'rahasia123');
    final u = await db.login(email: 'a@x.com', password: 'rahasia123');
    final w = (await db.walletsOf(u!.id)).first;
    await addExpense(db, w.id, 'Makan');

    final json = await db.exportJson();
    expect(json, contains('fintrack'));
    expect(json, contains('Makan'));

    final db2 = await FinDb.open(factory: databaseFactoryMemory, path: 'test2.db');
    await db2.importJson(json);

    final restored = await db2.transactionsOf(w.id);
    expect(restored, hasLength(1));
    expect(restored.first.amount, 50000);
    expect((await db2.categoriesForWallet(w.id)).length, 9, reason: 'kategori default ikut ter-restore');
  });
}