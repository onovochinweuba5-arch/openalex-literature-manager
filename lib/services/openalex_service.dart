import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/paper.dart';

class SearchPage {
  const SearchPage({
    required this.papers,
    required this.totalResults,
    required this.page,
    required this.perPage,
  });
  final List<Paper> papers;
  final int totalResults;
  final int page;
  final int perPage;
  int get totalPages => (totalResults / perPage).ceil().clamp(1, 1000);
}

class OpenAlexException implements Exception {
  const OpenAlexException(this.message);
  final String message;
  @override
  String toString() => message;
}

class OpenAlexService {
  OpenAlexService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _baseUrl = 'https://api.openalex.org/works';
  static const _userAgent =
      'OpenAlexLiteratureManager/1.0 (mailto:researcher@example.com)';

  Future<SearchPage> search({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'search': query.trim(),
        'page': '$page',
        'per-page': '$perPage',
        'mailto': 'researcher@example.com',
      },
    );
    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw const OpenAlexException('OpenAlex could not complete this search.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>? ?? const {};
    final results = (data['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Paper.fromJson)
        .toList();
    return SearchPage(
      papers: results,
      totalResults: meta['count'] as int? ?? results.length,
      page: page,
      perPage: perPage,
    );
  }

  Future<Paper> getPaper(String id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/$id'),
      headers: {'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw const OpenAlexException('This paper could not be loaded.');
    }
    return Paper.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
