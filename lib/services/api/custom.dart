// ignore_for_file: avoid_print

import 'package:dio/dio.dart';

class CustomInterceptors extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    //print('REQUEST[${options.method}] => PATH: ${options.path}');
    //print('REQUEST DATA: ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    //print('RESPUESTA POSITIVA[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    //print('Response REQUEST DATA: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  Future onError(err, ErrorInterceptorHandler handler) async {
    //print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    super.onError(err, handler);
  }
}
