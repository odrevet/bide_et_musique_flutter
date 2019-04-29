import 'package:flutter/material.dart';
import 'program.dart';
import 'wall.dart';
import 'playerWidget.dart';
import 'nowPlaying.dart';
import 'trombidoscope.dart';
import 'pochettoscope.dart';
import 'about.dart';
import 'searchWidget.dart';
import 'newSongs.dart';
import 'ident.dart';
import 'package:flutter_radio/flutter_radio.dart';

Future<void> audioStart() async {
  await FlutterRadio.audioStart();
}

void main() {
  audioStart();
  runApp(BideApp());
  FlutterRadio.stop();
}

var playerWidget = PlayerWidget();

class BideApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bide & Musique',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        canvasColor: Color.fromARGB(190, 245, 240, 220),
      ),
      home: DrawerWidget(),
    );
  }
}

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var actions = <Widget>[];

    actions.add(IconButton(
      icon: Icon(Icons.stop),
      onPressed: () {
        playerWidget.stop();
      },
    ));

    return Scaffold(
        appBar: AppBar(
          actions: actions,
          title: Text('Bide&Musique'),
        ),
        drawer: Drawer(
            child: ListView(
          children: <Widget>[
            DrawerHeader(
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
                              '\nLa web radio de l\'improbable et de l\'inouïe',
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
                    ],
                  ),
                ),
                decoration: BoxDecoration(color: Colors.deepOrange)),
            ListTile(
              title: Text('Compte'),
              leading: Icon(Icons.account_circle),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => IdentWidget()));
              },
            ),
            ListTile(
              title: Text('Programme'),
              leading: Icon(Icons.album),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ProgrammeWidget(program: fetchTitles())));
              },
            ),
            ListTile(
              title: Text('Recherche'),
              leading: Icon(Icons.search),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SearchWidget()));
              },
            ),
            ListTile(
              title: Text('Mur des messages'),
              leading: Icon(Icons.message),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WallWidget(posts: fetchPosts())));
              },
            ),
            ListTile(
              title: Text('Trombidoscope'),
              leading: Icon(Icons.apps),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TrombidoscopeWidget(
                            accounts: fetchTrombidoscope())));
              },
            ),
            ListTile(
              title: Text('Pochettoscope'),
              leading: Icon(Icons.apps),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PochettoscopeWidget(songs: fetchPochettoscope())));
              },
            ),
            ListTile(
              title: Text('Nouvelles entrées'),
              leading: Icon(Icons.fiber_new),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            SongsWidget(songs: fetchNewSongs())));
              },
            ),
            ListTile(
              title: Text('A propos'),
              leading: Icon(Icons.info),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutPage()));
              },
            ),
          ],
        )),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
              Expanded(
                child: NowPlayingWidget(),
              ),
              Expanded(child: playerWidget),
            ])));
  }
}
