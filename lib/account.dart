import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'session.dart';
import 'bidebox.dart';
import 'song.dart';
import 'utils.dart';

class AccountLink {
  String id;
  String name;
  String image;

  AccountLink({this.id, this.name});
}

class Account extends AccountLink {
  String type;
  String inscription;
  String messageForum;
  String comments;
  String presentation;
  List<SongLink> favorites;
  List<Message> messages;
}

class Message {
  String recipient;
  String date;
  String body;
}

openAccountImageViewerDialog(context, image) {
  Navigator.of(context).push(MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: image,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
      fullscreenDialog: true));
}

String extractAccountId(str) {
  final idRegex = RegExp(r'/account/(\d+).html');
  var match = idRegex.firstMatch(str);
  return match[1];
}

Future<Account> fetchAccount(String accountId) async {
  var account = Account();
  account.id = accountId;

  final url = '$baseUri/account.html?N=$accountId&Page=all';
  final bool ownAccount = accountId == Session.accountLink.id;

  final response = ownAccount ? await http.get(url) : await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var txtpresentation =
        document.getElementsByClassName('txtpresentation')[0].innerHtml.trim();
    account.presentation = txtpresentation;
    account.name =
        document.getElementsByClassName('titre-utilisateur')[0].innerHtml;

    dom.Element divInfo = document.getElementById('gd-encartblc2');
    List<dom.Element> ps = divInfo.getElementsByTagName('p');
    account.type = stripTags(ps[1].innerHtml);
    account.inscription = stripTags(ps[2].innerHtml);
    account.messageForum = stripTags(ps[3].innerHtml);
    account.comments = stripTags(ps[4].innerHtml);

    //set avatar path
    var img = divInfo.getElementsByTagName('img');
    if (img.isEmpty) {
      account.image = '';
    } else {
      account.image = img[0].attributes['src'];
    }

    //parse bm tables
    //bm table may list favourite songs or messages.
    //either are optional
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    bool hasMessage = Session.accountLink != null &&
        document.getElementsByClassName('titre-message').isNotEmpty;
    bool hasFavorite = (tables.length == 1 && !hasMessage) ||
        (tables.length == 2 && hasMessage);

    //parse favorites
    var favorites = <SongLink>[];
    if (hasFavorite) {
      for (dom.Element tr in tables[0].getElementsByTagName('tr')) {
        var songLink = SongLink();
        var aTitle = tr.children[4].children[0];
        songLink.id = extractSongId(aTitle.attributes['href']);
        songLink.title = stripTags(aTitle.innerHtml);
        songLink.artist = stripTags(tr.children[3].innerHtml);
        favorites.add(songLink);
      }
    }
    account.favorites = favorites;

    //parse message
    List<Message> messages = [];
    if (hasMessage) {
      int index = hasFavorite ? 1 : 0;
      dom.Element table = tables[index];
      for (dom.Element tr in table.getElementsByTagName('tr')) {
        var message = Message();
        dom.Element td = tr.children[0];
        List<String> header =
            td.getElementsByClassName('txtred')[0].text.split('\n');
        message.body = td.getElementsByTagName('p')[0].text;
        message.recipient = header[1].trim();
        message.date = header[2].trim();
        messages.add(message);
      }
    }
    account.messages = messages;

    return account;
  } else {
    throw Exception('Failed to load account ');
  }
}

Future<List<SongLink>> fetchVotes() async {
  var songLinks = <SongLink>[];
  final url = '$baseUri/mes-votes.html';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);
    var tables = document.getElementsByClassName('bmtable');

    if (tables.isEmpty) {
      return songLinks;
    }

    var table = tables[0];
    var trs = table.children[0].children;
    trs.removeAt(0); //remove header
    for (var tr in trs) {
      var song = SongLink();
      song.id = extractSongId(tr.children[3].children[0].attributes['href']);
      song.title = stripTags(tr.children[3].innerHtml);
      song.artist = stripTags(tr.children[2].innerHtml);
      songLinks.add(song);
    }
  } else {
    throw Exception('Failed to load votes');
  }

  return songLinks;
}

class AccountPageWidget extends StatefulWidget {
  final Future<Account> account;
  final int defaultPage;

  AccountPageWidget({Key key, this.account, this.defaultPage = 0})
      : super(key: key);

  @override
  _AccountPageWidgetState createState() => _AccountPageWidgetState();
}

class _AccountPageWidgetState extends State<AccountPageWidget> {
  int _currentPage;
  PageController controller;

  @override
  void initState() {
    _currentPage = widget.defaultPage;
    controller = PageController(initialPage: widget.defaultPage);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account>(
      future: widget.account,
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
    final url = baseUri + account.image;
    final image = NetworkImage(url);

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
                      Expanded(
                          child: InkWell(
                              onTap: () {
                                openAccountImageViewerDialog(context, image);
                              },
                              child: Image.network(url))),
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
            controller: controller,
            onPageChanged: (int page) => setState(() {
              _currentPage = page;
            }),
            children: <Widget>[
              account.presentation == ''
                  ? Center(
                      child: Text(
                          '${account.name} n\'a pas renseigné sa présentation. '))
                  : SingleChildScrollView(
                      child: Padding(
                      padding: EdgeInsets.only(left: 8.0, top: 2.0),
                      child: Html(
                          data: account.presentation,
                          defaultTextStyle: TextStyle(fontSize: 18.0),
                          useRichText: false,
                          onLinkTap: (url) {
                            onLinkTap(url, context);
                          }),
                    )),
              account.favorites.isEmpty
                  ? Center(child: Text('${account.name} n\'a pas de favoris. '))
                  : SongListingWidget(account.favorites),
              MessageListingWidget(account.messages)
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

    Widget mailButton = Session.accountLink.id == null || _currentPage != 2
        ? null
        : FloatingActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) => MessageEditor(account),
            ),
            child: Icon(Icons.mail),
          );

    return Scaffold(
        appBar: AppBar(
          title: Text(account.name),
        ),
        floatingActionButton: mailButton,
        body: nestedScrollView);
  }
}

class MessageListingWidget extends StatelessWidget {
  final List<Message> messages;
  MessageListingWidget(this.messages);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          Message message = messages[index];
          return ListTile(
              title: Text('${message.recipient} ${message.date}'),
              subtitle: Text(message.body));
        });
  }
}

///////////////////////////
// Manage the account after identification

Future<Account> fetchAccountSession() async {
  var account = Account();
  final accountId = Session.accountLink.id;
  final url = '$baseUri/account.html?N=$accountId&Page=all';
  final response = await Session.get(url);
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

    account.favorites = favorites;
    return account;
  } else {
    throw Exception('Failed to load account with id $accountId');
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
