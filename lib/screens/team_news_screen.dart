import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/naver_news_article.dart';
import '../services/naver_news_service.dart';

class TeamNewsScreen extends StatefulWidget {
  /// 예: "KT 위즈", "SSG 랜더스", "키움 히어로즈" ...
  final String teamName;

  /// 상단바 색
  final Color themeColor;

  const TeamNewsScreen({
    super.key,
    required this.teamName,
    required this.themeColor,
  });

  @override
  State<TeamNewsScreen> createState() => _TeamNewsScreenState();
}

class _TeamNewsScreenState extends State<TeamNewsScreen> {
  final _scrollCtrl = ScrollController();

  final List<NaverNewsArticle> _items = [];

  // ✅ 네이버는 page가 아니라 start/display 방식
  // start: 1~1000 (1부터 시작)
  // display: 1~100 (권장 20~50)
  static const int _display = 30;
  int _start = 1;

  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFirst();

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 320) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// 팀 이름을 네이버 검색에 유리한 “정식 키워드”로 정규화
  String _keywordFromTeamName(String teamName) {
    final t = teamName.trim();

    final hasNickname = RegExp(
      r'(위즈|랜더스|히어로즈|이글스|타이거즈|베어스|트윈스|라이온즈|자이언츠|다이노스)',
    ).hasMatch(t);

    if (hasNickname) return t;

    const map = {
      'SSG': 'SSG 랜더스',
      'LG': 'LG 트윈스',
      'KT': 'KT 위즈',
      'KIA': 'KIA 타이거즈',
      'NC': 'NC 다이노스',
      '두산': '두산 베어스',
      '한화': '한화 이글스',
      '삼성': '삼성 라이온즈',
      '롯데': '롯데 자이언츠',
      '키움': '키움 히어로즈',
    };

    final upper = t.toUpperCase();
    if (map.containsKey(upper)) return map[upper]!;
    if (map.containsKey(t)) return map[t]!;

    return t;
  }

  Future<void> _loadFirst() async {
    setState(() {
      _items.clear();
      _start = 1;
      _hasMore = true;
      _error = null;
    });
    await _loadChunk(start: 1);
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    await _loadChunk(start: _start);
  }

  Future<void> _loadChunk({required int start}) async {
    if (start > 1000) {
      setState(() => _hasMore = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final keyword = _keywordFromTeamName(widget.teamName);

      // ✅ 1차: 최신순(date)로 많이 가져오기
      final list = await NaverNewsService.fetchTeamNews(
        teamNameOrId: keyword,
        start: start,
        display: _display,
        sort: 'date',
      );

      // ✅ 결과가 너무 적으면(또는 0개) → 유사도(sim)로 한 번 더 시도 (완화)
      final fallback = (list.isEmpty)
          ? await NaverNewsService.fetchTeamNews(
        teamNameOrId: keyword,
        start: start,
        display: _display,
        sort: 'sim',
      )
          : list;

      // ✅ 중복 제거(같은 링크 반복 방지)
      final existingLinks = _items
          .map((e) => (e.originallink.isNotEmpty ? e.originallink : e.link).trim())
          .where((u) => u.isNotEmpty)
          .toSet();

      final deduped = fallback.where((e) {
        final u = (e.originallink.isNotEmpty ? e.originallink : e.link).trim();
        return u.isNotEmpty && !existingLinks.contains(u);
      }).toList();

      setState(() {
        _items.addAll(deduped);

        // 다음 페이지로
        _start = start + _display;

        // hasMore 판단:
        // - deduped가 너무 적으면 더 이상 안 나올 가능성이 큼
        // - start가 1000 넘어가면 중단
        _hasMore = deduped.length >= (_display ~/ 2) && _start <= 1000;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('링크를 열 수 없어요.')),
      );
    }
  }

  String _dateText(DateTime? dt) {
    if (dt == null) return '';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    final keyword = _keywordFromTeamName(widget.teamName);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${widget.teamName} 구단 소식'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFirst,
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          children: [
            // 상단 안내(현재 검색 키워드 표시)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.themeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.themeColor.withOpacity(0.20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: widget.themeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '검색 키워드: $keyword',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadFirst,
                    child: const Text('새로고침'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_error != null)
              _ErrorBox(
                message: _error!,
                onRetry: _loadFirst,
                themeColor: widget.themeColor,
              ),

            if (_items.isEmpty && _error == null && _loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (_items.isEmpty && _error == null && !_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: Text('검색 결과가 없어요.')),
              ),

            for (final a in _items) ...[
              _NewsCard(
                article: a,
                themeColor: widget.themeColor,
                dateText: _dateText(a.pubDate),
                onTap: () => _openUrl(
                  a.originallink.isNotEmpty ? a.originallink : a.link,
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_loading && _items.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (!_hasMore && _items.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6, bottom: 14),
                child: Center(
                  child: Text(
                    '마지막 소식이에요',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NaverNewsArticle article;
  final Color themeColor;
  final String dateText;
  final VoidCallback onTap;

  const _NewsCard({
    required this.article,
    required this.themeColor,
    required this.dateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.public, size: 16, color: themeColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _domainText(
                      article.originallink.isNotEmpty
                          ? article.originallink
                          : article.link,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (dateText.isNotEmpty)
                  Text(
                    dateText,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _domainText(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return uri.host.replaceFirst('www.', '');
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color themeColor;

  const _ErrorBox({
    required this.message,
    required this.onRetry,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '불러오기 실패',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade800),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ),
        ],
      ),
    );
  }
}

