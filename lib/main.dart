import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_pos_conectar/utils/generar_qr.dart';
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
  // Canales para las operaciones del POS
  static const MethodChannel _abrirPosChannel =
      MethodChannel('conectar_abrir_pos');
  static const MethodChannel _anulacionChannel =
      MethodChannel('anulacion_pos');
  static const MethodChannel _cierreChannel =
      MethodChannel('cierre_pos');
  static const MethodChannel _resumenLoteChannel =
      MethodChannel('resumen_lote_pos');
  static const MethodChannel _ultimoReciboChannel =
      MethodChannel('ultimo_recibo_pos');
  
  // Canales para recibir los resultados
  static const MethodChannel _resultadoPosChannel =
      MethodChannel('resultado_pos');
  static const MethodChannel _resultadoAnulacionChannel =
      MethodChannel('resultado_anulacion_pos');
  static const MethodChannel _resultadoCierreChannel =
      MethodChannel('resultado_cierre_pos');
  static const MethodChannel _resultadoResumenLoteChannel =
      MethodChannel('resultado_resumen_lote_pos');
  static const MethodChannel _resultadoUltimoReciboChannel =
      MethodChannel('resultado_ultimo_recibo_pos');
  
  // Canal para generación de QR
  static const MethodChannel _parseQrChannel = MethodChannel('generacion_qr');

  String? qrData;
  
  // Almacena el resultado de la última venta exitosa
  Map<String, dynamic>? ultimaVentaExitosa;
  
  // Indicador de si hay una venta disponible para anular
  bool hayVentaParaAnular = false;

  @override
  void initState() {
    super.initState();
    print("Inicializando Estado de la Aplicación");
    // Configurar los listeners para recibir los resultados
    _configureResultChannels();
  }

  void _configureResultChannels() {
    print("Configurando canales de resultado");
    _resultadoPosChannel.setMethodCallHandler((call) {
      print("Canal resultado_pos recibió llamada: ${call.method}");
      return _handlePosResult(call);
    });
    
    _resultadoAnulacionChannel.setMethodCallHandler((call) {
      print("Canal resultado_anulacion_pos recibió llamada: ${call.method}");
      return _handleAnulacionResult(call);
    });
    
    _resultadoCierreChannel.setMethodCallHandler((call) {
      print("Canal resultado_cierre_pos recibió llamada: ${call.method}");
      return _handleCierreResult(call);
    });
    
    _resultadoResumenLoteChannel.setMethodCallHandler((call) {
      print("Canal resultado_resumen_lote_pos recibió llamada: ${call.method}");
      return _handleResumenLoteResult(call);
    });
    
    _resultadoUltimoReciboChannel.setMethodCallHandler((call) {
      print("Canal resultado_ultimo_recibo_pos recibió llamada: ${call.method}");
      return _handleUltimoReciboResult(call);
    });
  }

  // Manejadores de resultados
  Future<dynamic> _handlePosResult(MethodCall call) async {
    print("Manejando resultado POS: ${call.method}");
    print("Argumentos recibidos: ${call.arguments}");
    
    if (call.method == 'resultadoTransaccionPos') {
      final Map<String, dynamic> result = Map<String, dynamic>.from(call.arguments);
      
      print("Resultado completo de la venta: $result");
      
      // Verificamos si la transacción fue exitosa para guardarla
      // Podemos tener diferentes criterios de éxito dependiendo de la respuesta
      if (result.containsKey('autorizacion') && 
          result['autorizacion'] != null && 
          result['autorizacion'].toString().isNotEmpty &&
          result['autorizacion'] != "null" &&
          result['autorizacion'] != "DECLINADA") {
        
        print("Venta exitosa encontrada, guardando datos para anulación");
        setState(() {
          ultimaVentaExitosa = Map<String, dynamic>.from(result);
          hayVentaParaAnular = true;
        });
        
        print('Datos guardados para anulación: $ultimaVentaExitosa');
        print('Estado de hayVentaParaAnular: $hayVentaParaAnular');
      } else {
        print("La venta no fue exitosa o no tiene código de autorización válido");
      }
      
      _showResultDialog('Resultado de Venta', result);
    }
    return null;
  }

  Future<dynamic> _handleAnulacionResult(MethodCall call) async {
    print("Manejando resultado anulación: ${call.method}");
    print("Argumentos recibidos: ${call.arguments}");
    
    if (call.method == 'resultadoAnulacionPos') {
      final Map<String, dynamic> result = Map<String, dynamic>.from(call.arguments);
      
      // Si la anulación fue exitosa, ya no tenemos una venta para anular
      if (result['status'] == 'Anulacion Ok' || result['response_code'] == '00') {
        print("Anulación exitosa, limpiando datos de venta");
        setState(() {
          hayVentaParaAnular = false;
          ultimaVentaExitosa = null;
        });
      }
      
      _showResultDialog('Resultado de Anulación', result);
    }
    return null;
  }

  Future<dynamic> _handleCierreResult(MethodCall call) async {
    print("Manejando resultado cierre: ${call.method}");
    print("Argumentos recibidos: ${call.arguments}");
    
    if (call.method == 'resultadoCierrePos') {
      final Map<String, dynamic> result = Map<String, dynamic>.from(call.arguments);
      
      // Después de un cierre exitoso, ya no hay ventas para anular
      if (result['status'] == 'cierreSuccess' || result['response_code'] == '00') {
        print("Cierre exitoso, limpiando datos de venta");
        setState(() {
          hayVentaParaAnular = false;
          ultimaVentaExitosa = null;
        });
      }
      
      _showResultDialog('Resultado de Cierre', result);
    }
    return null;
  }

  Future<dynamic> _handleResumenLoteResult(MethodCall call) async {
    print("Manejando resultado resumen lote: ${call.method}");
    
    if (call.method == 'resultadoResumenLotePos') {
      final Map<String, dynamic> result = Map<String, dynamic>.from(call.arguments);
      _showResultDialog('Resultado de Resumen de Lote', result);
    }
    return null;
  }

  Future<dynamic> _handleUltimoReciboResult(MethodCall call) async {
    print("Manejando resultado último recibo: ${call.method}");
    
    if (call.method == 'resultadoUltimoReciboPos') {
      final Map<String, dynamic> result = Map<String, dynamic>.from(call.arguments);
      _showResultDialog('Resultado de Último Recibo', result);
    }
    return null;
  }

  // Función para mostrar el resultado en un diálogo
  void _showResultDialog(String title, Map<String, dynamic> result) {
    print("Mostrando diálogo de resultado: $title");
    print("Datos a mostrar: $result");
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  JsonEncoder.withIndent('  ').convert(result),
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  final qrService = QrCodeService();

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

  // Función para generar QR C2P
  Future<void> handleGenerateC2PQr() async {
    try {
      // Datos de ejemplo para la generación del QR
      final Map<String, dynamic> params = {
        'dataQR': 'PAGOMOVIL12345ABCDE', // Datos codificados para el QR
        'merchantId': '123456789' // ID del comerciante
      };
      
      final String result = await _parseQrChannel.invokeMethod('setParseQrCode', params);
      print('QR C2P generado: $result');
      
      setState(() {
        qrData = result;
      });
    } catch (e) {
      print('Error al generar QR C2P: $e');
      // Manejo de errores
    }
  }

  // Función para abrir el POS y procesar un pago
  Future<void> realizarVenta() async {
    try {
      print("Iniciando venta...");
      final Map<String, dynamic> params = {
        'operation': 'VENTA',
        'monto': 243667, // Monto en centavos (2436.67)
        'isAmountEditable': false,
        'rapidAfilid': '123456',
        'cedula': '23635723',
        'tarjetasAceptadas': 'todas' // Puede ser 'todas', 'soloCredito' o 'soloDebito'
      };
      
      print("Parámetros de venta: $params");
      await _abrirPosChannel.invokeMethod('abrirAppRapidPago', params);
      print("Solicitud de venta enviada correctamente");
    } catch (e) {
      print('Error al abrir la aplicación de POS para venta: $e');
      _showErrorSnackBar('Error al iniciar venta: $e');
    }
  }

  // Función para anular una transacción usando los datos de la última venta
  Future<void> realizarAnulacion() async {
    print("Intentando realizar anulación...");
    print("Estado de hayVentaParaAnular: $hayVentaParaAnular");
    print("Datos almacenados para anulación: $ultimaVentaExitosa");
    
    // Verificar si hay una venta previa para anular
    if (!hayVentaParaAnular || ultimaVentaExitosa == null) {
      print("No hay venta válida para anular");
      _showErrorSnackBar('No hay una venta para anular. Realice una venta primero.');
      return;
    }
    
    try {
      // Obtenemos los datos de la última venta exitosa
      final String? pan = ultimaVentaExitosa!['pan'] as String?;
      final String? autorizacion = ultimaVentaExitosa!['autorizacion'] as String?;
      final dynamic monto = ultimaVentaExitosa!['monto']; // Puede ser int o long
      final String? cedula = ultimaVentaExitosa!['cedula'] as String?;
      
      print("PAN extraído: $pan");
      print("Autorización extraída: $autorizacion");
      print("Monto extraído: $monto (tipo: ${monto.runtimeType})");
      print("Cédula extraída: $cedula");
      
      // Validamos que tengamos todos los datos necesarios
      List<String> datosFaltantes = [];
      if (pan == null || pan.isEmpty || pan == "null" || pan == "DECLINADA") datosFaltantes.add('PAN');
      if (autorizacion == null || autorizacion.isEmpty || autorizacion == "null") datosFaltantes.add('código de autorización');
      if (monto == null) datosFaltantes.add('monto');
      
      if (datosFaltantes.isNotEmpty) {
        print("Datos insuficientes para anular: faltan ${datosFaltantes.join(', ')}");
        _showErrorSnackBar('Datos insuficientes para anular la venta. Faltan: ${datosFaltantes.join(', ')}');
        return;
      }
      
      // Convertimos el monto a entero si es necesario
      int montoEntero;
      if (monto is int) {
        montoEntero = monto;
      } else if (monto is double) {
        montoEntero = monto.toInt();
      } else {
        montoEntero = int.tryParse(monto.toString()) ?? 0;
      }
      
      print("Monto convertido para anulación: $montoEntero");
      
      final Map<String, dynamic> params = {
        'operation': 'ANULACION',
        'monto': montoEntero,
        'pan': pan,
        'autorizacion': autorizacion,
        'cedula': cedula ?? '23635723', // Usamos el valor de la venta o un valor por defecto
        'rapidAfilid': '123456'
      };
      
      print('Anulando transacción con datos: $params');
      
      await _anulacionChannel.invokeMethod('anulacionRapidPagoPos', params);
      print("Solicitud de anulación enviada correctamente");
    } catch (e) {
      print('Error al iniciar anulación: $e');
      _showErrorSnackBar('Error al iniciar anulación: $e');
    }
  }

  // Función para realizar cierre de lote
  Future<void> realizarCierre() async {
    try {
      print("Iniciando cierre de lote...");
      final Map<String, dynamic> params = {
        'operation': 'CIERRE'
      };
      
      await _cierreChannel.invokeMethod('cierreRapidPagoPos', params);
      print("Solicitud de cierre enviada correctamente");
    } catch (e) {
      print('Error al iniciar cierre de lote: $e');
      _showErrorSnackBar('Error al iniciar cierre de lote: $e');
    }
  }

  // Función para obtener resumen de lote
  Future<void> obtenerResumenLote() async {
    try {
      print("Solicitando resumen de lote...");
      final Map<String, dynamic> params = {
        'formatoJson': true
      };
      
      await _resumenLoteChannel.invokeMethod('resumenLotePos', params);
      print("Solicitud de resumen de lote enviada correctamente");
    } catch (e) {
      print('Error al obtener resumen de lote: $e');
      _showErrorSnackBar('Error al obtener resumen de lote: $e');
    }
  }

  // Función para obtener último recibo
  Future<void> obtenerUltimoRecibo() async {
    try {
      print("Solicitando último recibo...");
      final Map<String, dynamic> params = {
        'printRecibo': true,
        'formatoJson': true
      };
      
      await _ultimoReciboChannel.invokeMethod('ultimoReciboPos', params);
      print("Solicitud de último recibo enviada correctamente");
    } catch (e) {
      print('Error al obtener último recibo: $e');
      _showErrorSnackBar('Error al obtener último recibo: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    print("Mostrando SnackBar de error: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Aplicación POS Demo"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Operaciones POS",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Indicador de venta disponible para anular
                if (hayVentaParaAnular && ultimaVentaExitosa != null)
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.green.shade600),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            "Venta disponible para anular:\nAutorización: ${ultimaVentaExitosa!['autorizacion']}\nPAN: ${ultimaVentaExitosa!['pan']}",
                            style: TextStyle(color: Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Depuración del estado
                Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Estado de anulación: ${hayVentaParaAnular ? 'Disponible' : 'No disponible'}"),
                      if (ultimaVentaExitosa != null)
                        Text("Última venta guardada: Sí"),
                      if (ultimaVentaExitosa == null)
                        Text("Última venta guardada: No"),
                    ],
                  ),
                ),
                
                // Sección de operaciones POS
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: realizarVenta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Realizar Venta'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: hayVentaParaAnular ? realizarAnulacion : () {
                            print("Botón de anulación presionado, pero no hay venta para anular");
                            _showErrorSnackBar('No hay una venta para anular. Realice una venta primero.');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hayVentaParaAnular ? Colors.red : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Anular Transacción'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: realizarCierre,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cierre de Lote'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: obtenerResumenLote,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Obtener Resumen de Lote'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: obtenerUltimoRecibo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Obtener Último Recibo'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Sección de QR
                const Text(
                  "Funciones QR",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: handleGenerateQr,
                              child: const Text('Generar QR Estándar'),
                            ),
                            ElevatedButton(
                              onPressed: handleGenerateC2PQr,
                              child: const Text('Generar QR C2P'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Visualización del QR
                        Center(
                          child: qrData != null
                            ? QrImageView(
                                data: qrData!,
                                size: 200,
                              )
                            : Container(
                                width: 200,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Text('No hay QR generado'),
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Añadir un botón de depuración para ver la última venta si existe
                if (ultimaVentaExitosa != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextButton(
                      onPressed: () {
                        print("Mostrando datos detallados de la última venta");
                        _showResultDialog('Datos de la última venta', ultimaVentaExitosa!);
                      },
                      child: const Text('Ver detalles de la última venta'),
                    ),
                  ),
                
                // Botón para forzar una verificación del estado
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: TextButton(
                    onPressed: () {
                      print("Verificación manual del estado de anulación");
                      print("hayVentaParaAnular: $hayVentaParaAnular");
                      print("ultimaVentaExitosa: $ultimaVentaExitosa");
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Estado de anulación: ${hayVentaParaAnular ? 'Disponible' : 'No disponible'}"),
                          backgroundColor: hayVentaParaAnular ? Colors.green : Colors.orange,
                        ),
                      );
                    },
                    child: const Text('Verificar estado de anulación'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}