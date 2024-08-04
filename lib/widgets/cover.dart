import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song.dart';
import '../utils.dart';
import 'cover_viewer.dart';
import 'song_page/song_page.dart';

class CoverThumb extends StatelessWidget {
  final SongLink? _songLink;

  const CoverThumb(this._songLink, {super.key});

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
                imageUrl: _songLink.thumbLink,
                placeholder: (context, url) =>
                    const Icon(Icons.album, size: 50.0),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.album, size: 50.0))));
  }
}

class CoverWithGesture extends StatelessWidget {
  final SongLink? songLink;
  final Duration fadeInDuration;
  final bool displayPlaceholder;

  const CoverWithGesture(
      {super.key,
      this.songLink,
      this.fadeInDuration = const Duration(),
      this.displayPlaceholder = false});

  @override
  Widget build(BuildContext context) {
    var tag = createTag(songLink!);

    return Wrap(
        direction: MediaQuery.of(context).orientation == Orientation.portrait
            ? Axis.horizontal
            : Axis.vertical,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(6.0, 6.0),
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
                Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return CoverViewer(songLink);
                    },
                    fullscreenDialog: true));
              },
              child: Cover(songLink!.coverLink,
                  displayPlaceholder: displayPlaceholder,
                  fadeInDuration: fadeInDuration,
                  tag: tag),
            ),
          )
        ]);
  }
}

class Cover extends StatelessWidget {
  final String _url;
  final Duration fadeInDuration;
  final bool displayPlaceholder;
  final String tag;

  const Cover(this._url,
      {this.fadeInDuration = const Duration(),
      this.displayPlaceholder = false,
      this.tag = '',
      super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: CachedNetworkImage(
        fadeInDuration: fadeInDuration,
        placeholder: displayPlaceholder
            ? (context, url) => Image.asset('assets/vinyl-default.jpg')
            : null,
        imageUrl: _url,
        errorWidget: (context, url, error) =>
            Image.asset('assets/vinyl-default.jpg'),
      ),
    );
  }
}
