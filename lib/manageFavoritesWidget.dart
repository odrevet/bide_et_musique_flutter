import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'utils.dart';
import 'song.dart';
import 'identification.dart';
import 'account.dart';

class ManageFavoritesWidget extends StatefulWidget {
  final Session session;

  ManageFavoritesWidget({Key key, this.session}) : super(key: key);

  @override
  _ManageFavoritesWidgetState createState() =>
      _ManageFavoritesWidgetState(this.session);
}

class _ManageFavoritesWidgetState extends State<ManageFavoritesWidget> {
  _ManageFavoritesWidgetState(this.session);
  Session session;
  Future<Account> accountInformations;

  List<Dismissible> _rows;

  @override
  void initState() {
    super.initState();
    accountInformations = fetchAccountSession(this.session);
    _rows = <Dismissible>[];
  }

  Dismissible _createSongTile(
      SongLink song, Account accountInformations, int index) {
    int position = ++index;
    return Dismissible(
        key: Key(song.id),
        onDismissed: (direction) {
          _confirmDeletion(song, accountInformations);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image: NetworkImage('$baseUri/images/thumb25/${song.id}.jpg')),
          ),
          title: Text('#$position - ${song.title}'),
          subtitle: Text(song.artist),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SongPageWidget(
                        song: song,
                        songInformations: fetchSongInformations(song.id))));
          },
        ));
  }

  Future<void> _confirmDeletion(
      SongLink song, Account accountInformations) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Retirer un favoris'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Vraiment retirer "${song.title}" de vos favoris ? '),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Oui'),
              onPressed: () async {
                var accountId = session.id;
                var K = song.id;
                var direction = 'DS';

                final response = await session.post(
                    '$baseUri/account/$accountId.html', {
                  'K': K,
                  'Step': '',
                  direction + '.x': '1',
                  direction + '.y': '1'
                });

                if (response.statusCode == 200) {
                  setState(() {
                    accountInformations.favorites
                        .removeWhere((song) => song.id == K);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Non'),
              onPressed: () {
                int index = accountInformations.favorites.indexOf(song);

                setState(() {
                  _rows.insert(
                      index, _createSongTile(song, accountInformations, index));
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildView(BuildContext context, Session session,
      Account accountInformations) {
    _rows.clear();
    int index = 0;
    for (SongLink song in accountInformations.favorites) {
      _rows.add(_createSongTile(song, accountInformations, index));
      index++;
    }

    return ReorderableListView(
        children: _rows,
        onReorder: (int initialPosition, int targetPosition) async {
          var draggedSong = accountInformations.favorites[initialPosition];
          //update server
          var accountId = session.id;
          var K = draggedSong.id;
          var step = initialPosition - targetPosition;
          var direction = step < 0 ? 'down' : 'up';

          final response =
              await session.post('$baseUri/account/$accountId.html', {
            'K': K,
            'Step': step.abs().toString(),
            direction + '.x': '1',
            direction + '.y': '1'
          });

          if (response.statusCode == 200) {
            setState(() {
              accountInformations.favorites.removeAt(initialPosition);
              accountInformations.favorites.insert(targetPosition, draggedSong);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Account>(
        future: accountInformations,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, session, snapshot.data);
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
