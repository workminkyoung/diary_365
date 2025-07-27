import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';

class DiaryService {
  static const String _storageKey = 'diary_entries';
  
  // Get all diary entries
  Future<List<DiaryEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_storageKey) ?? [];
    
    return entriesJson
        .map((json) => DiaryEntry.fromJson(jsonDecode(json)))
        .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  // Get diary entry by ID
  Future<DiaryEntry?> getEntryById(String id) async {
    final entries = await getAllEntries();
    try {
      return entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save diary entry
  Future<void> saveEntry(DiaryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();
    
    // Check if entry already exists
    final existingIndex = entries.indexWhere((e) => e.id == entry.id);
    
    if (existingIndex >= 0) {
      // Update existing entry
      entries[existingIndex] = entry;
    } else {
      // Add new entry
      entries.add(entry);
    }
    
    // Save to storage
    final entriesJson = entries
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, entriesJson);
  }

  // Delete diary entry
  Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();
    
    entries.removeWhere((entry) => entry.id == id);
    
    final entriesJson = entries
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    
    await prefs.setStringList(_storageKey, entriesJson);
  }

  // Get entries by date range
  Future<List<DiaryEntry>> getEntriesByDateRange(DateTime start, DateTime end) async {
    final entries = await getAllEntries();
    return entries.where((entry) {
      return entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
             entry.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get entries for a specific date
  Future<List<DiaryEntry>> getEntriesForDate(DateTime date) async {
    final entries = await getAllEntries();
    return entries.where((entry) {
      return entry.date.year == date.year &&
             entry.date.month == date.month &&
             entry.date.day == date.day;
    }).toList();
  }

  // Generate unique ID
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
} 