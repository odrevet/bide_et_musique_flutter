import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'utils.dart';
import 'account.dart';

class ManageAccountPageWidget extends StatelessWidget {
  final Account account;
  final Future<AccountInformations> accountInformations;

  ManageAccountPageWidget({Key key, this.account, this.accountInformations})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }

  Widget _buildView(
      BuildContext context, AccountInformations accountInformations) {
    final url = baseUri + accountInformations.avatar;
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
                            //_openAvatarViewerDialog(context, image);
                          },
                          child: Image.network(url))),
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
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.7)),
                  ),
                ),
                PageView(
                  children: <Widget>[
                    SingleChildScrollView(
                        child: Html(
                            data: accountInformations.presentation,
                            onLinkTap: (url) {
                              onLinkTap(url);
                            })),
                    //SongListingWidget(accountInformations.favorites),
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
