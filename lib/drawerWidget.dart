import 'package:flutter/material.dart';
import 'titles.dart';
import 'wall.dart';
import 'trombidoscope.dart';
import 'pochettoscope.dart';
import 'about.dart';
import 'searchWidget.dart';
import 'newSongs.dart';
import 'nowSong.dart';
import 'identification.dart';
import 'schedule.dart';

class DrawerWidget extends StatelessWidget {
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
          title: Text('Compte'),
          leading: Icon(Icons.account_circle),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => IdentWidget()));
          },
        ),
        ListTile(
          title: Text('Titres'),
          leading: Icon(Icons.album),
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
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        TrombidoscopeWidget(accounts: fetchTrombidoscope())));
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
                    builder: (context) => SongsWidget(songs: fetchNewSongs())));
          },
        ),
        ListTile(
          title: Text('A propos'),
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
