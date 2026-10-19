class VideoPost {
  final String id;
  final String caption;
  final String videoUrl;
  final String mediaType;
  final String filterName;
  final int likes;
  final int views;

  VideoPost({
    this.id = '',
    required this.caption,
    required this.videoUrl,
    this.mediaType = 'video',
    this.filterName = 'original',
    this.likes = 0,
    this.views = 0,
  });

  bool get isImage => mediaType == 'image';
}
