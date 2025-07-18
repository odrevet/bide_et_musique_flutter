import 'dart:async';

import 'package:flutter/material.dart';

import '../models/now_song.dart';
import '../widgets/error_display.dart';
import 'cover.dart';
import 'html_with_style.dart';
import 'song_listing.dart';

class NowSongsWidget extends StatelessWidget {
  final Future<List<NowSong>>? nowSongs;

  const NowSongsWidget({super.key, this.nowSongs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Morceau du moment')),
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
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, List<NowSong> nowSongs) {
    var rows = <ListTile>[];

    for (NowSong nowSong in nowSongs) {
      rows.add(
        ListTile(
          onTap: () => launchSongPage(nowSong.songLink!, context),
          leading: CoverThumb(nowSong.songLink),
          title: HtmlWithStyle(
            data: '${nowSong.songLink!.name}<br/>${nowSong.desc}',
          ),
          subtitle: Text('Le ${nowSong.date}'),
        ),
      );
    }

    return ListView(children: rows);
  }
}
