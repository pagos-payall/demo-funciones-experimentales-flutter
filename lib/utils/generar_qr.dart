import 'dart:convert';

import 'package:flutter/services.dart';

class QrCodeService {
  static final QrCodeService _instance = QrCodeService._internal();
  factory QrCodeService() => _instance;
  QrCodeService._internal();

  // Canal de método
  static const _channel = MethodChannel('generacion_qr');

  String defaultDataQR = json.encode({
    "id": "V26040153",
    "name": "Pedro Perez",
    "phone": "584242038635",
    "bank": "0169",
    "amount": "10,00"
  });

  static const String merchantId = "0169";
  static const String defaultTotpKey = "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK";
  static const String defaultSecretKey = "12345678";

  // Método para parsear QR
/*   Future<String> parseQrCode() async {
    try {
      final String result = await _channel.invokeMethod('getParseQrCode', {
        'dataQR': defaultDataQR,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error al parsear QR: ${e.message}');
    }
  } */

  // Método para generar QR simple
  Future<String> generateQrCode() async {
    try {
      final String result = await _channel.invokeMethod('setParseQrCode', {
        'dataQR': defaultDataQR,
        'merchantId': merchantId,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error al generar QR: ${e.message}');
    }
  }

  // Método para generar QR con TOTP
/*   Future<String> generateQrCodeWithTotp() async {
    try {
      final String result = await _channel.invokeMethod('setParseQrCodeTotp', {
        'dataQR': defaultDataQR,
        'merchantId': merchantId,
        'totpKey': defaultTotpKey,
        'secretKey': defaultSecretKey,
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Error al generar QR con TOTP: ${e.message}');
    }
  } */
}
