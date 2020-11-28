import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:page_indicator/page_indicator.dart';

import '../models/account.dart';
import '../services/account.dart';
import '../session.dart';
import '../utils.dart';
import '../widgets/song.dart';
import 'bidebox.dart';
import 'htmlWithStyle.dart';
import 'pochettoscope.dart';

openAccountImageViewerDialog(context, image, title) {
  Navigator.of(context).push(MaterialPageRoute<Null>(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: InteractiveViewer(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      fullscreenDialog: true));
}

class AccountPage extends StatefulWidget {
  final Future<Account> account;
  final int defaultPage;

  AccountPage({Key key, this.account, this.defaultPage = 0}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState(this.account);
}

class _AccountPageState extends State<AccountPage> {
  int _currentPage;
  PageController controller;
  bool _viewPochettoscope = false;
  Future<Account> _account;

  _AccountPageState(this._account);

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
                                openAccountImageViewerDialog(context, image, account.name);
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
                        child: HtmlWithStyle(
                          data: account.presentation,
                        ),
                      )),
                account.favorites.isEmpty
                    ? Center(
                        child: Text('${account.name} n\'a pas de favoris. '))
                    : _viewPochettoscope
                        ? PochettoscopeWidget(songLinks: account.favorites)
                        : SongListingWidget(account.favorites),
                if (Session.accountLink.id != null)
                  MessageListing(account.messages)
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

class MessageListing extends StatelessWidget {
  final List<Message> messages;

  MessageListing(this.messages);

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

class AccountListing extends StatelessWidget {
  final List<AccountLink> _accountLinks;

  AccountListing(this._accountLinks, {Key key}) : super(key: key);

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
                  builder: (context) =>
                      AccountPage(account: fetchAccount(accountLink.id))));
        },
      ));
    }

    return ListView(children: rows);
  }
}

class AccountListingFuture extends StatelessWidget {
  final Future<List<AccountLink>> accounts;

  AccountListingFuture(this.accounts, {Key key}) : super(key: key);

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
              return AccountListing(snapshot.data);
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
