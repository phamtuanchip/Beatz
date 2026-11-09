class Album {
  final int id;
  final String album;
  final String artist;

  /// Absolute path to the cover image, or null when the album has none.
  final String? albumArt;
  final int numOfSongs;

  const Album(this.id, this.album, this.artist, this.albumArt, this.numOfSongs);

  factory Album.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as String?;
    return Album(
      json['id'] as int,
      json['album'] as String? ?? 'Unknown',
      artist == null || artist == '<unknown>' ? 'Unknown' : artist,
      json['albumArt'] as String?,
      json['numOfSongs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'album': album,
        'artist': artist,
        'albumArt': albumArt,
        'numOfSongs': numOfSongs,
      };
}
