import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarScreen extends StatefulWidget {
  // ✅ 메인에서 현재 팀 ID를 받아옵니다.
  final String currentTeamId;

  const CalendarScreen({super.key, required this.currentTeamId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMyRecordsFromFirestore();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _loadMyRecordsFromFirestore() async {
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('jikgwan_records')
          .orderBy('date')
          .get();

      final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // ✅ [핵심 수정] 캘린더 필터링 로직
        String? recordTeamId = data['myTeamId'];

        // 1. 기록에 팀 정보가 있는데, 현재 팀과 다르다면? -> 과감히 패스 (숨김)
        if (recordTeamId != null && recordTeamId != widget.currentTeamId) {
          continue;
        }
        // 2. 기록에 팀 정보가 없다면? (옛날 데이터)
        // -> 일단 보여주거나, 혹은 이것도 숨길 수 있습니다.
        // -> 여기서는 "팀 세탁"이 목적이므로, 확실하지 않은 옛날 데이터는 보여주되
        //    나중에 수정하면 현재 팀으로 귀속되게 둡니다.

        final DateTime date = (data['date'] as Timestamp).toDate();
        final dateKey = DateTime.utc(date.year, date.month, date.day);

        final event = {
          'id': doc.id,
          'title': data['title'],
          'opponent': data['opponent'],
          'stadium': data['stadium'],
          'result': data['result'],
          'date': date,
          'myTeamId': recordTeamId, // 데이터 보존
        };

        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(event);
      }

      if (mounted) {
        setState(() {
          _events.clear();
          _events.addAll(newEvents);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('데이터 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteEvent(String? docId) async {
    if (docId == null || uid == null) return;

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('jikgwan_records')
            .doc(docId)
            .delete();

        _loadMyRecordsFromFirestore();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  void _showAddScheduleSheet({Map<String, dynamic>? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddScheduleBottomSheet(
        initialDate: _selectedDay!,
        editingEvent: event,
        onEventAdded: (newData, newDate) async {
          if (uid == null) return;

          try {
            final col = FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('jikgwan_records');

            // ✅ 저장/수정 시 현재 팀 ID(widget.currentTeamId)를 박제합니다.
            final Map<String, dynamic> dataToSave = {
              ...newData,
              'date': Timestamp.fromDate(newDate),
              'myTeamId': widget.currentTeamId,
            };

            if (event != null && event['id'] != null) {
              await col.doc(event['id']).update(dataToSave);
            } else {
              dataToSave['createdAt'] = FieldValue.serverTimestamp();
              await col.add(dataToSave);
            }
            _loadMyRecordsFromFirestore();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
            }
          }
        },
      ),
    );
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
        onPressed: () => _showAddScheduleSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showAddScheduleSheet(event: event);
                  } else if (value == 'delete') {
                    _deleteEvent(event['id']);
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
}

class AddScheduleBottomSheet extends StatefulWidget {
  final DateTime initialDate;
  final Map<String, dynamic>? editingEvent;
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
    if (widget.editingEvent != null) {
      _titleController.text = widget.editingEvent!['title'];
      _selectedOpponent = widget.editingEvent!['opponent'];
      _selectedStadium = widget.editingEvent!['stadium'];
      _selectedResult = widget.editingEvent!['result'];
      _selectedDate = widget.editingEvent!['date'];
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
                      const SnackBar(content: Text('모든 항목을 입력해 주세요!')),
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
