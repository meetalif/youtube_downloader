import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
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
              if (tasks.isEmpty) {
                return const Center(child: Text('No history'));
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  FlutterDownloader.registerCallback((id, status, progress) => log("$id $status $progress"));
                  return WaveListTile(
                    title: Text(task.filename ?? ""),
                    subtitle: Text(task.status.toString()),
                    trailing: task.status == DownloadTaskStatus.running
                        ? IconButton(
                            icon: const Icon(WaveIcons.dismiss_circle_24_regular),
                            onPressed: () => FlutterDownloader.cancel(taskId: task.taskId),
                          )
                        : task.status == DownloadTaskStatus.failed || task.status == DownloadTaskStatus.canceled
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(WaveIcons.arrow_clockwise_24_regular),
                                onPressed: () => FlutterDownloader.retry(taskId: task.taskId),
                              ),
                              IconButton(
                                icon: const Icon(WaveIcons.delete_24_regular),
                                onPressed: () =>
                                    FlutterDownloader.remove(taskId: task.taskId, shouldDeleteContent: true),
                              ),
                            ],
                          )
                        : null,
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
