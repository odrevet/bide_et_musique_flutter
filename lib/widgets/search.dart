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
      padding: const EdgeInsets.symmetric(vertical: 8),
      controller: _controller,
      itemCount: _songLinks!.length,
      itemBuilder: (BuildContext context, int index) {
        final link = _songLinks![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          child: ListTile(
            leading: CoverThumb(link),
            title: Text(
              link.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: link.artist != null && link.artist!.isNotEmpty
                ? Text(link.artist!)
                : null,
            onTap: () => launchSongPage(link, context),
          ),
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
      appBar: AppBar(title: const Text('Rechercher dans la base')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  initialValue: _currentItem,
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

            const SizedBox(height: 16),

            SearchBar(
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'Rechercher un titre, un artiste...',
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

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSearching ? null : performSearch,
              icon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
    );
  }
}

class SearchType {
  final String value;
  final String label;
  final IconData icon;

  SearchType(this.value, this.label, this.icon);
}
