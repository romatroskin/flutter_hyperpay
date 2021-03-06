import Flutter
import UIKit

public class SwiftFlutterHyperpayPlugin: NSObject, FlutterPlugin {
    fileprivate var resourcePath: String?
    fileprivate var result: FlutterResult?
    fileprivate var checkoutProvider: OPPCheckoutProvider?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_hyperpay", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterHyperpayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.result = result
        
        let args = call.arguments as! Dictionary<String, Any>
        if call.method == "checkout" {
            let provider = OPPPaymentProvider(mode: OPPProviderMode.test)
            
            let checkoutSettings = OPPCheckoutSettings()
            
            // Set available payment brands for your shop
            checkoutSettings.paymentBrands = ["VISA", "DIRECTDEBIT_SEPA"]
            
            // Set shopper result URL
            checkoutSettings.shopperResultURL = "foreman://payment-result"
            
            self.checkoutProvider = OPPCheckoutProvider(paymentProvider: provider, checkoutID: args["checkoutId"] as! String, settings: checkoutSettings)
            
            checkoutProvider?.presentCheckout(forSubmittingTransactionCompletionHandler: { (transaction, error) in guard let transaction = transaction else {
                // Handle invalid transaction, check error
                return
                
            }
                
                self.resourcePath = transaction.resourcePath
                
                if transaction.type == .synchronous {
                    // If a transaction is synchronous, just request the payment status
                    // You can use transaction.resourcePath or just checkout ID to do it
                    result(self.resourcePath)
                    
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
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            if url.scheme?.caseInsensitiveCompare("foreman") == .orderedSame {
                checkoutProvider!.dismissCheckout(animated: true) {
                        self.result!(self.resourcePath)
                    }
                return true
            }
            return false
      }
}
