import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../team_theme.dart';

class CalendarScreen extends StatefulWidget {
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
  List<Map<String, String>> _todayScheduledGames = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMyRecordsFromFirestore();
    _loadGamesForDate(_selectedDay!);
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _loadGamesForDate(DateTime date) async {
    try {
      final rawData = await rootBundle.loadString('assets/data/games.csv');
      final lines = rawData.replaceAll('\r', '').split('\n');
      final String targetDate = "${date.year}.${date.month}.${date.day}";

      List<Map<String, String>> matches = [];
      for (int i = 1; i < lines.length; i++) {
        final cells = lines[i].split(',');
        if (cells.length < 5) continue;

        if (cells[0].trim() == targetDate) {
          matches.add({
            'stadium': cells[1].trim(),
            'away': cells[3].trim(),
            'home': cells[4].trim(),
            'time': (cells.length > 5) ? cells[5].trim() : '',
          });
        }
      }

      String myTeamName = teamThemes[widget.currentTeamId]?.nameKo ?? '';
      if (myTeamName.isNotEmpty) {
        matches.sort((a, b) {
          bool aIsMyTeam =
              a['away']!.contains(myTeamName) ||
              a['home']!.contains(myTeamName) ||
              myTeamName.contains(a['away']!) ||
              myTeamName.contains(a['home']!);
          bool bIsMyTeam =
              b['away']!.contains(myTeamName) ||
              b['home']!.contains(myTeamName) ||
              myTeamName.contains(b['away']!) ||
              myTeamName.contains(b['home']!);

          if (aIsMyTeam && !bIsMyTeam) return -1;
          if (!aIsMyTeam && bIsMyTeam) return 1;
          return 0;
        });
      }

      if (mounted) {
        setState(() {
          _todayScheduledGames = matches;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _todayScheduledGames = [];
        });
      }
    }
  }

  // 🤖 자동 계산 헬퍼 함수: 스코어보드 DB에서 결과를 읽어와 승/무/패를 리턴합니다.
  Future<String?> _fetchAndCalcResult(
    DateTime date,
    String? away,
    String? home,
    String myTeamId,
  ) async {
    if (away == null || home == null) return null;

    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    String getCode(String t) {
      if (t.contains('SSG')) return 'SK';
      if (t.contains('삼성')) return 'SS';
      if (t.contains('두산')) return 'OB';
      if (t.contains('기아') || t.contains('KIA')) return 'HT';
      if (t.contains('LG')) return 'LG';
      if (t.contains('NC')) return 'NC';
      if (t.contains('롯데')) return 'LT';
      if (t.contains('키움')) return 'WO';
      if (t.contains('한화')) return 'HH';
      if (t.contains('KT')) return 'KT';
      return t;
    }

    String gameId = "$y$m$d${getCode(away)}${getCode(home)}0";

    try {
      final scoreDoc = await FirebaseFirestore.instance
          .collection('kbo_scoreboards')
          .doc(gameId)
          .get();
      if (scoreDoc.exists) {
        final scoreData = scoreDoc.data() as Map<String, dynamic>;
        final scoreboard = scoreData['scoreboard'] as List<dynamic>?;

        if (scoreboard != null && scoreboard.length >= 2) {
          int awayScore = int.tryParse(scoreboard[0]['R'].toString()) ?? -1;
          int homeScore = int.tryParse(scoreboard[1]['R'].toString()) ?? -1;

          if (awayScore == -1 || homeScore == -1) return null; // 아직 점수 없음

          if (awayScore == homeScore) return '무';

          String myName = teamThemes[myTeamId]?.nameKo ?? '';
          bool isMyTeamAway = away.contains(myName) || myName.contains(away);
          bool isMyTeamHome = home.contains(myName) || myName.contains(home);

          if (awayScore > homeScore) {
            return isMyTeamAway ? '승' : '패';
          } else {
            return isMyTeamHome ? '승' : '패';
          }
        }
      }
    } catch (e) {
      debugPrint('스코어 자동 계산 에러: $e');
    }
    return null;
  }

  // ♻️ 데이터 로드 시 승/무/패 자동 업데이트 로직 적용
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
        String? recordTeamId = data['myTeamId'];

        if (recordTeamId != null && recordTeamId != widget.currentTeamId) {
          continue;
        }

        final DateTime date = (data['date'] as Timestamp).toDate();
        final dateKey = DateTime.utc(date.year, date.month, date.day);

        // 🔥 결과가 없고(null), 오늘을 포함해 경기 날짜가 지났을 때만 스코어 계산 시도
        String? currentResult = data['result'];
        if (currentResult == null && !date.isAfter(DateTime.now())) {
          currentResult = await _fetchAndCalcResult(
            date,
            data['awayTeam'],
            data['homeTeam'],
            recordTeamId!,
          );
          if (currentResult != null) {
            // 계산된 승무패를 DB에 덮어씀 (다음 로드부터는 계산 안 함)
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('jikgwan_records')
                .doc(doc.id)
                .update({'result': currentResult});
          }
        }

        final event = {
          'id': doc.id,
          'title': data['title'],
          'awayTeam': data['awayTeam'],
          'homeTeam': data['homeTeam'],
          'opponent': data['opponent'],
          'stadium': data['stadium'],
          'result': currentResult, // 🔥 새로 업데이트된 결과 렌더링
          'date': date,
          'myTeamId': recordTeamId,
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

  void _showAddScheduleSheet({
    Map<String, dynamic>? event,
    Map<String, String>? prefilledGame,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddScheduleBottomSheet(
        currentTeamId: widget.currentTeamId,
        initialDate: _selectedDay!,
        editingEvent: event,
        prefilledGame: prefilledGame,
        onEventAdded: (newData, newDate) async {
          if (uid == null) return;

          try {
            final col = FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('jikgwan_records');

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
                    _loadGamesForDate(selectedDay);
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
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
                Expanded(child: _buildBottomSection()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFC62828),
        onPressed: () => _showAddScheduleSheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBottomSection() {
    final events = _getEventsForDay(_selectedDay!);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: [
        if (events.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Text(
              '나의 직관 기록',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          ...events.map((e) => _buildMyRecordCard(e)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 30, color: Color(0xFFEEEEEE)),
          ),
        ],

        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Text(
            '오늘의 KBO 경기 일정',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),

        if (_todayScheduledGames.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Text(
                '해당 날짜에 예정된 경기가 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          for (var game in _todayScheduledGames) _buildKboGameCard(game),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildMyRecordCard(Map<String, dynamic> event) {
    final bool hasResult = event['result'] != null;
    Color resultColor = Colors.grey;
    if (event['result'] == '승') {
      resultColor = const Color(0xFFC62828);
    } else if (event['result'] == '무') {
      resultColor = Colors.green;
    } else if (event['result'] == '패') {
      resultColor = Colors.blue;
    }

    String matchInfo = "";
    if (event['awayTeam'] != null && event['homeTeam'] != null) {
      matchInfo = "${event['awayTeam']} vs ${event['homeTeam']}";
    } else {
      matchInfo = "상대: ${event['opponent']}";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
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
                  "$matchInfo | 장소: ${event['stadium']}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          if (hasResult)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
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
  }

  Widget _buildKboGameCard(Map<String, String> game) {
    return InkWell(
      onTap: () => _showAddScheduleSheet(prefilledGame: game),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_baseball,
                color: Colors.black54,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${game['away']} vs ${game['home']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${game['stadium']} | ${game['time']}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle, color: Color(0xFFC62828), size: 28),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🌟 바텀시트: 수동 입력 제거 버전
// ==========================================
class AddScheduleBottomSheet extends StatefulWidget {
  final String currentTeamId;
  final DateTime initialDate;
  final Map<String, dynamic>? editingEvent;
  final Map<String, String>? prefilledGame;
  final Function(Map<String, dynamic>, DateTime) onEventAdded;

  const AddScheduleBottomSheet({
    super.key,
    required this.currentTeamId,
    required this.initialDate,
    this.editingEvent,
    this.prefilledGame,
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

  String? _selectedAwayTeam;
  String? _selectedHomeTeam;
  String? _selectedStadium;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    if (widget.editingEvent != null) {
      _titleController.text = widget.editingEvent!['title'];
      _selectedAwayTeam = widget.editingEvent!['awayTeam'];
      _selectedHomeTeam = widget.editingEvent!['homeTeam'];

      if (_selectedAwayTeam == 'KIA') _selectedAwayTeam = '기아';
      if (_selectedHomeTeam == 'KIA') _selectedHomeTeam = '기아';

      if (_selectedAwayTeam != null && !_teams.contains(_selectedAwayTeam)) {
        _selectedAwayTeam = null;
      }
      if (_selectedHomeTeam != null && !_teams.contains(_selectedHomeTeam)) {
        _selectedHomeTeam = null;
      }

      if (_selectedAwayTeam == null &&
          widget.editingEvent!['opponent'] != null) {
        String opp = widget.editingEvent!['opponent'];
        if (opp == 'KIA') opp = '기아';

        if (_teams.contains(opp)) {
          _selectedAwayTeam = opp;
          String myTeamName = teamThemes[widget.currentTeamId]?.nameKo ?? '';
          for (String t in _teams) {
            if (myTeamName.contains(t) || t.contains(myTeamName)) {
              _selectedHomeTeam = t;
              break;
            }
          }
        }
      }

      _selectedStadium = widget.editingEvent!['stadium'];
      _selectedDate = widget.editingEvent!['date'];
    } else if (widget.prefilledGame != null) {
      String away = widget.prefilledGame!['away']!;
      String home = widget.prefilledGame!['home']!;
      String stadium = widget.prefilledGame!['stadium']!;

      away = away.toUpperCase().replaceAll('KIA', '기아');
      home = home.toUpperCase().replaceAll('KIA', '기아');

      for (String t in _teams) {
        if (away.contains(t) || t.contains(away)) _selectedAwayTeam = t;
        if (home.contains(t) || t.contains(home)) _selectedHomeTeam = t;
      }

      String upperStadium = stadium.toUpperCase();
      if (upperStadium.contains('JAMSIL') || upperStadium.contains('잠실')) {
        _selectedStadium = '잠실';
      } else if (upperStadium.contains('GOCHEOK') ||
          upperStadium.contains('고척')) {
        _selectedStadium = '고척';
      } else if (upperStadium.contains('MUNHAK') ||
          upperStadium.contains('INCHEON') ||
          upperStadium.contains('문학')) {
        _selectedStadium = '문학';
      } else if (upperStadium.contains('SUWON') ||
          upperStadium.contains('수원')) {
        _selectedStadium = '수원';
      } else if (upperStadium.contains('DAEJEON') ||
          upperStadium.contains('대전')) {
        _selectedStadium = '대전';
      } else if (upperStadium.contains('GWANGJU') ||
          upperStadium.contains('광주')) {
        _selectedStadium = '광주';
      } else if (upperStadium.contains('DAEGU') ||
          upperStadium.contains('대구')) {
        _selectedStadium = '대구';
      } else if (upperStadium.contains('CHANGWON') ||
          upperStadium.contains('창원')) {
        _selectedStadium = '창원';
      } else if (upperStadium.contains('SAJIK') ||
          upperStadium.contains('사직') ||
          upperStadium.contains('BUSAN')) {
        _selectedStadium = '사직';
      }
    } else {
      String myTeamName = teamThemes[widget.currentTeamId]?.nameKo ?? '';
      for (String t in _teams) {
        if (myTeamName.contains(t) || t.contains(myTeamName)) {
          _selectedHomeTeam = t;
          break;
        }
      }
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

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAwayTeam,
                    decoration: const InputDecoration(
                      labelText: '원정 팀',
                      border: OutlineInputBorder(),
                    ),
                    items: _teams
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedAwayTeam = val),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'VS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedHomeTeam,
                    decoration: const InputDecoration(
                      labelText: '홈 팀',
                      border: OutlineInputBorder(),
                    ),
                    items: _teams
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedHomeTeam = val),
                  ),
                ),
              ],
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

            // 🔥 수동 입력 대신 자동 업데이트 안내 문구로 깔끔하게 교체
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _isFutureDate()
                      ? '경기 후에 결과가 자동으로 기록됩니다. ⚾️'
                      : '앱이 경기 결과를 자동으로 불러와 기록합니다! 📊',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                      _selectedAwayTeam == null ||
                      _selectedHomeTeam == null ||
                      _selectedStadium == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 항목을 입력해 주세요!')),
                    );
                    return;
                  }

                  String myTeamValue = '';
                  if (widget.currentTeamId == 'kia') {
                    myTeamValue = '기아';
                  } else if (widget.currentTeamId == 'lg') {
                    myTeamValue = 'LG';
                  } else if (widget.currentTeamId == 'doosan') {
                    myTeamValue = '두산';
                  } else if (widget.currentTeamId == 'lotte') {
                    myTeamValue = '롯데';
                  } else if (widget.currentTeamId == 'samsung') {
                    myTeamValue = '삼성';
                  } else if (widget.currentTeamId == 'ssg') {
                    myTeamValue = 'SSG';
                  } else if (widget.currentTeamId == 'nc') {
                    myTeamValue = 'NC';
                  } else if (widget.currentTeamId == 'kiwoom') {
                    myTeamValue = '키움';
                  } else if (widget.currentTeamId == 'hanwha') {
                    myTeamValue = '한화';
                  } else if (widget.currentTeamId == 'kt') {
                    myTeamValue = 'KT';
                  }

                  String calculatedOpponent = '';

                  if (_selectedAwayTeam == myTeamValue) {
                    calculatedOpponent = _selectedHomeTeam!;
                  } else if (_selectedHomeTeam == myTeamValue) {
                    calculatedOpponent = _selectedAwayTeam!;
                  } else {
                    calculatedOpponent =
                        '$_selectedAwayTeam vs $_selectedHomeTeam';
                  }

                  widget.onEventAdded({
                    'title': _titleController.text,
                    'awayTeam': _selectedAwayTeam,
                    'homeTeam': _selectedHomeTeam,
                    'opponent': calculatedOpponent,
                    'stadium': _selectedStadium,
                    // 🔥 기존의 result가 있으면 살려두고, 없으면 null 처리 (자동 갱신 대상)
                    'result': widget.editingEvent != null
                        ? widget.editingEvent!['result']
                        : null,
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
}
