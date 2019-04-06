import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  AboutPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(title: new Text("A propos")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: RichText(
                text: new TextSpan(
                  style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    new TextSpan(
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
                    new TextSpan(
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
                    new TextSpan(
                        text:
                            'Application non-officiel par Olivier Drevet. \nDistribuée sous la license GPLv3\n'
                            'Vous pouvez consulter le code source sur https://github.com/odrevet/bide-et-musique-flutter\n\n',
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
