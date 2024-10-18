import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_pos_conectar/services/api/transacciones.dart';
import 'package:flutter_application_pos_conectar/services/store/store.dart';
import 'package:flutter_application_pos_conectar/utils/fecha.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:libreria_flutter_payall/api/banks/banks.dart';
import 'package:libreria_flutter_payall/api/categories/categories.dart';
import 'package:libreria_flutter_payall/api/generalInformation/general_information.dart';
import 'package:libreria_flutter_payall/config/dio_client.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  DioClient.setUri("http://10.10.22.249:3005/api/v1");
  runApp(const MyApp());
}

Future<void> validarInternet() async {
  InternetConnection().onStatusChange.listen((InternetStatus status) async {
    switch (status) {
      case InternetStatus.connected:
        final validandoConexion = await Store.getValidacionInternet();
        if (validandoConexion.toString() == "sinInternet") {
          await Store.deleteValidacionInternet();
        }
        break;
      case InternetStatus.disconnected:
        await Store.setValidacionInternet("sinInternet");
        break;
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    validarInternet();
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
  String? autorizacion;
  String? pan;
  String? stan;
  String? merchantID;
  String? terminalID;
  String? recibo;
  String? lote;
  int? monto;
  String? cedula;
  dynamic dataPunto;
  String? qrImageBase64;

  @override
  void initState() {
    super.initState();
    _resultChannel.setMethodCallHandler((call) async {
      if (call.method == 'resultFromPointOfSale') {
        setState(() {
          dataPunto = call.arguments;
          autorizacion = call.arguments['autorizacion'];
          pan = call.arguments['pan'];
          stan = call.arguments['stan'];
          merchantID = call.arguments['merchantID'];
          terminalID = call.arguments['terminalID'];
          recibo = call.arguments['recibo'];
          lote = call.arguments['lote'];
          monto = call.arguments['monto'];
          cedula = call.arguments['cedula'];
        });
      }
    });
  }

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

  Future<void> generateQR() async {
    try {
      final Map<String, dynamic> params = {
        'data': json.encode({
          "id": "V17654345",
          "name": "Juan Diaz",
          "phone": "584247689898",
          "bank": "0102"
        }),
        'merchantId': "0102",
        'totpKey': "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
        'secretKey': "12345678",
        'timeout': 20,
        'config': json.encode({
          "title": "QR C2P S7B \n Generación de QR para pago C2P",
          "qr_size": "200",
          "image_size": "200",
          "font_size_title": "10",
          "font_size_text": "15",
          "background_color": "#8F8F8F",
          "progressbar_color": "#03AF7B",
          "back_button_color": "#03AF7B",
          "back_button_visibility": true,
          "base64_img": ""
        }),
        'digitsTotp': 8,
      };
      final String result =
          await _qrGeneratorChannel.invokeMethod('generateQR', params);
      setState(() {
        qrImageBase64 = result;
      });
    } on PlatformException catch (e) {
      print("Error al generar el código QR: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime currentDateTime = DateTime(
        now.year, now.month, now.day, now.hour, now.minute, now.second);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Aplicacion de prueba"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text("Invocar compra"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await openPointOfSale();
              },
              child: Text(currentDateTime.toString()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final exampleMethod = Categories();
                String token =
                    "Bearer eyJhbGciOiJIUzUxMiJ9.eyJqdGkiOiJwYXlhbGwiLCJzdWIiOiIwMDAwMDAwMDAwMDA0NzM3LmF1dG8iLCJwdiI6IjY2YmY0OGQ4ODM5NzFlMmE3YjhiNDU3OCIsInNlY3JldCI6IkxFRUpYbEBEMzNlT1Y2dmQkajcxSW9OZmNnI2tmY1lFIiwiYXV0aG9yaXRpZXMiOlsiUk9MRV9VU0VSIl0sImlhdCI6MTcyNTM2OTg0Nn0.kj6AcJi8INB98kqPTlPSZmkSZyhb5NuWBF3zknHdEgvrOpYciPekDmRmsxRic_Hv46gnToucACE5_0iBqhSJyQ";
                final getCategories =
                    await exampleMethod.getCategoriesFormat(token);
                print(getCategories.toString());
              },
              child: const Text('invocar getBanksC2p'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await generateQR();
              },
              child: const Text('Get QR'),
            ),
            const SizedBox(height: 16),
            if (qrImageBase64 != null)
              Image.memory(
                base64Decode(qrImageBase64!),
                width: 200,
                height: 200,
              ),
          ],
        ),
      ),
    );
  }
}
