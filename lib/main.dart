import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_pos_conectar/services/api/transacciones.dart';
import 'package:flutter_application_pos_conectar/services/store/store.dart';
import 'package:flutter_application_pos_conectar/utils/fecha.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

validarInternet() async {
  InternetConnection().onStatusChange.listen((InternetStatus status) async {
    switch (status) {
      case InternetStatus.connected:
        final validandoConexion = await Store.getValidacionInternet();
        if (validandoConexion.toString() == "sinInternet") {
          conexionFalla("Vuelve a tener conexión", Colors.green);
          await Store.deleteValidacionInternet();
        }
        break;
      case InternetStatus.disconnected:
        conexionFalla("Sin acceso a internet", Colors.red);
        await Store.setValidacionInternet("sinInternet");
        break;
    }
  });
}

conexionFalla(String texto, Color color) {
  _scaffoldKey.currentState?.showSnackBar(
    SnackBar(
      backgroundColor: color,
      duration: const Duration(seconds: 4),
      content: Text(texto, style: const TextStyle(fontWeight: FontWeight.w400)),
/*       action: SnackBarAction(
        label: 'Action',
        onPressed: () {
          // Code to execute.
        },
      ), */
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel _pointOfSaleChannel =
      MethodChannel('point_of_sale_opener');
  static const MethodChannel _resultChannel =
      MethodChannel('point_of_sale_result');
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

  @override
  void initState() {
    super.initState();
    _resultChannel.setMethodCallHandler((call) async {
      if (call.method == 'resultFromPointOfSale') {
        /* print(call.arguments);   */
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

/*   llamarResponseCode() async {
    final apiLibreriaPayall = ResponseCodes();
    final codigosDeRespuesta = await apiLibreriaPayall.getResponseCodes();
    print(codigosDeRespuesta.data);
  } */

  actualizarDataAnulacion(context) async {
    String fecha = fechaActual();
    final Map<String, dynamic> data = {
      'referencia': "XXXXX",
      'fecha': fecha,
    };
    await actualizarStatusAnulacion(data);
  }

  llamarPackagePos() async {}

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
              const Text("probar endpoint anulacion"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  //await openPointOfSale();
                  actualizarDataAnulacion(context);
                },
                child: Text(currentDateTime.toString()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  //llamarResponseCode();
                },
                child: const Text('peticion get a libreria codigo respuesta'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  //   llamarCategorias();
                },
                child: const Text('peticion pos a libreria categorias'),
              ),
/*               Text('Autorización: $autorizacion'),
              Text('PAN: $pan'),
              Text('STAN: $stan'),
              Text('Merchant ID: $merchantID'),
              Text('Terminal ID: $terminalID'),
              Text('Recibo: $recibo'),
              Text('Lote: $lote'),
              Text('Monto: $monto'),
              Text('Cédula: $cedula'),
              Text("aquii: $dataPunto.toString()") */
            ],
          ),
        ));
  }
}
