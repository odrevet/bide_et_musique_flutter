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
    fetchSearchSong(widget.search, widget.type, _pageCurrent)
        .then((SearchResult searchResult) {
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

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange &&
        _pageCurrent < _pageCount! &&
        _loadingMore == false) {
      setState(() {
        _loadingMore = true;
        _pageCurrent++;
      });
      fetchSearchSong(widget.search, widget.type, _pageCurrent)
          .then((SearchResult searchResult) => setState(() {
                _loadingMore = false;
                _songLinks = [..._songLinks!, ...searchResult.songLinks];
              }));
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
              title: Text(
                _songLinks![index].name,
              ),
              subtitle: Text(_songLinks![index].artist == null
                  ? ''
                  : _songLinks![index].artist!),
              onTap: () => launchSongPage(_songLinks![index], context));
        });
  }
}

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();

  final List _searchTypes = [
    'Interprète / Nom du morceau',
    'Interprète',
    'Nom du morceau',
    'Auteur / Compositeur',
    'Label',
    'Paroles',
    'Année',
    'Dans les crédits de la pochette',
    'Dans une émission',
    'Bidonaute'
  ];
  List<DropdownMenuItem<String>>? _dropDownMenuItems;

  String? _currentItem; //selected index from 1

  _SearchState();

  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = [];
    var i = 1;
    for (var searchType in _searchTypes) {
      items.add(DropdownMenuItem(value: i.toString(), child: Text(searchType)));
      i++;
    }

    return items;
  }

  @override
  void initState() {
    super.initState();
    _dropDownMenuItems = getDropDownMenuItems();
    _currentItem = _dropDownMenuItems![0].value;
  }

  void performSearch() {
    if (_currentItem == '10') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AccountListingFuture(fetchSearchAccount(_controller.text))));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Recherche de chansons'),
                    ),
                    body: Center(
                        child: SearchResults(_controller.text, _currentItem)),
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Rechercher dans la base'),
        ),
        body: Container(
            padding: const EdgeInsets.all(30.0),
            margin: const EdgeInsets.only(top: 20.0),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16.0),
              children: [
                Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2.0),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(24.0)),
                    ),
                    margin: const EdgeInsets.all(15.0),
                    padding: const EdgeInsets.all(3.0),
                    child: DropdownButtonFormField(
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      value: _currentItem,
                      items: _dropDownMenuItems,
                      onChanged: changedDropDownItem,
                    )),
                TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Entrez ici votre recherche',
                      contentPadding:
                          const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32.0)),
                    ),
                    onSubmitted: (value) => performSearch(),
                    controller: _controller),
                Container(
                  margin: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                      child: const Text(
                        'Lancer la recherche',
                      ),
                      onPressed: () => performSearch()),
                )
              ],
            )));
  }

  void changedDropDownItem(String? searchType) {
    setState(() {
      _currentItem = searchType;
    });
  }
}
