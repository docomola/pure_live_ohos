part of 'main.dart';

void clearProxyOverride() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTest('clearProxyOverride', () async {
    var proxyAvailable =
        await WebViewFeature.isFeatureSupported(WebViewFeature.PROXY_OVERRIDE);

    if (!proxyAvailable) {
      return;
    }

    ProxyController proxyController = ProxyController.instance();

    await proxyController.setProxyOverride(
        settings: ProxySettings(
      proxyRules: [ProxyRule(url: "${environment["NODE_SERVER_IP"]}:8083")],
    ));
    await expectLater(proxyController.clearProxyOverride(), completes);
  }, skip: shouldSkip);
}
