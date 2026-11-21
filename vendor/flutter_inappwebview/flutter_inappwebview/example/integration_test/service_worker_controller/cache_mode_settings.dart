part of 'main.dart';

void cacheModeSettings() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.ohos,
        ].contains(defaultTargetPlatform);

  skippableTest('get/set AllowContentAccess, AllowFileAccess, CacheMode',
      () async {
    var swAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.SERVICE_WORKER_BASIC_USAGE);

    if (!swAvailable) {
      return;
    }

    await ServiceWorkerController.setAllowContentAccess(true);
    expect(await ServiceWorkerController.getAllowContentAccess(), isTrue);

    await ServiceWorkerController.setAllowFileAccess(true);
    expect(await ServiceWorkerController.getAllowFileAccess(), isTrue);

    await ServiceWorkerController.setCacheMode(CacheMode.LOAD_DEFAULT);
    expect(await ServiceWorkerController.getCacheMode(),
        CacheMode.LOAD_DEFAULT);

    await ServiceWorkerController.setCacheMode(CacheMode.LOAD_NO_CACHE);
    expect(await ServiceWorkerController.getCacheMode(),
        CacheMode.LOAD_NO_CACHE);
  }, skip: shouldSkip);
}
