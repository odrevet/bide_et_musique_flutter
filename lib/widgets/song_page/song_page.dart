import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:page_indicator_plus/page_indicator_plus.dart';

import '../../models/session.dart';
import '../../models/song.dart';
import '../../utils.dart';
import '../cover_viewer.dart';
import '../error_display.dart';
import '../html_with_style.dart';
import '../song_app_bar.dart';
import '../song_informations.dart';
import 'comment_dialog.dart';
import 'comments_list.dart';

class SongLyricsAndComments extends StatefulWidget {
  final Song song;
  final SongLink songLink;
  final Function onPageChange;

  const SongLyricsAndComments(
    this.song,
    this.songLink,
    this.onPageChange, {
    super.key,
  });

  @override
  State<SongLyricsAndComments> createState() => _SongLyricsAndCommentsState();
}

class _SongLyricsAndCommentsState extends State<SongLyricsAndComments> {
  final PageController _pageController = PageController();
  final Key _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          child: CachedNetworkImage(
            imageUrl: widget.song.coverLink,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 9.6, sigmaY: 9.6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Stack(
          children: [
            PageView(
              key: _key,
              controller: _pageController,
              onPageChanged: (int page) => widget.onPageChange(page),
              children: <Widget>[
                widget.song.lyrics != null
                    ? SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 2.0),
                          child: HtmlWithStyle(
                            data: widget.song.lyrics == ''
                                ? '<i>Paroles non renseignées</i>'
                                : widget.song.lyrics,
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
                CommentsList(widget.song, widget.songLink),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: PageIndicator(
                controller: _pageController,
                count: 2,
                size: 10.0,
                layout: PageIndicatorLayout.WARM,
                scale: 0.75,
                space: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MiniCover extends StatelessWidget {
  final Song song;
  final SongLink songLink;

  const MiniCover(this.song, this.songLink, {super.key});

  void _openCoverViewerDialog(SongLink? songLink, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return CoverViewer(songLink);
        },
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String coverLink = song.coverLink;
    final tag = createTag(songLink);
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Hero(
        tag: tag,
        child: Material(
          child: InkWell(
            onTap: () {
              _openCoverViewerDialog(songLink, context);
            },
            child: CachedNetworkImage(imageUrl: coverLink),
          ),
        ),
      ),
    );
  }
}

// New widget for landscape cover/info toggle
class LandscapeCoverToggle extends StatefulWidget {
  final Song song;
  final SongLink songLink;
  final bool preview;

  const LandscapeCoverToggle({
    super.key,
    required this.song,
    required this.songLink,
    required this.preview,
  });

  @override
  State<LandscapeCoverToggle> createState() => _LandscapeCoverToggleState();
}

class _LandscapeCoverToggleState extends State<LandscapeCoverToggle>
    with SingleTickerProviderStateMixin {
  bool _showInfo = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _showInfo = !_showInfo;
      if (_showInfo) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _openCoverViewerDialog(SongLink? songLink, BuildContext context) {
    if (!_showInfo) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return CoverViewer(songLink);
          },
          fullscreenDialog: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main content area (cover or info)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showInfo
                  ? Container(
                      key: const ValueKey('info'),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: widget.preview
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: SongInformations(song: widget.song),
                            ),
                    )
                  : Hero(
                      key: const ValueKey('cover'),
                      tag: createTag(widget.songLink),
                      child: Material(
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              _openCoverViewerDialog(widget.songLink, context),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: widget.song.coverLink,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        // Toggle button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleView,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _showInfo ? Icons.image : Icons.info_outline,
                  key: ValueKey(_showInfo),
                ),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _showInfo ? 'Voir la pochette' : 'Voir les infos',
                  key: ValueKey(_showInfo),
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                foregroundColor: Theme.of(context).primaryColor,
                elevation: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SongPageContent extends StatefulWidget {
  final SongLink songLink;
  final Song song;
  final Function onPageChange;
  final bool preview;

  const SongPageContent(
    this.songLink,
    this.song,
    this.onPageChange,
    this.preview, {
    super.key,
  });

  @override
  State<SongPageContent> createState() => _SongPageContentState();
}

class _SongPageContentState extends State<SongPageContent> {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      backgroundColor: Theme.of(context).canvasColor,
                      expandedHeight: 200.0,
                      automaticallyImplyLeading: false,
                      floating: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: MiniCover(
                                      widget.song,
                                      widget.songLink,
                                    ),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: widget.preview == true
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : SongInformations(song: widget.song),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
            body: SongLyricsAndComments(
              widget.song,
              widget.songLink,
              widget.onPageChange,
            ),
          );
        } else {
          // Improved landscape layout
          return Row(
            children: [
              // Cover/Info toggle section (left)
              Expanded(
                flex: 2,
                child: LandscapeCoverToggle(
                  song: widget.song,
                  songLink: widget.songLink,
                  preview: widget.preview,
                ),
              ),
              // Lyrics and comments section (right)
              Expanded(
                flex: 3,
                child: SongLyricsAndComments(
                  widget.song,
                  widget.songLink,
                  widget.onPageChange,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class SongPageWidget extends StatefulWidget {
  final SongLink? songLink;
  final Future<Song>? song;

  const SongPageWidget({super.key, this.songLink, this.song});

  @override
  State<SongPageWidget> createState() => _SongPageWidgetState();
}

class _SongPageWidgetState extends State<SongPageWidget> {
  int? _currentPage;

  _SongPageWidgetState();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Song>(
      future: widget.song,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _buildView(context, snapshot.data!, false);
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ouille ouille ouille !')),
            body: Center(child: ErrorDisplay(snapshot.error)),
          );
        }

        var song = Song(id: widget.songLink!.id, name: widget.songLink!.name);
        return _buildView(context, song, true);
      },
    );
  }

  void onPageChange(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildView(BuildContext context, Song song, preview) {
    Widget? postNewComment = Session.accountLink.id == null || _currentPage != 1
        ? null
        : FloatingActionButton(
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) {
                return CommentDialog(song, widget.songLink!, null);
              },
            ),
            child: const Icon(Icons.add_comment),
          );

    return Scaffold(
      appBar: SongAppBar(widget.song),
      body: SongPageContent(widget.songLink!, song, onPageChange, preview),
      floatingActionButton: postNewComment,
    );
  }
}
