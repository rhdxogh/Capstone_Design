import 'package:flutter/material.dart';
import 'food_guide_screen.dart';
import '../widgets/review_widget.dart';

class FoodDetailScreen extends StatefulWidget {
  final String stadiumId;
  final String stadiumName;
  final Color themeColor;
  final FoodItem food;

  const FoodDetailScreen({
    super.key,
    required this.stadiumId,
    required this.stadiumName,
    required this.themeColor,
    required this.food,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

// 💡 애니메이션을 위해 with SingleTickerProviderStateMixin 추가!
class _FoodDetailScreenState extends State<FoodDetailScreen>
    with SingleTickerProviderStateMixin {
  final Color appMainRed = const Color(0xFFC41212);
  bool _isMapVisible = false;

  // 💡 마커 파동(Pulse) 애니메이션 컨트롤러
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // 2초 주기로 무한 반복되는 애니메이션 설정
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.food;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            // --- 1. 타이틀 및 위치 영역 ---
            Text(
              f.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${widget.stadiumName} ${f.location} ${f.floor}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),

                // [사진 보기] <-> [지도 보기] 토글 버튼 (버튼도 살짝 더 세련되게 다듬음)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isMapVisible = !_isMapVisible;
                    });
                  },
                  borderRadius: BorderRadius.circular(20), // 더 둥글게
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _isMapVisible ? appMainRed : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isMapVisible
                              ? Icons.image_outlined
                              : Icons.map_outlined,
                          size: 16,
                          color: _isMapVisible ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isMapVisible ? '매장 로고 보기' : '매장 위치 보기',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isMapVisible
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 2. 애니메이션 교체 영역 (사진 <-> 오차 없는 확대 지도) ---
            ClipRRect(
              borderRadius: BorderRadius.circular(20), // 곡률을 좀 더 부드럽게
              child: Container(
                height: 250,
                color: const Color(0xFFF4F5F7), // 지도가 돋보이는 약간 더 부드러운 배경색
                alignment: Alignment.center,
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 400),
                  crossFadeState: _isMapVisible
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,

                  firstChild: SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: Image.asset(f.foodImg, fit: BoxFit.cover),
                  ),

                  secondChild: SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double viewWidth = constraints.maxWidth;
                          final double viewHeight = 250.0;

                          final double baseMapSize = viewWidth;
                          final double scale =
                              2.0; // 💡 2.5배는 너무 깨져서 2.0배로 조정 (고급스러움 확보)
                          final double expandedMapSize = baseMapSize * scale;

                          final double targetPixelX = expandedMapSize * f.mapX;
                          final double targetPixelY = expandedMapSize * f.mapY;

                          final double mapLeftOffset =
                              (viewWidth / 2) - targetPixelX;
                          final double mapTopOffset =
                              (viewHeight / 2) - targetPixelY;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // 이동된 배경 지도
                              Positioned(
                                left: mapLeftOffset,
                                top: mapTopOffset,
                                width: expandedMapSize,
                                height: expandedMapSize,
                                child: Image.asset(
                                  'assets/stadium_img/${widget.stadiumId.toLowerCase()}.png',
                                  fit: BoxFit.contain,
                                ),
                              ),

                              // 💡 요즘 스타일의 숨쉬는(Pulse) 레이더 마커
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 퍼져나가는 파동
                                      Container(
                                        width:
                                            12 +
                                            (_pulseController.value *
                                                48), // 12에서 60까지 커짐
                                        height:
                                            12 + (_pulseController.value * 48),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: appMainRed.withOpacity(
                                            1.0 - _pulseController.value,
                                          ), // 점점 투명해짐
                                        ),
                                      ),
                                      // 정중앙 고정 메인 도트
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: appMainRed,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.3,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              // 촌스러웠던 하단 텍스트 뱃지는 삭제했습니다!
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(thickness: 8, color: Color(0xFFF2F4F6)),
            const SizedBox(height: 24),

            // --- 3. 리뷰 영역 ---
            ReviewWidget(category: 'food', targetId: f.name, isEmbedded: true),
          ],
        ),
      ),
    );
  }
}
