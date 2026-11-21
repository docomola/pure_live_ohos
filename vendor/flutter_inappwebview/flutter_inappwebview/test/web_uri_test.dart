import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebUri', () {
    test('constructor should parse valid https URL', () {
      final uri = WebUri('https://example.com:8443/path?q=1#frag');

      expect(uri.rawValue, 'https://example.com:8443/path?q=1#frag');
      expect(uri.isValidUri, isTrue);
      expect(uri.scheme, 'https');
      expect(uri.host, 'example.com');
      expect(uri.port, 8443);
      expect(uri.path, '/path');
      expect(uri.query, 'q=1');
      expect(uri.fragment, 'frag');
      expect(uri.authority, 'example.com:8443');
      expect(uri.toString(), 'https://example.com:8443/path?q=1#frag');
    });

    test('WebUri.uri should preserve rawValue from Uri', () {
      final source = Uri.parse('https://flutter.dev/docs');
      final uri = WebUri.uri(source);

      expect(uri.rawValue, source.toString());
      expect(uri.uriValue, source);
      expect(uri.isValidUri, isTrue);
      expect(uri.host, 'flutter.dev');
      expect(uri.path, '/docs');
    });

    test('constructor should keep invalid URI as raw fallback', () {
      final uri = WebUri('intent://not:valid_uri');

      expect(uri.rawValue, 'intent://not:valid_uri');
      expect(uri.isValidUri, isFalse);
      expect(uri.uriValue.toString(), '');
      expect(uri.toString(), 'intent://not:valid_uri');
    });

    test('forceToStringRawValue should preserve custom host casing', () {
      final uri = WebUri('scheme://CustomHostValue');
      expect(uri.isValidUri, isTrue);
      expect(uri.toString(), 'scheme://customhostvalue');

      uri.forceToStringRawValue = true;
      expect(uri.toString(), 'scheme://CustomHostValue');
    });

    test('equality should compare rawValue and parsed uri', () {
      final first = WebUri('https://example.com');
      final second = WebUri('https://example.com');
      final third = WebUri('https://other.example.com');

      expect(first, equals(second));
      expect(first, isNot(equals(third)));
      expect(first.hashCode, equals(second.hashCode));
    });

    test('origin queryParameters and queryParametersAll should parse query',
        () {
      final uri = WebUri('https://example.com/path?a=1&b=2&a=3#frag');

      expect(uri.origin, 'https://example.com');
      expect(uri.queryParameters, {'a': '3', 'b': '2'});
      expect(uri.queryParametersAll, {
        'a': ['1', '3'],
        'b': ['2'],
      });
    });

    test('isScheme normalizePath and resolve should delegate to parsed uri',
        () {
      final uri = WebUri('https://example.com/base/path');

      expect(uri.isScheme('https'), isTrue);
      expect(uri.isScheme('http'), isFalse);
      expect(uri.normalizePath().path, '/base/path');
      expect(
        uri.resolve('other.html').toString(),
        'https://example.com/base/other.html',
      );
    });

    test('boolean URI properties should delegate to parsed uri', () {
      final uri = WebUri('https://example.com:8443/path?q=1');

      expect(uri.hasScheme, isTrue);
      expect(uri.hasAuthority, isTrue);
      expect(uri.hasPort, isTrue);
      expect(uri.hasQuery, isTrue);
      expect(uri.isAbsolute, isTrue);

      final withFragment = WebUri('https://example.com/path#frag');
      expect(withFragment.hasFragment, isTrue);

      final relative = WebUri('path/only');
      expect(relative.hasScheme, isFalse);
      expect(relative.hasAuthority, isFalse);
      expect(relative.hasPort, isFalse);
      expect(relative.hasQuery, isFalse);
      expect(relative.hasFragment, isFalse);
      expect(relative.isAbsolute, isFalse);
    });

    test('removeFragment replace resolveUri should delegate to parsed uri', () {
      final uri = WebUri('https://example.com/path?q=1#frag');

      expect(uri.removeFragment().fragment, isEmpty);
      expect(uri.removeFragment().toString(), 'https://example.com/path?q=1');
      expect(
        uri.replace(scheme: 'http', host: 'other.example.com').scheme,
        'http',
      );
      expect(
        uri.replace(scheme: 'http', host: 'other.example.com').host,
        'other.example.com',
      );
      expect(
        uri.resolveUri(WebUri('/other')).path,
        '/other',
      );
    });

    test('replace should cover optional userInfo queryParameters and path args',
        () {
      final uri = WebUri('https://example.com/old?q=1#frag');

      final withUserInfo = uri.replace(
        userInfo: 'alice:secret',
        host: 'api.example.com',
        port: 9443,
        path: '/v1/items',
        query: 'debug=1',
        fragment: 'section',
      );
      expect(withUserInfo.userInfo, 'alice:secret');
      expect(withUserInfo.host, 'api.example.com');
      expect(withUserInfo.port, 9443);
      expect(withUserInfo.path, '/v1/items');
      expect(withUserInfo.query, 'debug=1');
      expect(withUserInfo.fragment, 'section');
      expect(
        withUserInfo.toString(),
        contains('alice:secret@api.example.com:9443'),
      );

      final withQueryParameters = uri.replace(
        pathSegments: ['v2', 'users'],
        queryParameters: {'a': '1', 'b': '2'},
      );
      expect(withQueryParameters.pathSegments, ['v2', 'users']);
      expect(withQueryParameters.queryParameters, {'a': '1', 'b': '2'});
    });

    test('toFilePath should delegate to parsed uri', () {
      final uri = WebUri('file:///tmp/example.html');
      expect(uri.toFilePath(), contains('example.html'));
    });

    test('toFilePath should honor windows parameter', () {
      final uri = WebUri('file:///C:/Users/test/example.html');

      final posixPath = uri.toFilePath(windows: false);
      final windowsPath = uri.toFilePath(windows: true);

      expect(posixPath, contains('example.html'));
      expect(windowsPath, contains('example.html'));
      expect(windowsPath.contains(r'\'), isTrue);
      expect(posixPath.contains('/'), isTrue);
    });

    test('remaining Uri getters should delegate to parsed uri', () {
      final uri = WebUri('https://user:pass@example.com:8443/a/b?x=1#frag');

      expect(uri.hasAbsolutePath, isTrue);
      expect(uri.hasEmptyPath, isFalse);
      expect(uri.userInfo, 'user:pass');
      expect(uri.pathSegments, ['a', 'b']);
      expect(uri.data, isNull);

      final emptyPath = WebUri('https://example.com');
      expect(emptyPath.hasEmptyPath, isTrue);
    });

    test('data should expose UriData for data scheme URIs', () {
      final dataUri = WebUri('data:text/plain;charset=utf-8,hello');

      expect(dataUri.data, isNotNull);
      expect(dataUri.data!.mimeType, 'text/plain');
      expect(dataUri.data!.contentAsString(), 'hello');
      expect(dataUri.scheme, 'data');

      final httpsUri = WebUri('https://example.com');
      expect(httpsUri.data, isNull);
    });
  });
}
