import 'package:flutter/material.dart';

import 'song.dart';

class PochettoscopeWidget extends StatefulWidget {
  List<SongLink> songLinks = <SongLink>[];
  final Function onEndReached;

  PochettoscopeWidget({this.songLinks, this.onEndReached, Key key})
      : super(key: key);

  @override
  _PochettoscopeWidgetState createState() => _PochettoscopeWidgetState();
}

class _PochettoscopeWidgetState extends State<PochettoscopeWidget> {
  ScrollController _controller;

  @override
  void initState() {
    super.initState();
    if(widget.onEndReached != null){
      _controller = ScrollController();
      _controller.addListener(_scrollListener);
      widget
          .onEndReached()
          .then((songLinks) => {setState(() => widget.songLinks = songLinks)});
    }
  }

  @override
  void dispose() {
    super.dispose();
    if(widget.onEndReached != null)_controller.removeListener(_scrollListener);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange) {
      widget.onEndReached().then((songLinks) => {
        setState(() {
          widget.songLinks = [...widget.songLinks, ...songLinks];
        })
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    if (widget.songLinks == null) {
      return Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
        itemCount: widget.songLinks.length,
        controller: _controller,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: orientation == Orientation.portrait ? 2 : 3),
        itemBuilder: (BuildContext context, int index) {
          return SongCardWidget(songLink: widget.songLinks[index]);
        });
  }
}