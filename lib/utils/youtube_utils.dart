class YoutubeUtils {
  static String? extractVideoId(String? url) {
    if (url != null && url.isNotEmpty) {
      RegExp exp = RegExp(
        r"^(?:https?:\/\/)?(?:www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$",
      );
      RegExpMatch? match = exp.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  static String? extractThumbUrl(String? url) {
    var videoId = extractVideoId(url);
    if (videoId != null) {
      return 'https://i3.ytimg.com/vi/$videoId/maxresdefault.jpg';
    }
    return null;
  }
}
