import 'dart:async';

import 'package:flutter/services.dart';

class FlutterHyperpay {
  static const MethodChannel _channel = MethodChannel('flutter_hyperpay');

  static Future<String?> checkout(String checkoutId) async {
    return _channel.invokeMethod('checkout', {'checkoutId': checkoutId});
  }
}
