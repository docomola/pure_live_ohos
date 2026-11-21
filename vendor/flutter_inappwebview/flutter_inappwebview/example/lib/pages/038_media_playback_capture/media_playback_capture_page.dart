/// Demo 038: 媒体播放暂停控制
///
/// 对应用例覆盖度报告：严重缺失的核心功能 Demo：
///   - setAllMediaPlaybackSuspended() - 媒体播放暂停控制
///   - closeAllMediaPresentations() - 关闭媒体展示
///   - requestMediaPlaybackState() - 请求媒体播放状态
///   - getCameraCaptureState / setCameraCaptureState (OHOS/Android 均不支持)
///   - getMicrophoneCaptureState / setMicrophoneCaptureState (OHOS/Android 均不支持)
///
/// 本页加载一个含音频播放和视频元素的 HTML，演示前 3 个媒体控制 API。
/// 后 4 个 camera/mic API 平台不支持，点击时预期抛出 UnimplementedError。

import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../common/event_log_panel.dart';
import '../../common/test_button.dart';

const String _kTag = 'InAppWebView_MediaPlaybackCapture';

const String _kMediaHtml = '''
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Media Demo</title>
  <style>
    body { font-family: sans-serif; padding: 16px; }
    button { font-size: 14px; padding: 6px 12px; margin: 4px; }
    #status { background: #f4f4f4; padding: 8px; margin: 8px 0; }
    video { width: 100%; max-width: 100%; height: auto; }
  </style>
</head>
<body>
  <h2>媒体播放 Demo</h2>
  <p>先点击按钮触发媒体，再测试下方 API：</p>
  <button onclick="startAudio()">播放音频</button>
  <button onclick="pauseAudio()">暂停音频</button>
  <button onclick="stopAudio()">停止音频</button>
  <button onclick="playVideo()">播放视频</button>
  <div id="status">等待操作...</div>
  <div id="mediaContainer">
    <video id="videoPlayer" controls width="100%" style="max-width:100%;height:auto;margin-top:8px">
      <source src="https://www.w3schools.com/html/mov_bbb.mp4" type="video/mp4">
    </video>
  </div>
  <audio id="audioPlayer" src="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"></audio>
  <script>
    const statusDiv = document.getElementById('status');
    function setStatus(msg) { statusDiv.textContent = msg; }

    function startAudio() {
      const audio = document.getElementById('audioPlayer');
      audio.play().then(function() { setStatus('音频播放中...'); })
        .catch(function(e) { setStatus('音频播放失败: ' + e.message); });
    }
    function pauseAudio() {
      document.getElementById('audioPlayer').pause();
      setStatus('音频已暂停');
    }
    function stopAudio() {
      const audio = document.getElementById('audioPlayer');
      audio.pause();
      audio.currentTime = 0;
      setStatus('音频已停止');
    }
    function playVideo() {
      const video = document.getElementById('videoPlayer');
      video.play().then(function() { setStatus('视频播放中...'); })
        .catch(function(e) { setStatus('视频播放失败: ' + e.message); });
    }
  </script>
</body>
</html>
''';

class MediaPlaybackCapturePage extends StatefulWidget {
  const MediaPlaybackCapturePage({super.key});

  @override
  State<MediaPlaybackCapturePage> createState() =>
      _MediaPlaybackCapturePageState();
}

class _MediaPlaybackCapturePageState extends State<MediaPlaybackCapturePage> {
  final EventLogController _logger = EventLogController();
  InAppWebViewController? _controller;

  @override
  void initState() {
    super.initState();
    dev.log('Page appeared', name: _kTag);
  }

  @override
  void dispose() {
    _logger.dispose();
    super.dispose();
  }

  // ---------- setAllMediaPlaybackSuspended ----------

  Future<Object?> _suspendAllMediaPlayback() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    await c.setAllMediaPlaybackSuspended(suspended: true);
    return '已暂停所有媒体播放 (suspended=true)';
  }

  Future<Object?> _resumeAllMediaPlayback() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    await c.setAllMediaPlaybackSuspended(suspended: false);
    return '已恢复所有媒体播放 (suspended=false)';
  }

  // ---------- closeAllMediaPresentations ----------

  Future<Object?> _closeAllMediaPresentations() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    await c.closeAllMediaPresentations();
    return '已调用 closeAllMediaPresentations';
  }

  // ---------- requestMediaPlaybackState ----------

  Future<Object?> _requestMediaPlaybackState() async {
    final c = _controller;
    if (c == null) return 'controller 未就绪';
    final state = await c.requestMediaPlaybackState();
    return '媒体播放状态: $state';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('[038] 媒体播放控制')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text(
                  '点页面上的按钮触发媒体，测试下方 API。',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: InAppWebView(
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      mediaPlaybackRequiresUserGesture: false,
                    ),
                    initialData: InAppWebViewInitialData(
                      data: _kMediaHtml,
                      mimeType: 'text/html',
                      encoding: 'utf-8',
                    ),
                    onWebViewCreated: (c) {
                      _controller = c;
                      _logger.log(_kTag, 'WebView created');
                    },
                    onLoadStop: (c, url) {
                      _logger.log(_kTag, 'onLoadStop: $url');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // 媒体播放暂停控制
                _sectionLabel('setAllMediaPlaybackSuspended'),
                AsyncTestButton(
                  label: '暂停所有媒体播放 (suspended=true)',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _suspendAllMediaPlayback,
                ),
                AsyncTestButton(
                  label: '恢复所有媒体播放 (suspended=false)',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _resumeAllMediaPlayback,
                ),
                const SizedBox(height: 8),
                // 关闭媒体展示
                _sectionLabel('closeAllMediaPresentations'),
                AsyncTestButton(
                  label: '关闭所有媒体展示',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _closeAllMediaPresentations,
                ),
                const SizedBox(height: 8),
                // 媒体播放状态
                _sectionLabel('requestMediaPlaybackState'),
                AsyncTestButton(
                  label: '获取媒体播放状态',
                  tag: _kTag,
                  logger: _logger,
                  onPressed: _requestMediaPlaybackState,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: EventLogPanel(controller: _logger, height: 180),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}