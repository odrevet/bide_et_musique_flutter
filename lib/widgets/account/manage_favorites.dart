import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/favorites.dart';
import '../../models/song.dart';
import '../../services/account.dart';
import '../../services/favorite.dart';
import '../../services/song.dart';
import '../cover.dart';
import '../song_page/song_page.dart';

class ManageFavoritesWidget extends StatefulWidget {
  const ManageFavoritesWidget({super.key});

  @override
  State<ManageFavoritesWidget> createState() => _ManageFavoritesWidgetState();
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
      onDismissed: (direction) async {
        int statusCode = await removeSongFromFavorites(songLink.id);

        if (statusCode == 200) {
          setState(() {
            account.favorites!.removeWhere((song) => song.id == songLink.id);
          });
        }
      },
      confirmDismiss: (DismissDirection direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Confirmation"),
              content: Text(
                'Vraiment retirer "${songLink.name}" de vos favoris ? ',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "Oui, Supprimer",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Non, Conserver"),
                ),
              ],
            );
          },
        );
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
                songLink: songLink,
                song: fetchSong(songLink.id),
              ),
            ),
          ).then((_) => _account = fetchAccountSession());
        },
      ),
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
          draggedSong.id,
          initialPosition,
          targetPosition,
        );

        if (statusCode == 200) {
          FavoritesResults favoriteResults = await fetchFavorites(
            account.id,
            -1,
          );
          setState(() {
            account.favorites = favoriteResults.songLinks;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Account>(
        future: _account,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.favorites!.isEmpty) {
              return const Center(
                child: Text('Vous n\'avez pas de chanson dans vos favoris'),
              );
            } else {
              return _buildView(context, snapshot.data!);
            }
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
