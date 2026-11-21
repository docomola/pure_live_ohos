part of 'main.dart';

void serverProperties(InAppLocalhostServer localhostServer) {
  skippableTest('port, directoryIndex, documentRoot, shared, start, close',
      () async {
    expect(localhostServer.port, 8080);
    expect(localhostServer.directoryIndex, 'index.html');
    expect(localhostServer.documentRoot, './');
    expect(localhostServer.shared, isFalse);
    expect(localhostServer.isRunning(), isTrue);

    final customServer = InAppLocalhostServer(
      port: 8081,
      directoryIndex: 'index.html',
      documentRoot: './',
      shared: false,
    );
    await customServer.start();
    expect(customServer.port, 8081);
    expect(customServer.isRunning(), isTrue);
    await customServer.close();
    expect(customServer.isRunning(), isFalse);
  });
}
