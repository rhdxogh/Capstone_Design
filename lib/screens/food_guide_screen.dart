import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'food_detail_screen.dart';
// ✅ 좌표 추출 화면 import 복구
import 'coordinate_picker_screen.dart';

// 앱 전체 공통 빨간색
const Color appMainRed = Color(0xFFC41212);

class FoodGuideScreen extends StatefulWidget {
  final String stadiumId;
  final String stadiumName;
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

    final header = rows.first.map((e) => e.trim()).toList();
    int idx(String name) => header.indexOf(name);

    final iStadiumId = idx('stadiumId');
    final iFoodId = idx('foodId');
    final iName = idx('name');
    final iLocation = idx('location');
    final iFloor = idx('floor');
    final iTags = idx('tags');
    final iFoodImg = idx('food_img');
    final iMapX = idx('map_x');
    final iMapY = idx('map_y');

    if ([
      iStadiumId,
      iFoodId,
      iName,
      iLocation,
      iFloor,
      iTags,
      iFoodImg,
      iMapX,
      iMapY,
    ].any((i) => i < 0)) {
      setState(() {
        loading = false;
        all = [];
        filtered = [];
      });
      return;
    }

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
          mapX: double.tryParse(clean(row[iMapX])) ?? 0.0,
          mapY: double.tryParse(clean(row[iMapY])) ?? 0.0,
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
        return name.contains(q) ||
            tags.contains(q) ||
            loc.contains(q) ||
            floor.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.stadiumName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // ✅ 스패너 아이콘 다시 추가
        actions: [
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CoordinatePickerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final f = filtered[i];
                              return _FoodTile(
                                item: f,
                                stadiumName: widget.stadiumName,
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
  final String location;
  final String floor;
  final String tagsRaw;
  final String foodImg;
  final double mapX;
  final double mapY;

  FoodItem({
    required this.stadiumId,
    required this.foodId,
    required this.name,
    required this.location,
    required this.floor,
    required this.tagsRaw,
    required this.foodImg,
    required this.mapX,
    required this.mapY,
  });

  List<String> get tags {
    final t = tagsRaw.replaceAll(',', ' ').split(' ');
    return t.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}

class _FoodTile extends StatelessWidget {
  final FoodItem item;
  final String stadiumName;

  const _FoodTile({required this.item, required this.stadiumName});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(
              stadiumId: item.stadiumId.toLowerCase(),
              stadiumName: stadiumName,
              themeColor: appMainRed,
              food: item,
            ),
          ),
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
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFFF2F2F2),
                alignment: Alignment.center,
                child: Image.asset(
                  item.foodImg,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.fastfood, size: 28, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.location} · ${item.floor}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: item.tags.map((t) {
                      final tag = t.trim();
                      return Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: const TextStyle(
                          fontSize: 11,
                          color: appMainRed,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// CSV 파서 및 헬퍼 함수들 (기존과 동일)
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
