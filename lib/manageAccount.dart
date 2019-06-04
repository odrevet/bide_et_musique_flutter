import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'account.dart';
import 'utils.dart';

class ManageAccountPageWidget extends StatelessWidget {
  final Future<Account> account;

  ManageAccountPageWidget({Key key, this.account})
      : super(key: key);

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
    final url = baseUri + account.avatar;
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
                            openAvatarViewerDialog(context, image);
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
