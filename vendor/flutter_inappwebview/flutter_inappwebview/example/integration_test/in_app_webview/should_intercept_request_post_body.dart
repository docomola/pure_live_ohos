part of 'main.dart';

/// 加固用例：shouldInterceptRequest 拦截机制下，POST/PUT/PATCH 请求 body 不丢失。
///
/// 背景：鸿蒙 ArkWeb 的 onInterceptRequest 回调中，WebResourceRequest 不暴露
/// getHttpBodyStream 接口，异步化（deferred response）后 Dart 返回 null 时，
/// fetchOriginalResource 用 @ohos.net.http 重发请求会丢失 body。
/// 修复方案（a3c0c09a）：POST/PUT/PATCH 改用 WebSchemeHandler 路径读取 body。
///
/// 本组用例验证：
/// 1. POST + shouldInterceptRequest 返回 null → 服务端回显 body 完整
/// 2. POST + shouldInterceptRequest 返回自定义响应 → 页面展示自定义内容
/// 3. PUT / PATCH + 返回 null → 服务端回显 body 完整
/// 4. FormData / 大体积 body + 返回 null → body 完整无截断
/// 5. 跨域 OPTIONS 预检 → 正式请求 body 不丢
///
/// 页面加载说明：测试页面由本地 Node 服务器提供（/test-post-body-page），
/// 用 initialUrlRequest 加载而不是 initialData，避免 data: 源被
/// useShouldInterceptRequest 拦截后 fallback 失败（Cannot fetch non-http
/// local resource）导致页面 JS 不执行。跨域预检用例从独立端口 8084 加载页面，
/// 使其与 8082 目标源不同以触发 OPTIONS 预检。
void shouldInterceptRequestPostBody() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  final ip = environment["NODE_SERVER_IP"];
  final postUrl = "http://$ip:8082/test-ajax-post";
  final echoUrl = "http://$ip:8082/test-echo-body";
  final page8082 = "http://$ip:8082/test-post-body-page";
  final page8084 = "http://$ip:8084/test-post-body-page";

  /// 构建服务器测试页面 URL。
  /// [pageOrigin] 页面地址（8082 同源 / 8084 跨域）；
  /// [target] 页面内 fetch 的目标 URL；[method] 请求方法；
  /// [bodyType] body 类型 json/formdata/large；[size] large 类型 body 字节数；
  /// [preflight] 是否追加自定义头触发跨域预检。
  String buildPageUrl(
    String pageOrigin,
    String target, {
    String method = 'POST',
    String bodyType = 'json',
    int size = 1048576,
    bool preflight = false,
  }) {
    final query = StringBuffer(
        'method=$method&target=${Uri.encodeComponent(target)}&bodyType=$bodyType');
    if (bodyType == 'large') {
      query.write('&size=$size');
    }
    if (preflight) {
      query.write('&preflight=1');
    }
    return '$pageOrigin?$query';
  }

  /// 等待 [completer] 完成并返回，超过 [timeout] 抛超时错误（用于诊断而非断言）。
  Future<T> waitWithTimeout<T>(Completer<T> completer,
      {Duration timeout = const Duration(seconds: 45)}) {
    return completer.future.timeout(timeout);
  }

  skippableGroup('shouldInterceptRequest POST body', () {
    skippableTestWidgets('POST + return null keeps body',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<Map<String, dynamic>> resultCompleter =
          Completer<Map<String, dynamic>>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldInterceptRequest: true,
            ),
            initialUrlRequest: URLRequest(
                url: WebUri(buildPageUrl(page8082, postUrl))),
            onWebViewCreated: (controller) {
              // WebView 平台视图在测试结束/重建时可能重复触发回调，
              // 用 isCompleted 保护避免重复 complete 抛异常。
              if (!controllerCompleter.isCompleted) {
                controllerCompleter.complete(controller);
              }
              controller.addJavaScriptHandler(
                  handlerName: "postResult",
                  callback: (args) {
                    // 页面在测试结束/WebView 重建时可能再次回调，
                    // 忽略已完成的 completer，避免重复 complete 抛异常。
                    if (resultCompleter.isCompleted) {
                      return;
                    }
                    final value = args[0];
                    if (value is Map<String, dynamic>) {
                      resultCompleter.complete(value);
                    } else {
                      resultCompleter.completeError(
                          StateError("unexpected result: $value"));
                    }
                  });
            },
            shouldInterceptRequest: (controller, request) async {
              // 模拟 Dart 层异步判断后返回 null（不拦截），验证 fallback 重发时 body 不丢。
              await Future.delayed(const Duration(milliseconds: 500));
              return null;
            },
          ),
        ),
      );

      await controllerCompleter.future;
      final result = await waitWithTimeout(resultCompleter);

      expect(
          mapEquals(result, {'firstname': 'Foo', 'lastname': 'Bar'}), true);
    });

    skippableTestWidgets('POST + custom response from Dart',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<Map<String, dynamic>> resultCompleter =
          Completer<Map<String, dynamic>>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldInterceptRequest: true,
            ),
            initialUrlRequest: URLRequest(
                url: WebUri(buildPageUrl(page8082, postUrl))),
            onWebViewCreated: (controller) {
              // WebView 平台视图在测试结束/重建时可能重复触发回调，
              // 用 isCompleted 保护避免重复 complete 抛异常。
              if (!controllerCompleter.isCompleted) {
                controllerCompleter.complete(controller);
              }
              controller.addJavaScriptHandler(
                  handlerName: "postResult",
                  callback: (args) {
                    // 页面在测试结束/WebView 重建时可能再次回调，
                    // 忽略已完成的 completer，避免重复 complete 抛异常。
                    if (resultCompleter.isCompleted) {
                      return;
                    }
                    final value = args[0];
                    if (value is Map<String, dynamic>) {
                      resultCompleter.complete(value);
                    } else {
                      resultCompleter.completeError(
                          StateError("unexpected result: $value"));
                    }
                  });
            },
            shouldInterceptRequest: (controller, request) async {
              // Dart 直接返回自定义响应，验证拦截替换路径功能正常。
              return WebResourceResponse(
                contentType: 'application/json',
                contentEncoding: 'utf-8',
                data: Uint8List.fromList(
                    utf8.encode('{"firstname": "Foo2", "lastname": "Bar2"}')),
                statusCode: 200,
                reasonPhrase: 'OK',
              );
            },
          ),
        ),
      );

      await controllerCompleter.future;
      final result = await waitWithTimeout(resultCompleter);

      expect(
          mapEquals(result, {'firstname': 'Foo2', 'lastname': 'Bar2'}), true);
    });

    skippableTestWidgets('PUT / PATCH + return null keeps body',
        (WidgetTester tester) async {
      // 分别用 PUT / PATCH 各发一次，验证服务端均收到完整 body。
      for (final method in ['PUT', 'PATCH']) {
        // 每轮新建 completer，避免复用上一轮已完成的 completer 导致
        // await 立即返回旧结果。
        final Completer<InAppWebViewController> controllerCompleter =
            Completer<InAppWebViewController>();
        final Completer<Map<String, dynamic>> resultCompleter =
            Completer<Map<String, dynamic>>();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: InAppWebView(
              key: GlobalKey(),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldInterceptRequest: true,
              ),
              initialUrlRequest: URLRequest(
                  url: WebUri(
                      buildPageUrl(page8082, postUrl, method: method))),
              onWebViewCreated: (controller) {
                controllerCompleter.complete(controller);
                controller.addJavaScriptHandler(
                    handlerName: "postResult",
                    callback: (args) {
                      final value = args[0];
                      if (value is Map<String, dynamic>) {
                        resultCompleter.complete(value);
                      } else {
                        resultCompleter.completeError(
                            StateError("unexpected result: $value"));
                      }
                    });
              },
              shouldInterceptRequest: (controller, request) async {
                await Future.delayed(const Duration(milliseconds: 500));
                return null;
              },
            ),
          ),
        );

        await controllerCompleter.future;
        final result = await waitWithTimeout(resultCompleter);

        expect(result['method'], method);
        expect(
            mapEquals(result,
                {'method': method, 'firstname': 'Foo', 'lastname': 'Bar'}),
            true);
      }
    });

    skippableTestWidgets('FormData + return null keeps body',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<Map<String, dynamic>> resultCompleter =
          Completer<Map<String, dynamic>>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldInterceptRequest: true,
            ),
            initialUrlRequest: URLRequest(
                url: WebUri(buildPageUrl(page8082, postUrl,
                    bodyType: 'formdata'))),
            onWebViewCreated: (controller) {
              // WebView 平台视图在测试结束/重建时可能重复触发回调，
              // 用 isCompleted 保护避免重复 complete 抛异常。
              if (!controllerCompleter.isCompleted) {
                controllerCompleter.complete(controller);
              }
              controller.addJavaScriptHandler(
                  handlerName: "postResult",
                  callback: (args) {
                    // 页面在测试结束/WebView 重建时可能再次回调，
                    // 忽略已完成的 completer，避免重复 complete 抛异常。
                    if (resultCompleter.isCompleted) {
                      return;
                    }
                    final value = args[0];
                    if (value is Map<String, dynamic>) {
                      resultCompleter.complete(value);
                    } else {
                      resultCompleter.completeError(
                          StateError("unexpected result: $value"));
                    }
                  });
            },
            shouldInterceptRequest: (controller, request) async {
              await Future.delayed(const Duration(milliseconds: 500));
              return null;
            },
          ),
        ),
      );

      await controllerCompleter.future;
      final result = await waitWithTimeout(resultCompleter);

      expect(
          mapEquals(result, {'firstname': 'Foo', 'lastname': 'Bar'}), true);
    });

    skippableTestWidgets('large body + return null keeps body',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<Map<String, dynamic>> resultCompleter =
          Completer<Map<String, dynamic>>();

      // 大于 http 默认限制（100KB）的 body，验证分块读取与透传无截断。
      const largeSize = 1024 * 1024; // 1MB
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldInterceptRequest: true,
            ),
            initialUrlRequest: URLRequest(
                url: WebUri(buildPageUrl(page8082, echoUrl,
                    method: 'POST', bodyType: 'large', size: largeSize))),
            onWebViewCreated: (controller) {
              // WebView 平台视图在测试结束/重建时可能重复触发回调，
              // 用 isCompleted 保护避免重复 complete 抛异常。
              if (!controllerCompleter.isCompleted) {
                controllerCompleter.complete(controller);
              }
              controller.addJavaScriptHandler(
                  handlerName: "postResult",
                  callback: (args) {
                    // 页面在测试结束/WebView 重建时可能再次回调，
                    // 忽略已完成的 completer，避免重复 complete 抛异常。
                    if (resultCompleter.isCompleted) {
                      return;
                    }
                    final value = args[0];
                    if (value is Map<String, dynamic>) {
                      resultCompleter.complete(value);
                    } else {
                      resultCompleter.completeError(
                          StateError("unexpected result: $value"));
                    }
                  });
            },
            shouldInterceptRequest: (controller, request) async {
              await Future.delayed(const Duration(milliseconds: 500));
              return null;
            },
          ),
        ),
      );

      await controllerCompleter.future;
      final result = await waitWithTimeout(resultCompleter);

      expect(result['method'], 'POST');
      // 服务端回显的 body 是解析后的 JSON 对象，bodyLength 由服务端按序列化长度统计，
      // 这里验证接收到了完整的 1MB 数据（body.data 长度一致）。
      expect(result['body']['data'] is String, true);
      expect((result['body']['data'] as String).length, largeSize);
    });

    skippableTestWidgets('cross-origin POST preflight then body',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<Map<String, dynamic>> resultCompleter =
          Completer<Map<String, dynamic>>();

      // 页面从独立端口 8084 加载（源 http://<ip>:8084），fetch 目标为 8082（跨域），
      // 且带自定义头 X-Requested-With，会触发 OPTIONS 预检，预检通过后
      // 正式 POST 请求 body 不应丢失。
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldInterceptRequest: true,
            ),
            initialUrlRequest: URLRequest(
                url: WebUri(buildPageUrl(page8084, postUrl,
                    preflight: true))),
            onWebViewCreated: (controller) {
              // WebView 平台视图在测试结束/重建时可能重复触发回调，
              // 用 isCompleted 保护避免重复 complete 抛异常。
              if (!controllerCompleter.isCompleted) {
                controllerCompleter.complete(controller);
              }
              controller.addJavaScriptHandler(
                  handlerName: "postResult",
                  callback: (args) {
                    // 页面在测试结束/WebView 重建时可能再次回调，
                    // 忽略已完成的 completer，避免重复 complete 抛异常。
                    if (resultCompleter.isCompleted) {
                      return;
                    }
                    final value = args[0];
                    if (value is Map<String, dynamic>) {
                      resultCompleter.complete(value);
                    } else {
                      resultCompleter.completeError(
                          StateError("unexpected result: $value"));
                    }
                  });
            },
            shouldInterceptRequest: (controller, request) async {
              await Future.delayed(const Duration(milliseconds: 500));
              return null;
            },
          ),
        ),
      );

      await controllerCompleter.future;
      final result = await waitWithTimeout(resultCompleter);

      expect(
          mapEquals(result, {'firstname': 'Foo', 'lastname': 'Bar'}), true);
    });

    skippableTestWidgets('private GET subresource + custom response from Dart',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<Map<String, dynamic>> resultCompleter =
          Completer<Map<String, dynamic>>();

      // 页面从 8082 加载（私网 main frame 导航不回调 Dart，页面正常加载），
      // 页面内发起同源 GET fetch（私网 GET 子资源）。验证与 Android/iOS 对齐后，
      // 私网 GET 子资源也会回调 Dart，且 Dart 返回的自定义响应能生效。
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldInterceptRequest: true,
            ),
            initialUrlRequest: URLRequest(
                url: WebUri(
                    buildPageUrl(page8082, echoUrl, method: 'GET'))),
            onWebViewCreated: (controller) {
              // WebView 平台视图在测试结束/重建时可能重复触发回调，
              // 用 isCompleted 保护避免重复 complete 抛异常。
              if (!controllerCompleter.isCompleted) {
                controllerCompleter.complete(controller);
              }
              controller.addJavaScriptHandler(
                  handlerName: "postResult",
                  callback: (args) {
                    // 页面在测试结束/WebView 重建时可能再次回调，
                    // 忽略已完成的 completer，避免重复 complete 抛异常。
                    if (resultCompleter.isCompleted) {
                      return;
                    }
                    final value = args[0];
                    if (value is Map<String, dynamic>) {
                      resultCompleter.complete(value);
                    } else {
                      resultCompleter.completeError(
                          StateError("unexpected result: $value"));
                    }
                  });
            },
            shouldInterceptRequest: (controller, request) async {
              // 仅对 GET 子资源返回自定义响应；main frame 页面加载（私网导航）
              // 不回调 Dart，不会走到这里。
              if (request.method == 'GET') {
                return WebResourceResponse(
                  contentType: 'application/json',
                  contentEncoding: 'utf-8',
                  data: Uint8List.fromList(
                      utf8.encode('{"firstname": "Foo2", "lastname": "Bar2"}')),
                  statusCode: 200,
                  reasonPhrase: 'OK',
                );
              }
              return null;
            },
          ),
        ),
      );

      await controllerCompleter.future;
      final result = await waitWithTimeout(resultCompleter);

      expect(
          mapEquals(result, {'firstname': 'Foo2', 'lastname': 'Bar2'}), true);
    });
  }, skip: shouldSkip);
}
