import 'dart:async';

import 'package:flutter/material.dart';

import '../models/account.dart';
import '../models/favorites.dart';
import '../models/song.dart';
import '../services/account.dart';
import '../services/favorite.dart';
import '../services/song.dart';
import 'song.dart';
import 'song_page.dart';

class ManageFavoritesWidget extends StatefulWidget {
  ManageFavoritesWidget({Key? key}) : super(key: key);

  @override
  _ManageFavoritesWidgetState createState() => _ManageFavoritesWidgetState();
}

class _ManageFavoritesWidgetState extends State<ManageFavoritesWidget> {
  _ManageFavoritesWidgetState();

  Future<Account>? _account;

  late List<Dismissible> _rows;

  @override
  void initState() {
    super.initState();
    _account = fetchAccountSession();
    _rows = <Dismissible>[];
  }

  Dismissible _createSongTile(SongLink songLink, Account account, int index) {
    int position = ++index;
    return Dismissible(
        key: Key(songLink.id.toString()),
        onDismissed: (direction) {
          _confirmDeletion(songLink, account);
        },
        child: ListTile(
          leading: CoverThumb(songLink),
          title: Text('#$position - ${songLink.name}'),
          subtitle: Text(songLink.artist!),
          onTap: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongPageWidget(
                            songLink: songLink, song: fetchSong(songLink.id))))
                .then((_) => _account = fetchAccountSession());
          },
        ));
  }

  Future<void> _confirmDeletion(SongLink songLink, Account account) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Retirer un favoris'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Vraiment retirer "${songLink.name}" de vos favoris ? '),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Oui'),
              onPressed: () async {
                int statusCode = await removeSongFromFavorites(songLink.id);

                if (statusCode == 200) {
                  setState(() {
                    account.favorites!
                        .removeWhere((song) => song.id == songLink.id);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Non'),
              onPressed: () {
                int index = account.favorites!.indexOf(songLink);

                setState(() {
                  _rows.insert(
                      index, _createSongTile(songLink, account, index));
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildView(BuildContext context, Account account) {
    _rows.clear();
    int index = 0;
    for (SongLink songLink in account.favorites!) {
      _rows.add(_createSongTile(songLink, account, index));
      index++;
    }

    return ReorderableListView(
        children: _rows,
        onReorder: (int initialPosition, int targetPosition) async {
          var draggedSong = account.favorites![initialPosition];

          int statusCode = await changeFavoriteRank(
              draggedSong.id, initialPosition, targetPosition);

          if (statusCode == 200) {
            FavoritesResults favoriteResults =
                await fetchFavorites(account.id, -1);
            setState(() {
              account.favorites = favoriteResults.songLinks;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Account>(
        future: _account,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.favorites!.isEmpty)
              return Center(
                  child: Text('Vous n\'avez pas de chanson dans vos favoris'));
            else
              return _buildView(context, snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
