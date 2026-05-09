class Note {
  final String? author;
  final String? content;
  final int? authorId;
  final String? timestamp;

  Note({
    this.author,
    this.content,
    this.authorId,
    this.timestamp,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      author: json['author'],
      content: json['content'],
      authorId: json['authorId'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (author != null) 'author': author,
      if (content != null) 'content': content,
      if (authorId != null) 'authorId': authorId,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}
