import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_pos_conectar/services/api/transacciones.dart';
import 'package:flutter_application_pos_conectar/services/store/store.dart';
import 'package:flutter_application_pos_conectar/utils/fecha.dart';
import 'package:flutter_application_pos_conectar/utils/generar_qr.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:libreria_flutter_payall/api/banks/banks.dart';
import 'package:libreria_flutter_payall/api/categories/categories.dart';
import 'package:libreria_flutter_payall/api/generalInformation/general_information.dart';
import 'package:libreria_flutter_payall/config/dio_client.dart';
import 'package:qr_flutter/qr_flutter.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
/*   await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  DioClient.setUri("http://10.10.22.249:3005/api/v1"); */
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldKey,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel _pointOfSaleChannel =
      MethodChannel('point_of_sale_opener');
  static const MethodChannel _resultChannel =
      MethodChannel('point_of_sale_result');
  static const MethodChannel _qrGeneratorChannel = MethodChannel('generadorQR');

  String? qrData;

  @override
  void initState() {
    super.initState();
  }

  final qrService = QrCodeService();

  // Función parseo de QR
/*   void handleParseQr() async {
    try {
      String result = await qrService.parseQrCode();
      print('QR parseado: $result');
      setState(() {
        qrData = result;
      });
    } catch (e) {
      print('Error: $e');
    }
  } */

  // Función  QR
  void handleGenerateQr() async {
    try {
      String result = await qrService.generateQrCode();
      print('QR generado: $result');

      setState(() {
        qrData = result;
      });
    } catch (e) {
      print('Error: $e');
      // Manejo de errores
    }
  }

  // Función QR con TOTP
/*   void handleGenerateQrWithTotp() async {
    try {
      String result = await qrService.generateQrCodeWithTotp();
      print('QR con TOTP generado: $result');
      // Aquí puedes manejar el resultado como necesites
      setState(() {
        qrData = result;
      });
    } catch (e) {
      print('Error: $e');
      // Manejo de errores
    }
  } */

  Future<void> openPointOfSale() async {
    try {
      final Map<String, dynamic> params = {
        'operation': 'VENTA',
        'monto': 243667,
        'isAmountEditable': false,
        'rapidAfilid': '123456',
        'cedula': '23635723'
      };
      await _pointOfSaleChannel.invokeMethod('openPointOfSale', params);
    } on PlatformException catch (e) {
      print("Error al abrir la aplicación de punto de venta: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Aplicacion de experimentos"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text("Pruebas QR Demo s7b"),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
/*             ElevatedButton(
              onPressed: handleParseQr,
              child: const Text('Parsear QR'),
            ), */
            ElevatedButton(
              onPressed: handleGenerateQr,
              child: const Text('Generar QR'),
            ),
/*             ElevatedButton(
              onPressed: handleGenerateQrWithTotp,
              child: const Text('Generar QR con TOTP'),
            ), */
            const SizedBox(height: 16),
            if (qrData != null)
              QrImageView(
                data: qrData!,
                size: 200,
              )
            else
              Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Text('No hay QR generado'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
