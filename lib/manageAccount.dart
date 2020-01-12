import 'dart:async';
import 'dart:ui';

import 'package:bide_et_musique/requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'account.dart';
import 'bidebox.dart';
import 'manageFavorites.dart';
import 'requests.dart';
import 'session.dart';
import 'song.dart';
import 'utils.dart';

class LoggedInPage extends StatelessWidget {
  LoggedInPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //disconnect button
    var actions = <Widget>[];
    actions.add(IconButton(
      icon: Icon(Icons.close),
      onPressed: () {
        Session.accountLink.id = null;
        Session.headers = {};
        Navigator.pop(context);
      },
    ));

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          actions: actions,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_circle)),
              Tab(icon: Icon(Icons.star)),
              Tab(icon: Icon(Icons.exposure_plus_1)),
              Tab(icon: Icon(Icons.mail)),
              Tab(icon: Icon(Icons.feedback)),
            ],
          ),
          title: Text('Gestion de votre compte'),
        ),
        body: TabBarView(
          children: [
            ManageAccountPageWidget(
                account: fetchAccount(Session.accountLink.id)),
            ManageFavoritesWidget(),
            VoteListing(fetchVotes()),
            BideBoxWidget(messages: fetchMessages()),
            RequestsPageWidget()
          ],
        ),
      ),
    );
  }
}

// Display songs from future song list
class VoteListing extends StatelessWidget {
  final Future<List<SongLink>> songLinks;

  VoteListing(this.songLinks, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongLink>>(
        future: songLinks,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.isEmpty)
              return Center(
                  child: Text('Vous n\'avez pas voté cette semaine. '));
            else
              return SongListingWidget(snapshot.data);
          } else if (snapshot.hasError) {
            return Center(child: Text("${snapshot.error}"));
          }

          return Center(child: CircularProgressIndicator());
        });
  }
}

class ManageAccountPageWidget extends StatelessWidget {
  final Future<Account> account;

  ManageAccountPageWidget({Key key, this.account}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Account>(
        future: account,
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

  Widget _buildView(BuildContext context, Account account) {
    final url = baseUri + account.image;
    final image = NetworkImage(url);

    return Container(
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
                  ),
                ],
              )),
          Expanded(
            flex: 7,
            child: Container(
              child: Stack(children: [
                PageView(
                  children: <Widget>[
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Stack(children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(0.7)),
                        ),
                        SingleChildScrollView(
                            child: Html(
                                data: account.presentation,
                                onLinkTap: (url) {
                                  onLinkTap(url, context);
                                })),
                      ]),
                    )
                  ],
                )
              ]),
              decoration: BoxDecoration(
                  image: DecorationImage(
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
