import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:youtube_downloader/utils/newpipe_channel.dart';

part 'download_providers.g.dart';

@riverpod
class YoutubeFormats extends _$YoutubeFormats {
  @override
  AsyncValue<List<StreamItem>> build() => const AsyncValue.data([]);

  Future<void> loadFormats(String url) async {
    state = const AsyncValue.loading();
    try {
      final api = const NewPipeApi();
      final streams = await api.getStreams(url);
      state = AsyncValue.data(streams);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

@riverpod
class YoutubeInfo extends _$YoutubeInfo {
  @override
  AsyncValue<VideoInfo?> build() => const AsyncValue.data(null);

  Future<void> loadInfo(String url) async {
    state = const AsyncValue.loading();
    try {
      final api = const NewPipeApi();
      final info = await api.getVideoInfo(url);
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
