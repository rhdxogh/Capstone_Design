import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KmaRadarScreen extends StatefulWidget {
  final Color themeColor;

  const KmaRadarScreen({super.key, required this.themeColor});

  @override
  State<KmaRadarScreen> createState() => _KmaRadarScreenState();
}

class _KmaRadarScreenState extends State<KmaRadarScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 🌟 유저님이 직접 찾아주신 완벽한 최신 기상청 GIS 레이더 주소!
    final String radarUrl = 'https://www.weather.go.kr/wgis-nuri/html/map.html';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);

            // 혹시 모를 무한 로딩에 대비한 3초 안전장치
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _isLoading) setState(() => _isLoading = false);
            });
          },
          onPageFinished: (String url) {
            // 로딩이 완료되면 즉시 스피너 끄기
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('웹뷰 에러: ${error.description}');
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(radarUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '기상청 실시간 레이더',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _controller.reload();
              // 새로고침 시에도 3초 안전장치
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && _isLoading) setState(() => _isLoading = false);
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 웹뷰 화면
            WebViewWidget(controller: _controller),

            // 2. 로딩 스피너
            if (_isLoading)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CircularProgressIndicator(color: widget.themeColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
