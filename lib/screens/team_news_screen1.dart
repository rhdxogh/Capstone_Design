import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_article.dart';
import '../services/news_service.dart';
import '../widgets/news_article_tile.dart';

class TeamNewsScreen extends StatefulWidget {
  final String teamKeyword; // 예: "SSG 랜더스"
  final Color themeColor;

  const TeamNewsScreen({
    super.key,
    required this.teamKeyword,
    required this.themeColor,
  });

  @override
  State<TeamNewsScreen> createState() => _TeamNewsScreenState();
}

class _TeamNewsScreenState extends State<TeamNewsScreen> {
  final _items = <NewsArticle>[];
  final _controller = ScrollController();

  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _loadFirst();

    _controller.addListener(() {
      if (!_hasMore || _loading) return;
      if (_controller.position.pixels >= _controller.position.maxScrollExtent - 400) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      final res = await NewsService.fetchTeamNews(
        teamInput: widget.teamKeyword,
        page: _page,
        pageSize: 10,
      );

      setState(() {
        _items.addAll(res);
        _page += 1;
        if (res.isEmpty) _hasMore = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('뉴스 불러오기 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('구단 소식'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFirst,
        child: ListView(
          controller: _controller,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            for (final a in _items)
              NewsArticleTile(
                article: a,
                onTap: () => _open(a.url),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_hasMore && _items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Center(
                  child: Text('마지막 소식이에요', style: TextStyle(color: Colors.grey.shade700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
