import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../constants.dart';
import '../util.dart';

void main() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  skippableGroup('WebAuthenticationSession', () {
    skippableTest('id, callbackURLScheme, canStart, isAvailable, dispose',
        () async {
      final isAvailable = await WebAuthenticationSession.isAvailable();
      expect(isAvailable, isA<bool>());

      final session = await WebAuthenticationSession.create(
        url: TEST_CROSS_PLATFORM_URL_1,
        callbackURLScheme: 'testscheme',
        onComplete: (url, error) async {},
      );

      expect(session.id, isNotEmpty);
      expect(session.callbackURLScheme, 'testscheme');
      expect(await session.canStart(), isA<bool>());

      await expectLater(session.dispose(), completes);
    });
  }, skip: shouldSkip);
}
