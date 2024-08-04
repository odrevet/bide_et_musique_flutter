import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:page_indicator_plus/page_indicator_plus.dart';

import '../models/account.dart';
import '../models/session.dart';
import '../services/account.dart';
import '../utils.dart';
import '../widgets/song_listing.dart';
import 'account/bidebox.dart';
import 'html_with_style.dart';
import 'pochettoscope.dart';

openAccountImageViewerDialog(context, image, title) {
  Navigator.of(context).push(MaterialPageRoute<void>(
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
  final Future<Account>? account;
  final int defaultPage;

  const AccountPage({super.key, this.account, this.defaultPage = 0});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int? _currentPage;
  final PageController _pageController = PageController(
    initialPage: 0,
  );
  bool _viewPochettoscope = false;

  _AccountPageState();

  @override
  void initState() {
    _currentPage = widget.defaultPage;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Account>(
      future: widget.account,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildView(context, snapshot.data!);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }

        // By default, show a loading spinner
        return Scaffold(
            appBar: AppBar(
              title: const Text('Chargement du compte utilisateur'),
            ),
            body: const Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildView(BuildContext context, Account account) {
    final url = baseUri + account.image!;
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
                                openAccountImageViewerDialog(
                                    context, image, account.name);
                              },
                              child: Image.network(url))),
                      Expanded(
                        child: Text(
                            '${account.type}\n${account.inscription}\n${account.messageForum}\n${account.comments}\n',
                            style: const TextStyle(fontSize: 14)),
                      )
                    ],
                  ))
            ])),
          ),
        ];
      },
      body: Center(
          child: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
          fit: BoxFit.fill,
          alignment: FractionalOffset.topCenter,
          image: NetworkImage(url),
        )),
        child: Stack(children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9.6, sigmaY: 9.6),
            child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey.shade200.withOpacity(0.7)),
            ),
          ),
          Stack(children: [
            PageView(
              controller: _pageController,
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
                        padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                        child: HtmlWithStyle(
                          data: account.presentation,
                        ),
                      )),
                account.favorites!.isEmpty
                    ? Center(
                        child: Text('${account.name} n\'a pas de favoris. '))
                    : _viewPochettoscope
                        ? PochettoscopeWidget(songLinks: account.favorites!)
                        : SongListingWidget(account.favorites),
                if (Session.accountLink.id != null)
                  MessageListing(account.messages)
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: PageIndicator(
                controller: _pageController,
                count: Session.accountLink.id == null ? 2 : 3,
                size: 10.0,
                layout: PageIndicatorLayout.WARM,
                scale: 0.75,
                space: 10,
              ),
            ),
          ]),
        ]),
      )),
    );

    Widget? mailButton = Session.accountLink.id == null || _currentPage != 2
        ? null
        : FloatingActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) => MessageEditor(account),
            ).then((status) async {
              if (status == true) {
                // refresh current page so posted message is visible
                Navigator.of(context).pop();
              }
            }),
            child: const Icon(Icons.mail),
          );

    return Scaffold(
        appBar: AppBar(
            title: Text(account.name!),
            actions: _currentPage == 1
                ? <Widget>[
                    Padding(
                        padding: const EdgeInsets.only(right: 20.0),
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
  final List<Message>? messages;

  const MessageListing(this.messages, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: messages!.length,
        itemBuilder: (BuildContext context, int index) {
          Message message = messages![index];
          return ListTile(
              title: Text(message.body),
              subtitle: Text('${message.recipient} ${message.date}'));
        });
  }
}

class AccountListing extends StatelessWidget {
  final List<AccountLink>? _accountLinks;

  const AccountListing(this._accountLinks, {super.key});

  @override
  Widget build(BuildContext context) {
    var rows = <ListTile>[];
    for (AccountLink accountLink in _accountLinks!) {
      rows.add(ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black12,
          child: Image(
              image: NetworkImage(
                  '$baseUri/images/avatars/${accountLink.id}.png')),
        ),
        title: Text(
          accountLink.name!,
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

  const AccountListingFuture(this.accounts, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche de bidonautes'),
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
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
