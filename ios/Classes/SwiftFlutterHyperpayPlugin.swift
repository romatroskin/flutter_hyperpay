import Flutter
import UIKit

public class SwiftFlutterHyperpayPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_hyperpay", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterHyperpayPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let args = call.arguments as! Dictionary<String, Any>
      if call.method == "checkout" {
          let provider = OPPPaymentProvider(mode: OPPProviderMode.test)
          
          let checkoutSettings = OPPCheckoutSettings()

          // Set available payment brands for your shop
          checkoutSettings.paymentBrands = ["VISA", "DIRECTDEBIT_SEPA"]

          // Set shopper result URL
          checkoutSettings.shopperResultURL = "com.companyname.appname.payments://result"
          
          let checkoutProvider = OPPCheckoutProvider(paymentProvider: provider, checkoutID: args["checkoutId"] as! String, settings: checkoutSettings)
          
          checkoutProvider?.presentCheckout(forSubmittingTransactionCompletionHandler: { (transaction, error) in
              guard let transaction = transaction else {
                  // Handle invalid transaction, check error
                  return
              }
              
              if transaction.type == .synchronous {
                  // If a transaction is synchronous, just request the payment status
                  // You can use transaction.resourcePath or just checkout ID to do it
                  result(transaction.resourcePath)
              } else if transaction.type == .asynchronous {
                  // The SDK opens transaction.redirectUrl in a browser
                  // See 'Asynchronous Payments' guide for more details
              } else {
                  // Executed in case of failure of the transaction for any reason
                  result(FlutterError())
              }
          }, cancelHandler: {
              // Executed if the shopper closes the payment page prematurely
              result(nil)
          })
          //    result("iOS " + UIDevice.current.systemVersion)
      } else {
          result(FlutterMethodNotImplemented)
      }
  }
}
