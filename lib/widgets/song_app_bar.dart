import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session.dart';
import '../models/song.dart';
import '../services/favorite.dart';
import '../services/song.dart';
import '../utils.dart';
import 'player/song_player.dart';

class SongActionMenu extends StatelessWidget {
  final Song? _song;

  const SongActionMenu(this._song, {super.key});

  @override
  Widget build(BuildContext context) {
    //add buttons to the actions menu
    //some action buttons are added when user is logged in
    //some action buttons are not available on some songs
    final actions = <Widget>[];
    //if the song can be listen, add the song player
    if (_song!.canListen) {
      actions.add(SongPlayerWidget(_song));
    }

    //if the user is logged in
    if (Session.accountLink.id != null) {
      if (_song.canFavourite) {
        actions.add(SongFavoriteIconWidget(_song));
      }

      actions.add(SongVoteIconWidget(_song));
    }

    actions.add(SongOpenInBrowserIconWidget(_song));

    // Share buttons (message and song id)
    var actionsShare = <Widget>[];

    var shareSongStream = ElevatedButton.icon(
      icon: const Icon(Icons.music_note),
      label: const Text('Flux musical'),
      onPressed: () => SharePlus.instance.share(ShareParams(text: _song.streamLink)),
    );

    actionsShare.add(SongShareIconWidget(_song));
    actionsShare.add(shareSongStream);

    //build widget for overflow button
    var popupMenuShare = <PopupMenuEntry<Widget>>[];
    for (Widget actionWidget in actionsShare) {
      popupMenuShare.add(PopupMenuItem<Widget>(child: actionWidget));
    }

    Widget popupMenuButtonShare = PopupMenuButton<Widget>(
      icon: const Icon(Icons.share),
      itemBuilder: (BuildContext context) => popupMenuShare,
    );

    ///////////////////////////////////
    //// Copy
    var popupMenuCopy = <PopupMenuEntry<Widget>>[];
    popupMenuCopy.add(
      PopupMenuItem<Widget>(child: SongCopyLinkIconWidget(_song)),
    );
    popupMenuCopy.add(
      PopupMenuItem<Widget>(child: SongCopyLinkHtmlIconWidget(_song)),
    );

    Widget popupMenuButtonCopy = PopupMenuButton<Widget>(
      icon: const Icon(Icons.content_copy),
      itemBuilder: (BuildContext context) => popupMenuCopy,
    );

    actions.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[popupMenuButtonCopy, popupMenuButtonShare],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions,
    );
  }
}


class SongAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Future<Song>? _song;

  const SongAppBar(this._song, {super.key})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize;

  @override
  State<SongAppBar> createState() => _SongAppBarState();
}

class _SongAppBarState extends State<SongAppBar> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Song>(
      future: widget._song,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final song = snapshot.data!;
          return AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (song.artist?.isNotEmpty == true)
                  Text(
                    song.artist!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Options de la chanson',
                onPressed: () => _showSongOptionsBottomSheet(context, song),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return AppBar(
            title: const Text("Erreur de chargement"),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          );
        }

        return AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text("Chargement..."),
            ],
          ),
        );
      },
    );
  }

  void _showSongOptionsBottomSheet(BuildContext context, Song song) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SongActionBottomSheet(song, scrollController: scrollController);
          },
        );
      },
    );
  }
}

/////////////////////////////////////////////////////////////////////////////
// Enhanced Bottom Sheet with Better UX

class SongActionBottomSheet extends StatefulWidget {
  final Song song;
  final ScrollController? scrollController;

  const SongActionBottomSheet(this.song, {this.scrollController, super.key});

  @override
  State<SongActionBottomSheet> createState() => _SongActionBottomSheetState();
}

class _SongActionBottomSheetState extends State<SongActionBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Song info header
          _buildSongHeader(theme),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.song.canListen) ...[
                  _buildSectionTitle('Lecture', Icons.play_circle),
                  const SizedBox(height: 8),
                  SongPlayerWidget(widget.song),
                  const SizedBox(height: 24),
                ],

                if (Session.accountLink.id != null) ...[
                  _buildSectionTitle('Actions utilisateur', Icons.person),
                  const SizedBox(height: 8),
                  _buildUserActions(),
                  const SizedBox(height: 24),
                ],

                _buildSectionTitle('Partager', Icons.share),
                const SizedBox(height: 8),
                _buildShareActions(),
                const SizedBox(height: 24),

                _buildSectionTitle('Copier', Icons.content_copy),
                const SizedBox(height: 8),
                _buildCopyActions(),
                const SizedBox(height: 24),

                _buildSectionTitle('Ouvrir', Icons.open_in_browser),
                const SizedBox(height: 8),
                SongOpenInBrowserIconWidget(widget.song),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.song.artist?.isNotEmpty == true)
                  Text(
                    widget.song.artist!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildUserActions() {
    return Column(
      children: [
        if (widget.song.canFavourite)
          SongFavoriteIconWidget(widget.song),
        const SizedBox(height: 8),
        SongVoteIconWidget(widget.song),
      ],
    );
  }

  Widget _buildShareActions() {
    return Column(
      children: [
        SongShareIconWidget(widget.song),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.music_note),
          label: const Text('Partager le flux musical'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          onPressed: () => Share.share(widget.song.streamLink),
        ),
      ],
    );
  }

  Widget _buildCopyActions() {
    return Column(
      children: [
        SongCopyLinkIconWidget(widget.song),
        const SizedBox(height: 8),
        SongCopyLinkHtmlIconWidget(widget.song),
      ],
    );
  }
}

/////////////////////////////////////////////////////////////////////////////
// Enhanced Action Widgets

class SongFavoriteIconWidget extends StatefulWidget {
  final Song song;

  const SongFavoriteIconWidget(this.song, {super.key});

  @override
  State<SongFavoriteIconWidget> createState() => _SongFavoriteIconWidgetState();
}

class _SongFavoriteIconWidgetState extends State<SongFavoriteIconWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.song.isFavourite;

    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Icon(isFavorite ? Icons.star : Icons.star_border),
      label: Text(isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: isFavorite
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: isFavorite
            ? Theme.of(context).colorScheme.onErrorContainer
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      onPressed: _isLoading ? null : _toggleFavorite,
    );
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isLoading = true);

    try {
      final statusCode = widget.song.isFavourite
          ? await removeSongFromFavorites(widget.song.id)
          : await addSongToFavorites(widget.song.link);

      if (statusCode == 200) {
        setState(() {
          widget.song.isFavourite = !widget.song.isFavourite;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.song.isFavourite
                    ? 'Ajouté aux favoris !'
                    : 'Retiré des favoris',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Erreur lors de la modification des favoris');
      }
    } catch (e) {
      _showErrorSnackBar('Une erreur est survenue');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class SongVoteIconWidget extends StatefulWidget {
  final Song song;

  const SongVoteIconWidget(this.song, {super.key});

  @override
  State<SongVoteIconWidget> createState() => _SongVoteIconWidgetState();
}

class _SongVoteIconWidgetState extends State<SongVoteIconWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasVoted = widget.song.hasVote;

    return ElevatedButton.icon(
      icon: _isLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : Icon(hasVoted ? Icons.how_to_vote : Icons.exposure_plus_1),
      label: Text(hasVoted ? 'Déjà voté' : 'Voter pour cette chanson'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: hasVoted
            ? Theme.of(context).colorScheme.surfaceVariant
            : Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: hasVoted
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      onPressed: (hasVoted || _isLoading) ? null : _vote,
    );
  }

  Future<void> _vote() async {
    setState(() => _isLoading = true);

    try {
      final statusCode = await voteForSong(widget.song.link);

      if (statusCode == 200) {
        setState(() {
          widget.song.hasVote = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vote enregistré !'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _showErrorSnackBar('Erreur lors du vote');
      }
    } catch (e) {
      _showErrorSnackBar('Une erreur est survenue');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

/////////////////////////////////////////////////////////////////////////////
// Enhanced Share and Copy Widgets

class SongShareIconWidget extends StatelessWidget {
  final Song song;

  const SongShareIconWidget(this.song, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.message),
      label: const Text('Partager par message'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () => Share.share(
        '''🎵 En ce moment j'écoute "${song.name}" sur Bide et Musique !

🔗 Découvre cette chanson :
${song.link}

📱 Télécharge l'app :
• Android : https://play.google.com/store/apps/details?id=fr.odrevet.bide_et_musique 
• iOS : https://apps.apple.com/fr/app/bide-et-musique/id1524513644''',
        subject: '"${song.name}" sur Bide et Musique',
      ),
    );
  }
}

class SongCopyLinkIconWidget extends StatelessWidget {
  final Song song;

  const SongCopyLinkIconWidget(this.song, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.link),
      label: const Text('Copier le lien'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: song.link));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien copié dans le presse-papiers !'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

class SongCopyLinkHtmlIconWidget extends StatelessWidget {
  final Song song;

  const SongCopyLinkHtmlIconWidget(this.song, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.code),
      label: const Text('Copier le code HTML'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () {
        Clipboard.setData(
          ClipboardData(text: '<a href="${song.link}">${song.name}</a>'),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code HTML copié !'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

class SongOpenInBrowserIconWidget extends StatelessWidget {
  final Song song;

  const SongOpenInBrowserIconWidget(this.song, {super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.open_in_browser),
      label: const Text('Ouvrir dans le navigateur'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () => launchURL(song.link),
    );
  }
}