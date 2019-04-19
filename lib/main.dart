import 'package:flutter/material.dart';
import 'program.dart';
import 'wall.dart';
import 'playerWidget.dart';
import 'nowPlaying.dart';
import 'trombidoscope.dart';
import 'pochettoscope.dart';
import 'about.dart';
import 'searchWidget.dart';
import 'song.dart';
import 'ident.dart';

void main() => runApp(BideApp());

class BideApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bide & Musique',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        canvasColor: Color.fromARGB(190, 245, 240, 220),
      ),
      home: new DrawerWidget(),
    );
  }
}

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => new _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Bide & Musique'),
      ),
      drawer: new Drawer(
          child: new ListView(
        children: <Widget>[
          new DrawerHeader(
              child: new RichText(
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
                        text: '\nLa web radio de l\'improbable et de l\'inouïe',
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
              decoration: new BoxDecoration(color: Colors.deepOrange)),
          new ListTile(
            title: Text('Compte'),
            leading: Icon(Icons.account_circle),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => IdentWidget()));
            },
          ),
          new ListTile(
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
          new ListTile(
            title: Text('Recherche'),
            leading: Icon(Icons.search),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SearchWidget()));
            },
          ),
          new ListTile(
            title: Text('Mur des messages'),
            leading: Icon(Icons.message),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => WallWidget(posts: fetchPosts())));
            },
          ),
          new ListTile(
            title: Text('Trombidoscope'),
            leading: Icon(Icons.apps),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          TrombidoscopeWidget(accounts: fetchTrombidoscope())));
            },
          ),
          new ListTile(
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
          new ListTile(
            title: Text('Nouvelles entrées'),
            leading: Icon(Icons.fiber_new),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          NewSongsWidget(songs: fetchNewSongs())));
            },
          ),
          new ListTile(
            title: Text('A propos'),
            leading: Icon(Icons.info),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AboutPage()));
            },
          ),
        ],
      )),
      body: OrientationBuilder(
        builder: (context, orientation) {
          var children = [
            Expanded(
              child: NowPlayingWidget(),
            ),
            Expanded(
              child: PlayerWidget(),
            ),
          ];

          return orientation == Orientation.portrait
              ? new Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: children))
              : new Center(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: children));
        },
      ),
    );
  }
}
