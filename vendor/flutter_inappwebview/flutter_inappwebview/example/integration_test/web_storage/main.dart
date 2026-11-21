import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import '../constants.dart';
import '../util.dart';

part 'local_session_storage.dart';
part 'web_storage_manager.dart';

void main() {
  final shouldSkip = kIsWeb;

  skippableGroup('Web Storage', () {
    localSessionStorage();
    webStorageManager();
  }, skip: shouldSkip);
}
