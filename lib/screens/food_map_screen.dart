import 'package:flutter/material.dart';
import 'food_guide_screen.dart';
import 'food_detail_screen.dart';

class FoodMapScreen extends StatefulWidget {
  final List<FoodItem> foodList;
  final String stadiumName;
  final Color themeColor;

  const FoodMapScreen({
    super.key,
    required this.foodList,
    required this.stadiumName,
    required this.themeColor,
  });

  @override
  State<FoodMapScreen> createState() => _FoodMapScreenState();
}

class _FoodMapScreenState extends State<FoodMapScreen> {
  String selectedFloor = '';
  List<String> currentTabs = [];
  String stadiumIdLowerCase = 'munhak';

  final Color appMainRed = const Color(0xFFC41212);

  // 💡 현재 선택된 매장 (목록에서 누르거나, 지도에서 누르면 이게 바뀜!)
  FoodItem? _selectedFood;

  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _setupDynamicStadium();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transformCtrl.value = Matrix4.identity()
        ..translate(-30.0, -30.0)
        ..scale(1.2);
    });
  }

  void _setupDynamicStadium() {
    if (widget.foodList.isEmpty) return;

    final String sId = widget.foodList.first.stadiumId.toUpperCase();
    stadiumIdLowerCase = sId.toLowerCase();

    switch (sId) {
      case 'MUNHAK':
        currentTabs = ['1층', '2층', '4층', '외야'];
        break;
      case 'CHANGWON':
        currentTabs = ['1층', '2층'];
        break;
      case 'GOCHEOK':
        currentTabs = ['2층', '3층', '4층'];
        break;
      case 'SUWON':
        currentTabs = ['상단', '하단'];
        break;
      case 'DAEJEON':
      case 'GWANGJU':
        currentTabs = ['3층', '4층', '5층'];
        break;
      default:
        currentTabs = widget.foodList.map((f) => f.floor).toSet().toList()
          ..sort();
    }

    if (currentTabs.isNotEmpty) {
      selectedFloor = currentTabs.first;
    }
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  // --- 1. 평상시: 작고 얌전한 회색 점 ---
  Widget _buildUnselectedMarker(int count) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.grey.shade500, // 💡 튀지 않는 회색
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: count > 1
          ? Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // --- 2. 선택 시: 빨간색으로 빛나며 튀어나오는 로고 핀 ---
  Widget _buildSelectedMarker(FoodItem food) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 말풍선 꼬리
        Positioned(
          bottom: -10,
          child: Icon(Icons.location_on, color: appMainRed, size: 40),
        ),
        // 로고 이미지 (뿅!)
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: appMainRed, width: 3),
            boxShadow: [
              BoxShadow(
                color: appMainRed.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              food.foodImg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.restaurant, size: 24, color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 현재 탭에 맞는 매장들 필터링
    final filteredFoods = widget.foodList.where((food) {
      if (widget.foodList.isEmpty) return false;
      final String sId = widget.foodList.first.stadiumId.toUpperCase();

      if (sId == 'MUNHAK') {
        if (selectedFloor == '1층')
          return food.floor.contains('1층') || food.floor.contains('지하');
        if (selectedFloor == '4층')
          return food.floor.contains('4층') || food.floor.contains('3층');
        if (selectedFloor == '외야')
          return food.floor.contains('단층') || food.location.contains('외야');
        return food.floor.contains(selectedFloor);
      } else if (sId == 'SUWON') {
        return food.floor.contains(selectedFloor);
      } else {
        return food.floor.contains(selectedFloor) ||
            food.location.contains(selectedFloor);
      }
    }).toList();

    // 2. 같은 좌표끼리 그룹화 (지도 마커용)
    final Map<String, List<FoodItem>> groupedFoods = {};
    for (var food in filteredFoods) {
      final String coordKey = '${food.mapX}_${food.mapY}';
      if (!groupedFoods.containsKey(coordKey)) {
        groupedFoods[coordKey] = [];
      }
      groupedFoods[coordKey]!.add(food);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          '${widget.stadiumName} 매장 지도',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      // 💡 Stack을 사용해서 지도 위에 '끌어올리는 패널'을 덮습니다!
      body: Stack(
        children: [
          // ==============================
          // [배경 레이어] 지도 & 마커
          // ==============================
          Column(
            children: [
              // 상단 층수 선택 탭
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: currentTabs.map((floorName) {
                      bool isSelected = selectedFloor == floorName;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!isSelected) {
                              setState(() {
                                selectedFloor = floorName;
                                _selectedFood = null; // 층을 바꾸면 선택 해제
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? appMainRed
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: appMainRed.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              floorName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 지도 뷰어
              Expanded(
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double mapSize = constraints.maxWidth;
                        return SizedBox(
                          width: mapSize,
                          height: mapSize,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/stadium_img/$stadiumIdLowerCase.png',
                                  fit: BoxFit.contain,
                                ),
                              ),

                              // 지도 마커들
                              ...groupedFoods.values.map((foodGroup) {
                                final representativeFood = foodGroup.first;

                                // 이 그룹 안에 현재 선택된 매장이 있는지 확인
                                final bool isSelectedGroup =
                                    _selectedFood != null &&
                                    foodGroup.any(
                                      (f) => f.name == _selectedFood!.name,
                                    );

                                return Positioned(
                                  left: mapSize * representativeFood.mapX,
                                  top: mapSize * representativeFood.mapY,
                                  child: FractionalTranslation(
                                    translation: isSelectedGroup
                                        ? const Offset(-0.5, -0.9)
                                        : const Offset(-0.5, -0.5),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        // 💡 회색 마커를 누르면 해당 그룹의 첫번째 매장이 선택되고 로고가 뿅 튀어나옴!
                                        setState(() {
                                          _selectedFood = isSelectedGroup
                                              ? null
                                              : foodGroup.first;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: isSelectedGroup
                                            ? _buildSelectedMarker(
                                                _selectedFood!,
                                              ) // 선택됨 -> 빨간 로고 핀
                                            : _buildUnselectedMarker(
                                                foodGroup.length,
                                              ), // 평상시 -> 회색 점
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ==============================
          // [전경 레이어] 끌어올리는 매장 목록 (바텀 시트)
          // ==============================
          DraggableScrollableSheet(
            initialChildSize: 0.35, // 처음엔 화면의 35%만 차지
            minChildSize: 0.15, // 최소 크기
            maxChildSize: 0.85, // 쭈욱 올리면 85%까지 올라감
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 드래그 손잡이 (가운데 회색 작대기)
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 제목
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            '$selectedFloor 매장 목록',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '총 ${filteredFoods.length}개',
                            style: TextStyle(
                              color: appMainRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),

                    // 리스트 뷰
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filteredFoods.length,
                        itemBuilder: (context, index) {
                          final food = filteredFoods[index];
                          final isSelected =
                              _selectedFood == food; // 현재 리스트 항목이 선택된 녀석인지?

                          return Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  // 💡 리스트에서 누르면 지도 마커가 뿅! 하고 바뀜
                                  setState(() {
                                    _selectedFood = isSelected ? null : food;
                                  });
                                },
                                // 선택된 항목은 배경색을 연한 빨간색으로 칠해서 하이라이트 해줌
                                child: Container(
                                  color: isSelected
                                      ? appMainRed.withOpacity(0.05)
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                  child: Row(
                                    children: [
                                      // 리스트 안의 썸네일
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: isSelected
                                              ? Border.all(
                                                  color: appMainRed,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.asset(
                                            food.foodImg,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.fastfood,
                                                  color: Colors.grey,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              food.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.w900
                                                    : FontWeight.bold,
                                                color: isSelected
                                                    ? appMainRed
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${food.location} ${food.floor}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 4,
                                              children: food.tags
                                                  .map(
                                                    (t) => Text(
                                                      t.startsWith('#')
                                                          ? t
                                                          : '#$t',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: appMainRed,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // 💡 선택된 항목 바로 밑에 '후기 보러가기' 버튼이 스르륵 열림!
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    16,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: appMainRed,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FoodDetailScreen(
                                              stadiumId: food.stadiumId
                                                  .toLowerCase(),
                                              stadiumName: widget.stadiumName,
                                              themeColor: appMainRed,
                                              food: food,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        '해당 매장 후기 보러가기',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              const Divider(height: 1),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
