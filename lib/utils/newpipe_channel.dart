import 'package:flutter/services.dart';

const _channel = MethodChannel('com.example.youtube_downloader/newpipe');

class VideoInfo {
  final String id;
  final String title;
  final String author;
  final String thumbnailUrl;
  final String uploadDate;
  const VideoInfo({
    required this.id,
    required this.title,
    required this.author,
    required this.thumbnailUrl,
    required this.uploadDate,
  });

  factory VideoInfo.fromMap(Map map) => VideoInfo(
        id: (map['id'] ?? '') as String,
        title: (map['title'] ?? '') as String,
        author: (map['author'] ?? '') as String,
        thumbnailUrl: (map['thumbnailUrl'] ?? '') as String,
        uploadDate: (map['uploadDate'] ?? '') as String,
      );
}

class StreamItem {
  final String url;
  final String format;
  final String quality; // could be resolution like 1080p or bitrate label
  final bool isVideoOnly;
  final bool isAudioOnly;
  final String fileExtension; // e.g. mp4 or m4a
  const StreamItem({
    required this.url,
    required this.format,
    required this.quality,
    required this.isVideoOnly,
    required this.isAudioOnly,
    required this.fileExtension,
  });

  factory StreamItem.fromMap(Map map) => StreamItem(
        url: (map['url'] ?? '') as String,
        format: (map['format'] ?? '') as String,
        quality: '${map['quality'] ?? ''}',
        isVideoOnly: (map['isVideoOnly'] ?? false) as bool,
        isAudioOnly: (map['isAudioOnly'] ?? false) as bool,
        fileExtension: (map['fileExtension'] ?? 'mp4') as String,
      );
}

class NewPipeApi {
  const NewPipeApi();

  Future<VideoInfo> getVideoInfo(String url) async {
    final res = await _channel.invokeMethod('getVideoInfo', {'url': url});
    return VideoInfo.fromMap(Map.from(res as Map));
    
  }

  Future<List<StreamItem>> getStreams(String url) async {
    final res = await _channel.invokeMethod('getStreams', {'url': url});
    final list = (res as List).cast<Map>();
    return list.map((e) => StreamItem.fromMap(Map.from(e))).toList();
  }
}
