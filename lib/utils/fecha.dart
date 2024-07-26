import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';



fechaActual() {
  DateTime now = DateTime.now();
  DateTime dateTime =DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);
  return dateTime.toString();
}
