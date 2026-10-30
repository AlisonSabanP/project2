import 'package:intl/intl.dart';

/// Shared display formatting. Kept in one place so every screen renders money
/// and dates identically.
abstract final class Formatters {
  static final NumberFormat _money = NumberFormat.currency(
    locale: 'es',
    symbol: r'$',
    decimalDigits: 2,
  );

  static final NumberFormat _decimal = NumberFormat('#,##0.00', 'es');

  static final DateFormat _date = DateFormat('dd/MM/yyyy', 'es');

  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'es');

  static final DateFormat _fileStamp = DateFormat('yyyyMMdd-HHmmss');

  static String money(num value) => _money.format(value);

  static String decimal(num value) => _decimal.format(value);

  static String date(DateTime value) => _date.format(value);

  static String dateTime(DateTime value) => _dateTime.format(value);

  static String fileStamp(DateTime value) => _fileStamp.format(value);
}
