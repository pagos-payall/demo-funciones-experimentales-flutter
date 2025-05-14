package com.example.flutter_application_pos_conectar
import android.content.Intent
import android.content.ComponentName
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import org.json.JSONObject
import android.util.Base64
//import org.suiche7b.sdk.qrcode.functions.ParseQR VERSION C2P
//import org.suiche7b.sdk.qrcode.functions.code.ParseQrCode VERSION C2P
import org.suiche7b.sdk.qrcode.functions.code.ParseQR
import java.nio.charset.StandardCharsets
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import java.security.MessageDigest
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

//nuevo
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private val ABRIR_POS_CHANNEL = "conectar_abrir_pos"
    private val ANULACION_CHANNEL = "anulacion_pos"
    private val CIERRE_CHANNEL = "cierre_pos"
    
    // Nuevos canales para resumen de lote y último recibo
    private val RESUMEN_LOTE_CHANNEL = "resumen_lote_pos"
    private val ULTIMO_RECIBO_CHANNEL = "ultimo_recibo_pos"

    private val RESULTADO_POS_CHANNEL = "resultado_pos"
    private val RESULTADO_ANULACION_CHANNEL = "resultado_anulacion_pos"
    private val RESULTADO_CIERRE_CHANNEL = "resultado_cierre_pos"
    
    // Canales de resultado para las nuevas funcionalidades
    private val RESULTADO_RESUMEN_LOTE_CHANNEL = "resultado_resumen_lote_pos"
    private val RESULTADO_ULTIMO_RECIBO_CHANNEL = "resultado_ultimo_recibo_pos"

    private val INTENT_VENTA = 100
    private val INTENT_ANULACION = 101
    private val INTENT_CIERRE = 102
    
    // Códigos de intent para las nuevas funcionalidades
    private val INTENT_RESUMEN_LOTE = 104
    private val INTENT_ULTIMO_RECIBO = 105

    private val PARSE_QR_CHANNEL = "generacion_qr"  

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
    
    override fun onResume() {
        super.onResume()
        Log.d("MainActivity", "onResume llamado")
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                if (flutterEngine != null) {
                    flutterEngine?.lifecycleChannel?.appIsResumed()
                    Log.d("MainActivity", "Flutter Engine resumido exitosamente")
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error en onResume: ${e.message}")
            }
        }, 300)
    }
    
    override fun onPause() {
        super.onPause()
        flutterEngine?.lifecycleChannel?.appIsInactive()
    }
    
    override fun onRestart() {
        super.onRestart()
        Handler(Looper.getMainLooper()).postDelayed({
            flutterEngine?.lifecycleChannel?.appIsResumed()
        }, 100)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d("MainActivity", "Nuevo intent recibido")
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureAbrirPosChannel(flutterEngine)
        configureAnulacionChannel(flutterEngine)
        configureCierreChannel(flutterEngine)
        configureGenerarQrChannel(flutterEngine)
        
        // Configuración de los nuevos canales
        configureResumenLoteChannel(flutterEngine)
        configureUltimoReciboChannel(flutterEngine)
    }

    /* ############################################## IMPLEMENTANDO QR ################################################## */
    private fun configureGenerarQrChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PARSE_QR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
  
    
                "setParseQrCode" -> {
                    try {
                        val dataQR = call.argument<String>("dataQR") ?: ""
                        val merchantId = call.argument<String>("merchantId") ?: ""
                        val encodedData = setParseQrCode(dataQR, merchantId)
                        result.success(encodedData)
                    } catch (e: Exception) {
                        result.error("ERROR", "Error generating QR code", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /* ##############################################FIN IMPLEMENTANDO QR ################################################## */

    /* ################################ IMPLEMENTANDO NUEVOS CANALES ################################## */
    
    private fun configureResumenLoteChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RESUMEN_LOTE_CHANNEL).setMethodCallHandler { call, result ->
            try {
                if (call.method == "resumenLotePos") {
                    val formatoJson = call.argument<Boolean>("formatoJson") ?: true
                    resumenLotePos(formatoJson)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error en resumenLotePos: ${e.message}", e)
                result.error("RUNTIME_ERROR", "Error al obtener resumen de lote: ${e.message}", null)
            }
        }
    }

    private fun configureUltimoReciboChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ULTIMO_RECIBO_CHANNEL).setMethodCallHandler { call, result ->
            try {
                if (call.method == "ultimoReciboPos") {
                    val printRecibo = call.argument<Boolean>("printRecibo") ?: true
                    val formatoJson = call.argument<Boolean>("formatoJson") ?: true
                    ultimoReciboPos(printRecibo, formatoJson)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error en ultimoReciboPos: ${e.message}", e)
                result.error("RUNTIME_ERROR", "Error al obtener último recibo: ${e.message}", null)
            }
        }
    }
    
    /* ########################## FIN DE IMPLEMENTACIÓN DE NUEVOS CANALES ############################ */

    private fun configureAbrirPosChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ABRIR_POS_CHANNEL).setMethodCallHandler { call, result ->
            try {
            
                if (call.method == "abrirAppRapidPago") {
                    Log.d("MainActivity", "Todos los argumentos: ${call.arguments}")
                    val operation = call.argument<String>("operation")
                    val monto = call.argument<Int>("monto")?.toLong()
                    val isAmountEditable = call.argument<Boolean>("isAmountEditable")
                    val rapidAfilid = call.argument<String>("rapidAfilid")
                    val cedula = call.argument<String>("cedula")
                    val tarjetasAceptadas = call.argument<String>("tarjetasAceptadas")

                    if (operation != null && monto != null && isAmountEditable != null && rapidAfilid != null && cedula != null && tarjetasAceptadas != null) {
                        abrirAppRapidPago(operation, monto, isAmountEditable, rapidAfilid, cedula, tarjetasAceptadas)
                        result.success(null)
                    } else {
                        result.error("ARGUMENT_ERROR", "One or more arguments are null", null)
                    }
                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error en abrirAppRapidPago: ${e.message}", e)
                result.error("RUNTIME_ERROR", "Error al abrir RapidPago: ${e.message}", null)
            }
        }
    }

    private fun configureAnulacionChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANULACION_CHANNEL).setMethodCallHandler { call, result ->
            try {
                if (call.method == "anulacionRapidPagoPos") {
                    val operation = call.argument<String>("operation")
                    val monto = call.argument<Int>("monto")?.toLong()
                    val pan = call.argument<String>("pan")
                    val autorizacion = call.argument<String>("autorizacion")
                    val cedula = call.argument<String>("cedula")
                    val rapidAfilid = call.argument<String>("rapidAfilid")

                    if (operation != null && monto != null && pan != null && autorizacion != null && cedula != null && rapidAfilid != null) {
                        anulacionRapidPagoPos(operation, monto, pan, autorizacion, cedula, rapidAfilid)
                        result.success(null)
                    } else {
                        result.error("ARGUMENT_ERROR", "One or more arguments are null", null)
                    }
                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error en anulacionRapidPagoPos: ${e.message}", e)
                result.error("RUNTIME_ERROR", "Error en anulación RapidPago: ${e.message}", null)
            }
        }
    }

    private fun configureCierreChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CIERRE_CHANNEL).setMethodCallHandler { call, result ->
            try {
                if (call.method == "cierreRapidPagoPos") {
                    val operation = call.argument<String>("operation")
                    if (operation != null) {
                        cierreRapidPagoPos(operation)
                        result.success(null)
                    } else {
                        result.error("ARGUMENT_ERROR", "Operation argument is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e("MainActivity", "Error en cierreRapidPagoPos: ${e.message}", e)
                result.error("RUNTIME_ERROR", "Error en cierre RapidPago: ${e.message}", null)
            }
        }
    }

    // Implementación de funciones para QR
    private fun getParseQrCode(dataQR: String): String {
        val decodedBytes = Base64.decode(dataQR, Base64.DEFAULT)
        return String(decodedBytes, StandardCharsets.UTF_8)
    }


    private fun setParseQrCode(dataQR: String, merchantId: String): String {
        if (dataQR.isEmpty() || merchantId.isEmpty()) {
            throw Exception("dataQR y merchantId son requeridos")
        }
        var resultQR: String = ""
        val latch = CountDownLatch(1)
        val parseQR = ParseQR()
        try {
            Log.d("ParseQR", "Iniciando parseQR")
            val resultado = parseQR.setParseQrCode(dataQR, merchantId)
            Log.d("ParseQR", "Resultado: $resultado")
            return resultado
            
        } catch (e: Exception) {
            throw Exception(e.message ?: "Error al generar QR")
        }
    }

    /* ####################### IMPLEMENTACIÓN DE NUEVAS FUNCIONES ###################### */
    
    private fun resumenLotePos(formatoJson: Boolean = true) {
        Log.d("MainActivity", "Obteniendo resumen de lote")
        val intent = getIntent()
        intent.putExtra("OPERACION", "RESUMEN_LOTE")
        // Siempre añadimos el formato JSON
        intent.putExtra("VERSION_INVOKE", "2")
        startActivityForResult(intent, INTENT_RESUMEN_LOTE)
    }

    private fun ultimoReciboPos(printRecibo: Boolean, formatoJson: Boolean = true) {
        Log.d("MainActivity", "Obteniendo último recibo")
        val intent = getIntent()
        intent.putExtra("OPERACION", "ULTIMO_RECIBO")
        // Siempre añadimos el formato JSON
        intent.putExtra("VERSION_INVOKE", "2")
        intent.putExtra("IMPRIMIR_RECIBO", printRecibo)
        startActivityForResult(intent, INTENT_ULTIMO_RECIBO)
    }
    
    /* ######################## FIN DE IMPLEMENTACIÓN DE NUEVAS FUNCIONES ##################### */

    override fun getIntent(): Intent {
        val intent = Intent("android.intent.action.MAIN")
        val appURL = "com.rapidpago.mpos.financialdev" // Desarrollo
        //val appURL = "com.rapidpago.mpos.financialqa" // QA
       //val appURL = "com.rapidpago.mpos.financialapp" // Produccion
        val cn = ComponentName(appURL, "com.rapidpago.mpos.sunmi.InvokeActivity")
        intent.component = cn
        return intent
    }

    private fun abrirAppRapidPago(operation: String, monto: Long, isAmountEditable: Boolean, rapidAfilid: String, cedula: String, tarjetasAceptadas: String) {
        Log.d("MainActivity", "Abriendo App RapidPago: operation=$operation, monto=$monto")
        val intent = getIntent()
        intent.putExtra("OPERACION", operation)
        intent.putExtra("MONTO", monto)
        
        // AÑADIR EL FORMATO JSON CAMBIA LA ESTRUCTURA DE RESPUESTA
        //intent.putExtra("VERSION_INVOKE", "2")
       
        if(tarjetasAceptadas == "soloCredito"){
          intent.putExtra("SOLO_TC", true)
        }
          
        if(tarjetasAceptadas == "soloDebito"){
          intent.putExtra("SOLO_TD", true)
         }
            
        intent.putExtra("MONTO_EDITABLE", isAmountEditable)
        intent.putExtra("CEDULA", cedula)


        startActivityForResult(intent, INTENT_VENTA)
    }
    // 

    private fun anulacionRapidPagoPos(operation: String, monto: Long, pan: String, autorizacion: String, cedula: String, rapidAfilid: String) {
        Log.d("MainActivity", "Iniciando anulación RapidPago: operation=$operation, monto=$monto")
        val intent = getIntent()
        intent.putExtra("OPERACION", operation)
        intent.putExtra("MONTO", monto)
        intent.putExtra("PAN", pan)
        intent.putExtra("AUTORIZACION", autorizacion)
        intent.putExtra("PEDIR_PASS", false)
        
        // Añadimos siempre el formato JSON
        intent.putExtra("VERSION_INVOKE", "2")
        
        startActivityForResult(intent, INTENT_ANULACION)
    }

    private fun cierreRapidPagoPos(operation: String) {
        Log.d("MainActivity", "Iniciando cierre RapidPago: operation=$operation")
        val intent = getIntent()
        intent.putExtra("OPERACION", operation)
        
        // Añadimos siempre el formato JSON
        intent.putExtra("VERSION_INVOKE", "2")
        
        startActivityForResult(intent, INTENT_CIERRE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        Log.d("MainActivity", "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
        try {
            when (requestCode) {
                INTENT_VENTA -> handleVentaResult(resultCode, data)
                INTENT_ANULACION -> handleAnulacionResult(resultCode, data)
                INTENT_CIERRE -> handleCierreResult(resultCode, data)
                // Manejadores para los nuevos intents
                INTENT_RESUMEN_LOTE -> handleResumenLoteResult(resultCode, data)
                INTENT_ULTIMO_RECIBO -> handleUltimoReciboResult(resultCode, data)
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error en onActivityResult: ${e.message}", e)
            sendErrorToFlutter("Error inesperado: ${e.message}")
        }
    }

    private fun handleVentaResult(resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "Manejando resultado de venta. ResultCode: $resultCode")
        val responseCode = data?.getStringExtra("RESPONSE_CODE") ?: "Error"
        data?.let { intent ->
            val resultMap = if (resultCode == Activity.RESULT_OK) {
                // Verificar si hay formato JSON
                val responseJson = intent.getStringExtra("RESPONSE_JSON")
                if (responseJson != null && responseJson.isNotEmpty()) {
                    // Si hay JSON, lo incluimos en los resultados
                    mapOf(
                        "autorizacion" to intent.getStringExtra("AUTORIZACION"),
                        "pan" to intent.getStringExtra("PAN"),
                        "stan" to intent.getStringExtra("STAN"),
                        "merchantID" to intent.getStringExtra("MERCHANT_ID"),
                        "terminalID" to intent.getStringExtra("TERMINAL_ID"),
                        "recibo" to intent.getStringExtra("RECIBO"),
                        "lote" to intent.getStringExtra("LOTE"),
                        "monto" to intent.getLongExtra("MONTO", 0),
                        "cedula" to intent.getStringExtra("CEDULA"),
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Pago realizado"),
                        "response_code" to responseCode,
                        "response_json" to responseJson
                    )
                } else {
                    mapOf(
                        "autorizacion" to intent.getStringExtra("AUTORIZACION"),
                        "pan" to intent.getStringExtra("PAN"),
                        "stan" to intent.getStringExtra("STAN"),
                        "merchantID" to intent.getStringExtra("MERCHANT_ID"),
                        "terminalID" to intent.getStringExtra("TERMINAL_ID"),
                        "recibo" to intent.getStringExtra("RECIBO"),
                        "lote" to intent.getStringExtra("LOTE"),
                        "monto" to intent.getLongExtra("MONTO", 0),
                        "cedula" to intent.getStringExtra("CEDULA"),
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Pago realizado"),
                        "response_code" to responseCode
                    )
                }
            } else {
                // También verificar JSON en respuestas de error
                val responseJson = intent.getStringExtra("RESPONSE_JSON")
                if (responseJson != null && responseJson.isNotEmpty()) {
                    mapOf(
                        "autorizacion" to intent.getStringExtra("AUTORIZACION"),
                        "pan" to "DECLINADA",
                        "stan" to "N/A",
                        "merchantID" to "N/A",
                        "terminalID" to "N/A",
                        "recibo" to "N/A",
                        "lote" to "N/A",
                        "monto" to 0,
                        "cedula" to "N/A",
                        "response_code" to responseCode,
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Error"),
                        "response_json" to responseJson
                    )
                } else {
                    mapOf(
                        "autorizacion" to intent.getStringExtra("AUTORIZACION"),
                        "pan" to "DECLINADA",
                        "stan" to "N/A",
                        "merchantID" to "N/A",
                        "terminalID" to "N/A",
                        "recibo" to "N/A",
                        "lote" to "N/A",
                        "monto" to 0,
                        "cedula" to "N/A",
                        "response_code" to responseCode,
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Error")
                    )
                }
            }
            sendDelayedResultToFlutter(RESULTADO_POS_CHANNEL, "resultadoTransaccionPos", resultMap)
        } ?: run {
            Log.w("MainActivity", "Data es null en handleVentaResult")
            sendErrorToFlutter("No se recibieron datos de la transacción")
        }
    }

    private fun handleAnulacionResult(resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "Manejando resultado de anulación. ResultCode: $resultCode")
        val responseMessage = data?.getStringExtra("RESPONSE_MESSAGE") ?: "Error"
        val responseCode = data?.getStringExtra("RESPONSE_CODE") ?: "Error"
        val status = if (resultCode == Activity.RESULT_OK) "Anulacion Ok" else "Anulacion fallida"
        
        data?.let { intent ->
            val responseJson = intent.getStringExtra("RESPONSE_JSON")
            val resultMap = if (responseJson != null && responseJson.isNotEmpty()) {
                mapOf(
                    "response_message" to responseMessage,
                    "response_code" to responseCode,
                    "status" to status,
                    "response_json" to responseJson
                )
            } else {
                mapOf(
                    "response_message" to responseMessage,
                    "response_code" to responseCode,
                    "status" to status
                )
            }
            sendDelayedResultToFlutter(RESULTADO_ANULACION_CHANNEL, "resultadoAnulacionPos", resultMap)
        } ?: run {
            val resultMap = mapOf(
                "response_message" to responseMessage,
                "response_code" to responseCode,
                "status" to status
            )
            sendDelayedResultToFlutter(RESULTADO_ANULACION_CHANNEL, "resultadoAnulacionPos", resultMap)
        }
    }

    private fun handleCierreResult(resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "Manejando resultado de cierre. ResultCode: $resultCode")
        val responseMessage = data?.getStringExtra("RESPONSE_MESSAGE") ?: "Error"
        val responseCode = data?.getStringExtra("RESPONSE_CODE") ?: "Error"
        val status = if (resultCode == Activity.RESULT_OK) "cierreSuccess" else "cierreFallido"
        
        data?.let { intent ->
            val responseJson = intent.getStringExtra("RESPONSE_JSON")
            val resultMap = if (responseJson != null && responseJson.isNotEmpty()) {
                mapOf(
                    "response_message" to responseMessage,
                    "response_code" to responseCode,
                    "status" to status,
                    "response_json" to responseJson
                )
            } else {
                mapOf(
                    "response_message" to responseMessage,
                    "response_code" to responseCode,
                    "status" to status
                )
            }
            sendDelayedResultToFlutter(RESULTADO_CIERRE_CHANNEL, "resultadoCierrePos", resultMap)
        } ?: run {
            val resultMap = mapOf(
                "response_message" to responseMessage,
                "response_code" to responseCode,
                "status" to status
            )
            sendDelayedResultToFlutter(RESULTADO_CIERRE_CHANNEL, "resultadoCierrePos", resultMap)
        }
    }

    /* ##################### IMPLEMENTACIÓN DE MANEJADORES PARA NUEVAS FUNCIONES ##################### */
    
    private fun handleResumenLoteResult(resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "Manejando resultado de resumen de lote. ResultCode: $resultCode")
        
        data?.let { intent ->
            val resultMap = if (resultCode == Activity.RESULT_OK) {
                // Verificar formato JSON primero
                val responseJson = intent.getStringExtra("RESPONSE_JSON")
                if (responseJson != null && responseJson.isNotEmpty()) {
                    mapOf(
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Resumen obtenido"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "00"),
                        "status" to "resumenObtenido",
                        "resumen_data" to (intent.getStringExtra("RESUMEN_JSON") ?: "{}"),
                        "response_json" to responseJson
                    )
                } else {
                    // Formato estándar
                    mapOf("response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Resumen obtenido"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "00"),
                        "status" to "resumenObtenido",
                        "resumen_data" to (intent.getStringExtra("RESUMEN_JSON") ?: "{}")
                    )
                }
            } else {
                // También verificar JSON en respuestas de error
                val responseJson = intent.getStringExtra("RESPONSE_JSON")
                if (responseJson != null && responseJson.isNotEmpty()) {
                    mapOf(
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Error"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "Error"),
                        "status" to "resumenFallido",
                        "response_json" to responseJson
                    )
                } else {
                    mapOf(
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Error"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "Error"),
                        "status" to "resumenFallido"
                    )
                }
            }
            
            sendDelayedResultToFlutter(RESULTADO_RESUMEN_LOTE_CHANNEL, "resultadoResumenLotePos", resultMap)
        } ?: run {
            Log.w("MainActivity", "Data es null en handleResumenLoteResult")
            val errorMap = mapOf(
                "error" to "No se recibieron datos del resumen",
                "status" to "resumenFallido"
            )
            sendDelayedResultToFlutter(RESULTADO_RESUMEN_LOTE_CHANNEL, "resultadoResumenLotePos", errorMap)
        }
    }

    private fun handleUltimoReciboResult(resultCode: Int, data: Intent?) {
        Log.d("MainActivity", "Manejando resultado de último recibo. ResultCode: $resultCode")
        
        data?.let { intent ->
            val resultMap = if (resultCode == Activity.RESULT_OK) {
                // Verificar formato JSON primero
                val responseJson = intent.getStringExtra("RESPONSE_JSON")
                if (responseJson != null && responseJson.isNotEmpty()) {
                    mapOf(
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Recibo obtenido"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "00"),
                        "status" to "reciboObtenido",
                        "recibo_data" to (intent.getStringExtra("RECIBO_DATA") ?: ""),
                        "response_json" to responseJson
                    )
                } else {
                    // Formato estándar
                    mapOf(
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Recibo obtenido"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "00"),
                        "status" to "reciboObtenido",
                        "recibo_data" to (intent.getStringExtra("RECIBO_DATA") ?: "")
                    )
                }
            } else {
                // También verificar JSON en respuestas de error
                val responseJson = intent.getStringExtra("RESPONSE_JSON")
                if (responseJson != null && responseJson.isNotEmpty()) {
                    mapOf(
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Error"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "Error"),
                        "status" to "reciboFallido",
                        "response_json" to responseJson
                    )
                } else {
                    mapOf(
                        "response_message" to (intent.getStringExtra("RESPONSE_MESSAGE") ?: "Error"),
                        "response_code" to (intent.getStringExtra("RESPONSE_CODE") ?: "Error"),
                        "status" to "reciboFallido"
                    )
                }
            }
            
            sendDelayedResultToFlutter(RESULTADO_ULTIMO_RECIBO_CHANNEL, "resultadoUltimoReciboPos", resultMap)
        } ?: run {
            Log.w("MainActivity", "Data es null en handleUltimoReciboResult")
            val errorMap = mapOf(
                "error" to "No se recibieron datos del recibo",
                "status" to "reciboFallido"
            )
            sendDelayedResultToFlutter(RESULTADO_ULTIMO_RECIBO_CHANNEL, "resultadoUltimoReciboPos", errorMap)
        }
    }
    
    /* ################### FIN DE IMPLEMENTACIÓN DE MANEJADORES PARA NUEVAS FUNCIONES #################### */

    private fun sendDelayedResultToFlutter(channel: String, method: String, resultMap: Map<String, Any?>) {
        if (!isFinishing && !isDestroyed) {
            runOnUiThread {
                flutterEngine?.let { engine ->
                    MethodChannel(engine.dartExecutor.binaryMessenger, channel)
                        .invokeMethod(method, resultMap)
                    Log.d("MainActivity", "Enviando resultado a Flutter: $resultMap")
                } ?: Log.e("MainActivity", "FlutterEngine no está disponible")
            }
        } else {
            Log.w("MainActivity", "Actividad no válida para enviar resultado")
        }
    }

    private fun sendErrorToFlutter(errorMessage: String) {
        val errorMap = mapOf("error" to errorMessage)
        sendDelayedResultToFlutter(RESULTADO_POS_CHANNEL, "resultadoTransaccionPos", errorMap)
    }
}