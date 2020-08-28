import 'package:flutter/material.dart';

import '../models/song.dart';
import 'song.dart';

class PochettoscopeWidget extends StatefulWidget {
  final List<SongLink> songLinks;
  final Function onEndReached;

  PochettoscopeWidget({this.songLinks, this.onEndReached, Key key})
      : super(key: key);

  @override
  _PochettoscopeWidgetState createState() =>
      _PochettoscopeWidgetState(this.songLinks);
}

class _PochettoscopeWidgetState extends State<PochettoscopeWidget> {
  ScrollController _controller;
  List<SongLink> _songLinks;
  bool _isLoading;

  _PochettoscopeWidgetState(this._songLinks);

  @override
  void initState() {
    super.initState();
    if (widget.onEndReached != null) {
      _controller = ScrollController();
      _controller.addListener(_scrollListener);
      _isLoading = true;
      widget.onEndReached().then((songLinks) => {
            setState(() {
              _isLoading = false;
              _songLinks = songLinks;
            })
          });
    } else
      _isLoading = false;
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.onEndReached != null)
      _controller.removeListener(_scrollListener);
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange &&
        _isLoading == false) {
      setState(() {
        _isLoading = true;
      });
      widget.onEndReached().then((songLinks) => {
            setState(() {
              _isLoading = false;
              _songLinks = [..._songLinks, ...songLinks];
            })
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    if (_songLinks == null) {
      return Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
        itemCount: _songLinks.length,
        controller: _controller,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: orientation == Orientation.portrait ? 2 : 3),
        itemBuilder: (BuildContext context, int index) {
          return Padding(
              padding: EdgeInsets.all(1),
              child: CoverWithGesture(
                  songLink: _songLinks[index],
                  displayPlaceholder: true,
                  fadeInDuration: Duration(milliseconds: 250)));
        });
  }
}
