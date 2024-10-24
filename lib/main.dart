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

void main() async {
   WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
    String base64 ="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";

    try {
      final Map<String, dynamic> params = {
        'data': json.encode({
          "id": "V26040153",
          "name": "Mariangel Perez",
          "phone": "584242038635",
          "bank": "0105"
        }),
        'merchantId': "0105",
        'totpKey': "KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK",
        'secretKey': "12345678",
        'timeout': 20,
        'config': json.encode({
          "title": "Mi Banco, Banco Microfinanciero, C.A.",
          "qr_size": "160",
          "image_size": "50",
          "font_size_title": "2",
          "font_size_text": "2",
          "background_color": "#8F8F8F",
          "progressbar_color": "#03AF7B",
          "back_button_color": "#03AF7B",
          "back_button_visibility": false,
          "base64_img": base64
        }),
        'digitsTotp': 8,
      };

      print("enviar parametros");
      final String result =
          await _qrGeneratorChannel.invokeMethod('generateQR', params);
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
            ElevatedButton(
              onPressed: () async {
                await generateQR();
              },
              child: const Text('Get QR'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
