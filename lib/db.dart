import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart' as sembast;

import 'db_factory.dart';
import 'models.dart';

class FinDb {
  FinDb._(this.db);

  final sembast.Database db;

  static const _users = 'users';
  static const _wallets = 'wallets';
  static const _categories = 'categories';
  static const _transactions = 'transactions';
  static const _meta = 'meta';

  static Future<FinDb> open({sembast.DatabaseFactory? factory, String? path}) async {
    final f = factory ?? dbFactory;
    final p = path ?? await defaultPath();
    final db = await f.openDatabase(p);
    final fin = FinDb._(db);
    await fin._seedCategories();
    return fin;
  }

  static Future<String> defaultPath() async {
    if (kIsWeb) return 'fintrack.db';
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'fintrack.db');
  }

  sembast.StoreRef<int, Map<String, Object?>> _store(String name) =>
      sembast.intMapStoreFactory.store(name);

  sembast.StoreRef<String, Map<String, Object?>> _metaStore() =>
      sembast.stringMapStoreFactory.store(_meta);

  // ---------------------------------------------------------------- kategori

  Future<void> _seedCategories() async {
    if (await _store(_categories).count(db) > 0) return;
    const expense = [
      ('Makan', 'restaurant'),
      ('Transport', 'directions_car'),
      ('Tagihan', 'receipt'),
      ('Kesehatan', 'medical_services'),
      ('Pendidikan', 'school'),
      ('Hiburan', 'sports_esports'),
    ];
    const income = [
      ('Gaji', 'payments'),
      ('Jualan', 'storefront'),
      ('Iuran', 'groups'),
    ];
    for (final (name, icon) in expense) {
      await _store(_categories).add(db, Category(
            id: null,
            walletId: null,
            name: name,
            icon: icon,
            type: 'expense',
            isDefault: true,
          ).toMap());
    }
    for (final (name, icon) in income) {
      await _store(_categories).add(db, Category(
            id: null,
            walletId: null,
            name: name,
            icon: icon,
            type: 'income',
            isDefault: true,
          ).toMap());
    }
  }

  Future<List<Category>> categoriesForWallet(int walletId) async {
    final snaps = await _store(_categories).find(db, finder: sembast.Finder());
    final out = <Category>[];
    for (final s in snaps) {
      final c = Category.fromMap(s.key, Map<String, Object?>.from(s.value));
      if (c.walletId == null || c.walletId == walletId) out.add(c);
    }
    out.sort((a, b) {
      final t = a.type.compareTo(b.type);
      return t != 0 ? t : a.name.compareTo(b.name);
    });
    return out;
  }

  Future<int> addCategory({
    required int walletId,
    required String name,
    required String icon,
    required String type,
  }) {
    return _store(_categories).add(db, Category(
          id: null,
          walletId: walletId,
          name: name,
          icon: icon,
          type: type,
          isDefault: false,
        ).toMap());
  }

  // ------------------------------------------------------------------- auth

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt::$password')).toString();

  static String _newSalt() =>
      base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));

  Future<User?> findUserByEmail(String email) async {
    final snaps = await _store(_users).find(
      db,
      finder: sembast.Finder(filter: sembast.Filter.equals('email', email.trim().toLowerCase())),
    );
    if (snaps.isEmpty) return null;
    final s = snaps.first;
    return User.fromMap(s.key, Map<String, Object?>.from(s.value));
  }

  Future<User?> findUserByEmailForId(int id) async {
    final snap = await _store(_users).record(id).get(db);
    if (snap == null) return null;
    return User.fromMap(id, Map<String, Object?>.from(snap));
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final em = email.trim().toLowerCase();
    if (await findUserByEmail(em) != null) return 'Email sudah terdaftar';
    final salt = _newSalt();
    final id = await _store(_users).add(db, User(
          id: 0,
          name: name.trim(),
          email: em,
          salt: salt,
          hash: _hash(salt, password),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ).toMap());
    await _store(_wallets).add(db, Wallet(
          id: 0,
          name: 'Dompet Pribadi',
          ownerId: id,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ).toMap());
    return null;
  }

  Future<User?> login({required String email, required String password}) async {
    final u = await findUserByEmail(email);
    if (u == null) return null;
    if (_hash(u.salt, password) != u.hash) return null;
    return u;
  }

  // ---------------------------------------------------------------- dompet

  Future<List<Wallet>> walletsOf(int userId) async {
    final snaps = await _store(_wallets).find(
      db,
      finder: sembast.Finder(
        filter: sembast.Filter.equals('ownerId', userId),
        sortOrders: [sembast.SortOrder('createdAt')],
      ),
    );
    return snaps
        .map((s) => Wallet.fromMap(s.key, Map<String, Object?>.from(s.value)))
        .toList();
  }

  Future<Wallet> createWallet(String name, int ownerId) async {
    final trimmed = name.trim();
    final id = await _store(_wallets).add(db, Wallet(
          id: 0,
          name: trimmed,
          ownerId: ownerId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ).toMap());
    return Wallet(id: id, name: trimmed, ownerId: ownerId, createdAt: 0);
  }

  // ------------------------------------------------------------ transaksi

  Future<List<Transaction>> transactionsOf(int walletId) async {
    final snaps = await _store(_transactions).find(
      db,
      finder: sembast.Finder(
        filter: sembast.Filter.equals('walletId', walletId),
        sortOrders: [sembast.SortOrder('date', false), sembast.SortOrder('createdAt', false)],
      ),
    );
    return snaps
        .map((s) => Transaction.fromMap(s.key, Map<String, Object?>.from(s.value)))
        .toList();
  }

  Future<int> addTransaction({
    required int walletId,
    required int categoryId,
    required String type,
    required int amount,
    required String note,
    required String date,
  }) {
    return _store(_transactions).add(db, Transaction(
          id: 0,
          walletId: walletId,
          categoryId: categoryId,
          type: type,
          amount: amount,
          note: note,
          date: date,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ).toMap());
  }

  Future<void> updateTransaction(Transaction t) {
    return _store(_transactions).record(t.id).put(db, t.toMap());
  }

  Future<void> deleteTransaction(int id) {
    return _store(_transactions).record(id).delete(db);
  }

  // ------------------------------------------------------------ sesi

  Future<void> setSession({int? userId, int? walletId}) {
    return _metaStore().record('session').put(db, {
      'userId': userId,
      'walletId': walletId,
    });
  }

  Future<({int? userId, int? walletId})> getSession() async {
    final m = await _metaStore().record('session').get(db);
    final map = m == null ? <String, Object?>{} : Map<String, Object?>.from(m);
    return (
      userId: map['userId'] as int?,
      walletId: map['walletId'] as int?,
    );
  }

  // ------------------------------------------------------------ backup

  Future<String> exportJson() async {
    final out = <String, Object?>{
      'app': 'fintrack',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'store': <String, Object?>{
        for (final name in [_users, _wallets, _categories, _transactions])
          name: (await _store(name).find(db, finder: sembast.Finder()))
              .map((s) => {'key': s.key, ...s.value})
              .toList(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  Future<void> importJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Format backup tidak valid');
    final data = Map<String, Object?>.from(decoded);
    if (data['app'] != 'fintrack') throw const FormatException('Bukan file backup FinTrack');
    final storeData = Map<String, Object?>.from(data['store'] as Map);

    await db.transaction((txn) async {
      for (final name in [_users, _wallets, _categories, _transactions]) {
        final src = _store(name);
        for (final snap in await src.find(txn, finder: sembast.Finder())) {
          await snap.ref.delete(txn);
        }
        final records = storeData[name] as List;
        for (final rec in records) {
          final map = Map<String, Object?>.from(rec as Map);
          final key = map.remove('key') as int;
          await src.record(key).put(txn, map);
        }
      }
      await _metaStore().record('session').delete(txn);
    });
  }
}