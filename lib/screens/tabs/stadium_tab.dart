import 'package:flutter/material.dart';
import '../stadium_detail_screen.dart';

class StadiumTab extends StatefulWidget {
  final Color teamColor;
  const StadiumTab({super.key, required this.teamColor});

  @override
  State<StadiumTab> createState() => _StadiumTabState();
}

class _StadiumTabState extends State<StadiumTab> {
  final List<_StadiumItem> stadiums = const [
    _StadiumItem(
      id: 'gocheok',
      nameKo: '고척스카이돔',
      asset: 'assets/stadium_img/gocheok.png',
    ),
    _StadiumItem(
      id: 'jamsil',
      nameKo: '잠실야구장',
      asset: 'assets/stadium_img/jamsil.png',
    ),
    _StadiumItem(
      id: 'daegu',
      nameKo: '대구 삼성 라이온즈파크',
      asset: 'assets/stadium_img/daegu.png',
    ),
    _StadiumItem(
      id: 'daejeon',
      nameKo: '대전 한화생명 볼파크',
      asset: 'assets/stadium_img/daejeon.png',
    ),
    _StadiumItem(
      id: 'sajik',
      nameKo: '사직 야구장',
      asset: 'assets/stadium_img/sajik.png',
    ),
    _StadiumItem(
      id: 'munhak',
      nameKo: '인천 SSG 랜더스필드',
      asset: 'assets/stadium_img/munhak.png',
    ),
    _StadiumItem(
      id: 'suwon',
      nameKo: '수원 케이티 위즈파크',
      asset: 'assets/stadium_img/suwon.png',
    ),
    _StadiumItem(
      id: 'changwon',
      nameKo: '창원NC파크',
      asset: 'assets/stadium_img/changwon.png',
    ),
    _StadiumItem(
      id: 'gwangju',
      nameKo: '광주-기아 챔피언스필드',
      asset: 'assets/stadium_img/gwangju.png',
    ),
  ];

  void _openDetail(_StadiumItem s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StadiumDetailScreen(
          stadiumId: s.id, // gocheok/munhak...
          stadiumName: s.nameKo,
          themeColor: widget.teamColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '구장 선택',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '좌석 후기를 확인할 구장을 선택해주세요!',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),

              // ✅ 카드 그리드
              Expanded(
                child: GridView.builder(
                  itemCount: stadiums.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  itemBuilder: (context, i) {
                    final s = stadiums[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openDetail(s), // ✅ 여기서 상세로 이동
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  // ✅ 이미지 영역
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        color: const Color(0xFFF1F1F1),
                                        alignment:
                                            Alignment.center, // ✅ 중앙 정렬 핵심
                                        child: Image.asset(
                                          s.asset,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // ✅ 이름
                                  Text(
                                    s.nameKo,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StadiumItem {
  final String id;
  final String nameKo;
  final String asset;
  const _StadiumItem({
    required this.id,
    required this.nameKo,
    required this.asset,
  });
}
