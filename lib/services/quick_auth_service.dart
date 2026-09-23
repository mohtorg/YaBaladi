import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
class QuickAuthService {
 static const MethodChannel _channel=MethodChannel('ya_baladi/quick_auth');
 Future<bool> isDeviceSupported() async { if(kIsWeb)return false; return await _channel.invokeMethod<bool>('isDeviceSupported')??false; }
 Future<bool> isEnabled() async { if(kIsWeb)return false; return await _channel.invokeMethod<bool>('isEnabled')??false; }
 Future<void> setEnabled(bool enabled) async { if(kIsWeb)return; await _channel.invokeMethod<void>('setEnabled',{'enabled':enabled}); }
 Future<bool> authenticate() async { if(kIsWeb)return true; return await _channel.invokeMethod<bool>('authenticate')??false; }
}
