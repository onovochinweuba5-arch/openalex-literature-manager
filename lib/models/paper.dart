class Paper {
  const Paper({
    required this.id,
    required this.title,
    required this.authors,
    this.publication,
    this.year,
    this.journal,
    this.doi,
    this.citationCount = 0,
    this.abstractText,
    this.concepts = const [],
    this.primaryLocationUrl,
  });

  final String id;
  final String title;
  final List<String> authors;
  final String? publication;
  final int? year;
  final String? journal;
  final String? doi;
  final int citationCount;
  final String? abstractText;
  final List<String> concepts;
  final String? primaryLocationUrl;

  String get authorsLabel =>
      authors.isEmpty ? 'Unknown authors' : authors.join(', ');
  String get doiUrl =>
      doi == null || doi!.isEmpty ? '' : 'https://doi.org/$doi';
  String get openAlexUrl => 'https://openalex.org/$id';

  factory Paper.fromJson(Map<String, dynamic> json) {
    final authorships = json['authorships'] as List<dynamic>? ?? const [];
    final authors = authorships
        .map(
          (item) =>
              (item as Map<String, dynamic>)['author'] as Map<String, dynamic>?,
        )
        .whereType<Map<String, dynamic>>()
        .map((author) => author['display_name'] as String?)
        .whereType<String>()
        .toList();
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    final source = primaryLocation?['source'] as Map<String, dynamic>?;
    final concepts = (json['concepts'] as List<dynamic>? ?? const [])
        .map(
          (item) => (item as Map<String, dynamic>)['display_name'] as String?,
        )
        .whereType<String>()
        .take(6)
        .toList();

    return Paper(
      id: (json['id'] as String? ?? '').replaceFirst(
        'https://openalex.org/',
        '',
      ),
      title: json['title'] as String? ?? 'Untitled work',
      authors: authors,
      publication: json['publication_year']?.toString(),
      year: json['publication_year'] as int?,
      journal: source?['display_name'] as String?,
      doi: (json['doi'] as String?)?.replaceFirst('https://doi.org/', ''),
      citationCount: json['cited_by_count'] as int? ?? 0,
      concepts: concepts,
      primaryLocationUrl: primaryLocation?['landing_page_url'] as String?,
      abstractText: _reconstructAbstract(json['abstract_inverted_index']),
    );
  }

  factory Paper.fromStorage(Map<String, dynamic> json) => Paper(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? 'Untitled work',
    authors: (json['authors'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    publication: json['publication'] as String?,
    year: json['year'] as int?,
    journal: json['journal'] as String?,
    doi: json['doi'] as String?,
    citationCount: json['citationCount'] as int? ?? 0,
    abstractText: json['abstractText'] as String?,
    concepts: (json['concepts'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(),
    primaryLocationUrl: json['primaryLocationUrl'] as String?,
  );

  Map<String, dynamic> toStorage() => {
    'id': id,
    'title': title,
    'authors': authors,
    'publication': publication,
    'year': year,
    'journal': journal,
    'doi': doi,
    'citationCount': citationCount,
    'abstractText': abstractText,
    'concepts': concepts,
    'primaryLocationUrl': primaryLocationUrl,
  };

  static String? _reconstructAbstract(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final words = <int, String>{};
    for (final entry in value.entries) {
      final positions = (entry.value as List<dynamic>? ?? const []);
      for (final position in positions) {
        if (position is int) words[position] = entry.key;
      }
    }
    if (words.isEmpty) return null;
    final ordered = words.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return ordered.map((entry) => entry.value).join(' ');
  }
}
