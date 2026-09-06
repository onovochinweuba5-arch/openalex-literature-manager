import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/paper.dart';

class LocalStorage {
  static const _savedKey = 'saved_papers';
  static const _historyKey = 'search_history';

  Future<List<Paper>> savedPapers() async {
    final preferences = await SharedPreferences.getInstance();
    final values = preferences.getStringList(_savedKey) ?? const [];
    return values
        .map(
          (value) =>
              Paper.fromStorage(jsonDecode(value) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> savePaper(Paper paper) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await savedPapers();
    final updated = [paper, ...saved.where((item) => item.id != paper.id)];
    await preferences.setStringList(
      _savedKey,
      updated.map((item) => jsonEncode(item.toStorage())).toList(),
    );
  }

  Future<void> removePaper(String id) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await savedPapers();
    await preferences.setStringList(
      _savedKey,
      saved
          .where((item) => item.id != id)
          .map((item) => jsonEncode(item.toStorage()))
          .toList(),
    );
  }

  Future<List<String>> searchHistory() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_historyKey) ?? const [];
  }

  Future<void> addSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final history = await searchHistory();
    await preferences.setStringList(
      _historyKey,
      [
        trimmed,
        ...history.where((item) => item.toLowerCase() != trimmed.toLowerCase()),
      ].take(12).toList(),
    );
  }

  Future<void> clearHistory() async =>
      (await SharedPreferences.getInstance()).remove(_historyKey);
}

String papersToCsv(Iterable<Paper> papers) {
  final rows = <List<String>>[
    ['Title', 'Authors', 'Year', 'Journal', 'DOI', 'Citations', 'OpenAlex ID'],
    ...papers.map(
      (paper) => [
        paper.title,
        paper.authorsLabel,
        '${paper.year ?? ''}',
        paper.journal ?? '',
        paper.doi ?? '',
        '${paper.citationCount}',
        paper.id,
      ],
    ),
  ];
  return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
}

String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
