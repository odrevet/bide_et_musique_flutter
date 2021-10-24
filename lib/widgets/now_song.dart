import 'dart:async';

import 'package:flutter/material.dart';

import '../models/nowSong.dart';
import '../utils.dart';
import 'html_with_style.dart';
import 'song.dart';
import 'cover.dart';

class NowSongsWidget extends StatelessWidget {
  final Future<List<NowSong>>? nowSongs;

  NowSongsWidget({Key? key, this.nowSongs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Morceau du moment'),
      ),
      body: Center(
        child: FutureBuilder<List<NowSong>>(
          future: nowSongs,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return _buildView(context, snapshot.data!);
            } else if (snapshot.hasError) {
              return ErrorDisplay(snapshot.error);
            }

            // By default, show a loading spinner
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, List<NowSong> nowSongs) {
    var rows = <ListTile>[];

    for (NowSong nowSong in nowSongs) {
      rows.add(ListTile(
          onTap: () => launchSongPage(nowSong.songLink!, context),
          leading: CoverThumb(nowSong.songLink),
          title: HtmlWithStyle(
              data: nowSong.songLink!.name + '<br/>' + nowSong.desc),
          subtitle: Text('Le ${nowSong.date}')));
    }

    return ListView(children: rows);
  }
}
