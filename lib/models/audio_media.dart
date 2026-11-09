class AudioMedia {
  final int id;
  final String title;
  final String displayName;
  final String artist;

  /// Duration in milliseconds.
  final int duration;
  final int track;

  /// content:// URI of the track in MediaStore.
  final String uri;
  final String? type;

  const AudioMedia(this.id, this.title, this.displayName, this.artist,
      this.duration, this.track, this.uri, this.type);

  factory AudioMedia.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as String?;
    return AudioMedia(
      json['id'] as int,
      json['title'] as String? ?? '',
      json['displayName'] as String? ?? '',
      artist == null || artist == '<unknown>' ? 'Unknown' : artist,
      json['duration'] as int? ?? 0,
      json['track'] as int? ?? 0,
      json['uri'] as String,
      json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'displayName': displayName,
        'artist': artist,
        'duration': duration,
        'track': track,
        'uri': uri,
        'type': type,
      };
}
