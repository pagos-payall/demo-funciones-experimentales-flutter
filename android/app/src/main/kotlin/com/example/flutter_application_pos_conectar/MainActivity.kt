package com.example.flutter_application_pos_conectar

import io.flutter.embedding.android.FlutterFragmentActivity
import androidx.annotation.NonNull
import android.content.Intent
import android.net.Uri
import android.content.ComponentName
import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.DialogInterface
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.widget.TextView
import android.widget.Toast
import androidx.annotation.Nullable
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AlertDialog
import org.json.JSONObject
import org.suiche7b.sdk.qrcode.functions.GenerateQrTotp
import org.suiche7b.sdk.qrcode.functions.ScanQrTotp
import org.suiche7b.sdk.qrcode.functions.code.GenerateQrCodeTotp
import org.suiche7b.sdk.qrcode.functions.code.ScanQrCodeTotp

@SuppressWarnings("ALL")  
class MainActivity: FlutterFragmentActivity() {
    private val POINT_OF_SALE_CHANNEL = "point_of_sale_opener"
    private val RESULT_CHANNEL = "point_of_sale_result"
    private val QR_GENERATOR_CHANNEL = "generadorQR"
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, QR_GENERATOR_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "generateQR") {
                val data = call.argument<String>("data")
                val merchantId = call.argument<String>("merchantId")
                val totpKey = call.argument<String>("totpKey")
                val secretKey = call.argument<String>("secretKey")
                val timeout = call.argument<Int>("timeout") ?: 20
                val config = call.argument<String>("config")
                val digitsTotp = call.argument<Int>("digitsTotp") ?: 8

                if (data != null && merchantId != null && totpKey != null && secretKey != null && config != null) {
                    generateQR(data, merchantId, totpKey, secretKey, timeout, config, digitsTotp, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openPointOfSale(operation: String, monto: Long, isAmountEditable: Boolean, rapidAfilid: String, cedula:String) {
        val intent = Intent("android.intent.action.MAIN")
        val appURL = "com.rapidpago.mpos.financialdev"
        val cn = ComponentName(appURL,"com.rapidpago.mpos.sunmi.InvokeActivity")
        intent.component = cn
        intent.putExtra("OPERACION", operation)
        intent.putExtra("MONTO", monto)
        intent.putExtra("MONTO_EDITABLE", isAmountEditable)
        intent.putExtra("RAPID_AFILID", rapidAfilid)
        intent.putExtra("CEDULA", cedula)
        startActivityForResult(intent, INTENT_VENTA)
    }

    private fun generateQR(data: String, merchantId: String, totpKey: String, secretKey: String, timeout: Int, config: String, digitsTotp: Int, result: MethodChannel.Result) {
        val generateQrTotp = GenerateQrTotp(this)
        generateQrTotp.createQrCode(data, merchantId, totpKey, secretKey, timeout, config, digitsTotp, true, false, object : GenerateQrCodeTotp.OncreateQrCode {
            override fun oncreateQrCodeSuccess(code: String) {
                runOnUiThread {
                    result.success(code)
                }
            }

            override fun oncreateQrCodeError(error: String?) {
                runOnUiThread {
                    result.error("QR_GENERATION_FAILED", error ?: "Unknown error", null)
                }
            }
        })
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