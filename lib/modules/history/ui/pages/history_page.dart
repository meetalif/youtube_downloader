import 'dart:async';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/history/providers/history_providers.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  Timer? _timer;
  final controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).fetchHistory();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(historyProvider.notifier).fetchHistory();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return WaveScaffold(
      appBar: WaveAppBar(title: const Text('History'), alwaysShowDivider: true, scrollController: controller),
      body: ref
          .watch(historyProvider)
          .when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const Center(child: Text('No history'));
              }
              return ListView.separated(
                controller: controller,
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const WaveDivider(),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final isRunning = task.status == DownloadTaskStatus.running;
                  return GestureDetector(
                    onTap: task.status == DownloadTaskStatus.complete
                        ? () => FlutterDownloader.open(taskId: task.taskId)
                        : null,
                    child: ColoredBox(
                      color: colorScheme.surfacePrimary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(task.filename ?? "", style: textTheme.body)),
                                if (isRunning)
                                  IconButton(
                                    icon: const Icon(WaveIcons.dismiss_circle_24_regular),
                                    onPressed: () => FlutterDownloader.cancel(taskId: task.taskId),
                                  )
                                else if (task.status == DownloadTaskStatus.failed ||
                                    task.status == DownloadTaskStatus.canceled)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(WaveIcons.delete_24_regular),
                                        onPressed: () =>
                                            FlutterDownloader.remove(taskId: task.taskId, shouldDeleteContent: true),
                                      ),
                                    ],
                                  )
                                else if (task.status == DownloadTaskStatus.complete)
                                  IconButton(
                                    icon: const Icon(WaveIcons.folder_open_24_regular),
                                    onPressed: () => FlutterDownloader.open(taskId: task.taskId),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (task.status == DownloadTaskStatus.running)
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                      color: colorScheme.brandPrimary,
                                      backgroundColor: colorScheme.brandPrimary.withValues(alpha: 0.1),
                                      value: (task.progress) <= 0 ? null : (task.progress / 100.0),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${task.progress}%', style: textTheme.small),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Text(task.status.toString(), style: textTheme.small),
                          ],
                        ),
                      ),
                    ),
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
