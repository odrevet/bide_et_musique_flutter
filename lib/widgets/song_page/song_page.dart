import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:page_indicator_plus/page_indicator_plus.dart';

import '../../models/comment.dart';
import '../../models/song.dart';
import '../../services/account.dart';
import '../../session.dart';
import '../../utils.dart';
import '../account.dart';
import 'comment_dialog.dart';
import '../cover_viewer.dart';
import '../error_display.dart';
import '../html_with_style.dart';
import '../song_app_bar.dart';
import '../song_informations.dart';


class SongPageNestedScrollView extends StatefulWidget {
  final SongLink songLink;
  final Song song;
  final Function onPageChange;


  const SongPageNestedScrollView(
      this.songLink, this.song, this.onPageChange,
      {super.key});

  @override
  State<SongPageNestedScrollView> createState() =>
      _SongPageNestedScrollViewState();
}

class _SongPageNestedScrollViewState extends State<SongPageNestedScrollView> {
  final PageController _pageController = PageController(
    initialPage: 0,
  );

  Widget _buildViewComments(BuildContext context, Song song) {
    List<Comment> comments = song.comments;
    var rows = <Widget>[];
    String? loginName = Session.accountLink.name;
    var selfComment = const TextStyle(
      color: Colors.red,
    );

    for (Comment comment in comments) {
      rows.add(ListTile(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AccountPage(account: fetchAccount(comment.author.id))));
          },
          title: HtmlWithStyle(data: comment.body),
          subtitle: Text('Par ${comment.author.name!} ${comment.time}',
              style: comment.author.name == loginName ? selfComment : null),
          trailing: comment.author.name == loginName
              ? IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CommentDialog(song, widget.songLink, comment);
                        });
                  },
                )
              : null));
      rows.add(const Divider());
    }

    return ListView(children: rows);
  }

  void _openCoverViewerDialog(SongLink? songLink, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return CoverViewer(songLink);
        },
        fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    final String coverLink = widget.song.coverLink;
    final tag = createTag(widget.songLink);

    return NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Theme.of(context).canvasColor,
              expandedHeight: 200.0,
              automaticallyImplyLeading: false,
              floating: true,
              flexibleSpace: FlexibleSpaceBar(
                  background: Row(children: [
                Expanded(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Hero(
                                  tag: tag,
                                  child: Material(
                                    child: InkWell(
                                        onTap: () {
                                          _openCoverViewerDialog(
                                              widget.songLink, context);
                                        },
                                        child: CachedNetworkImage(
                                            imageUrl: coverLink)),
                                  ))),
                        ),
                        Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                                child: SongInformations(song: widget.song))),
                      ],
                    ))
              ])),
            ),
          ];
        },
        body: Stack(children: [
          CachedNetworkImage(
            imageUrl: widget.song.coverLink,
            imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: imageProvider, fit: BoxFit.cover)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 9.6, sigmaY: 9.6),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.7)),
                  ),
                )),
          ),
          Stack(
            children: [
              PageView(
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
                                  : widget.song.lyrics),
                        ))
                      : const Center(child: CircularProgressIndicator()),
                  _buildViewComments(context, widget.song),
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
        ]));
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
          return _buildView(context, snapshot.data!);
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ouille ouille ouille !')),
            body: Center(child: ErrorDisplay(snapshot.error)),
          );
        }

        var song = Song(id: widget.songLink!.id, name: widget.songLink!.name);
        return _buildView(context, song);
      },
    );
  }

  void onPageChange(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Widget _buildView(BuildContext context, Song song) {
    Widget? postNewComment = Session.accountLink.id == null || _currentPage != 1
        ? null
        : FloatingActionButton(
            onPressed: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CommentDialog(song, widget.songLink!, null);
                }),
            child: const Icon(Icons.add_comment),
          );

    return Scaffold(
      appBar: SongAppBar(widget.song),
      body: SongPageNestedScrollView(
          widget.songLink!, song, onPageChange),
      floatingActionButton: postNewComment,
    );
  }
}
