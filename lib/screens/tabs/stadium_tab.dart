import 'package:flutter/material.dart';
import '../stadium_detail_screen.dart';

class StadiumTab extends StatefulWidget {
  final Color teamColor;
  const StadiumTab({super.key, required this.teamColor});

  @override
  State<StadiumTab> createState() => _StadiumTabState();
}

class _StadiumTabState extends State<StadiumTab> {
  // ... (기존 stadiums 리스트 데이터는 동일하게 유지)
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
          stadiumId: s.id,
          stadiumName: s.nameKo,
          themeColor: widget.teamColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 배경을 완전 흰색으로 변경
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white, // ✅ 화이트 앱바 적용
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false, // 좌측 정렬 유지 (iOS 감성)
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            '구장 선택',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  '후기를 확인하고 싶은 구장을 선택해주세요!',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
              ),

              // ✅ 카드 그리드 디자인 개선
              Expanded(
                child: GridView.builder(
                  itemCount: stadiums.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, i) {
                    final s = stadiums[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openDetail(s),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade100,
                          ), // 아주 연한 테두리
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              color: Colors.black.withOpacity(
                                0.04,
                              ), // 더 부드러운 그림자
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 이미지 영역
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    color: const Color(0xFFF8F9FA),
                                    alignment: Alignment.center,
                                    child: Image.asset(
                                      s.asset,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 구장 이름
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                              child: Text(
                                s.nameKo,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF222222),
                                ),
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
