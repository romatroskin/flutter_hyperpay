
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterHyperpay {
  static const MethodChannel _channel = MethodChannel('flutter_hyperpay');

  static Future<bool> checkout(String checkoutId) async {
    final result = await _channel.invokeMethod('checkout', {'checkoutId': checkoutId});
    return result == 0;
  }
}
