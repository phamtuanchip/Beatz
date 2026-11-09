import 'dart:async';
import 'dart:collection';

import 'package:beatz/blocs/bloc_provider.dart';
import 'package:beatz/models/album.dart';
import 'package:beatz/services/platform_service.dart';
import 'package:rxdart/rxdart.dart';

class AlbumsPageBloc extends BlocBase {
  /// Emits the album list, or an error when the library can't be read
  /// (e.g. the permission was denied).
  final BehaviorSubject<List<Album>> _listController =
      BehaviorSubject<List<Album>>();
  Stream<List<Album>> get albumListStream => _listController.stream;

  final Future<List<Album>> Function() _fetchAlbums;

  AlbumsPageBloc({Future<List<Album>> Function()? fetchAlbums})
      : _fetchAlbums = fetchAlbums ?? PlatformService.fetchAlbums {
    refresh();
  }

  Future<void> refresh() async {
    try {
      final albums = await _fetchAlbums();
      if (!_listController.isClosed) {
        _listController.add(UnmodifiableListView<Album>(albums));
      }
    } catch (e) {
      if (!_listController.isClosed) _listController.addError(e);
    }
  }

  @override
  void dispose() {
    _listController.close();
  }
}
