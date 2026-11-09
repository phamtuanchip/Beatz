import 'package:beatz/blocs/albums_page_bloc.dart';
import 'package:beatz/blocs/bloc_provider.dart';
import 'package:beatz/blocs/current_album_bloc.dart';
import 'package:beatz/models/album.dart';
import 'package:beatz/pages/current_album_page.dart';
import 'package:beatz/widgets/record_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlbumsPage extends StatelessWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AlbumsPageBloc bloc = BlocProvider.of<AlbumsPageBloc>(context);
    return StreamBuilder<List<Album>>(
      stream: bloc.albumListStream,
      builder: (BuildContext context, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          return _Message(
            icon: Icons.lock_outline,
            text: _errorText(snapshot.error),
            onRetry: bloc.refresh,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final albums = snapshot.data!;
        if (albums.isEmpty) {
          return _Message(
            icon: Icons.library_music_outlined,
            text: 'No albums found on this device.',
            onRetry: bloc.refresh,
          );
        }
        return RefreshIndicator(
          onRefresh: bloc.refresh,
          child: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) =>
                _AlbumTile(album: albums[index]),
          ),
        );
      },
    );
  }

  static String _errorText(Object? error) {
    if (error is PlatformException && error.code == 'permission_denied') {
      return 'Beatz needs access to your music to show albums.';
    }
    return 'Could not load your music library.';
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToCurrentAlbum(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Hero(
              tag: '${album.id}',
              child: RecordWidget(diameter: 130.0, albumArt: album.albumArt),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      album.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                          color: Color(0xFF444444)),
                    ),
                    Text(
                      album.album,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15.0,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 5.0),
                    Text(
                      '${album.numOfSongs} '
                      '${album.numOfSongs == 1 ? 'Song' : 'Songs'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCurrentAlbum(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return BlocProvider<CurrentAlbumBloc>(
          bloc: CurrentAlbumBloc(album.id),
          child: CurrentAlbumPage(album: album),
        );
      }),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.0, color: Colors.grey),
            const SizedBox(height: 12.0),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12.0),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
