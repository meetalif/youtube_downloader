import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_providers.g.dart';

@riverpod
class History extends _$History {
  @override
  AsyncValue<List<DownloadTask>> build() {
    return const AsyncValue.data([]);
  }

  Future<void> fetchHistory() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await FlutterDownloader.loadTasks();
      state = AsyncValue.data(tasks!);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
