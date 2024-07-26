import 'package:dio/dio.dart';
import 'package:flutter_application_pos_conectar/config.dart';
import 'package:flutter_application_pos_conectar/dio_manager.dart';

Future actualizarStatusAnulacion(Map<String, dynamic> anulacionDatos) async {
  final Dio dio = DioManager.dio;
  final token = "xxxxxxxxxxxx";
  try {
    final response = await dio.post(
      "${AppConfig.apiBaseUrl}/actualizarAnulacion",
      data: anulacionDatos,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        responseType: ResponseType.json,
      ),
    );

    if (response.statusCode == 200 &&
        response.data['success'] == true &&
        response.data['codigo_respuesta'] == "00") {
      print("anulada por el usuario con exito");
    } else {
      print("problemas al registrar el estado de la anulacion ");
    }
  } catch (err) {
    return false;
  }
}
