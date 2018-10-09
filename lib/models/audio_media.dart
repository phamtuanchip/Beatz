class AudioMedia {
  int id;
  String title;
  String displayName;
  String artist;
  int duration;
  int track;

  AudioMedia(this.id, this.title, this.displayName, this.artist, this.duration,
      this.track);

  AudioMedia.fromJson(Map<String, dynamic> json) {
    artist = json['artist'];
    displayName = json['displayName'];
    duration = json['duration'];
    id = json['id'];
    title = json['title'];
    track = json['track'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['artist'] = this.artist;
    data['displayName'] = this.displayName;
    data['duration'] = this.duration;
    data['id'] = this.id;
    data['title'] = this.title;
    data['track'] = this.track;
    return data;
  }
}