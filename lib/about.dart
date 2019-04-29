import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class AboutPage extends StatelessWidget {
  AboutPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("A propos")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'Bide&Musique',
                        style: TextStyle(
                          fontSize: 30.0,
                          color: Colors.orange,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black,
                            ),
                          ],
                        )),
                    TextSpan(
                        text:
                            '\nLa web radio de l\'improbable et de l\'inouïe\n\n',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.yellow,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black,
                            ),
                          ],
                        )),
                    TextSpan(
                        text:
                            'Application Bide&Musique non-officielle par Olivier Drevet. \nDistribuée sous la license GPLv3\n'
                            'Code source sur https://github.com/odrevet/bide-et-musique-flutter\n\n',
                        /*recognizer:  TapGestureRecognizer()
                          ..onTap = () => {
                                Navigator.push(
                                    context,
                                     MaterialPageRoute(
                                        builder: (context) =>
                                             AccountPageWidget(
                                                account:
                                                    Account('84482', 'drev'),
                                                txtpresentation:
                                                    fetchAccount('84482')))),
                              },*/
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.black,
                          shadows: <Shadow>[
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Colors.black,
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
