import 'package:intl/intl.dart';

double convertstringtodouble(String string) {
  double? amount = double.tryParse(string);
  return amount ?? 0;
}

String formatamount(double amount) {
  final format =
      NumberFormat.currency(locale: "en_IN", symbol: "₹", decimalDigits: 2);
  return format.format(amount);
}

String getCurrentMonthName() {
  DateTime now = DateTime.now();
  List<String> months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ];
  return months[now.month - 1];
}
