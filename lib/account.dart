import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:flutter_html/flutter_html.dart';
import 'utils.dart';
import 'song.dart';
import 'identification.dart';

class AccountLink {
  String id;
  String name;

  AccountLink(this.id, this.name);
}

// Information present on the account page
class Account {
  String name;
  String type;
  String inscription;
  String messageForum;
  String comments;
  String presentation;
  List<SongLink> favorites;
  String avatar;
}

String extractAccountId(str) {
  final idRegex = RegExp(r'/account/(\d+).html');
  var match = idRegex.firstMatch(str);
  return match[1];
}

Future<Account> fetchAccount(String accountId) async {
  var account = Account();
  final url = '$baseUri/account.html?N=$accountId&Page=all';
  final response = await http.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var txtpresentation =
        document.getElementsByClassName('txtpresentation')[0].innerHtml;
    account.presentation = txtpresentation;
    account.name =
        document.getElementsByClassName('titre-utilisateur')[0].innerHtml;

    dom.Element divInfo = document.getElementById('gd-encartblc2');
    List<dom.Element> ps = divInfo.getElementsByTagName('p');
    account.type = stripTags(ps[1].innerHtml);
    account.inscription = stripTags(ps[2].innerHtml);
    account.messageForum = stripTags(ps[3].innerHtml);
    account.comments = stripTags(ps[4].innerHtml);

    //set avatar path (cannot be always firgured out from account id as some
    //are jpg and some are png
    var img = divInfo.getElementsByTagName('img');
    if (img.isEmpty) {
      account.avatar = '';
    } else {
      account.avatar = img[0].attributes['src'];
    }

    //parse favorites
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    var favorites = <SongLink>[];
    if (tables.isNotEmpty) {
      for (dom.Element tr in tables[0].getElementsByTagName('tr')) {
        var song = SongLink();
        var aTitle = tr.children[4].children[0];
        song.id = extractSongId(aTitle.attributes['href']);
        song.title = stripTags(aTitle.innerHtml);
        song.artist = stripTags(tr.children[3].innerHtml);
        favorites.add(song);
      }
    }

    account.favorites = favorites;
    return account;
  } else {
    throw Exception('Failed to load account ');
  }
}

Future<List<SongLink>> fetchVotes() async {
  var session = Session();
  var songs = <SongLink>[];
  final url = '$baseUri/mes-votes.html';
  final response = await session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var tables = document.getElementsByClassName('bmtable');

    if (tables.isEmpty) {
      return songs;
    }

    var table = tables[0];
    var trs = table.children[0].children;
    trs.removeAt(0); //remove header
    for (var tr in trs) {
      var song = SongLink();
      song.id = extractSongId(tr.children[3].children[0].attributes['href']);
      song.title = stripTags(tr.children[3].innerHtml);
      song.artist = stripTags(tr.children[2].innerHtml);
      songs.add(song);
    }
  } else {
    throw Exception('Failed to load account ');
  }

  return songs;
}

class AccountPageWidget extends StatelessWidget {
  final Future<Account> account;

  AccountPageWidget({Key key, this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account>(
      future: account,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildView(context, snapshot.data);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        // By default, show a loading spinner
        return Scaffold(
            appBar: AppBar(
              title: Text('Chargement du compte utilisateur'),
            ),
            body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildView(BuildContext context, Account account) {
    final url = baseUri + account.avatar;

    var nestedScrollView = NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            backgroundColor: Theme.of(context).canvasColor,
            expandedHeight: 200.0,
            automaticallyImplyLeading: false,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
                background: Row(children: [
              Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Image.network(url),
                      Expanded(
                        child: Text(
                            account.type +
                                '\n' +
                                account.inscription +
                                '\n' +
                                account.messageForum +
                                '\n' +
                                account.comments +
                                '\n',
                            style: TextStyle(fontSize: 14)),
                      )
                    ],
                  ))
            ])),
          ),
        ];
      },
      body: Center(
          child: Container(
        child: Stack(children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          PageView(
            children: <Widget>[
              SingleChildScrollView(
                  child: Padding(
                padding: EdgeInsets.only(left: 8.0, top: 2.0),
                child: Html(
                    data: account.presentation,
                    defaultTextStyle: TextStyle(fontSize: 18.0),
                    onLinkTap: (url) {
                      onLinkTap(url, context);
                    }),
              )),
              SongListingWidget(account.favorites)
            ],
          )
        ]),
        decoration: BoxDecoration(
            image: DecorationImage(
          fit: BoxFit.fill,
          alignment: FractionalOffset.topCenter,
          image: NetworkImage(url),
        )),
      )),
    );

    return Scaffold(
        appBar: AppBar(
          title: Text(account.name),
        ),
        body: nestedScrollView);
  }
}

///////////////////////////
// Manage the account after identification

Future<Account> fetchAccountSession(Session session) async {
  var accountInformations = Account();
  final accountId = session.id;
  final url = '$baseUri/account.html?N=$accountId&Page=all';
  final response = await session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    //parse favorites
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    var favorites = <SongLink>[];
    if (tables.isNotEmpty) {
      for (dom.Element tr in tables[0].getElementsByTagName('tr')) {
        var song = SongLink();
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

////////////////////////////////////
class AccountListingWidget extends StatelessWidget {
  final List<AccountLink> _accountLinks;

  AccountListingWidget(this._accountLinks, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var rows = <ListTile>[];
    for (AccountLink accountLink in _accountLinks) {
      rows.add(ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black12,
          child: Image(
              image: NetworkImage(
                  '$baseUri/images/avatars/${accountLink.id}.png')),
        ),
        title: Text(
          accountLink.name,
        ),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AccountPageWidget(
                      account: fetchAccount(accountLink.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}

class AccountListingFutureWidget extends StatelessWidget {
  final Future<List<AccountLink>> accounts;

  AccountListingFutureWidget(this.accounts, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche de bidonautes'),
      ),
      body: Center(
        child: FutureBuilder<List<AccountLink>>(
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
