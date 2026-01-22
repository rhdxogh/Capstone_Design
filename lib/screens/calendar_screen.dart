import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 일정 저장 맵
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '직관 캘린더',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0x66C62828),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFFC62828),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Color(0xFFC62828),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(thickness: 1, height: 1),
          Expanded(child: _buildEventList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC62828),
        onPressed: () => _showAddScheduleSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // 일정 리스트 UI (수정/삭제 버튼 추가)
  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return const Center(child: Text('기록된 직관 일정이 없습니다.'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final bool hasResult = event['result'] != null;

        Color resultColor = Colors.grey;
        if (event['result'] == '승')
          resultColor = const Color(0xFFC62828);
        else if (event['result'] == '무')
          resultColor = Colors.green;
        else if (event['result'] == '패')
          resultColor = Colors.blue;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "상대: ${event['opponent']} | 장소: ${event['stadium']}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              // 결과 배지 또는 "예정" 표시
              if (hasResult)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event['result'],
                    style: TextStyle(
                      color: resultColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                const Text(
                  "예정",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

              const SizedBox(width: 8),
              // 더보기 메뉴 (수정/삭제)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddScheduleSheet(context, event: event, index: index);
                  } else if (value == 'delete') {
                    _deleteEvent(index);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('수정')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 삭제 로직
  void _deleteEvent(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final dateKey = DateTime.utc(
                  _selectedDay!.year,
                  _selectedDay!.month,
                  _selectedDay!.day,
                );
                _events[dateKey]!.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleSheet(
    BuildContext context, {
    Map<String, dynamic>? event,
    int? index,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddScheduleBottomSheet(
        initialDate: _selectedDay!,
        editingEvent: event, // 수정할 데이터 전달
        onEventAdded: (newData, newDate) {
          setState(() {
            final oldDateKey = DateTime.utc(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
            );
            final newDateKey = DateTime.utc(
              newDate.year,
              newDate.month,
              newDate.day,
            );

            if (event != null && index != null) {
              // 수정 모드
              _events[oldDateKey]!.removeAt(index); // 기존 데이터 삭제
              if (_events[newDateKey] == null) _events[newDateKey] = [];
              _events[newDateKey]!.add(newData); // 새 날짜(혹은 같은 날짜)에 추가
            } else {
              // 추가 모드
              if (_events[newDateKey] == null) _events[newDateKey] = [];
              _events[newDateKey]!.add(newData);
            }
          });
        },
      ),
    );
  }
}

// --- 일정 추가/수정 팝업창 ---
class AddScheduleBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final Map<String, dynamic>? editingEvent; // 수정 시 넘어오는 데이터
  final Function(Map<String, dynamic>, DateTime) onEventAdded;

  const AddScheduleBottomSheet({
    super.key,
    required this.initialDate,
    this.editingEvent,
    required this.onEventAdded,
  });

  @override
  State<AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<AddScheduleBottomSheet> {
  final _titleController = TextEditingController();
  late DateTime _selectedDate;

  final List<String> _teams = [
    'LG',
    'KT',
    'SSG',
    'NC',
    '두산',
    '기아',
    '롯데',
    '삼성',
    '한화',
    '키움',
  ];
  final List<String> _stadiums = [
    '잠실',
    '고척',
    '문학',
    '수원',
    '대전',
    '광주',
    '대구',
    '창원',
    '사직',
  ];

  String? _selectedOpponent;
  String? _selectedStadium;
  String? _selectedResult;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    // 수정 모드인 경우 기존 데이터 채워넣기
    if (widget.editingEvent != null) {
      _titleController.text = widget.editingEvent!['title'];
      _selectedOpponent = widget.editingEvent!['opponent'];
      _selectedStadium = widget.editingEvent!['stadium'];
      _selectedResult = widget.editingEvent!['result'];
    }
  }

  bool _isFutureDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _selectedDate.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.editingEvent != null ? '일정 수정' : '새로운 일정 추가',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '메모',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedOpponent,
              decoration: const InputDecoration(
                labelText: '상대 팀 선택',
                border: OutlineInputBorder(),
              ),
              items: _teams
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedOpponent = val),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedStadium,
              decoration: const InputDecoration(
                labelText: '경기장 선택',
                border: OutlineInputBorder(),
              ),
              items: _stadiums
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedStadium = val),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '날짜',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat(
                        'yyyy년 MM월 dd일 (E)',
                        'ko_KR',
                      ).format(_selectedDate),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              '직관 결과 기록',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (_isFutureDate())
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    '경기 후에 결과를 기록할 수 있습니다. ⚾️',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildResultButton('승', const Color(0xFFC62828)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildResultButton('무', Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildResultButton('패', Colors.blue)),
                ],
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (_titleController.text.isEmpty ||
                      _selectedOpponent == null ||
                      _selectedStadium == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 항목을 입력/선택해주세요!')),
                    );
                    return;
                  }
                  widget.onEventAdded({
                    'title': _titleController.text,
                    'opponent': _selectedOpponent,
                    'stadium': _selectedStadium,
                    'result': _isFutureDate() ? null : _selectedResult,
                  }, _selectedDate);
                  Navigator.pop(context);
                },
                child: Text(
                  widget.editingEvent != null ? '수정 완료' : '일정 추가하기',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultButton(String text, Color color) {
    bool isSelected = _selectedResult == text;
    return GestureDetector(
      onTap: () => setState(() => _selectedResult = text),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
