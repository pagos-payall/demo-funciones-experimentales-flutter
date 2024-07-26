class AppConfig {
//esta es la protegida por VPN
/* static const String apiBaseUrl = "http://172.20.254.216:8090/api/v1"; */
/* static const String apiBaseUrl = "http://207.210.121.11:8090/api/v1"; */
static const String versionApp = "V-1.0.0-Beta-01";
static const String apiBaseUrl = "http://10.10.22.249:3005/api/v1";

  static Map<String, String> headersAuth = {
    'Content-Type': 'application/json',
    'Authorization': "",
  };

  static Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': "",
  };
}
