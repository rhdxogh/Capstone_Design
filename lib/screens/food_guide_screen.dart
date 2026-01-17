import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class FoodGuideScreen extends StatefulWidget {
  final String stadiumId;     // 예: 'munhak'
  final String stadiumName;   // 예: '인천 SSG 랜더스 필드'
  final Color themeColor;

  const FoodGuideScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
    required this.themeColor,
  });

  @override
  State<FoodGuideScreen> createState() => _FoodGuideScreenState();
}

class _FoodGuideScreenState extends State<FoodGuideScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  bool loading = true;
  List<FoodItem> all = [];
  List<FoodItem> filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    // ✅ CSV 파일 경로
    final csv = await rootBundle.loadString('assets/data/foods.csv');

    final rows = _parseCsv(csv);
    if (rows.isEmpty) {
      setState(() {
        loading = false;
        all = [];
        filtered = [];
      });
      return;
    }

    // 헤더 인덱스 찾기
    final header = rows.first.map((e) => e.trim()).toList();

    int idx(String name) => header.indexOf(name);

    final iStadiumId = idx('stadiumId');
    final iFoodId = idx('foodId');
    final iName = idx('name');
    final iLocation = idx('location');
    final iFloor = idx('floor');
    final iTags = idx('tags');
    final iFoodImg = idx('food_img');

    // 헤더가 없으면 방어
    if ([iStadiumId, iFoodId, iName, iLocation, iFloor, iTags, iFoodImg].any((i) => i < 0)) {
      setState(() {
        loading = false;
        all = [];
        filtered = [];
      });
      return;
    }

    // stadiumId는 CSV에 대문자(MUNHAK)로 들어있을 가능성이 높아서
    final target = widget.stadiumId.toUpperCase();

    final items = <FoodItem>[];
    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.length <= iFoodImg) continue;

      final stadiumId = row[iStadiumId].trim();
      if (stadiumId != target) continue;

      String clean(String s) => s.trim().replaceAll('"', '');

      items.add(
        FoodItem(
          stadiumId: clean(stadiumId),
          foodId: clean(row[iFoodId]),
          name: clean(row[iName]),
          location: clean(row[iLocation]),
          floor: clean(row[iFloor]),
          tagsRaw: clean(row[iTags]),
          foodImg: clean(row[iFoodImg]),
        ),
      );
    }

    setState(() {
      loading = false;
      all = items;
      filtered = items;
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => filtered = all);
      return;
    }

    setState(() {
      filtered = all.where((f) {
        final name = f.name.toLowerCase();
        final tags = f.tags.join(' ').toLowerCase();
        final loc = f.location.toLowerCase();
        final floor = f.floor.toLowerCase();
        return name.contains(q) || tags.contains(q) || loc.contains(q) || floor.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.stadiumName),
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            // 상단 제목/검색 영역
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*
                  const Text(
                    '랜필 먹거리',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                   */
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // 리스트
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Text(
                  '검색 결과가 없어요.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final f = filtered[i];
                  return _FoodTile(
                    item: f,
                    themeColor: widget.themeColor,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodItem {
  final String stadiumId;
  final String foodId;
  final String name;
  final String location; // 예: 1루
  final String floor;    // 예: 1층
  final String tagsRaw;  // 예: #햄버거, #피자
  final String foodImg;  // 예: assets/food_img/MUNHAK/burgerwonders.png

  FoodItem({
    required this.stadiumId,
    required this.foodId,
    required this.name,
    required this.location,
    required this.floor,
    required this.tagsRaw,
    required this.foodImg,
  });

  List<String> get tags {
    // "#햄버거, #피자" / "#햄버거 #피자" 둘 다 대응
    final t = tagsRaw.replaceAll(',', ' ').split(' ');
    return t.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}

class _FoodTile extends StatelessWidget {
  final FoodItem item;
  final Color themeColor;

  const _FoodTile({
    required this.item,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // 나중에 상세 페이지 만들면 여기서 push 하면 됨
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} (상세는 추후 추가)')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 62,
                height: 62,
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: Image.asset(
                  item.foodImg,
                  width: 62,
                  height: 62,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.location} · ${item.floor}',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: item.tags.take(4).map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: themeColor.withOpacity(0.25)),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: themeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, size: 16, color: themeColor),
          ],
        ),
      ),
    );
  }
}

/// 매우 단순 CSV 파서 (따옴표 포함/쉼표 포함까지 “완벽”하진 않지만 일반적인 데이터는 잘 됨)
List<List<String>> _parseCsv(String csv) {
  final lines = const LineSplitter().convert(csv);
  if (lines.isEmpty) return [];

  final rows = <List<String>>[];
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    rows.add(_splitCsvLine(line));
  }
  return rows;
}

List<String> _splitCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < line.length; i++) {
    final c = line[i];

    if (c == '"') {
      inQuotes = !inQuotes;
      continue;
    }

    if (c == ',' && !inQuotes) {
      out.add(buf.toString());
      buf.clear();
      continue;
    }

    buf.write(c);
  }

  out.add(buf.toString());
  return out;
}
