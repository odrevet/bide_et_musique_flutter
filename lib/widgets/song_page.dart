import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:page_indicator_plus/page_indicator_plus.dart';

import '../models/song.dart';
import '../services/account.dart';
import '../services/song.dart';
import '../session.dart';
import '../utils.dart';
import 'account.dart';
import 'cover_viewer.dart';
import 'error_display.dart';
import 'html_with_style.dart';
import 'song_app_bar.dart';
import 'song_information.dart';

class SongPageWidget extends StatefulWidget {
  final SongLink? songLink;
  final Future<Song>? song;

  const SongPageWidget({super.key, this.songLink, this.song});

  @override
  State<SongPageWidget> createState() => _SongPageWidgetState();
}

class _SongPageWidgetState extends State<SongPageWidget> {
  int? _currentPage;
  final _commentController = TextEditingController();
  final PageController _pageController = PageController(
    initialPage: 0,
  );

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

        return Center(child: _pageLoading(context, widget.songLink!));
      },
    );
  }

  void _openCoverViewerDialog(SongLink? songLink, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return CoverViewer(songLink);
        },
        fullscreenDialog: true));
  }

  Widget _pageLoading(BuildContext context, SongLink songLink) {
    var coverLink = songLink.coverLink;

    var loadingMessage = '';
    if (songLink.name.isNotEmpty) {
      loadingMessage += songLink.name;
    } else {
      loadingMessage = 'Chargement';
    }

    Widget body = Stack(children: <Widget>[
      CachedNetworkImage(
        imageUrl: coverLink,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: BoxFit.fitWidth),
          ),
        ),
        errorWidget: (context, url, error) =>
            Image.asset('assets/vinyl-default.jpg'),
      ),
      const Align(
          alignment: Alignment.center, child: CircularProgressIndicator())
    ]);

    return Scaffold(appBar: AppBar(title: Text(loadingMessage)), body: body);
  }

  _newMessageDialog(BuildContext context, Song song) {
    _commentController.text = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Envoyer"),
              onPressed: () async {
                Navigator.of(context).pop();
                sendAddComment(song, _commentController.text);
                // refresh current page so posted comment is visible
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongPageWidget(
                            songLink: widget.songLink,
                            song: fetchSong(widget.songLink!.id))));
                // refresh current page so posted comment is visible
              },
            )
          ],
          title: const Text('Nouveau commentaire'),
          content: TextFormField(
              maxLines: 5,
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Entrez votre commentaire ici',
              )),
        );
      },
    );
  }

  _editMessageDialog(BuildContext context, Song song, Comment comment) {
    _commentController.text = comment.body!;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          actions: [
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Envoyer"),
              onPressed: () async {
                Navigator.of(context).pop();
                sendEditComment(song, comment, _commentController.text);
                // refresh current page so posted comment is visible
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SongPageWidget(
                            songLink: widget.songLink,
                            song: fetchSong(widget.songLink!.id))));
              },
            )
          ],
          title: const Text('Edition d\'un commentaire'),
          content: TextFormField(
              maxLines: 5,
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Entrez votre commentaire ici',
              )),
        );
      },
    );
  }

  Widget _buildView(BuildContext context, Song song) {
    final String coverLink = song.coverLink;
    final tag = createTag(widget.songLink!);

    var nestedScrollView = NestedScrollView(
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
                                  child: InkWell(
                                      onTap: () {
                                        _openCoverViewerDialog(
                                            widget.songLink, context);
                                      },
                                      child: CachedNetworkImage(
                                          imageUrl: coverLink)))),
                        ),
                        Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                                child: SongInformations(song: song))),
                      ],
                    ))
              ])),
            ),
          ];
        },
        body: Stack(children: [
          CachedNetworkImage(
            imageUrl: song.coverLink,
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
                onPageChanged: (int page) => setState(() {
                    _currentPage = page;
                  }),
                children: <Widget>[
                  SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0, top: 2.0),
                        child: HtmlWithStyle(
                            data: song.lyrics == ''
                                ? '<center><i>Paroles non renseignées</i></center>'
                                : song.lyrics),
                      )),
                  _buildViewComments(context, song),
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

    Widget? postNewComment = Session.accountLink.id == null || _currentPage != 1
        ? null
        : FloatingActionButton(
            onPressed: () => _newMessageDialog(context, song),
            child: const Icon(Icons.add_comment),
          );

    return Scaffold(
      appBar: SongAppBar(widget.song),
      body: nestedScrollView,
      floatingActionButton: postNewComment,
    );
  }

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
                    _editMessageDialog(context, song, comment);
                  },
                )
              : null));
      rows.add(const Divider());
    }

    return ListView(children: rows);
  }
}
