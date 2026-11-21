import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:flutter_inappwebview_example/call_async_javascript_example.screen.dart';
import 'package:flutter_inappwebview_example/chrome_safari_browser_example.screen.dart';
import 'package:flutter_inappwebview_example/content_blocker_example.screen.dart';
import 'package:flutter_inappwebview_example/find_interaction_validation.screen.dart';
import 'package:flutter_inappwebview_example/headless_in_app_webview.screen.dart';
import 'package:flutter_inappwebview_example/in_app_webiew_example.screen.dart';
import 'package:flutter_inappwebview_example/transparent_background_errors_example.screen.dart';
import 'package:flutter_inappwebview_example/in_app_browser_example.screen.dart';
import 'package:flutter_inappwebview_example/redirect_test_demo.dart';
import 'package:flutter_inappwebview_example/ssl_error_test.screen.dart';
import 'package:flutter_inappwebview_example/js_bridge_security_test.screen.dart';
import 'package:flutter_inappwebview_example/web_authentication_session_example.screen.dart';
import 'package:flutter_inappwebview_example/webview_push_pop_test.screen.dart';
import 'package:flutter_inappwebview_example/cookie_security_test.screen.dart';
import 'package:flutter_inappwebview_example/scheme_uri_test.screen.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:flutter_inappwebview_example/cookie_delete_validation.screen.dart';
import 'package:flutter_inappwebview_example/scroll_clamp_validation.screen.dart';
import 'package:flutter_inappwebview_example/custom_scheme_test.screen.dart';
import 'package:flutter_inappwebview_example/file_url_access_ab_test.screen.dart';
import 'package:flutter_inappwebview_example/sync_callback_test.screen.dart';
import 'package:flutter_inappwebview_example/console_message_level_test.screen.dart';
import 'package:flutter_inappwebview_example/hit_test_verification.screen.dart';
import 'package:flutter_inappwebview_example/web_message_channel_test.screen.dart';
import 'package:flutter_inappwebview_example/print_test.screen.dart';
import 'package:flutter_inappwebview_example/permission_test.screen.dart';
import 'package:flutter_inappwebview_example/async_post_test.screen.dart';
import 'package:flutter_inappwebview_example/keyboard_avoid_mode_test.screen.dart';
import 'package:flutter_inappwebview_example/custom_path_handler_vite_spa.screen.dart';

// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

final localhostServer = InAppLocalhostServer(documentRoot: 'assets');
WebViewEnvironment? webViewEnvironment;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Permission.camera.request();
  // await Permission.microphone.request();
  // await Permission.storage.request();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    assert(availableVersion != null,
        'Failed to find an installed WebView2 runtime or non-stable Microsoft Edge installation.');

    webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: 'custom_path'));
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(MyApp());
}

PointerInterceptor myDrawer({required BuildContext context}) {
  var children = [
    ListTile(
      title: Text('InAppWebView'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/');
      },
    ),
    ListTile(
      title: Text('InAppBrowser'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/InAppBrowser');
      },
    ),
    ListTile(
      title: Text('WebAuthenticationSession'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/WebAuthenticationSession');
      },
    ),
    ListTile(
      title: Text('HeadlessInAppWebView'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/HeadlessInAppWebView');
      },
    ),
    ListTile(
      title: Text('Redirection test'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/RedirectTest');
      },
    ),
    ListTile(
      title: Text('WebView Push/Pop Test'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/WebViewPushPopTest');
      },
    ),
    ListTile(
      title: Text('TransparentBackground & Errors'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/TransparentBackgroundErrors');
      },
    ),
    ListTile(
      title: Text('Content Blocker Demo'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/ContentBlocker');
      },
    ),
    ListTile(
      title: Text('CookieDeleteValidation'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/CookieDeleteValidation');
      },
    ),
    ListTile(
      title: Text('ScrollClampValidation'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/ScrollClampValidation');
      },
    ),
    ListTile(
      title: Text('FindInteractionValidation'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/FindInteractionValidation');
      },
    ),
    ListTile(
      title: Text('SSL Error Test'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/SslErrorTest');
       },
    ),
    ListTile(
      title: Text('CallAsyncJavaScript'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/CallAsyncJavaScript');
      },
    ),
    ListTile(
      title: Text('JSBridge Security Test'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/JSBridgeSecurityTest');
       },
    ),
    if (defaultTargetPlatform != TargetPlatform.ohos)
      ListTile(
        title: Text('Custom Scheme Test (Issue #98)', style: TextStyle(color: Colors.red)),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/CustomSchemeTest');
        },
      ),
    ListTile(
      title: Text('File URL Access A/B Test'),
      onTap: () {
        Navigator.pushReplacementNamed(context, '/FileUrlAccessABTest');
      },
    ),
    if (defaultTargetPlatform == TargetPlatform.ohos) ...[
      ListTile(
        title: Text('Cookie 安全校验测试'),
        subtitle: Text('RFC 6265 / MyCookieManager'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/CookieSecurityTest');
        },
      ),
      ListTile(
        title: Text('scheme uri.URI 测试'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/SchemeUriTest');
        },
      ),
      ListTile(
        title: Text('Custom Scheme Test (Issue #98)'),
        subtitle: Text('onLoadResourceWithCustomScheme'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/CustomSchemeTest');
        },
      ),
      ListTile(
        title: Text('Sync Callback 测试'),
        subtitle: Text('SyncBaseCallbackResultImpl'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/SyncCallbackTest');
        },
      ),
      ListTile(
        title: Text('ConsoleMessageLevel 测试'),
        subtitle: Text('OHOS MessageLevel 映射校验'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/ConsoleMessageLevelTest');
        },
      ),
      ListTile(
        title: Text('HitTest Verification'),
        subtitle: Text('requestFocusNodeHref / requestImageRef / getHitTestResult'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/HitTestVerification');
        },
      ),
      ListTile(
        title: Text('WebMessageChannel 测试'),
        subtitle: Text('createWebMessageChannel 验证'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/WebMessageChannelTest');
        },
      ),
      ListTile(
        title: Text('Print 打印测试'),
        subtitle: Text('printCurrentPage / PrintJobController'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/PrintTest');
        },
      ),
      ListTile(
        title: Text('Permission 权限测试'),
        subtitle: Text('onPermissionRequest 回调验证'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/PermissionTest');
        },
      ),
      ListTile(
        title: Text('Async POST (fetch) 测试'),
        subtitle: Text('fetch POST / assets/async_post_test.html'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/AsyncPostTest');
        },
      ),
      ListTile(
        title: Text('软键盘避让 RESIZE_VISUAL'),
        subtitle: Text('WebKeyboardAvoidMode 默认行为验证'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/KeyboardAvoidModeTest');
        },
      ),
      ListTile(
        title: Text('CustomPathHandler Vite SPA'),
        subtitle: Text('Issue #327：ES module + SVG 经 CustomPathHandler 加载'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/CustomPathHandlerViteSpa');
        },
      ),
    ],
  ];
  if (kIsWeb) {
    children = [
      ListTile(
        title: Text('InAppWebView'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/');
        },
      )
    ];
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    children = [
      ListTile(
        title: Text('InAppWebView'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/');
        },
      ),
      ListTile(
        title: Text('InAppBrowser'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/InAppBrowser');
        },
      ),
      ListTile(
        title: Text('WebAuthenticationSession'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/WebAuthenticationSession');
        },
      ),
      ListTile(
        title: Text('HeadlessInAppWebView'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/HeadlessInAppWebView');
        },
      ),
      ListTile(
        title: Text('WebView Push/Pop Test'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/WebViewPushPopTest');
        },
      ),
      ListTile(
        title: Text('File URL Access A/B Test'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/FileUrlAccessABTest');
        },
      ),
    ];
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    children = [
      ListTile(
        title: Text('InAppWebView'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/');
        },
      ),
      ListTile(
        title: Text('InAppBrowser'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/InAppBrowser');
        },
      ),
      ListTile(
        title: Text('HeadlessInAppWebView'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/HeadlessInAppWebView');
        },
      ),
      ListTile(
        title: Text('WebView Push/Pop Test'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/WebViewPushPopTest');
        },
      ),
      ListTile(
        title: Text('File URL Access A/B Test'),
        onTap: () {
          Navigator.pushReplacementNamed(context, '/FileUrlAccessABTest');
        },
      ),
    ];
  }

  return PointerInterceptor(
    child: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('flutter_inappwebview example'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ...children
        ],
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp(initialRoute: '/', routes: {
        '/': (context) => InAppWebViewExampleScreen(),
      });
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return MaterialApp(initialRoute: '/', routes: {
        '/': (context) => InAppWebViewExampleScreen(),
        '/InAppBrowser': (context) => InAppBrowserExampleScreen(),
        '/HeadlessInAppWebView': (context) =>
            HeadlessInAppWebViewExampleScreen(),
        '/WebAuthenticationSession': (context) =>
            WebAuthenticationSessionExampleScreen(),
        '/RedirectTest': (context) => RedirectTestScreen(),
        '/WebViewPushPopTest': (context) => const WebViewPushPopTestScreen(),
        '/ContentBlocker': (context) => const ContentBlockerExampleScreen(),
        '/FileUrlAccessABTest': (context) => FileUrlAccessABTestScreen(),
      });
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return MaterialApp(initialRoute: '/', routes: {
        '/': (context) => InAppWebViewExampleScreen(),
        '/InAppBrowser': (context) => InAppBrowserExampleScreen(),
        '/HeadlessInAppWebView': (context) =>
            HeadlessInAppWebViewExampleScreen(),
        '/RedirectTest': (context) => RedirectTestScreen(),
        '/WebViewPushPopTest': (context) => const WebViewPushPopTestScreen(),
        '/FileUrlAccessABTest': (context) => FileUrlAccessABTestScreen(),
      });
    }
    return MaterialApp(initialRoute: '/', routes: {
      '/': (context) => InAppWebViewExampleScreen(),
      '/InAppBrowser': (context) => InAppBrowserExampleScreen(),
      '/ScrollClampValidation': (context) => ScrollClampValidationScreen(),
      '/FindInteractionValidation': (context) => FindInteractionValidationScreen(),
      '/HeadlessInAppWebView': (context) => HeadlessInAppWebViewExampleScreen(),
      '/CookieDeleteValidation': (context) => CookieDeleteValidationScreen(),
      '/SslErrorTest': (context) => SslErrorTestScreen(),
      '/WebAuthenticationSession': (context) =>
          WebAuthenticationSessionExampleScreen(),
      '/RedirectTest': (context) => RedirectTestScreen(),
      '/WebViewPushPopTest': (context) => const WebViewPushPopTestScreen(),
      '/TransparentBackgroundErrors': (context) =>
          TransparentBackgroundErrorsExampleScreen(),
      '/ContentBlocker': (context) => const ContentBlockerExampleScreen(),
      '/CallAsyncJavaScript': (context) => CallAsyncJavaScriptExampleScreen(),
      '/JSBridgeSecurityTest': (context) => JSBridgeSecurityTestScreen(),
      '/CookieSecurityTest': (context) => CookieSecurityTestScreen(),
      '/SchemeUriTest': (context) => SchemeUriTestScreen(),
      '/CustomSchemeTest': (context) => CustomSchemeTestScreen(),
      '/FileUrlAccessABTest': (context) => FileUrlAccessABTestScreen(),
      '/SyncCallbackTest': (context) => SyncCallbackTestScreen(),
      '/ConsoleMessageLevelTest': (context) => ConsoleMessageLevelTestScreen(),
      '/HitTestVerification': (context) => HitTestVerificationScreen(),
      '/WebMessageChannelTest': (context) => WebMessageChannelTestScreen(),
      '/PrintTest': (context) => PrintTestScreen(),
      '/PermissionTest': (context) => PermissionTestScreen(),
      '/AsyncPostTest': (context) => AsyncPostTestScreen(),
      '/KeyboardAvoidModeTest': (context) => const KeyboardAvoidModeTestScreen(),
      '/CustomPathHandlerViteSpa': (context) =>
          const CustomPathHandlerViteSpaScreen(),
    });
  }
}