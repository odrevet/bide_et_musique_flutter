import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'account.dart';
import 'identification.dart';
import 'song.dart';
import 'utils.dart';

class ManageFavoritesWidget extends StatefulWidget {
  ManageFavoritesWidget({Key key}) : super(key: key);

  @override
  _ManageFavoritesWidgetState createState() =>
      _ManageFavoritesWidgetState();
}

class _ManageFavoritesWidgetState extends State<ManageFavoritesWidget> {
  _ManageFavoritesWidgetState();

  Future<Account> _account;

  List<Dismissible> _rows;

  @override
  void initState() {
    super.initState();
    _account = fetchAccountSession();
    _rows = <Dismissible>[];
  }

  Dismissible _createSongTile(SongLink songLink, Account account, int index) {
    int position = ++index;
    return Dismissible(
        key: Key(songLink.id),
        onDismissed: (direction) {
          _confirmDeletion(songLink, account);
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.black12,
            child: Image(
                image:
                    NetworkImage('$baseUri/images/thumb25/${songLink.id}.jpg')),
          ),
          title: Text('#$position - ${songLink.title}'),
          subtitle: Text(songLink.artist),
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
                Text('Vraiment retirer "${songLink.title}" de vos favoris ? '),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Oui'),
              onPressed: () async {
                var accountId = Session.accountLink.id;
                var K = songLink.id;
                var direction = 'DS';

                final response = await Session.post(
                    '$baseUri/account/$accountId.html', {
                  'K': K,
                  'Step': '',
                  direction + '.x': '1',
                  direction + '.y': '1'
                });

                if (response.statusCode == 200) {
                  setState(() {
                    account.favorites.removeWhere((song) => song.id == K);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Non'),
              onPressed: () {
                int index = account.favorites.indexOf(songLink);

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
    for (SongLink songLink in account.favorites) {
      _rows.add(_createSongTile(songLink, account, index));
      index++;
    }

    return ReorderableListView(
        children: _rows,
        onReorder: (int initialPosition, int targetPosition) async {
          var draggedSong = account.favorites[initialPosition];
          //update server
          var accountId = Session.accountLink.id;
          var K = draggedSong.id;
          var step = initialPosition - targetPosition;
          var direction = step < 0 ? 'down' : 'up';

          final response =
              await Session.post('$baseUri/account/$accountId.html', {
            'K': K,
            'Step': step.abs().toString(),
            direction + '.x': '1',
            direction + '.y': '1'
          });

          if (response.statusCode == 200) {
            setState(() {
              account.favorites.removeAt(initialPosition);
              account.favorites.insert(targetPosition, draggedSong);
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
            return _buildView(context, snapshot.data);
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
