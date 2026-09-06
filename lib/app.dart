import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/paper.dart';
import 'services/local_storage.dart';
import 'services/openalex_service.dart';

class LiteratureManagerApp extends StatelessWidget {
  const LiteratureManagerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OpenAlex Literature Manager',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B67)),
      scaffoldBackgroundColor: const Color(0xFFF7F9F7),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = OpenAlexService();
  final _storage = LocalStorage();
  final _queryController = TextEditingController();
  SearchPage? _results;
  List<Paper> _saved = const [];
  List<String> _history = const [];
  String? _error;
  bool _loading = false;
  int _page = 1;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final saved = await _storage.savedPapers();
    final history = await _storage.searchHistory();
    if (mounted) {
      setState(() {
        _saved = saved;
        _history = history;
      });
    }
  }

  Future<void> _search([String? value]) async {
    final query = (value ?? _queryController.text).trim();
    if (query.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _tab = 0;
    });
    try {
      final result = await _service.search(query: query, page: 1);
      await _storage.addSearch(query);
      await _loadLocalData();
      if (mounted) {
        setState(() {
          _results = result;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _changePage(int page) async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _page = page;
    });
    try {
      final result = await _service.search(query: query, page: page);
      if (mounted) {
        setState(() {
          _results = result;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleSaved(Paper paper) async {
    if (_saved.any((item) => item.id == paper.id)) {
      await _storage.removePaper(paper.id);
    } else {
      await _storage.savePaper(paper);
    }
    await _loadLocalData();
  }

  Future<void> _export(Iterable<Paper> papers) async {
    await Clipboard.setData(ClipboardData(text: papersToCsv(papers)));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV copied to clipboard.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 860;
        final body = _body(wide);
        if (!wide) {
          return Scaffold(
            appBar: _mobileAppBar(),
            body: body,
            bottomNavigationBar: _navigation(false),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              _sideBar(),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _mobileAppBar() => AppBar(
    title: const Row(
      children: [
        Icon(Icons.menu_book_rounded, color: Color(0xFF176B67)),
        SizedBox(width: 8),
        Text('OpenAlex', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
    actions: [
      IconButton(
        onPressed: () => _showHistory(),
        tooltip: 'Search history',
        icon: const Icon(Icons.history),
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _sideBar() => Container(
    width: 240,
    color: const Color(0xFF123D3B),
    padding: const EdgeInsets.fromLTRB(18, 32, 16, 20),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Color(0xFFE2BC73), size: 30),
              SizedBox(width: 10),
              Text(
                'OPENALEX',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 46),
          _navItem(Icons.search, 'Discover', 0),
          _navItem(
            Icons.bookmark_outline,
            'Saved papers',
            1,
            count: _saved.length,
          ),
          _navItem(Icons.history, 'Search history', 2),
          const Spacer(),
          const Divider(color: Color(0xFF35605D)),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'OpenAlex API\nFree, open scholarly metadata',
              style: TextStyle(
                color: Color(0xFFB7D0CC),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _navItem(IconData icon, String label, int index, {int? count}) =>
      ListTile(
        onTap: () => setState(() => _tab = index),
        selected: _tab == index,
        selectedTileColor: const Color(0xFF2A6661),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        leading: Icon(
          icon,
          color: _tab == index ? Colors.white : const Color(0xFFA9C8C3),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: _tab == index ? Colors.white : const Color(0xFFA9C8C3),
            fontSize: 13,
          ),
        ),
        trailing: count == null
            ? null
            : Text('$count', style: const TextStyle(color: Color(0xFFE2BC73))),
      );

  Widget _navigation(bool wide) => NavigationBar(
    selectedIndex: _tab,
    onDestinationSelected: (index) => setState(() => _tab = index),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.search), label: 'Discover'),
      NavigationDestination(icon: Icon(Icons.bookmark_outline), label: 'Saved'),
      NavigationDestination(icon: Icon(Icons.history), label: 'History'),
    ],
  );

  Widget _body(bool wide) {
    if (_tab == 1) {
      return SavedScreen(
        papers: _saved,
        onToggle: _toggleSaved,
        onExport: _export,
        onOpen: _openDetails,
      );
    }
    if (_tab == 2) return _historyScreen();
    return _discoverScreen(wide);
  }

  Widget _discoverScreen(bool wide) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      wide ? 54 : 20,
      wide ? 44 : 18,
      wide ? 54 : 20,
      40,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LITERATURE WORKSPACE',
              style: TextStyle(
                color: Color(0xFF176B67),
                letterSpacing: 1.7,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Discover what matters.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Color(0xFF173D3A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search the OpenAlex scholarly index by title, author, DOI, institution, or topic.',
              style: TextStyle(color: Color(0xFF657875)),
            ),
            const SizedBox(height: 28),
            _searchField(),
            const SizedBox(height: 30),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) _errorState(),
            if (!_loading && _error == null && _results == null) _emptyState(),
            if (_results != null && !_loading) _resultsView(),
          ],
        ),
      ),
    ),
  );

  Widget _searchField() => TextField(
    controller: _queryController,
    onSubmitted: _search,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'e.g. climate adaptation, DOI, author, or institution',
      prefixIcon: const Icon(Icons.search, color: Color(0xFF176B67)),
      suffixIcon: IconButton(
        onPressed: () => _search(),
        icon: const Icon(Icons.arrow_forward_rounded),
        tooltip: 'Search',
      ),
    ),
  );

  Widget _resultsView() {
    final result = _results!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${result.totalResults.toString()} results',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF173D3A),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _export(result.papers),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export CSV'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (result.papers.isEmpty)
          _emptyState(message: 'No works matched that search.'),
        ...result.papers.map(_paperCard),
        if (result.papers.isNotEmpty) _pagination(result),
      ],
    );
  }

  Widget _pagination(SearchPage result) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        onPressed: _page > 1 ? () => _changePage(_page - 1) : null,
        icon: const Icon(Icons.chevron_left),
        tooltip: 'Previous page',
      ),
      Text(
        'Page ${result.page} of ${result.totalPages}',
        style: const TextStyle(fontSize: 13),
      ),
      IconButton(
        onPressed: result.page < result.totalPages
            ? () => _changePage(_page + 1)
            : null,
        icon: const Icon(Icons.chevron_right),
        tooltip: 'Next page',
      ),
    ],
  );

  Widget _paperCard(Paper paper) {
    final saved = _saved.any((item) => item.id == paper.id);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: InkWell(
        onTap: () => _openDetails(paper),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paper.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF173D3A),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      paper.authorsLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF526764),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${paper.year ?? 'Year unknown'}  ·  ${paper.journal ?? paper.publication ?? 'Source unavailable'}  ·  ${paper.citationCount} citations',
                      style: const TextStyle(
                        color: Color(0xFF71817F),
                        fontSize: 12,
                      ),
                    ),
                    if (paper.doi != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'DOI: ${paper.doi}',
                          style: const TextStyle(
                            color: Color(0xFF176B67),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _toggleSaved(paper),
                tooltip: saved ? 'Remove saved paper' : 'Save paper',
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFF176B67),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    String message = 'Search the open scholarly index to begin.',
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 50),
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: Color(0xFFA8BCB8),
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF71817F))),
        ],
      ),
    ),
  );

  Widget _errorState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 34),
    child: Center(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Color(0xFFB16B52),
          ),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(onPressed: _search, child: const Text('Retry')),
        ],
      ),
    ),
  );

  Widget _historyScreen() => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search history',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFF173D3A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Recent queries',
                  style: TextStyle(color: Color(0xFF657875)),
                ),
                const Spacer(),
                if (_history.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await _storage.clearHistory();
                      await _loadLocalData();
                    },
                    child: const Text('Clear history'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_history.isEmpty)
              _emptyState(message: 'Your searches will appear here.'),
            ..._history.map(
              (query) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: const Icon(Icons.arrow_outward),
                onTap: () {
                  _queryController.text = query;
                  _search(query);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _showHistory() => setState(() => _tab = 2);

  void _openDetails(Paper paper) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PaperDetailsScreen(
        paper: paper,
        saved: _saved.any((item) => item.id == paper.id),
        onToggle: () async {
          await _toggleSaved(paper);
          if (mounted) Navigator.pop(context);
        },
      ),
    ),
  );
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({
    super.key,
    required this.papers,
    required this.onToggle,
    required this.onExport,
    required this.onOpen,
  });
  final List<Paper> papers;
  final Future<void> Function(Paper) onToggle;
  final Future<void> Function(Iterable<Paper>) onExport;
  final void Function(Paper) onOpen;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Saved papers',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173D3A),
                  ),
                ),
                const Spacer(),
                if (papers.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => onExport(papers),
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Export CSV'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${papers.length} papers in your local library',
              style: const TextStyle(color: Color(0xFF657875)),
            ),
            const SizedBox(height: 22),
            if (papers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    'No saved papers yet. Search the OpenAlex index to build your library.',
                  ),
                ),
              ),
            ...papers.map(
              (paper) => Card(
                elevation: 0,
                child: ListTile(
                  onTap: () => onOpen(paper),
                  title: Text(
                    paper.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${paper.authorsLabel} · ${paper.year ?? 'Year unknown'}',
                  ),
                  trailing: IconButton(
                    onPressed: () => onToggle(paper),
                    icon: const Icon(Icons.bookmark, color: Color(0xFF176B67)),
                    tooltip: 'Remove saved paper',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class PaperDetailsScreen extends StatelessWidget {
  const PaperDetailsScreen({
    super.key,
    required this.paper,
    required this.saved,
    required this.onToggle,
  });
  final Paper paper;
  final bool saved;
  final VoidCallback onToggle;

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper details'),
        actions: [
          IconButton(
            onPressed: onToggle,
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            tooltip: saved ? 'Remove saved paper' : 'Save paper',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paper.title,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173D3A),
                  ),
                ),
                const SizedBox(height: 18),
                Text(paper.authorsLabel, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 10),
                Text(
                  '${paper.year ?? 'Year unknown'} · ${paper.journal ?? paper.publication ?? 'Source unavailable'} · ${paper.citationCount} citations',
                  style: const TextStyle(color: Color(0xFF657875)),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (paper.doiUrl.isNotEmpty)
                      FilledButton.tonalIcon(
                        onPressed: () => _launch(context, paper.doiUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open DOI'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _launch(context, paper.openAlexUrl),
                      icon: const Icon(Icons.public),
                      label: const Text('Open OpenAlex'),
                    ),
                  ],
                ),
                const Divider(height: 40),
                if (paper.doi != null) _detail('DOI', paper.doi!),
                _detail('OpenAlex ID', paper.id),
                if (paper.concepts.isNotEmpty)
                  _detail('Concepts', paper.concepts.join(' · ')),
                const SizedBox(height: 16),
                const Text(
                  'Abstract',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173D3A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  paper.abstractText ??
                      'No abstract is available for this work.',
                  style: const TextStyle(height: 1.6, color: Color(0xFF526764)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
