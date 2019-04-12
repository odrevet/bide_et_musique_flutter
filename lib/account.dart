import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'utils.dart';
import 'song.dart';

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

Future<AccountInformations> fetchAccount(String accountId) async {
  var accountInformations = AccountInformations();
  final url = '$host/account.html?N=$accountId&Page=all';
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
    dom.Element table = document.getElementsByClassName('bmtable')[0];
    var favorites = <Song>[];
    for (dom.Element tr in table.getElementsByTagName('tr')) {
      var song = Song();
      var aTitle = tr.children[4].children[0];
      song.id = extractSongId(aTitle.attributes['href']);
      song.title = stripTags(aTitle.innerHtml);
      song.artist = stripTags(tr.children[3].innerHtml);
      favorites.add(song);
    }

    accountInformations.favorites = favorites;
    return accountInformations;
  } else {
    throw Exception('Failed to load account ');
  }
}

class AccountPageWidget extends StatelessWidget {
  Account account;
  Future<AccountInformations> accountInformations;

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
    final url = 'http://www.bide-et-musique.com/images/photos/ACT' +
        account.id +
        '.jpg';

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
                    _buildViewFavorites(context, accountInformations.favorites),
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

  Widget _buildViewFavorites(BuildContext context, List<Song> songs) {
    var rows = <ListTile>[];
    for (Song song in songs) {
      rows.add(ListTile(
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
      ));
    }

    return ListView(children: rows);
  }

}
