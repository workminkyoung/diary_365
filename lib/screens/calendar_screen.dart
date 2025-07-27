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
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    children: [
                      // 월 표시 상단 영역
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        child: Text(
                          DateFormat('MM 월').format(_focusedDate),
                          style: TextStyle(
                            fontFamily: 'OngeulipParkDaHyeon',
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
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                        child: Row(
                          children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          fontFamily: 'OngeulipParkDaHyeon',
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: day == 'SUN' 
                                              ? Colors.red 
                                              : day == 'SAT' 
                                                  ? Colors.blue 
                                                  : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      // 캘린더 그리드
                      Expanded(
                        child: _buildCalendarGrid(),
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
    final lastDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    // 이전 달의 마지막 날짜들
    final previousMonth = DateTime(_focusedDate.year, _focusedDate.month - 1, 0);
    final daysInPreviousMonth = previousMonth.day;
    
    // 다음 달의 첫 번째 날짜들
    final nextMonthStart = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
    
    // 전체 그리드에 필요한 셀 수 계산 (6주 * 7일 = 42개)
    final totalCells = 42;
    final cells = <Widget>[];
    
    for (int i = 0; i < totalCells; i++) {
      DateTime cellDate;
      bool isCurrentMonth = false;
      
      if (i < firstWeekday) {
        // 이전 달
        final day = daysInPreviousMonth - firstWeekday + i + 1;
        cellDate = DateTime(_focusedDate.year, _focusedDate.month - 1, day);
      } else if (i >= firstWeekday && i < firstWeekday + daysInMonth) {
        // 현재 달
        final day = i - firstWeekday + 1;
        cellDate = DateTime(_focusedDate.year, _focusedDate.month, day);
        isCurrentMonth = true;
      } else {
        // 다음 달
        final day = i - firstWeekday - daysInMonth + 1;
        cellDate = DateTime(_focusedDate.year, _focusedDate.month + 1, day);
      }
      
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
            decoration: BoxDecoration(
              // 이미지 테두리 사용 예시 (이미지가 있다면)
              // border: Border.all(color: Colors.grey.shade300, width: 0.5),
              // 또는 이미지 배경 사용
              // image: DecorationImage(
              //   image: AssetImage('assets/images/calendar_cell_bg.png'),
              //   fit: BoxFit.cover,
              // ),
              // 현재는 일반 테두리 사용
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: Stack(
              children: [
                // 날짜 표시 (좌측상단)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Text(
                    '${cellDate.day}',
                    style: TextStyle(
                      fontFamily: 'OngeulipParkDaHyeon',
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
                        fontFamily: 'OngeulipParkDaHyeon',
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
      children: cells,
    );
  }
} 