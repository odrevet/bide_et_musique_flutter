import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/artist.dart';
import 'artist.dart';
import 'search.dart';

class SongInformations extends StatelessWidget {
  final Song song;
  final bool compact;

  const SongInformations({required this.song, this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact && song.year != 0)
            _buildInfoCard(
              context,
              title: 'Année',
              value: song.year.toString(),
              onTap: () => _navigateToSearch(
                context,
                'Recherche de l\'année "${song.year.toString()}"',
                song.year.toString(),
                '7',
              ),
            ),

          if (!compact && song.artist != null)
            _buildInfoCard(
              context,
              title: 'Artiste',
              value: song.artist!,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ArtistPageWidget(artist: fetchArtist(song.artistId)),
                ),
              ),
            ),

          if (song.durationPretty != null)
            _buildInfoCard(
              context,
              title: 'Durée',
              value: song.durationPretty!,
              isClickable: false,
            ),

          if (song.label != null && song.label!.isNotEmpty)
            _buildInfoCard(
              context,
              title: 'Label',
              value: song.label!,
              onTap: () => _navigateToSearch(
                context,
                'Recherche du label "${song.label}"',
                song.label!,
                '5',
              ),
            ),

          if (song.reference != null && song.reference!.isNotEmpty)
            _buildInfoCard(
              context,
              title: 'Référence',
              value: song.reference!,
              isClickable: false,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    VoidCallback? onTap,
    bool isClickable = true,
  }) {
    final theme = Theme.of(context);
    final isInteractive = isClickable && onTap != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 6.0),
      elevation: 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInteractive ? onTap : null,
          borderRadius: BorderRadius.circular(6.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isInteractive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          fontWeight: isInteractive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isInteractive)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSearch(
    BuildContext context,
    String title,
    String query,
    String searchType,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SearchResults(query, searchType),
        ),
      ),
    );
  }
}

// Alternative compact version for better compact layout
class CompactSongInformations extends StatelessWidget {
  final Song song;

  const CompactSongInformations({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6.0,
      runSpacing: 2.0,
      children: [
        if (song.durationPretty != null)
          _buildCompactChip(context, Icons.schedule, song.durationPretty!),

        if (song.year != 0)
          _buildCompactChip(context, Icons.event, song.year.toString()),

        if (song.artist != null)
          _buildCompactChip(
            context,
            Icons.person,
            song.artist!,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ArtistPageWidget(artist: fetchArtist(song.artistId)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactChip(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 14),
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
      ),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
