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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedDate = _focusedDate;
    // PageController를 먼저 초기화합니다.
    _pageController = PageController(initialPage: 1200);
    // 그 다음에 데이터 로딩을 시작합니다.
    _loadEntries();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _onDaySelected(DateTime date, DateTime focusedDate) async {
    // 날짜를 탭했을 때, PageView의 현재 월과 다른 월의 날짜라면 PageView를 해당 월로 이동시킵니다.
    if (date.month != _focusedDate.month || date.year != _focusedDate.year) {
      final now = DateTime.now();
      final currentMonth = now.year * 12 + now.month;
      final selectedMonth = date.year * 12 + date.month;
      final page = 1200 + (selectedMonth - currentMonth);
      _pageController.jumpToPage(page);
    }
    
    setState(() {
      _selectedDate = date;
      // _focusedDate는 PageView가 제어하므로 여기서는 변경하지 않습니다.
    });

    final entriesForDate = _getEntriesForDate(date);
    // 해당 날짜에 일기가 없으면 새로운 DiaryEntry 객체를 생성합니다.
    final existingEntry = entriesForDate.isNotEmpty 
        ? entriesForDate.first 
        : DiaryEntry(
            id: '', // 새 일기이므로 id는 비워둡니다.
            title: '',
            content: '',
            date: date,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (page) {
            final now = DateTime.now();
            // 페이지 인덱스를 기반으로 현재 표시해야 할 월을 계산합니다.
            final newFocusedDate = DateTime(now.year, now.month + (page - 1200), 1);

            // 월이 변경되었을 경우에만 상태를 업데이트하고 데이터를 새로 로드합니다.
            if (newFocusedDate.year != _focusedDate.year || newFocusedDate.month != _focusedDate.month) {
              setState(() {
                _focusedDate = newFocusedDate;
                _isLoading = true;
              });
              _loadEntries();
            }
          },
          itemBuilder: (context, index) {
            final now = DateTime.now();
            // 각 페이지에 해당하는 월을 계산합니다.
            final pageDate = DateTime(now.year, now.month + (index - 1200), 1);
            
            // 로딩 중이거나, 현재 페이지가 로딩이 필요한 월인 경우 로딩 인디케이터를 표시합니다.
            if (_isLoading && pageDate.year == _focusedDate.year && pageDate.month == _focusedDate.month) {
              return const Center(child: CircularProgressIndicator());
            }

            return _buildMonthView(pageDate);
          },
        ),
      ),
    );
  }

  // 월별 뷰를 구성하는 위젯
  Widget _buildMonthView(DateTime dateForMonth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 12.0),
      child: Center(
        child: Column(
          children: [
            // 월 표시 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Text(
                DateFormat('MM 월').format(dateForMonth),
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
            // 캘린더 그리드와 라인
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
                        _buildCalendarGrid(dateForMonth),
                        // 모든 가로 라인 이미지들
                        ...List.generate(5, (index) {
                          return Positioned(
                            top: cellHeight * (index + 1),
                            left: 0,
                            right: 0,
                            child: Transform.rotate(
                              angle: 0,
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
                            left: cellWidth * (index + 1),
                            child: Transform.rotate(
                              angle: 0,
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
    );
  }

  Widget _buildCalendarGrid(DateTime displayDate) {
    final firstDayOfMonth = DateTime(displayDate.year, displayDate.month, 1);
    
    final firstDayOfGrid = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday % 7));

    final totalCells = 42;
    final cells = <Widget>[];

    for (int i = 0; i < totalCells; i++) {
      final DateTime cellDate = firstDayOfGrid.add(Duration(days: i));
      final bool isCurrentMonth = cellDate.month == displayDate.month;
      
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
          onTap: () => _onDaySelected(cellDate, displayDate),
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
      physics: const NeverScrollableScrollPhysics(), // PageView 내부 스크롤 비활성화
      children: cells,
    );
  }
} 