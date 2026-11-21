import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_platform_interface/flutter_inappwebview_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_platforms.dart';
import 'helpers/test_platform.dart';

void main() {
  group('WebMessageChannel', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should wire id and ports', () {
      final port1 = WebMessagePort(index: 0);
      final port2 = WebMessagePort(index: 1);
      final channel = WebMessageChannel(id: 'ch-1', port1: port1, port2: port2);

      expect(channel.id, 'ch-1');
      expect(channel.port1, isA<WebMessagePort>());
      expect(channel.port2, isA<WebMessagePort>());
    });

    test('fromMap should restore channel when platform supports it', () {
      final restored = WebMessageChannel.fromMap({'id': 'mapped-channel'});
      expect(restored?.id, 'mapped-channel');
    });

    test('toString should delegate to platform', () {
      final fake = FakePlatformWebMessageChannel(id: 'ch-1');
      final channel = WebMessageChannel.fromPlatform(platform: fake);
      expect(channel.toString(), isNotEmpty);
    });

    test('dispose should delegate to platform', () {
      final fake = FakePlatformWebMessageChannel();
      final channel = WebMessageChannel.fromPlatform(platform: fake);
      channel.dispose();
      expect(fake.disposed, isTrue);
    });

    test('fromPlatform should expose id and ports', () {
      final fake = FakePlatformWebMessageChannel(id: 'ch-1');
      final channel = WebMessageChannel.fromPlatform(platform: fake);
      expect(channel.id, 'ch-1');
      expect(channel.port1, isA<WebMessagePort>());
      expect(channel.port2, isA<WebMessagePort>());
    });
  });

  group('WebMessagePort', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should create port from index', () {
      final port = WebMessagePort(index: 0);
      expect(port.platform.params.index, 0);
    });

    test('setWebMessageCallback should delegate to platform', () async {
      final fake = FakePlatformWebMessagePort(index: 0);
      final port = WebMessagePort.fromPlatform(platform: fake);
      await port.setWebMessageCallback((message) {});
      expect(port.platform, same(fake));
    });

    test('postMessage should delegate to platform', () async {
      final fake = FakePlatformWebMessagePort(index: 0);
      final port = WebMessagePort.fromPlatform(platform: fake);
      await port.postMessage(WebMessage(data: 'hello'));
      expect(port.platform, same(fake));
    });

    test('toMap and toJson should delegate to platform', () {
      final fake = FakePlatformWebMessagePort(index: 1);
      final port = WebMessagePort.fromPlatform(platform: fake);
      expect(port.toMap()['index'], 1);
      expect(port.toJson()['index'], 1);
    });

    test('close should delegate to platform', () async {
      final fake = FakePlatformWebMessagePort();
      final port = WebMessagePort.fromPlatform(platform: fake);
      await port.close();
      expect(fake.closed, isTrue);
    });
  });

  group('WebMessage', () {
    test('fromMap should restore string message', () {
      final message = WebMessage.fromMap({
        'data': 'hello',
        'type': WebMessageType.STRING.toNativeValue(),
      });

      expect(message?.data, 'hello');
      expect(message?.type, WebMessageType.STRING);
    });

    test('toMap and toString should expose payload', () {
      final message = WebMessage(data: 'hello');
      final map = message.toMap();

      expect(map['data'], 'hello');
      expect(map['type'], WebMessageType.STRING.toNativeValue());
      expect(message.toString(), contains('hello'));
    });

    test('should accept array buffer payload', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final message = WebMessage(
        data: bytes,
        type: WebMessageType.ARRAY_BUFFER,
      );

      expect(message.data, bytes);
      expect(message.type, WebMessageType.ARRAY_BUFFER);
    });
  });

  group('WebMessageListener', () {
    InAppWebViewPlatform? previousPlatform;

    setUp(() {
      previousPlatform = InAppWebViewPlatform.instance;
      installFakeInAppWebViewPlatform();
    });

    tearDown(() {
      restoreInAppWebViewPlatform(previousPlatform);
    });

    test('constructor should expose jsObjectName and onPostMessage callback',
        () {
      WebMessage? receivedMessage;
      final listener = WebMessageListener(
        jsObjectName: 'FlutterBridge',
        allowedOriginRules: {'https://example.com'},
        onPostMessage: (message, sourceOrigin, isMainFrame, replyProxy) {
          receivedMessage = message;
        },
      );

      expect(listener.jsObjectName, 'FlutterBridge');
      expect(listener.allowedOriginRules, {'https://example.com'});
      expect(listener.onPostMessage, isNotNull);
      listener.onPostMessage?.call(
        WebMessage(data: 'hello'),
        WebUri('https://example.com'),
        true,
        FakePlatformJavaScriptReplyProxy(
          FakePlatformWebMessageListener(),
        ),
      );
      expect(receivedMessage?.data, 'hello');
    });

    test('dispose should delegate to platform', () {
      final fake = FakePlatformWebMessageListener(
        allowedOriginRules: {'https://example.com'},
      );
      final listener = WebMessageListener.fromPlatform(platform: fake);
      expect(listener.allowedOriginRules, {'https://example.com'});
      listener.dispose();
      expect(fake.disposed, isTrue);
    });
  });
}
