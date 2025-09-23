import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/history/providers/history_providers.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).fetchHistory();
    });

    return WaveScaffold(
      appBar: WaveAppBar(title: const Text('History')),
      body: ref
          .watch(historyProvider)
          .when(
            data: (tasks) {
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return WaveListTile(
                    title: Text(tasks[index].filename ?? ""),
                    subtitle: Text(tasks[index].status.toString()),
                  );
                },
              );
            },
            loading: () => const Center(child: WaveCircularProgressIndicator()),
            error: (err, st) => Center(child: Text("Error: $err")),
          ),
    );
  }
}
