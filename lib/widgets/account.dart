import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:page_indicator/page_indicator.dart';

import '../models/account.dart';
import '../services/account.dart';
import '../services/favorite.dart';
import '../session.dart';
import '../utils.dart';
import '../widgets/bidebox.dart';
import '../widgets/pochettoscope.dart';
import '../widgets/song.dart';

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

class AccountPageWidget extends StatefulWidget {
  final Future<Account> account;
  final int defaultPage;

  AccountPageWidget({Key key, this.account, this.defaultPage = 0})
      : super(key: key);

  @override
  _AccountPageWidgetState createState() =>
      _AccountPageWidgetState(this.account);
}

class _AccountPageWidgetState extends State<AccountPageWidget> {
  int _currentPage;
  PageController controller;
  bool _viewPochettoscope = false;
  Future<Account> _account;

  _AccountPageWidgetState(this._account);

  @override
  void initState() {
    _currentPage = widget.defaultPage;
    controller = PageController(initialPage: widget.defaultPage);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account>(
      future: _account,
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
            filter: ImageFilter.blur(sigmaX: 9.6, sigmaY: 9.6),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          PageIndicatorContainer(
            align: IndicatorAlign.bottom,
            length: Session.accountLink.id == null ? 2 : 3,
            indicatorSpace: 20.0,
            padding: const EdgeInsets.all(10),
            shape: IndicatorShape.circle(size: 8),
            indicatorColor: Theme.of(context).canvasColor,
            indicatorSelectorColor: Theme.of(context).accentColor,
            child: PageView(
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
                            linkStyle: linkStyle,
                            onLinkTap: (url) {
                              onLinkTap(url, context);
                            }),
                      )),
                account.favorites.isEmpty
                    ? Center(
                        child: Text('${account.name} n\'a pas de favoris. '))
                    : _viewPochettoscope
                        ? PochettoscopeWidget(songLinks: account.favorites)
                        : SongListingWidget(account.favorites),
                if (Session.accountLink.id != null)
                  MessageListingWidget(account.messages)
              ],
            ),
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
            ).then((status) async {
              if (status == true) {
                setState(() {
                  _account = fetchAccount(account.id);
                });
              }
            }),
            child: Icon(Icons.mail),
          );

    return Scaffold(
        appBar: AppBar(
            title: Text(account.name),
            actions: _currentPage == 1
                ? <Widget>[
                    Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: _switchViewButton())
                  ]
                : []),
        floatingActionButton: mailButton,
        body: nestedScrollView);
  }

  Widget _switchViewButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewPochettoscope = !_viewPochettoscope;
        });
      },
      child: Icon(
        _viewPochettoscope == true ? Icons.image : Icons.queue_music,
      ),
    );
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
              title: Text(message.body),
              subtitle: Text('${message.recipient} ${message.date}'));
        });
  }
}

///////////////////////////
// Manage the account after identification

Future<Account> fetchAccountSession() async {
  var account = Account();
  account.id = Session.accountLink.id;
  final url = '$baseUri/account.html?N=${account.id}&Page=all';
  final response = await Session.get(url);
  if (response.statusCode == 200) {
    var body = response.body;
    dom.Document document = parser.parse(body);

    //parse bm tables
    //bm table may list favourite songs or messages.
    //either are optional
    List<dom.Element> tables = document.getElementsByClassName('bmtable');
    bool hasMessage = Session.accountLink != null &&
        document.getElementsByClassName('titre-message').isNotEmpty;
    bool hasFavorite = (tables.length == 1 && !hasMessage) ||
        (tables.length == 2 && hasMessage);

    //parse favorites
    if (hasFavorite)
      account.favorites = parseFavoriteTable(tables[0]);
    else
      account.favorites = [];

    return account;
  } else {
    throw Exception('Failed to load account $account');
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