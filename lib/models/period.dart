import 'package:intl/intl.dart';

/// İstatistik ekranındaki dönem seçenekleri.
enum PeriodType {
  today('Bugün'),
  week('Hafta'),
  month('Ay'),
  year('Yıl');

  const PeriodType(this.label);

  final String label;

  /// Dönem başlangıcı ve bitişi (bitiş hariç).
  PeriodRange rangeFor(DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case PeriodType.today:
        return PeriodRange(today, today.add(const Duration(days: 1)));
      case PeriodType.week:
        // Hafta pazartesi başlar.
        final DateTime monday = today.subtract(
          Duration(days: today.weekday - 1),
        );
        return PeriodRange(monday, monday.add(const Duration(days: 7)));
      case PeriodType.month:
        final DateTime first = DateTime(now.year, now.month);
        return PeriodRange(first, DateTime(now.year, now.month + 1));
      case PeriodType.year:
        final DateTime first = DateTime(now.year);
        return PeriodRange(first, DateTime(now.year + 1));
    }
  }

  /// Aynı uzunluktaki bir önceki dönem (takvime hizalı).
  PeriodRange previousRangeFor(DateTime now) {
    final PeriodRange current = rangeFor(now);
    switch (this) {
      case PeriodType.today:
        return PeriodRange(
          current.start.subtract(const Duration(days: 1)),
          current.start,
        );
      case PeriodType.week:
        return PeriodRange(
          current.start.subtract(const Duration(days: 7)),
          current.start,
        );
      case PeriodType.month:
        return PeriodRange(
          DateTime(current.start.year, current.start.month - 1),
          current.start,
        );
      case PeriodType.year:
        return PeriodRange(DateTime(current.start.year - 1), current.start);
    }
  }

  /// Grafikte gösterilecek kova sayısı.
  int bucketsIn(DateTime now) {
    switch (this) {
      case PeriodType.today:
        return 1;
      case PeriodType.week:
        return 7;
      case PeriodType.month:
        return DateUtilsX.daysInMonth(now.year, now.month);
      case PeriodType.year:
        return 12;
    }
  }
}

/// Yarım açık tarih aralığı: [start, end).
class PeriodRange {
  const PeriodRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  Duration get length => end.difference(start);

  int get dayCount => length.inHours ~/ 24;

  /// "1 - 7 Kasım 2026", "Kasım 2026", "2026" gibi başlık.
  String label(PeriodType type) {
    final DateTime lastDay = end.subtract(const Duration(days: 1));
    switch (type) {
      case PeriodType.today:
        return DateFormat('d MMMM y', 'tr_TR').format(start);
      case PeriodType.week:
        return '${DateFormat('d MMM', 'tr_TR').format(start)} - '
            '${DateFormat('d MMM y', 'tr_TR').format(lastDay)}';
      case PeriodType.month:
        return DateFormat('MMMM y', 'tr_TR').format(start);
      case PeriodType.year:
        return DateFormat('y', 'tr_TR').format(start);
    }
  }

  /// Karşılaştırma metni için kısa etiket ("geçen hafta", "geçen ay"...).
  String previousLabel(PeriodType type) {
    switch (type) {
      case PeriodType.today:
        return 'Düne göre';
      case PeriodType.week:
        return 'Geçen haftaya göre';
      case PeriodType.month:
        return 'Geçen aya göre';
      case PeriodType.year:
        return 'Geçen yıla göre';
    }
  }
}

/// Tarih yardımcıları (intl bağımlılığı olmadan).
class DateUtilsX {
  const DateUtilsX._();

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// İki tarihin aynı gün olup olmadığı.
  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dayStart(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
