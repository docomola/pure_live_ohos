import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void ensureTestBindings() {
  TestWidgetsFlutterBinding.ensureInitialized();
}

void setMockMethodChannelHandler(
  MethodChannel channel,
  Future<dynamic> Function(MethodCall call)? handler,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, handler);
}

Future<dynamic> sendPlatformMethodCall(
  MethodChannel channel,
  MethodCall call,
) async {
  final codec = channel.codec ?? const StandardMethodCodec();
  dynamic result;
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    channel.name,
    codec.encodeMethodCall(call),
    (data) {
      if (data != null) {
        result = codec.decodeEnvelope(data);
      }
    },
  );
  return result;
}

Map<String, dynamic> mockCookieMap({
  String name = 'session',
  String value = 'abc',
}) {
  return {
    'name': name,
    'value': value,
    'expiresDate': null,
    'isSessionOnly': false,
    'domain': 'example.com',
    'sameSite': null,
    'isSecure': false,
    'isHttpOnly': false,
    'path': '/',
  };
}
