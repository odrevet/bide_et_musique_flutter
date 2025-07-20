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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche en cours...'),
          ],
        ),
      );
    }

    if (_songLinks!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun résultat trouvé',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_songLinks!.length} résultat${_songLinks!.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        // Results list
        Expanded(
          child: ListView.separated(
            controller: _controller,
            itemCount: _songLinks!.length + (_loadingMore == true ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              if (index == _songLinks!.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CoverThumb(_songLinks![index]),
                  ),
                  title: Text(
                    _songLinks![index].name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    _songLinks![index].artist ?? 'Artiste inconnu',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  trailing: Icon(
                    Icons.play_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onTap: () => launchSongPage(_songLinks![index], context),
                ),
              );
            },
          ),
        ),
      ],
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
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher dans la base'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                          Icon(
                            type.icon,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'Entrez votre recherche...',
              leading: Icon(
                currentSearchType.icon,
                color: Theme.of(context).colorScheme.outline,
              ),
              trailing: _controller.text.isNotEmpty ? [
                IconButton(
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.clear),
                ),
              ] : null,
              onSubmitted: (_) => performSearch(),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 32),

            // Search button
            FilledButton.icon(
              onPressed: _isSearching ? null : performSearch,
              icon: _isSearching
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.search),
              label: Text(_isSearching ? 'Recherche...' : 'Lancer la recherche'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
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