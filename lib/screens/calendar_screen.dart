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
      appBar: AppBar(
        title: Text(
          DateFormat('yyyy년 M월').format(_focusedDate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
              });
            },
            tooltip: '이전 달',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime.now();
                _selectedDate = DateTime.now();
              });
            },
            tooltip: '오늘로 이동',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
              });
            },
            tooltip: '다음 달',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntries,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 요일 헤더
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: ['일', '월', '화', '수', '목', '금', '토']
                        .map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: day == '일' 
                                        ? Colors.red 
                                        : day == '토' 
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
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
              color: isSelected 
                  ? Colors.blue.shade100 
                  : isToday 
                      ? Colors.orange.shade50 
                      : Colors.white,
            ),
            child: Column(
              children: [
                // 날짜 표시
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${cellDate.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentMonth 
                          ? (isToday ? Colors.orange : Colors.black87)
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                // 일기 제목 표시
                if (entriesForDate.isNotEmpty)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      child: Text(
                        entriesForDate.first.title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
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