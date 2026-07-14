import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchPageController extends GetxController {
  final searchController = TextEditingController();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> get searchResults => _searchResults;

  // Mock data for search
  final List<Map<String, dynamic>> _allData = [
    {
      'id': 1,
      'type': 'subject',
      'title': 'Physics',
      'subtitle': '15 chapters • 125 videos',
    },
    {
      'id': 2,
      'type': 'subject',
      'title': 'Chemistry',
      'subtitle': '12 chapters • 98 videos',
    },
    {
      'id': 3,
      'type': 'subject',
      'title': 'Mathematics',
      'subtitle': '18 chapters • 156 videos',
    },
    {
      'id': 4,
      'type': 'exam',
      'title': 'Physics Mock Test 1',
      'subtitle': '30 questions • 60 minutes',
    },
    {
      'id': 5,
      'type': 'exam',
      'title': 'Chemistry Quiz',
      'subtitle': '15 questions • 30 minutes',
    },
    {
      'id': 6,
      'type': 'note',
      'title': 'Newton\'s Laws of Motion',
      'subtitle': 'Physics • Chapter 1',
    },
    {
      'id': 7,
      'type': 'note',
      'title': 'Atomic Structure',
      'subtitle': 'Chemistry • Chapter 1',
    },
    {
      'id': 8,
      'type': 'video',
      'title': 'Introduction to Mechanics',
      'subtitle': 'Physics • 15:30',
    },
    {
      'id': 9,
      'type': 'video',
      'title': 'Quantum Theory Basics',
      'subtitle': 'Physics • 22:45',
    },
    {
      'id': 10,
      'type': 'exam',
      'title': 'Mathematics Practice Test',
      'subtitle': '25 questions • 45 minutes',
    },
  ];

  void search(String query) async {
    _searchQuery = query.trim();
    
    if (_searchQuery.isEmpty) {
      _searchResults = [];
      update();
      return;
    }

    _isLoading = true;
    update();

    try {
      // Simulate API delay
      await Future.delayed(Duration(milliseconds: 500));

      // Filter results based on query
      _searchResults = _allData.where((item) {
        final title = item['title'].toString().toLowerCase();
        final subtitle = item['subtitle'].toString().toLowerCase();
        final type = item['type'].toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        return title.contains(searchLower) ||
               subtitle.contains(searchLower) ||
               type.contains(searchLower);
      }).toList();

      // Sort by relevance (exact matches first, then partial matches)
      _searchResults.sort((a, b) {
        final aTitle = a['title'].toString().toLowerCase();
        final bTitle = b['title'].toString().toLowerCase();
        final searchLower = _searchQuery.toLowerCase();

        final aExact = aTitle.startsWith(searchLower) ? 0 : 1;
        final bExact = bTitle.startsWith(searchLower) ? 0 : 1;

        return aExact.compareTo(bExact);
      });

    } catch (e) {
      Get.snackbar('Error', 'Failed to search');
    } finally {
      _isLoading = false;
      update();
    }
  }

  void openResult(Map<String, dynamic> result) {
    switch (result['type']) {
      case 'subject':
        Get.snackbar('Info', 'Opening subject: ${result['title']}');
        break;
      case 'exam':
        Get.snackbar('Info', 'Opening exam: ${result['title']}');
        break;
      case 'note':
        Get.snackbar('Info', 'Opening note: ${result['title']}');
        break;
      case 'video':
        Get.snackbar('Info', 'Opening video: ${result['title']}');
        break;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
