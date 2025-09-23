import 'dart:developer';

import 'package:flutter/material.dart' show IconButton, MaterialPageRoute;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/download/providers/download_providers.dart';
import 'package:youtube_downloader/modules/history/ui/pages/history_page.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key});

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  final controller = ScrollController();
  final urlTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WaveScaffold(
        appBar: _buildAppBar(context),
        backgroundColor: colorScheme.surfacePrimary,
        body: _buildBody(context),
      ),
    );
  }

  _buildAppBar(BuildContext context) {
    return WaveAppBar(
      title: _buildLogo(context),
      centeredTitle: false,
      scrollController: controller,
      alwaysShowDivider: true,
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryPage())),
          icon: const Icon(WaveIcons.clock_arrow_download_24_regular),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  _buildLogo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.brandPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("YOUTUBE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        Text(
          "DOWNLOADER",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 16),
          WaveTextFormField(
            controller: urlTextController,
            title: 'Enter YouTube URL',
            hintText: 'https://www.youtube.com/watch?v=XYZabc',
          ),
          SizedBox(height: 16),
          WaveButton(
            text: 'Generate Video Content',
            onTap: () {
              ref.read(youtubeFormatsProvider.notifier).loadFormats(urlTextController.text);
              ref.read(youtubeInfoProvider.notifier).loadInfo(urlTextController.text);
            },
          ),
          SizedBox(height: 16),
          ref
              .watch(youtubeInfoProvider)
              .when(
                data: (video) {
                  if (video == null) return SizedBox.shrink();
                  return _buildVideoInfo(video);
                },
                error: (error, stackTrace) => Text(error.toString()),
                loading: () => Skeletonizer(enabled: true, child: _buildVideoInfo(null)),
              ),
          SizedBox(height: 16),
          ref
              .watch(youtubeFormatsProvider)
              .when(
                data: (formats) {
                  if (formats.isEmpty) return SizedBox.shrink();
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 16 / 9,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: formats.length,
                    itemBuilder: (context, index) {
                      final item = formats[index];
                      return WaveTappable(
                        onTap: () async {
                          final downloadsDir = await getDownloadsDirectory();
                          final video = ref.watch(youtubeInfoProvider).value;
                          final title = video?.title ?? "video";
                          final quality = item.qualityLabel;
                          final container = item.container.name;

                          final safeFileName = "${title}_$quality.$container".replaceAll(RegExp(r'[^\w\s.-]'), '_');

                          await FlutterDownloader.enqueue(
                            url: item.url.toString(),
                            headers: {},
                            savedDir: downloadsDir!.path,
                            fileName: safeFileName,
                            showNotification: true,
                            openFileFromNotification: true,
                          );
                          log((await FlutterDownloader.loadTasks())?.first.status.toString() ?? "");
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.outlineDivider),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  item.container.name,
                                  style: TextStyle(
                                    color: colorScheme.outlineDivider.withValues(alpha: 0.5),
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(item.qualityLabel, style: textTheme.h6),
                                    Text('${item.size.totalMegaBytes.round()} MB', style: textTheme.body),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: WaveCircularProgressIndicator()),
                error: (err, st) => Center(child: Text("Error: $err")),
              ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo(Video? video) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(video?.title ?? "Sample youtube video title", style: textTheme.h4),
        SizedBox(height: 8),
        RichText(
          text: TextSpan(
            text: "Uploaded by ",
            style: textTheme.small.copyWith(color: colorScheme.textSecondary),
            children: [
              TextSpan(
                text: video?.author ?? 'Someone',
                style: textTheme.small.copyWith(color: colorScheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              TextSpan(text: " on "),
              TextSpan(
                text: DateFormat("d MMMM y 'at' hh:mm a").format(video?.publishDate ?? DateTime.now()),
                style: textTheme.small.copyWith(color: colorScheme.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  "https://i3.ytimg.com/vi/${video?.id ?? 'pbIv3Wupgmw'}/maxresdefault.jpg",
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
