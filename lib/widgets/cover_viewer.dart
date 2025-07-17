import 'package:flutter/material.dart';

import '../models/song.dart';
import '../utils.dart';
import 'cover.dart';

class CoverViewer extends StatefulWidget {
  final SongLink? songLink;

  const CoverViewer(this.songLink, {super.key});

  @override
  State<CoverViewer> createState() => _CoverViewerState();
}

class _CoverViewerState extends State<CoverViewer> {
  Offset _offset = Offset.zero;
  var _threeDimensionMode = false; // 3D or zoom

  _CoverViewerState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.songLink!.name),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _threeDimensionMode = !_threeDimensionMode),
              child: Icon(
                _threeDimensionMode
                    ? Icons.threed_rotation
                    : Icons.zoom_out_map,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: _threeDimensionMode
            ? Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(0.01 * _offset.dy)
                  ..rotateY(-0.01 * _offset.dx),
                alignment: FractionalOffset.center,
                child: GestureDetector(
                  onPanUpdate: (details) =>
                      setState(() => _offset += details.delta),
                  onDoubleTap: () => setState(() => _offset = Offset.zero),
                  child: _buildView(context),
                ),
              )
            : InteractiveViewer(child: _buildView(context)),
      ),
    );
  }

  _buildView(BuildContext context) {
    var tag = createTag(widget.songLink!);
    return Hero(tag: tag, child: Cover(widget.songLink!.coverLink));
  }
}
