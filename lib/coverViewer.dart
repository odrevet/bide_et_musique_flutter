import 'dart:ui';
import 'package:flutter/material.dart';


class coverViewer extends StatefulWidget {
  String songId;
  coverViewer(this.songId, {Key key}) : super(key: key); // changed

  @override
  _coverViewerState createState() => _coverViewerState(this.songId);
}

class _coverViewerState extends State<coverViewer> {
  String songId;
  Offset _offset = Offset.zero; // changed

  _coverViewerState(this.songId);

  @override
  Widget build(BuildContext context) {
    return Transform( // Transform widget
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(0.01 * _offset.dy) // changed
          ..rotateY(-0.01 * _offset.dx), // changed
        alignment: FractionalOffset.center,
        child: GestureDetector( // new
          onPanUpdate: (details) => setState(() => _offset += details.delta),
          onDoubleTap: () => setState(() => _offset = Offset.zero),
          child: _buildView(context, this.songId),
        )
    );
  }

  _buildView(BuildContext context, String songId) {
    var url = 'http://www.bide-et-musique.com/images/pochettes/' +
        songId +
        '.jpg';
    return Center(
      child: Container(
        child: new Container(
            decoration: new BoxDecoration(
            image: new DecorationImage(
              fit: BoxFit.contain,
              image: new NetworkImage(
                  'http://www.bide-et-musique.com/images/pochettes/' +
                      songId +
                      '.jpg'),
            ))),
        alignment: Alignment(0.0, 0.0),
      ),
    );
  }
}

