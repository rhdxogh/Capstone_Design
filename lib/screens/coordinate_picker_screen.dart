import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard 기능을 쓰기 위해 추가!

class CoordinatePickerScreen extends StatefulWidget {
  // 테스트할 구장의 영문 ID (예: 'changwon', 'daegu' 등으로 바꾸며 테스트하세요)
  final String testStadiumId = 'daejeon';

  const CoordinatePickerScreen({super.key});

  @override
  State<CoordinatePickerScreen> createState() => _CoordinatePickerScreenState();
}

class _CoordinatePickerScreenState extends State<CoordinatePickerScreen> {
  List<Offset> tappedPoints = [];
  String statusMessage = '원하는 위치를 터치하세요';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.testStadiumId} 좌표 따기 툴'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                tappedPoints.clear();
                statusMessage = '초기화 됨';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 안내 영역
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade100,
            width: double.infinity,
            child: Column(
              children: [
                const Text(
                  '🔥 터치하는 순간 자동으로 클립보드에 복사됩니다! 🔥',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '엑셀 map_x 칸을 클릭하고 그냥 Ctrl+V 하시면 알아서 두 칸으로 나뉩니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double boxWidth = constraints.maxWidth;
                  double boxHeight = constraints.maxWidth;

                  return SizedBox(
                    width: boxWidth,
                    height: boxHeight,
                    child: GestureDetector(
                      onTapDown: (TapDownDetails details) async {
                        double localX = details.localPosition.dx;
                        double localY = details.localPosition.dy;

                        double mapX = localX / boxWidth;
                        double mapY = localY / boxHeight;

                        // 💡 핵심: 쉼표(,) 대신 탭(\t)을 넣어주면 엑셀에서 알아서 두 칸으로 나뉩니다!
                        String copyText =
                            '${mapX.toStringAsFixed(4)}\t${mapY.toStringAsFixed(4)}';

                        // 💡 클립보드에 자동 복사!
                        await Clipboard.setData(ClipboardData(text: copyText));

                        setState(() {
                          tappedPoints.add(Offset(mapX, mapY));
                          statusMessage = '✅ 복사 완료! 엑셀에 붙여넣으세요';
                        });

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('복사됨: $copyText'),
                            duration: const Duration(milliseconds: 500),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          Positioned.fill(
                            // 💡 변수명으로 이미지를 불러오게 만들었습니다.
                            child: Image.asset(
                              'assets/stadium_img/${widget.testStadiumId}.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          ...tappedPoints.map((point) {
                            return Positioned(
                              left: point.dx * boxWidth - 5,
                              top: point.dy * boxHeight - 5,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
