package com.example.flutter_application_pos_conectar
import android.content.Intent
import android.net.Uri
import android.content.ComponentName
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val POINT_OF_SALE_CHANNEL = "point_of_sale_opener"
    private val RESULT_CHANNEL = "point_of_sale_result"
    private val INTENT_VENTA = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)


        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POINT_OF_SALE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openPointOfSale") {
                val operation = call.argument<String>("operation")
                val monto = call.argument<Int>("monto")?.toLong()
                val isAmountEditable = call.argument<Boolean>("isAmountEditable")
                val rapidAfilid = call.argument<String>("rapidAfilid")
                val cedula = call.argument<String>("cedula")

                if (operation != null && monto != null && isAmountEditable != null && rapidAfilid != null && 
                cedula != null) {
                    openPointOfSale(operation,monto,isAmountEditable,rapidAfilid,
                    cedula)
                    result.success(null)
                } else {
                    result.error("ARGUMENT_ERROR", "One or more arguments are null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RESULT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "resultFromPointOfSale") {
                val resultMap = call.arguments as Map<String, Any>
                val autorizacion = resultMap["autorizacion"] as String?
                val pan = resultMap["pan"] as String?
                val stan = resultMap["stan"] as String?
                val merchantID = resultMap["merchantID"] as String?
                val terminalID = resultMap["terminalID"] as String?
                val recibo = resultMap["recibo"] as String?
                val lote = resultMap["lote"] as String?
                val monto = resultMap["monto"] as Long?
                val cedula = resultMap["cedula"] as String?
            } else {
                result.notImplemented()
            }
        }
    }

    override fun getIntent(): Intent {
        val intent = Intent("android.intent.action.MAIN")
        val appURL = "com.rapidpago.mpos.financialdev"
        val cn = ComponentName(appURL,"com.rapidpago.mpos.sunmi.InvokeActivity") //USAR appURL o appURL2 segun sea el afiliado
        intent.component = cn
        return intent
    }


    private fun openPointOfSale(operation: String, monto: Long, isAmountEditable: Boolean, rapidAfilid: String, cedula:String) {
        val intent = getIntent();
        intent.putExtra("OPERACION", operation)
        intent.putExtra("MONTO", monto)
        intent.putExtra("MONTO_EDITABLE", isAmountEditable)
        intent.putExtra("RAPID_AFILID", rapidAfilid)
        intent.putExtra("CEDULA", cedula)
        startActivityForResult(intent, INTENT_VENTA)
        
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            INTENT_VENTA -> {

                val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, RESULT_CHANNEL)

                if(resultCode == Activity.RESULT_OK){
                    // Resultado de la actividad de punto de venta
                    val autorizacion = data?.getStringExtra("AUTORIZACION")
                    val pan = data?.getStringExtra("PAN")
                    val stan = data?.getStringExtra("STAN")
                    val merchantID = data?.getStringExtra("MERCHANT_ID")
                    val terminalID = data?.getStringExtra("TERMINAL_ID")
                    val recibo = data?.getStringExtra("RECIBO")
                    val lote = data?.getStringExtra("LOTE")
                    val monto = data?.getLongExtra("MONTO", 0)
                    val cedula = data?.getStringExtra("CEDULA")
                    val resultMap = mapOf(
                        "autorizacion" to autorizacion,
                        "pan" to pan,
                        "stan" to stan,
                        "merchantID" to merchantID,
                        "terminalID" to terminalID,
                        "recibo" to recibo,
                        "lote" to lote,
                        "monto" to monto,
                        "cedula" to cedula
                    )
                    channel.invokeMethod("resultFromPointOfSale", resultMap)
                }else{

                    val response_message = data!!.getStringExtra("RESPONSE_MESSAGE") ?: "Error"

                    val autorizacion = data?.getStringExtra("AUTORIZACION")
                    val pan = "DECLINADA"
                    val stan = "N/A"
                    val merchantID = "N/A"
                    val terminalID = "N/A"
                    val recibo = response_message 
                    val lote = "N/A"
                    val monto = 0
                    val cedula = "N/A"
                    
                    val resultMap = mapOf(
                        "autorizacion" to autorizacion,
                        "pan" to pan,
                        "stan" to stan,
                        "merchantID" to merchantID,
                        "terminalID" to terminalID,
                        "recibo" to recibo,
                        "lote" to lote,
                        "monto" to monto,
                        "cedula" to cedula
                    )
                    channel.invokeMethod("resultFromPointOfSale", resultMap)

                }

            }
        }
    }
}