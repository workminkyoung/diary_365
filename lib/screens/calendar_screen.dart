import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';
import 'diary_write_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DiaryService _diaryService = DiaryService();
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await _diaryService.getAllEntries();
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일기 목록을 불러오는데 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDaySelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _focusedDate = focusedDate;
    });
    
    // 해당 날짜의 일기 작성 화면으로 이동
    _navigateToWriteScreen(selectedDate);
  }

  Future<void> _navigateToWriteScreen(DateTime date) async {
    // 해당 날짜에 이미 일기가 있는지 확인
    final existingEntry = _entries.firstWhere(
      (entry) => entry.date.year == date.year &&
                  entry.date.month == date.month &&
                  entry.date.day == date.day,
      orElse: () => DiaryEntry(
        id: '',
        title: '',
        content: '',
        date: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(
          entry: existingEntry.id.isNotEmpty ? existingEntry : null,
          selectedDate: date,
        ),
      ),
    );

    if (result == true) {
      // 일기가 저장되었으면 목록을 새로고침
      _loadEntries();
    }
  }

  List<DiaryEntry> _getEntriesForDate(DateTime date) {
    return _entries.where((entry) =>
        entry.date.year == date.year &&
        entry.date.month == date.month &&
        entry.date.day == date.day).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 12.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    children: [
                      // 월 표시 상단 영역
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 40.0),
                        child: Text(
                          DateFormat('MM 월').format(_focusedDate),
                          style: TextStyle(
                            fontFamily: 'CookieRun',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      // 요일 헤더
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          fontFamily: 'CookieRun',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // 캘린더 그리드
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double gridWidth = constraints.maxWidth;
                            final double cellWidth = gridWidth / 7;
                            final double cellHeight = cellWidth / (48 / 84);
                            final double gridHeight = cellHeight * 6;
                            
                            return SizedBox(
                              width: gridWidth,
                              height: gridHeight,
                              child: Stack(
                                children: [
                                  _buildCalendarGrid(),
                                  // 모든 가로 라인 이미지들
                                  ...List.generate(5, (index) {
                                    return Positioned(
                                      top: cellHeight * (index + 1), // 각 줄 사이
                                      left: 0,
                                      right: 0,
                                      child: Transform.rotate(
                                        angle: 0, // 회전 없음 (원래 방향)
                                        child: Image.asset(
                                          'assets/images/hori.png',
                                          fit: BoxFit.fitWidth,
                                        ),
                                      ),
                                    );
                                  }),
                                  // 모든 세로 라인 이미지들
                                  ...List.generate(6, (index) {
                                    return Positioned(
                                      top: 0,
                                      left: cellWidth * (index + 1), // 각 열 사이
                                      child: Transform.rotate(
                                        angle: 0, // 회전 없음 (원래 방향)
                                        child: Image.asset(
                                          'assets/images/verti.png',
                                          fit: BoxFit.none,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    
    // 달력의 첫 번째 칸(일요일)에 해당하는 정확한 날짜를 계산합니다.
    // 예: 7월 1일이 화요일(weekday=2)이면, 1일에서 2일을 빼서 6월 29일(일요일)을 구합니다.
    // (DateTime.weekday는 월=1, ..., 일=7 이므로, 일요일(7)은 0으로 맞춰주기 위해 나머지 연산자(%)를 사용합니다.)
    final firstDayOfGrid = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));

    final totalCells = 42;
    final cells = <Widget>[];

    for (int i = 0; i < totalCells; i++) {
      // 첫 날짜부터 하루씩 더해가며 각 셀의 날짜를 계산합니다.
      final DateTime cellDate = firstDayOfGrid.add(Duration(days: i));
      final bool isCurrentMonth = cellDate.month == _focusedDate.month;
      
      final isToday = cellDate.year == DateTime.now().year &&
                      cellDate.month == DateTime.now().month &&
                      cellDate.day == DateTime.now().day;
      
      final isSelected = _selectedDate != null &&
                        cellDate.year == _selectedDate!.year &&
                        cellDate.month == _selectedDate!.month &&
                        cellDate.day == _selectedDate!.day;
      
      final entriesForDate = _getEntriesForDate(cellDate);
      
      cells.add(
        GestureDetector(
          onTap: () => _onDaySelected(cellDate, _focusedDate),
                      child: Container(
            child: Stack(
              children: [
                // 날짜 표시 (좌측상단)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Text(
                    '${cellDate.day}',
                    style: TextStyle(
                      fontFamily: 'CookieRun',
                      fontSize: 16,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      color: isCurrentMonth 
                          ? (isToday ? Colors.orange : Colors.black87)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                // 일기 제목 표시 (중앙 하단)
                if (entriesForDate.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 4,
                    right: 4,
                    child: Text(
                      entriesForDate.first.title,
                      style: TextStyle(
                        fontFamily: 'CookieRun',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      childAspectRatio: 48 / 84, // 48:84 비율로 설정
      children: cells,
    );
  }
} 