import 'package:bide_et_musique/widgets/song_page/song_page.dart';
import 'package:flutter/material.dart';

import '../../models/comment.dart';
import '../../models/song.dart';
import '../../services/song.dart';

class CommentDialog extends StatelessWidget {
  final Song song;
  final Comment? comment;
  final SongLink songLink;

  CommentDialog(this.song, this.songLink, this.comment, {super.key});

  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      actions: [
        ElevatedButton.icon(
          icon: const Icon(Icons.send),
          label: const Text("Envoyer"),
          onPressed: () async {
            Navigator.of(context).pop();
            if(comment == null){
              sendAddComment(song, _commentController.text);
            }
            else{
              sendEditComment(song, comment!, _commentController.text);
            }

            // refresh current page to display posted comment
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => SongPageWidget(
                        songLink: songLink,
                        song: fetchSong(songLink.id))));
          },
        )
      ],
      title: const Text('Votre commentaire'),
      content: TextFormField(
          maxLines: 5,
          controller: _commentController,
          decoration: const InputDecoration(
            hintText: 'Entrez votre commentaire ici',
          )),
    );
  }
}
