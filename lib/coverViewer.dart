import 'dart:ui';
import 'package:flutter/material.dart';

class CoverViewer extends StatefulWidget {
  final String songId;

  CoverViewer(this.songId, {Key key}) : super(key: key); // changed

  @override
  _CoverViewerState createState() => _CoverViewerState(this.songId);
}

class _CoverViewerState extends State<CoverViewer> {
  String songId;
  Offset _offset = Offset.zero; // changed

  _CoverViewerState(this.songId);

  @override
  Widget build(BuildContext context) {
    return Transform(
        // Transform widget
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(0.01 * _offset.dy) // changed
          ..rotateY(-0.01 * _offset.dx), // changed
        alignment: FractionalOffset.center,
        child: GestureDetector(
          // new
          onPanUpdate: (details) => setState(() => _offset += details.delta),
          onDoubleTap: () => setState(() => _offset = Offset.zero),
          child: _buildView(context, this.songId),
        ));
  }

  _buildView(BuildContext context, String songId) {
    var url =
        'http://www.bide-et-musique.com/images/pochettes/' + songId + '.jpg';
    return Center(
      child: Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
          fit: BoxFit.contain,
          image: new NetworkImage(url),
        )),
        alignment: Alignment(0.0, 0.0),
      ),
    );
  }
}
