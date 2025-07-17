import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/session.dart';
import '../../models/song.dart';
import '../../services/account.dart';
import '../../services/bidebox.dart';
import '../../utils.dart';
import '../account.dart';
import '../html_with_style.dart';
import '../song_listing.dart';
import 'bidebox.dart';
import 'manage_favorites.dart';
import 'requests.dart';

class DisconnectButton extends StatelessWidget {
  const DisconnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      onPressed: () {
        Session.accountLink.id = null;
        Session.headers = {};
        Navigator.pop(context);
      },
    );
  }
}

class LoggedInPage extends StatelessWidget {
  const LoggedInPage({super.key});

  @override
  Widget build(BuildContext context) {
    //disconnect button
    var actions = <Widget>[];
    actions.add(const DisconnectButton());

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          actions: actions,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_circle)),
              Tab(icon: Icon(Icons.star)),
              Tab(icon: Icon(Icons.exposure_plus_1)),
              Tab(icon: Icon(Icons.mail)),
              Tab(icon: Icon(Icons.feedback)),
            ],
          ),
          title: Text(Session.accountLink.name!),
        ),
        body: TabBarView(
          children: [
            ManageAccountPageWidget(
              account: fetchAccount(Session.accountLink.id),
            ),
            const ManageFavoritesWidget(),
            VoteListing(fetchVotes()),
            BideBoxWidget(exchanges: fetchExchanges()),
            const RequestsPageWidget(),
          ],
        ),
      ),
    );
  }
}

// Display songs from future song list
class VoteListing extends StatelessWidget {
  final Future<List<SongLink>> songLinks;

  const VoteListing(this.songLinks, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SongLink>>(
      future: songLinks,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Vous n\'avez pas voté cette semaine. '),
            );
          } else {
            return SongListingWidget(snapshot.data);
          }
        } else if (snapshot.hasError) {
          return Center(child: Text("${snapshot.error}"));
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class ManageAccountPageWidget extends StatelessWidget {
  final Future<Account>? account;

  const ManageAccountPageWidget({super.key, this.account});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<Account>(
        future: account,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildView(context, snapshot.data!);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // By default, show a loading spinner
          return const CircularProgressIndicator();
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, Account account) {
    final url = baseUri + account.image!;
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
                        openAccountImageViewerDialog(
                          context,
                          image,
                          account.name,
                        );
                      },
                      child: Image.network(url),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${account.type}\n${account.inscription}\n${account.messageForum}\n${account.comments}\n',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 7,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    alignment: FractionalOffset.topCenter,
                    image: image,
                  ),
                ),
                child: Stack(
                  children: [
                    PageView(
                      children: <Widget>[
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 9.6, sigmaY: 9.6),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                child: HtmlWithStyle(
                                  data: account.presentation,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
