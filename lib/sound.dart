class Sound {
  final String title;
  final String filename;
  bool cached = false;

  Sound(this.title, this.filename);

  @override
  String toString() => '{ title: "$title", filename: "$filename", cached: "$cached" }';
}
