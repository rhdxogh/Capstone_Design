import 'package:flutter/material.dart';

class StadiumTab extends StatefulWidget {
  final Color teamColor;
  const StadiumTab({super.key, required this.teamColor});

  @override
  State<StadiumTab> createState() => _StadiumTabState();
}

class _StadiumTabState extends State<StadiumTab> {
  String? selectedId;

  // ✅ 너가 가진 assets/stadium_img 경로 기준
  final List<_StadiumItem> stadiums = const [
    _StadiumItem(id: 'gocheok', nameKo: '고척스카이돔', asset: 'assets/stadium_img/gocheok.png'),
    _StadiumItem(id: 'jamsil', nameKo: '잠실야구장', asset: 'assets/stadium_img/jamsil.png'),
    _StadiumItem(id: 'daegu', nameKo: '대구 삼성 라이온즈파크', asset: 'assets/stadium_img/daegu.png'),
    _StadiumItem(id: 'daejeon', nameKo: '대전 한화생명 볼파크', asset: 'assets/stadium_img/daejeon.png'),
    _StadiumItem(id: 'sajik', nameKo: '사직 야구장', asset: 'assets/stadium_img/sajik.png'),
    _StadiumItem(id: 'munhak', nameKo: '인천 SSG 랜더스필드', asset: 'assets/stadium_img/munhak.png'),
    _StadiumItem(id: 'suwon', nameKo: '수원 케이티 위즈파크', asset: 'assets/stadium_img/suwon.png'),
    _StadiumItem(id: 'changwon', nameKo: '창원NC파크', asset: 'assets/stadium_img/changwon.png'),
    _StadiumItem(id: 'gwangju', nameKo: '광주-기아 챔피언스필드', asset: 'assets/stadium_img/gwangju.png'),
  ];

  void _onSelect(_StadiumItem s) {
    setState(() => selectedId = s.id);

    // 나중에 여기서 상세 화면으로 이동하면 됨
    // 지금은 선택만 반영
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
                    final isSel = selectedId == s.id;

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _onSelect(s),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSel ? widget.teamColor : Colors.transparent,
                            width: isSel ? 2 : 1,
                          ),
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
                                  // 이미지 영역
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        color: const Color(0xFFF1F1F1),
                                        alignment: Alignment.center,
                                        child: Image.asset(
                                          s.asset,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 이름
                                  Text(
                                    s.nameKo,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ✅ 선택 체크 뱃지
                            if (isSel)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: widget.teamColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ✅ 선택 완료 버튼(원하면)
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedId == null ? Colors.grey : widget.teamColor,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: selectedId == null
                      ? null
                      : () {
                    final picked = stadiums.firstWhere((s) => s.id == selectedId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${picked.nameKo} 선택됨 (상세 화면은 다음 단계)')),
                    );
                  },
                  child: const Text(
                    '선택 완료',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
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
  const _StadiumItem({required this.id, required this.nameKo, required this.asset});
}
