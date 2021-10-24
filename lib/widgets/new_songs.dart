import 'dart:async';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../utils.dart';
import 'song_listing.dart';

class SongsWidget extends StatelessWidget {
  final Future<List<SongLink>>? songs;

  SongsWidget({Key? key, this.songs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Les nouvelles entrées'),
      ),
      body: Center(
        child: FutureBuilder<List<SongLink>>(
          future: songs,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return SongListingWidget(snapshot.data);
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
}
