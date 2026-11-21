import 'dart:async';



import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter_test/flutter_test.dart';

import '../constants.dart';

import '../util.dart';

import '../env.dart';



part 'credentials.dart';



void main() {

  final shouldSkip = kIsWeb

      ? true

      : ![

          TargetPlatform.android,

          TargetPlatform.iOS,

          TargetPlatform.macOS,

          TargetPlatform.ohos,

        ].contains(defaultTargetPlatform);



  skippableGroup('HttpAuthCredentialDatabase', () {

    credentials();

  }, skip: shouldSkip);

}

