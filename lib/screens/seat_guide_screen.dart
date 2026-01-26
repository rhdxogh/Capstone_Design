import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'seat_overlay_screen.dart'; // 파일 위치에 맞게 경로 수정

class SeatGuideScreen extends StatefulWidget {
  final String stadiumId; // 'munhak'
  final String stadiumName; // '인천 SSG 랜더스필드'
  final Color themeColor;

  const SeatGuideScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
    required this.themeColor,
  });

  @override
  State<SeatGuideScreen> createState() => _SeatGuideScreenState();
}

class _SeatGuideScreenState extends State<SeatGuideScreen> {
  late Future<List<SeatSection>> sectionsFuture;

  String get viewImagePath => 'assets/stadium_img/${widget.stadiumId}.png';

  @override
  void initState() {
    super.initState();
    sectionsFuture = _loadSectionsFromCsv(widget.stadiumId);
  }

  Future<List<SeatSection>> _loadSectionsFromCsv(String stadiumId) async {
    // ✅ CSV 파일 위치
    final raw = await rootBundle.loadString('assets/data/sections.csv');

    final lines = raw
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return [];

    // 1) 헤더 파싱
    final headers = _parseCsvLine(lines.first).map((e) => e.trim()).toList();

    int idx(String name) => headers.indexOf(name);

    final iStadiumId = idx('stadiumId');
    final iSectionId = idx('sectionId');
    final iSectionName = idx('sectionName');
    final iColorHex = idx('colorHex');
    final iSortOrder = idx('sortOrder');
    final iOverlayAsset = idx('overlayAsset');

    // 필수 컬럼 체크
    if ([
      iStadiumId,
      iSectionId,
      iSectionName,
      iColorHex,
      iSortOrder,
      iOverlayAsset,
    ].any((v) => v < 0)) {
      throw Exception('CSV 헤더에 필요한 컬럼이 없어요.\n현재 헤더: $headers');
    }

    // 2) 데이터 파싱
    final result = <SeatSection>[];
    for (int r = 1; r < lines.length; r++) {
      final cols = _parseCsvLine(lines[r]);

      String getCol(int i) => i < cols.length ? cols[i].trim() : '';

      final sid = getCol(iStadiumId);
      if (sid.toLowerCase() != stadiumId.toLowerCase()) continue;

      result.add(
        SeatSection(
          stadiumId: sid,
          sectionId: getCol(iSectionId),
          sectionName: getCol(iSectionName),
          colorHex: _normalizeHex(getCol(iColorHex)),
          sortOrder: int.tryParse(getCol(iSortOrder)) ?? 0,
          overlayAsset: getCol(iOverlayAsset),
        ),
      );
    }

    result.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return result;
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
        child: FutureBuilder<List<SeatSection>>(
          future: sectionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('CSV 로딩 실패: ${snapshot.error}'));
            }

            final sections = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
              children: [
                Text(
                  widget.stadiumName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '좌석 후기를 확인할 구역을 선택하세요.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),

                // ✅ 구장 뷰 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 260,
                    color: const Color(0xFFF2F2F2),
                    alignment: Alignment.center,
                    child: Image.asset(viewImagePath, fit: BoxFit.contain),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  '좌석안내',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                ...sections.map(
                  (s) => _SectionRow(
                    section: s,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeatOverlayScreen(
                            stadiumName: widget.stadiumName,
                            sectionName: s.sectionName,
                            overlayAsset: s.overlayAsset,
                            themeColor: widget.themeColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// lib/screens/seat_guide_screen.dart 내의 _SectionRow 수정

class _SectionRow extends StatelessWidget {
  final SeatSection section;
  final VoidCallback onTap;

  const _SectionRow({required this.section, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dotColor = _hexToColor(section.colorHex);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
            ), // ListTile 자체 패딩 조절
            child: ListTile(
              // 1. 좌측 컬러 도트
              leading: Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  // 도트가 흰색 계열일 때를 대비해 아주 연한 테두리 추가
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
              ),
              // 2. 구역 이름 (글씨 크기 키움)
              title: Text(
                section.sectionName,
                style: const TextStyle(
                  fontSize: 15, // 기존 14에서 증가
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
              // 3. 우측 화살표 아이콘 추가
              trailing: const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFBDBDBD),
              ),
              contentPadding: EdgeInsets.zero, // 좌우 여백 제거 (ListView 패딩에 의존)
            ),
          ),
        ),
        // 4. 구분선 추가
        Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

class SeatSection {
  final String stadiumId;
  final String sectionId;
  final String sectionName;
  final String colorHex;
  final int sortOrder;
  final String overlayAsset;

  SeatSection({
    required this.stadiumId,
    required this.sectionId,
    required this.sectionName,
    required this.colorHex,
    required this.sortOrder,
    required this.overlayAsset,
  });
}

// ---- CSV 유틸 (간단 파서: 따옴표 포함 대응) ----
List<String> _parseCsvLine(String line) {
  final out = <String>[];
  final sb = StringBuffer();
  bool inQuotes = false;

  for (int i = 0; i < line.length; i++) {
    final c = line[i];

    if (c == '"') {
      // "" -> " 처리
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        sb.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c == ',' && !inQuotes) {
      out.add(sb.toString());
      sb.clear();
    } else {
      sb.write(c);
    }
  }
  out.add(sb.toString());
  return out;
}

String _normalizeHex(String hex) {
  var h = hex.trim();
  if (h.isEmpty) return '#CCCCCC';
  if (!h.startsWith('#')) h = '#$h';
  return h;
}

Color _hexToColor(String hex) {
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}
