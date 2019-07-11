import 'package:flutter/material.dart';

import 'about.dart';
import 'identification.dart';
import 'newSongs.dart';
import 'nowSong.dart';
import 'pochettoscope.dart';
import 'schedule.dart';
import 'search.dart';
import 'settings.dart';
import 'titles.dart';
import 'trombidoscope.dart';
import 'wall.dart';
import 'session.dart';

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  String _accountTitle;

  @override
  void initState() {
    super.initState();
    _setAccountTitle();
  }

  _setAccountTitle() {
    setState(() {
      _accountTitle = Session.accountLink.id == null
          ? 'Connexion à votre compte'
          : '${Session.accountLink.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      children: <Widget>[
        DrawerHeader(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/bm_logo.png'),
                ),
              ),
            ),
            decoration: BoxDecoration(color: Colors.orange)),
        ListTile(
          title: Text(_accountTitle),
          leading: Icon(Icons.account_circle),
          onTap: () {
            Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => IdentificationWidget()))
                .then((_) => _setAccountTitle());
          },
        ),
        ListTile(
          title: Text('Titres'),
          leading: Icon(Icons.queue_music),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TitlesWidget(program: fetchTitles())));
          },
        ),
        ListTile(
          title: Text('Programmation'),
          leading: Icon(Icons.music_note),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        ScheduleWidget(schedule: fetchSchedule())));
          },
        ),
        ListTile(
          title: Text('Chanson du moment'),
          leading: Icon(Icons.access_alarms),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        NowSongsWidget(nowSongs: fetchNowSongs())));
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
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => TrombidoscopeWidget()));
          },
        ),
        ListTile(
          title: Text('Pochettoscope'),
          leading: Icon(Icons.apps),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => PochettoscopeWidget()));
          },
        ),
        ListTile(
          title: Text('Nouvelles entrées'),
          leading: Icon(Icons.fiber_new),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SongsWidget(songs: fetchNewSongs())));
          },
        ),
        ListTile(
          title: Text('Options'),
          leading: Icon(Icons.settings),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SettingsPage()));
          },
        ),
        ListTile(
          title: Text('À propos'),
          leading: Icon(Icons.info),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => AboutPage()));
          },
        ),
      ],
    ));
  }
}
