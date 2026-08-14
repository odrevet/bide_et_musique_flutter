import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../../models/session.dart';
import '../../models/song.dart';
import '../../services/account.dart';
import '../account.dart';
import '../html_with_style.dart';
import 'comment_dialog.dart';

class CommentsList extends StatelessWidget {
  final Song song;
  final SongLink songLink;

  const CommentsList(this.song, this.songLink, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Comment> comments = song.comments;
    var rows = <Widget>[];
    String? loginName = Session.accountLink.name;
    var selfComment = TextStyle(color: Theme.of(context).colorScheme.primary);

    if (comments.length > 1) {
      for (Comment comment in comments) {
        rows.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AccountPage(account: fetchAccount(comment.author.id)),
                ),
              );
            },
            title: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: HtmlWithStyle(data: comment.body),
            ),
            subtitle: Text(
              'Par ${comment.author.name!} ${comment.time}',
              style: (comment.author.name == loginName ? selfComment : null)?.copyWith(
                fontSize: 12,
              ),
            ),
            trailing: comment.author.name == loginName
                ? IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CommentDialog(song, songLink, comment);
                        },
                      );
                    },
                  )
                : null,
          ),
        ),
      );
      }
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: rows,
      );
    } else {
      return const Padding(
        padding: EdgeInsets.only(left: 4.0, top: 2.0),
        child: HtmlWithStyle(data: '<i>Pas encore de commentaires</i>'),
      );
    }
  }
}
