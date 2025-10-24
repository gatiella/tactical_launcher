import 'package:flutter/services.dart';
import 'dart:async';

class BatteryService {
  static const platform = MethodChannel('com.tactical.launcher/battery');
  
  Future<int> getBatteryLevel() async {
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      return result;
    } on PlatformException catch (e) {
      print("Failed to get battery level: '${e.message}'.");
      return -1;
    }
  }
  
  Stream<int> get batteryLevelStream {
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getBatteryLevel();
    }).asyncMap((event) => event);
  }
}