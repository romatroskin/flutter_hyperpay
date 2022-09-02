package co.foreman.hyperpay.flutter_hyperpay

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import com.oppwa.mobile.connect.checkout.dialog.CheckoutActivity
import com.oppwa.mobile.connect.checkout.meta.CheckoutSettings
import com.oppwa.mobile.connect.exception.PaymentError
import com.oppwa.mobile.connect.provider.Connect
import com.oppwa.mobile.connect.provider.Transaction
import com.oppwa.mobile.connect.provider.TransactionType

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** FlutterHyperpayPlugin */
class FlutterHyperpayPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, PluginRegistry.NewIntentListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context : Context
  private lateinit var result: Result
  private var resourcePath: String? = null
  private var activity : Activity? = null

  private val paymentBrands = hashSetOf("VISA", "MASTER", "MADA", "AMEX", "DIRECTDEBIT_SEPA")

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_hyperpay")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) =
    if (call.method == "checkout") {
      this.result = result
      checkout(checkoutId = call.argument<String>("checkoutId") as String)
    } else {
      result.notImplemented()
    }

  private fun checkout(checkoutId: String) {
    val checkoutSettings = CheckoutSettings(checkoutId, paymentBrands, Connect.ProviderMode.TEST)
      .setShopperResultUrl("foreman://payment-result")
    checkoutSettings.isTotalAmountRequired = true

    val intent = checkoutSettings.createCheckoutActivityIntent(context)
    activity?.startActivityForResult(intent, CheckoutActivity.REQUEST_CODE_CHECKOUT)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
    binding.addOnNewIntentListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
    binding.addOnNewIntentListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    when (resultCode) {
      CheckoutActivity.RESULT_OK -> {
        /* transaction completed */
        val transaction: Transaction =
          data!!.getParcelableExtra(CheckoutActivity.CHECKOUT_RESULT_TRANSACTION)!!

        /* resource path if needed */
        resourcePath = data.getStringExtra(CheckoutActivity.CHECKOUT_RESULT_RESOURCE_PATH)

        if (transaction.transactionType == TransactionType.SYNC) {
          /* check the result of synchronous transaction */
          result.success(resourcePath)
        } else {
          /* wait for the asynchronous transaction callback in the onNewIntent() */
        }

        return true
      }

      CheckoutActivity.RESULT_CANCELED -> {
        /* shopper cancelled the checkout process */
        result.success(null)
        return true
      }

      CheckoutActivity.RESULT_ERROR -> {
        /* error occurred */
        val error: PaymentError =
          data!!.getParcelableExtra(CheckoutActivity.CHECKOUT_RESULT_ERROR)!!
        result.error(error.errorCode.name, error.errorMessage, error.errorInfo)
        return true
      }
    }
    return false
  }

  override fun onNewIntent(intent: Intent): Boolean {
    Log.d("FlutterHyperpayPlugin", "INTENT ARRIVED")
    if (intent.scheme == "foreman") {
      result.success(resourcePath)
      return true
    }

    return false
  }
}
