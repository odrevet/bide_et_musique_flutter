import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'utils.dart';
import 'song.dart';
import 'ident.dart';

class Account {
  String id;
  String name;

  Account(this.id, this.name);
}

// Information present on the account page
class AccountInformations {
  String type;
  String inscription;
  String messageForum;
  String comments;
  String presentation;
  List<Song> favorites;
}

String extractAccountId(str) {
  final idRegex = RegExp(r'/account/(\d+).html');
  var match = idRegex.firstMatch(str);
  return match[1];
}

Future<AccountInformations> fetchAccountInformations(String accountId) async {
  var accountInformations = AccountInformations();
  final url = '$baseUri/account.html?N=$accountId&Page=all';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var txtpresentation =
        document.getElementsByClassName('txtpresentation')[0].innerHtml;
    accountInformations.presentation = stripTags(txtpresentation);

    dom.Element divInfo = document.getElementById('gd-encartblc2');
    List<dom.Element> ps = divInfo.getElementsByTagName('p');
    accountInformations.type = stripTags(ps[1].innerHtml);
    accountInformations.inscription = stripTags(ps[2].innerHtml);
    accountInformations.messageForum = stripTags(ps[3].innerHtml);
    accountInformations.comments = stripTags(ps[4].innerHtml);

    //parse favorites
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    var favorites = <Song>[];
    if (tables.isNotEmpty) {
      for (dom.Element tr in tables[0].getElementsByTagName('tr')) {
        var song = Song();
        var aTitle = tr.children[4].children[0];
        song.id = extractSongId(aTitle.attributes['href']);
        song.title = stripTags(aTitle.innerHtml);
        song.artist = stripTags(tr.children[3].innerHtml);
        favorites.add(song);
      }
    }

    accountInformations.favorites = favorites;
    return accountInformations;
  } else {
    throw Exception('Failed to load account ');
  }
}

class AccountPageWidget extends StatelessWidget {
  final Account account;
  final Future<AccountInformations> accountInformations;

  AccountPageWidget({Key key, this.account, this.accountInformations})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
      ),
      body: Center(
        child: FutureBuilder<AccountInformations>(
          future: accountInformations,
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
      ),
    );
  }

  void _openAvatarViewerDialog(BuildContext context) {
    var urlCover = 'http://www.bide-et-musique.com/images/photos/ACT' +
        account.id +
        '.jpg';
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new Image.network(urlCover);
        },
        fullscreenDialog: true));
  }

  Widget _buildView(
      BuildContext context, AccountInformations accountInformations) {
    final url = 'http://www.bide-et-musique.com/images/photos/ACT${account.id}.png';
    final image = NetworkImage(url);

    return new Container(
      color: Theme.of(context).canvasColor,
      child: Center(
          child: Column(
        children: <Widget>[
          Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            _openAvatarViewerDialog(context);
                          },
                          child: new Image.network(url))),
                  Expanded(
                    child: Text(
                        accountInformations.type +
                            '\n' +
                            accountInformations.inscription +
                            '\n' +
                            accountInformations.messageForum +
                            '\n' +
                            accountInformations.comments +
                            '\n',
                        style: TextStyle(fontSize: 14)),
                  ),
                ],
              )),
          Expanded(
            flex: 7,
            child: Container(
              child: Stack(children: [
                new BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: new Container(
                    decoration: new BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.7)),
                  ),
                ),
                PageView(
                  children: <Widget>[
                    SingleChildScrollView(
                        child: Text(accountInformations.presentation,
                            style: TextStyle(fontSize: 20))),
                    SongListingWidget(accountInformations.favorites),
                  ],
                )
              ]),
              decoration: new BoxDecoration(
                  image: new DecorationImage(
                fit: BoxFit.fill,
                alignment: FractionalOffset.topCenter,
                image: image,
              )),
            ),
          ),
        ],
      )),
    );
  }
}

///////////////////////////
// Manage the account after identification

Future<AccountInformations> fetchAccountSession(Session session) async {
  var accountInformations = AccountInformations();
  final accountId = session.id;
  final url = '$baseUri/account.html?N=$accountId&Page=all';
  final response = await session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    //parse favorites
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    var favorites = <Song>[];
    if (tables.isNotEmpty) {
      for (dom.Element tr in tables[0].getElementsByTagName('tr')) {
        var song = Song();
        var aTitle = tr.children[4].children[0];
        song.id = extractSongId(aTitle.attributes['href']);
        song.title = stripTags(aTitle.innerHtml);
        song.artist = stripTags(tr.children[3].innerHtml);
        favorites.add(song);
      }
    }

    accountInformations.favorites = favorites;
    return accountInformations;
  } else {
    throw Exception('Failed to load account ');
  }
}

class ManageAccountWidget extends StatefulWidget {

  final Session session;

  ManageAccountWidget({Key key, this.session}) : super(key: key);

  @override
  _ManageAccountWidgetState createState() =>
      _ManageAccountWidgetState(this.session);
}

class _ManageAccountWidgetState extends State<ManageAccountWidget> {
  _ManageAccountWidgetState(this.session);
  Session session;
  Future<AccountInformations> accountInformations;

  List<Dismissible> _rows;

  @override
  void initState() {
    super.initState();
    accountInformations = fetchAccountSession(this.session);
    _rows = <Dismissible>[];
  }

  Widget _buildView(BuildContext context, Session session,
      AccountInformations accountInformations) {
    _rows.clear();
    for (Song song in accountInformations.favorites) {
      _rows.add(Dismissible(
          key: Key(song.id),
          onDismissed: (direction) async {
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
                //update model
                accountInformations.favorites
                    .removeWhere((song) => song.id == K);
              });
            }
          },
          child: ListTile(
            leading: new CircleAvatar(
              backgroundColor: Colors.black12,
              child: new Image(
                  image: new NetworkImage(
                      'http://bide-et-musique.com/images/thumb25/' +
                          song.id +
                          '.jpg')),
            ),
            title: Text(
              song.title,
            ),
            subtitle: Text(song.artist),
            onTap: () {
              Navigator.push(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => new SongPageWidget(
                          song: song,
                          songInformations: fetchSongInformations(song.id))));
            },
          )));
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

          final response = await session.post('$baseUri/account/$accountId.html', {
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
      child: FutureBuilder<AccountInformations>(
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

////////////////////////////////////
class AccountListingWidget extends StatelessWidget {
  final List<Account> _accounts;

  AccountListingWidget(this._accounts, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var rows = <ListTile>[];
    for (Account account in _accounts) {
      rows.add(ListTile(
        leading: new CircleAvatar(
          backgroundColor: Colors.black12,
          child: new Image(
              image: new NetworkImage(
                  'http://bide-et-musique.com/images/avatars/' +
                      account.id +
                      '.png')),
        ),
        title: Text(
          account.name,
        ),
        onTap: () {
          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new AccountPageWidget(
                      account: account,
                      accountInformations: fetchAccountInformations(account.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
  
}

class AccountListingFutureWidget extends StatelessWidget {
  final Future<List<Account>> accounts;

  AccountListingFutureWidget(this.accounts, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche de bidonautes'),
      ),
      body: Center(
        child: FutureBuilder<List<Account>>(
          future: accounts,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return AccountListingWidget(snapshot.data);
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
