import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';

class DiaryWriteScreen extends StatefulWidget {
  final DiaryEntry? entry;
  final DateTime? selectedDate;

  const DiaryWriteScreen({super.key, this.entry, this.selectedDate});

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> {
  final _contentController = TextEditingController();
  final _diaryService = DiaryService();
  
  late DateTime _selectedDate;
  
  // 디버깅용 아웃라인 표시 여부
  bool _showDebugOutlines = true;

  @override
  void initState() {
    super.initState();
    // 기존 일기를 수정하는 경우, 해당 내용을 컨트롤러에 설정합니다.
    if (widget.entry != null) {
      _contentController.text = widget.entry!.content;
      _selectedDate = widget.entry!.date;
    } else {
      // 새 일기를 작성하는 경우, 전달받은 날짜나 현재 날짜를 사용합니다.
      _selectedDate = widget.selectedDate ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    // 화면이 닫힐 때, 컨트롤러의 내용이 비어있지 않다면 자동 저장합니다.
    _autoSave();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _autoSave() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      // 내용이 비어있으면 저장하지 않습니다.
      // 만약 기존에 내용이 있었는데 모두 지운 경우, 삭제 처리를 할 수도 있습니다.
      // 현재는 내용이 없으면 아무것도 하지 않는 것으로 구현합니다.
      return;
    }

    try {
      final now = DateTime.now();
      // 기존 일기이거나, 새 일기이지만 id가 없는 경우를 모두 처리합니다.
      final entryId = widget.entry?.id ?? _diaryService.generateId();
      
      final entry = DiaryEntry(
        id: entryId,
        // 제목은 이제 사용하지 않으므로, 내용의 첫 줄을 제목으로 사용하거나 비워둡니다.
        title: content.split('\n').first, 
        content: content,
        date: _selectedDate,
        createdAt: widget.entry?.createdAt ?? now,
        updatedAt: now,
      );

      await _diaryService.saveEntry(entry);
    } catch (e) {
      // 자동 저장이므로 사용자에게 오류를 표시하기보다는 로깅을 하는 것이 좋습니다.
      print('Auto-save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              body: SafeArea(
          child: Padding(
            // 요청하신 대로 top: 60, 좌우 12의 패딩을 적용합니다.
            padding: const EdgeInsets.only(top: 60, left: 12, right: 12, bottom: 12),
            child: Column(
              children: [
                // cellStroke 이미지 영역 (타이틀 + 내용입력)
                Expanded(
                  child: Stack(
                    children: [
                      // 배경 이미지들
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/cellBG.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/cellStroke.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                      // 타이틀 영역
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        height: 60, // 타이틀 영역 높이
                        child: Container(
                          decoration: _showDebugOutlines 
                              ? BoxDecoration(
                                  border: Border.all(color: Colors.red, width: 2), // 디버깅용 빨간색 아웃라인
                                )
                              : null,
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: '제목을 입력하세요...',
                              border: InputBorder.none,
                              filled: false,
                            ),
                            style: TextStyle(
                              fontFamily: 'CookieRun',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // 내용 입력 영역
                      Positioned(
                        top: 92, // 타이틀 영역 아래 (16 + 60 + 16)
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          decoration: _showDebugOutlines 
                              ? BoxDecoration(
                                  border: Border.all(color: Colors.blue, width: 2), // 디버깅용 파란색 아웃라인
                                )
                              : null,
                          child: TextFormField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              hintText: '오늘 있었던 일들을 자유롭게 적어보세요...',
                              border: InputBorder.none,
                              filled: false,
                            ),
                            style: const TextStyle(
                              fontFamily: 'CookieRun',
                              fontSize: 16,
                            ),
                            autofocus: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 팁 텍스트 (cellStroke 영역 밖)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 27, right: 27),
                  child: Text(
                    '팁. ♤ ♧ † £ ¢ 특수기호 입력하면 고양이들이 나와요!',
                    style: TextStyle(
                      fontFamily: 'CookieRun',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
} 