import 'dart:ui';

import 'package:flutter/material.dart';

import 'song.dart';

class CoverViewer extends StatefulWidget {
  final SongLink songLink;

  CoverViewer(this.songLink, {Key key}) : super(key: key);

  @override
  _CoverViewerState createState() => _CoverViewerState(this.songLink);
}

class _CoverViewerState extends State<CoverViewer> {
  SongLink songLink;
  Offset _offset = Offset.zero;

  _CoverViewerState(this.songLink);

  @override
  Widget build(BuildContext context) {
    return Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(0.01 * _offset.dy)
          ..rotateY(-0.01 * _offset.dx),
        alignment: FractionalOffset.center,
        child: GestureDetector(
          onPanUpdate: (details) => setState(() => _offset += details.delta),
          onDoubleTap: () => setState(() => _offset = Offset.zero),
          child: _buildView(context),
        ));
  }

  _buildView(BuildContext context) {
    var tag = createTag(songLink);
    return Hero(tag: tag, child: Cover(songLink.coverLink));
  }
}
