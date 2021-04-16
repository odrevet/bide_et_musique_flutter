import 'account.dart';
import 'song.dart';

class Post {
  final AccountLink author;
  final SongLink during;
  final String body;
  final String date;
  final String time;

  Post(this.author, this.during, this.body, this.date, this.time);
}
