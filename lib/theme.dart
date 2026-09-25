import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0F766E);
  static const income = Color(0xFF16A34A);
  static const expense = Color(0xFFDC2626);
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const amber = Color(0xFFF59E0B);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
  return base;
}

String formatThousands(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatRp(int amount) {
  final neg = amount < 0;
  return '${neg ? '-' : ''}Rp ${formatThousands(amount)}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatDate(String iso) {
  final d = DateTime.parse(iso);
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

String monthLabel(DateTime d) => '${_months[d.month - 1]} ${d.year}';

String todayIso() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return const TextEditingValue();
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = formatThousands(int.parse(digits));
    final digitsBeforeCaret = text
        .substring(0, newValue.selection.extentOffset.clamp(0, text.length))
        .replaceAll(RegExp(r'[^0-9]'), '')
        .length;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: _digitToCaret(formatted, digitsBeforeCaret)),
    );
  }

  int _digitToCaret(String s, int digitIndex) {
    if (digitIndex <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < s.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(s[i])) seen++;
      if (seen == digitIndex) return i + 1;
    }
    return s.length;
  }
}

const _catIconMap = <String, IconData>{
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'receipt': Icons.receipt_long,
  'medical_services': Icons.medical_services,
  'school': Icons.school,
  'sports_esports': Icons.sports_esports,
  'payments': Icons.payments,
  'storefront': Icons.storefront,
  'groups': Icons.groups,
  'tag': Icons.tag,
  // kunci lama (emoji) dari data sebelum revamp
  '🍔': Icons.restaurant,
  '🚗': Icons.directions_car,
  '🧾': Icons.receipt_long,
  '🏥': Icons.medical_services,
  '📚': Icons.school,
  '🎮': Icons.sports_esports,
  '💼': Icons.payments,
  '🏪': Icons.storefront,
  '🤝': Icons.groups,
  '✨': Icons.tag,
};

IconData iconOf(String? iconKey, String type) =>
    _catIconMap[iconKey] ?? (type == 'income' ? Icons.trending_up : Icons.category);