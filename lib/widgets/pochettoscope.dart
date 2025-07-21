import 'package:flutter/material.dart';

import '../models/song.dart';
import 'cover.dart';

class PochettoscopeWidget extends StatefulWidget {
  final List<SongLink> songLinks;
  final Function? onEndReached;

  const PochettoscopeWidget({
    required this.songLinks,
    this.onEndReached,
    super.key,
  });

  @override
  State<PochettoscopeWidget> createState() => _PochettoscopeWidgetState();
}

class _PochettoscopeWidgetState extends State<PochettoscopeWidget> {
  ScrollController? _controller;
  bool? _isLoading;

  _PochettoscopeWidgetState();

  @override
  void initState() {
    super.initState();
    if (widget.onEndReached != null) {
      _controller = ScrollController();
      _controller!.addListener(_scrollListener);
      _isLoading = true;
      widget.onEndReached!().then(
        (songLinks) => {
          setState(() {
            _isLoading = false;
            widget.songLinks.addAll(songLinks);
          }),
        },
      );
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.onEndReached != null) {
      _controller!.removeListener(_scrollListener);
    }
  }

  void _scrollListener() {
    if (_controller!.offset >= _controller!.position.maxScrollExtent &&
        !_controller!.position.outOfRange &&
        _isLoading == false) {
      setState(() {
        _isLoading = true;
      });
      widget.onEndReached!().then(
        (songLinks) => {
          setState(() {
            _isLoading = false;
            widget.songLinks.addAll(songLinks);
          }),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    if (widget.songLinks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      itemCount: widget.songLinks.length,
      controller: _controller,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: orientation == Orientation.portrait ? 2 : 3,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: CoverWithGesture(
            songLink: widget.songLinks[index],
            displayPlaceholder: true,
            fadeInDuration: const Duration(milliseconds: 20),
          ),
        );
      },
    );
  }
}
