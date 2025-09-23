import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

part 'download_providers.g.dart';

@riverpod
class YoutubeFormats extends _$YoutubeFormats {
  @override
  AsyncValue<List<StreamInfo>> build() => const AsyncValue.data([]);

  Future<void> loadFormats(String url) async {
    state = const AsyncValue.loading();
    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(url);
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final streams = manifest.streams.where((stream) => stream.container.name == "mp4").toList();
      state = AsyncValue.data(streams);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
class YoutubeInfo extends _$YoutubeInfo {
  @override
  AsyncValue<Video?> build() => const AsyncValue.data(null);

  Future<void> loadInfo(String url) async {
    state = const AsyncValue.loading();
    try {
      final yt = YoutubeExplode();
      final video = await yt.videos.get(url);
      state = AsyncValue.data(video);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
