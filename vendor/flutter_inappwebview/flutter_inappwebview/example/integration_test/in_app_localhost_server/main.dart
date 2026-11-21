import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import '../util.dart';

part 'load_asset_file.dart';
part 'server_properties.dart';

void main() {
  final shouldSkip = kIsWeb;

  skippableGroup('InAppLocalhostServer', () {
    final InAppLocalhostServer localhostServer = InAppLocalhostServer();

    setUpAll(() async {
      await localhostServer.start();
    });

    serverProperties(localhostServer);
    loadAssetFile(localhostServer);

    tearDownAll(() async {
      await localhostServer.close();
    });
  }, skip: shouldSkip);
}
