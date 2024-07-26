import 'package:dio/dio.dart';
import 'package:flutter_application_pos_conectar/config.dart';
import 'package:flutter_application_pos_conectar/services/api/custom.dart';


class DioManager {
  static final Dio _dio = Dio(); // Instancia de Dio

  // Configuración de Dio con interceptores y opciones globales
  static Dio get dio {
    _dio.interceptors.add(CustomInterceptors());
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    // Otras configuraciones globales, como tiempo de espera, pueden agregarse aquí
    return _dio;
  }
}
