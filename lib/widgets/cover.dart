import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import '../models/song.dart';
import '../services/song.dart';
import 'cover_viewer.dart';
import 'song_page.dart';

class CoverThumb extends StatelessWidget {
  final SongLink? _songLink;

  CoverThumb(this._songLink);

  Widget _sizedContainer({Widget? child}) {
    return SizedBox(
      width: 50.0,
      height: 50.0,
      child: Center(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tag = createTag(_songLink!);
    return Hero(
        tag: tag,
        child: _sizedContainer(
            child: CachedNetworkImage(
                imageUrl: _songLink!.thumbLink,
                placeholder: (context, url) => Icon(Icons.album, size: 50.0),
                errorWidget: (context, url, error) =>
                    Icon(Icons.album, size: 50.0))));
  }
}

class CoverWithGesture extends StatelessWidget {
  final SongLink? songLink;
  final Duration fadeInDuration;
  final bool displayPlaceholder;

  CoverWithGesture(
      {Key? key,
        this.songLink,
        this.fadeInDuration = const Duration(),
        this.displayPlaceholder = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
        direction: MediaQuery.of(context).orientation == Orientation.portrait
            ? Axis.horizontal
            : Axis.vertical,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 20,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongPageWidget(
                            songLink: songLink,
                            song: fetchSong(songLink!.id))));
              },
              onLongPress: () {
                Navigator.of(context).push(MaterialPageRoute<Null>(
                    builder: (BuildContext context) {
                      return CoverViewer(songLink);
                    },
                    fullscreenDialog: true));
              },
              child: Cover(songLink!.coverLink,
                  displayPlaceholder: displayPlaceholder,
                  fadeInDuration: fadeInDuration),
            ),
          )
        ]);
  }
}

class Cover extends StatelessWidget {
  final String _url;
  final Duration fadeInDuration;
  final bool displayPlaceholder;

  Cover(this._url,
      {this.fadeInDuration = const Duration(),
        this.displayPlaceholder = false});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fadeInDuration: fadeInDuration,
      placeholder: displayPlaceholder
          ? (context, url) => Image.asset('assets/vinyl-default.jpg')
          : null,
      imageUrl: _url,
      errorWidget: (context, url, error) =>
          Image.asset('assets/vinyl-default.jpg'),
    );
  }
}