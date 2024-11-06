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
import android.util.Base64
import java.nio.charset.StandardCharsets
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import java.security.MessageDigest

@SuppressWarnings("ALL")  
class MainActivity: FlutterFragmentActivity() {
    private val POINT_OF_SALE_CHANNEL = "point_of_sale_opener"
    private val RESULT_CHANNEL = "point_of_sale_result"
    private val INTENT_VENTA = 1
    private val PARSE_QR_CHANNEL = "generacion_qr"  

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

        // Canal para generación de QR
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PARSE_QR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getParseQrCode" -> {
                    try {
                        val dataQR = call.argument<String>("dataQR") ?: ""
                        val parsedData = getParseQrCode(dataQR)
                        result.success(parsedData)
                    } catch (e: Exception) {
                        result.error("ERROR", "Error parsing QR code", e.message)
                    }
                }
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
                "setParseQrCodeTotp" -> {
                    try {
                        val dataQR = call.argument<String>("dataQR") ?: ""
                        val merchantId = call.argument<String>("merchantId") ?: ""
                        val totpKey = call.argument<String>("totpKey") ?: ""
                        val secretKey = call.argument<String>("secretKey") ?: ""
                        val encodedData = setParseQrCodeTotp(dataQR, merchantId, totpKey, secretKey)
                        result.success(encodedData)
                    } catch (e: Exception) {
                        result.error("ERROR", "Error generating QR code with TOTP", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openPointOfSale(operation: String, monto: Long, isAmountEditable: Boolean, rapidAfilid: String, cedula:String) {
        val intent = Intent("android.intent.action.MAIN")
        val appURL = ""
        val cn = ComponentName(appURL,"")
        intent.component = cn
        intent.putExtra("OPERACION", operation)
        intent.putExtra("MONTO", monto)
        intent.putExtra("MONTO_EDITABLE", isAmountEditable)
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

    // Implementación de funciones para QR
    private fun getParseQrCode(dataQR: String): String {
        val decodedBytes = Base64.decode(dataQR, Base64.DEFAULT)
        return String(decodedBytes, StandardCharsets.UTF_8)
    }

    private fun setParseQrCode(dataQR: String, merchantId: String): String {
        val jsonObject = JSONObject().apply {
            put("data", dataQR)
            put("merchantId", merchantId)
            put("timestamp", System.currentTimeMillis())
        }
        
        return Base64.encodeToString(
            jsonObject.toString().toByteArray(StandardCharsets.UTF_8),
            Base64.DEFAULT
        )
    }

    private fun setParseQrCodeTotp(
        dataQR: String,
        merchantId: String,
        totpKey: String,
        secretKey: String
    ): String {
        // Generar TOTP
        val totp = generateTotp(secretKey)
        
        val jsonObject = JSONObject().apply {
            put("data", dataQR)
            put("merchantId", merchantId)
            put("totpKey", totpKey)
            put("totp", totp)
            put("timestamp", System.currentTimeMillis())
            put("hash", generateHash(merchantId + totpKey + secretKey))
        }
        
        return Base64.encodeToString(
            jsonObject.toString().toByteArray(StandardCharsets.UTF_8),
            Base64.DEFAULT
        )
    }

    private fun generateTotp(secretKey: String): String {
        val time = System.currentTimeMillis() / 30000 // 30 segundos de intervalo
        val data = time.toString().toByteArray()
        val hmacSha1 = Mac.getInstance("HmacSHA1")
        val key = SecretKeySpec(secretKey.toByteArray(), "HmacSHA1")
        hmacSha1.init(key)
        val hmac = hmacSha1.doFinal(data)
        val offset = hmac[hmac.size - 1].toInt() and 0xf
        val binary = ((hmac[offset].toInt() and 0x7f) shl 24) or
                    ((hmac[offset + 1].toInt() and 0xff) shl 16) or
                    ((hmac[offset + 2].toInt() and 0xff) shl 8) or
                    (hmac[offset + 3].toInt() and 0xff)
        return String.format("%06d", binary % 1000000)
    }

    private fun generateHash(input: String): String {
        val bytes = MessageDigest.getInstance("SHA-256").digest(input.toByteArray())
        return bytes.joinToString("") { "%02x".format(it) }
    }
}