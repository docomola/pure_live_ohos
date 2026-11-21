/// 测试用 URL 与本地 HTML 字符串集合
///
/// 集中维护所有 Demo 中用到的测试地址、HTML 字符串和 data URI，
/// 便于在网络环境变化时统一更换。

/// 默认起始页（OpenHarmony 官网）
const String kHomeUrl = 'https://www.openharmony.cn/';

/// 备用 HTTPS 站点
const String kFlutterDevUrl = 'https://flutter.dev/';

/// 空白页（用于 reset/清屏）
const String kBlankUrl = 'about:blank';

/// 一段简短自包含 HTML，包含按钮、控制台输出、JS 调用、图片
const String kSampleHtml = '''
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Demo Sample Page</title>
  <style>
    body { font-family: sans-serif; padding: 16px; }
    button { font-size: 16px; padding: 8px 12px; margin: 4px 0; }
    #output { white-space: pre; background: #f4f4f4; padding: 8px; }
  </style>
</head>
<body>
  <h2>Flutter InAppWebView Sample</h2>
  <p>这是一份用于测试的本地 HTML。</p>
  <button onclick="console.log('hello from console')">触发 console.log</button>
  <button onclick="alert('Hello from alert')">触发 alert</button>
  <button onclick="confirm('Are you sure?')">触发 confirm</button>
  <button onclick="prompt('Enter your name', 'Tom')">触发 prompt</button>
  <button onclick="document.title = 'Title-' + Date.now()">变更 title</button>
  <button onclick="window.scrollTo(0, 800)">触发滚动</button>
  <a href="https://www.openharmony.cn/">跳转 OpenHarmony</a>
  <div id="output">DOM ready.</div>
  <script>
    document.getElementById('output').textContent =
      'UA: ' + navigator.userAgent + '\\nlocation: ' + location.href;
  </script>
</body>
</html>
''';

/// 一段长内容 HTML，便于测试滚动 / 缩放 / pull-to-refresh
String buildLongHtml({int paragraphs = 50}) {
  final buf = StringBuffer()
    ..writeln('<!DOCTYPE html><html><head>')
    ..writeln('<meta charset="utf-8"/>')
    ..writeln('<meta name="viewport" content="width=device-width,initial-scale=1"/>')
    ..writeln('<title>Long Page</title></head><body>')
    ..writeln('<h1>Long Content</h1>');
  for (int i = 0; i < paragraphs; i++) {
    buf.writeln('<p id="p$i">Paragraph #$i — Lorem ipsum dolor sit amet.</p>');
  }
  buf.writeln('</body></html>');
  return buf.toString();
}

/// 含表单提交的 HTML（用于测试 onFormResubmission / shouldOverrideUrlLoading）
const String kFormHtml = '''
<!DOCTYPE html>
<html><body>
  <form action="https://www.openharmony.cn/" method="get">
    <input type="text" name="q" value="hello" />
    <input type="submit" value="提交" />
  </form>
</body></html>
''';

/// 含外链下载的简单 HTML
const String kDownloadHtml = '''
<!DOCTYPE html>
<html><body>
  <a download href="data:text/plain;charset=utf-8,Hello%20from%20InAppWebView">
    点我下载 hello.txt
  </a>
</body></html>
''';
