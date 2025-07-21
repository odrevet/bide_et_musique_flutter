import 'package:flutter/material.dart';

import '../models/search.dart';
import '../models/song.dart';
import '../services/search.dart';
import 'account.dart';
import 'cover.dart';
import 'song_listing.dart';

class SearchResults extends StatefulWidget {
  final String? search;
  final String? type;

  const SearchResults(this.search, this.type, {super.key});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  int? _pageCount;
  int _pageCurrent = 0;
  List<SongLink>? _songLinks;
  bool? _loading;
  bool? _loadingMore;

  final _controller = ScrollController();

  _SearchResultsState();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
    _pageCurrent = 1;
    _songLinks = [];
    _loading = true;
    _loadingMore = false;
    fetchSearchSong(widget.search, widget.type, _pageCurrent).then((
      SearchResult searchResult,
    ) {
      setState(() {
        _loading = false;
        _pageCount = searchResult.pageCount;
        _songLinks = [..._songLinks!, ...searchResult.songLinks];
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.removeListener(_scrollListener);
  }

  void _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange &&
        _pageCurrent < _pageCount! &&
        _loadingMore == false) {
      setState(() {
        _loadingMore = true;
        _pageCurrent++;
      });
      fetchSearchSong(widget.search, widget.type, _pageCurrent).then(
        (SearchResult searchResult) => setState(() {
          _loadingMore = false;
          _songLinks = [..._songLinks!, ...searchResult.songLinks];
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading == true) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_songLinks!.isEmpty) {
      return const Center(child: Text('Pas de résultats pour cette recherche'));
    }

    return ListView.builder(
      controller: _controller,
      itemCount: _songLinks!.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          leading: CoverThumb(_songLinks![index]),
          title: Text(_songLinks![index].name),
          subtitle: Text(
            _songLinks![index].artist == null ? '' : _songLinks![index].artist!,
          ),
          onTap: () => launchSongPage(_songLinks![index], context),
        );
      },
    );
  }
}

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<SearchType> _searchTypes = [
    SearchType('1', 'Interprète / Nom du morceau', Icons.person_search),
    SearchType('2', 'Interprète', Icons.person),
    SearchType('3', 'Nom du morceau', Icons.music_note),
    SearchType('4', 'Auteur / Compositeur', Icons.edit),
    SearchType('5', 'Label', Icons.label),
    SearchType('6', 'Paroles', Icons.lyrics),
    SearchType('7', 'Année', Icons.calendar_today),
    SearchType('8', 'Dans les crédits de la pochette', Icons.photo),
    SearchType('9', 'Dans une émission', Icons.radio),
    SearchType('10', 'Bidonaute', Icons.account_circle),
  ];

  String _currentItem = '1';
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  SearchType get currentSearchType =>
      _searchTypes.firstWhere((type) => type.value == _currentItem);

  void performSearch() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un terme de recherche'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      if (_currentItem == '10') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AccountListingFuture(fetchSearchAccount(_controller.text)),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Résultats de recherche'),
                    Text(
                      '"${_controller.text}"',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              body: SearchResults(_controller.text, _currentItem),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style:
              FilledButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                // Use your app's orange accent
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    20.0,
                  ), // Match your app's button theme
                ),
                elevation: 2,
                shadowColor: Colors.orange.withValues(alpha: 0.3),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.white.withValues(alpha: 0.08);
                  }
                  if (states.contains(WidgetState.focused) ||
                      states.contains(WidgetState.pressed)) {
                    return Colors.white.withValues(alpha: 0.12);
                  }
                  return null;
                }),
              ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            elevation: 2,
            shadowColor: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style:
              IconButton.styleFrom(
                foregroundColor: Colors.orange,
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.all(8),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith<Color?>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.orange.withValues(alpha: 0.08);
                  }
                  if (states.contains(WidgetState.focused) ||
                      states.contains(WidgetState.pressed)) {
                    return Colors.orange.withValues(alpha: 0.12);
                  }
                  return null;
                }),
              ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rechercher dans la base'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Search type selector
              Text(
                'Type de recherche',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    value: _currentItem,
                    isExpanded: true,
                    items: _searchTypes.map((SearchType type) {
                      return DropdownMenuItem<String>(
                        value: type.value,
                        child: Row(
                          children: [
                            Icon(type.icon, size: 20, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(child: Text(type.label)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _currentItem = newValue);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Search input
              Text(
                'Terme de recherche',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              SearchBar(
                controller: _controller,
                focusNode: _focusNode,
                hintText: 'Entrez votre recherche...',
                leading: Icon(currentSearchType.icon, color: Colors.orange),
                trailing: _controller.text.isNotEmpty
                    ? [
                        IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ]
                    : null,
                onSubmitted: (_) => performSearch(),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 32),

              // Search button with applied theme
              FilledButton.icon(
                onPressed: _isSearching ? null : performSearch,
                icon: _isSearching
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isSearching ? 'Recherche...' : 'Lancer la recherche',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchType {
  final String value;
  final String label;
  final IconData icon;

  SearchType(this.value, this.label, this.icon);
}
