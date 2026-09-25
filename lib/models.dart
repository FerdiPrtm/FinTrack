class User {
  final int id;
  final String name;
  final String email;
  final String salt;
  final String hash;
  final int createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.salt,
    required this.hash,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'email': email,
        'salt': salt,
        'hash': hash,
        'createdAt': createdAt,
      };

  factory User.fromMap(int id, Map<String, Object?> m) => User(
        id: id,
        name: m['name'] as String,
        email: m['email'] as String,
        salt: m['salt'] as String,
        hash: m['hash'] as String,
        createdAt: m['createdAt'] as int,
      );
}

class Wallet {
  final int id;
  final String name;
  final int ownerId;
  final int createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'name': name,
        'ownerId': ownerId,
        'createdAt': createdAt,
      };

  factory Wallet.fromMap(int id, Map<String, Object?> m) => Wallet(
        id: id,
        name: m['name'] as String,
        ownerId: m['ownerId'] as int,
        createdAt: m['createdAt'] as int,
      );
}

class Category {
  final int? id; // null = (hanya dari seed) tapi seed di-store, jadi selalu ada id
  final int? walletId; // null = kategori global default
  final String name;
  final String icon;
  final String type; // income | expense
  final bool isDefault;

  Category({
    required this.id,
    required this.walletId,
    required this.name,
    required this.icon,
    required this.type,
    required this.isDefault,
  });

  Map<String, Object?> toMap() => {
        'walletId': walletId,
        'name': name,
        'icon': icon,
        'type': type,
        'isDefault': isDefault,
      };

  factory Category.fromMap(int id, Map<String, Object?> m) => Category(
        id: id,
        walletId: m['walletId'] as int?,
        name: m['name'] as String,
        icon: m['icon'] as String,
        type: m['type'] as String,
        isDefault: m['isDefault'] as bool? ?? false,
      );
}

class Transaction {
  final int id;
  final int walletId;
  final int categoryId;
  final String type; // income | expense
  final int amount; // Rupiah utuh (tanpa desimal)
  final String note;
  final String date; // ISO yyyy-MM-dd
  final int createdAt;

  Transaction({
    required this.id,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'walletId': walletId,
        'categoryId': categoryId,
        'type': type,
        'amount': amount,
        'note': note,
        'date': date,
        'createdAt': createdAt,
      };

  factory Transaction.fromMap(int id, Map<String, Object?> m) => Transaction(
        id: id,
        walletId: m['walletId'] as int,
        categoryId: m['categoryId'] as int,
        type: m['type'] as String,
        amount: m['amount'] as int,
        note: m['note'] as String? ?? '',
        date: m['date'] as String,
        createdAt: m['createdAt'] as int,
      );
}