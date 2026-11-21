import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import '../constants.dart';
import '../util.dart';

part 'set_get_delete.dart';
part 'get_all_cookies.dart';

void main() {
  final shouldSkip = kIsWeb;

  skippableGroup('Cookie Manager', () {
    setGetDelete();
    getAllCookies();
  }, skip: shouldSkip);
}
