import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'account.dart';
import 'utils.dart';

class AboutPage extends StatelessWidget {
  AboutPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var linkStyle = TextStyle(
      fontSize: 16.0,
      color: Colors.blue,
    );

    var defaultStyle = TextStyle(
      fontSize: 14.0,
      color: Colors.black,
    );

    var text = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Application Bide&Musique par \n',
            style: defaultStyle,
          ),
          TextSpan(
            text: 'Olivier Drevet',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AccountPageWidget(account: fetchAccount('84482')))),
          ),
          TextSpan(
            text: '\n\nDistribuée sous la ',
            style: defaultStyle,
          ),
          TextSpan(
            text: 'license GPLv3',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  launchURL('https://www.gnu.org/licenses/gpl-3.0.fr.html'),
          ),
          TextSpan(
            text: '\n\nCode source disponible sur ',
            style: defaultStyle,
          ),
          TextSpan(
            text: 'github.com\n\n',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchURL(
                  'https://github.com/odrevet/bide-et-musique-flutter'),
          ),
          TextSpan(
            text: 'Manuel Utilisateur en ligne',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchURL(
                  'https://github.com/odrevet/bide-et-musique-flutter/wiki/Manuel-Utilisateur'),
          )
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('À propos'),
      ),
      body: Center(
          child: Container(
        child: Stack(children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
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
                child: text,
              )),
            ],
          )
        ]),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bm_logo.png'),
          ),
        ),
      )),
    );
  }
}
