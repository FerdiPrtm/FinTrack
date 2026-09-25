import 'package:flutter/foundation.dart' hide Category;

import 'db.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static FinDb? _db;
  static FinDb get db => _db!;

  User? user;
  List<Wallet> wallets = [];
  int? walletId;
  List<Category> categories = [];
  List<Transaction> transactions = [];

  static Future<AppState> boot(FinDb fin) async {
    _db = fin;
    final s = await fin.getSession();
    if (s.userId != null) {
      final u = await fin.findUserByEmailForId(s.userId!);
      instance.user = u;
      if (u != null) {
        instance.wallets = await fin.walletsOf(u.id);
        final wid = s.walletId ?? (instance.wallets.isNotEmpty ? instance.wallets.first.id : null);
        if (wid != null) await instance.openWallet(wid);
      }
    }
    return instance;
  }

  Wallet? get wallet {
    for (final w in wallets) {
      if (w.id == walletId) return w;
    }
    return null;
  }

  Future<String?> register({required String name, required String email, required String password}) async {
    final err = await db.register(name: name, email: email, password: password);
    if (err != null) return err;
    await login(email: email, password: password);
    return null;
  }

  Future<bool> login({required String email, required String password}) async {
    final u = await db.login(email: email, password: password);
    if (u == null) return false;
    user = u;
    wallets = await db.walletsOf(u.id);
    await db.setSession(userId: u.id);
    final wid = wallets.isNotEmpty ? wallets.first.id : null;
    await openWallet(wid);
    return true;
  }

  Future<void> logout() async {
    user = null;
    wallets = [];
    walletId = null;
    categories = [];
    transactions = [];
    await db.setSession(userId: null, walletId: null);
    notifyListeners();
  }

  Future<void> openWallet(int? id) async {
    if (id == null) {
      walletId = null;
      categories = [];
      transactions = [];
      notifyListeners();
      return;
    }
    walletId = id;
    categories = await db.categoriesForWallet(id);
    transactions = await db.transactionsOf(id);
    await db.setSession(userId: user?.id, walletId: id);
    notifyListeners();
  }

  Future<void> createWallet(String name) async {
    if (user == null) return;
    final w = await db.createWallet(name, user!.id);
    wallets = await db.walletsOf(user!.id);
    await openWallet(w.id);
  }

  Future<void> refreshWallet() async {
    if (walletId == null) return;
    transactions = await db.transactionsOf(walletId!);
    notifyListeners();
  }

  Future<void> addTransaction({
    required int categoryId,
    required String type,
    required int amount,
    required String note,
    required String date,
  }) async {
    await db.addTransaction(
      walletId: walletId!,
      categoryId: categoryId,
      type: type,
      amount: amount,
      note: note,
      date: date,
    );
    await refreshWallet();
  }

  Future<void> updateTransaction(Transaction t) async {
    await db.updateTransaction(t);
    await refreshWallet();
  }

  Future<void> deleteTransaction(Transaction t) async {
    await db.deleteTransaction(t.id);
    await refreshWallet();
  }

  Future<int> addCategory({required String name, required String icon, required String type}) async {
    final id = await db.addCategory(walletId: walletId!, name: name, icon: icon, type: type);
    categories = await db.categoriesForWallet(walletId!);
    notifyListeners();
    return id;
  }

  // ------------------------------------------------------ agregasi (pemakaian UI)

  List<Transaction> get monthTransactions {
    final now = DateTime.now();
    return transactions.where((t) {
      final d = DateTime.parse(t.date);
      return d.year == now.year && d.month == now.month;
    }).toList();
  }

  int sumByType(List<Transaction> list, String type) =>
      list.where((t) => t.type == type).fold(0, (s, t) => s + t.amount);

  int get monthIncome => sumByType(monthTransactions, 'income');
  int get monthExpense => sumByType(monthTransactions, 'expense');
  int get totalBalance =>
      transactions.fold(0, (s, t) => s + (t.type == 'income' ? t.amount : -t.amount));
}