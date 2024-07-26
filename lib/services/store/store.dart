import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static Future<void> setValidacionInternet(String internet) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("conexion", internet);
  }

  static Future<void> deleteValidacionInternet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("conexion");
  }

  static Future<String?> getValidacionInternet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("conexion");
  }
}
