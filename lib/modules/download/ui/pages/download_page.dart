import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart' show IconButton, MaterialPageRoute;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/download/providers/download_providers.dart';
import 'package:youtube_downloader/modules/history/ui/pages/history_page.dart';
import 'package:youtube_downloader/utils/newpipe_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_downloader/modules/common/providers/overlay_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  // This runs in a background isolate; avoid interacting with UI directly.
  // For now, just log to the console. System notifications are handled by the plugin.
  log('Download update: id=$id status=$status progress=$progress%');
}

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key});

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  final controller = ScrollController();
  final urlTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Register to receive download progress notifications (system notifications handled by plugin)
    FlutterDownloader.registerCallback(downloadCallback);
    _ensurePermissions();
  }

  Future<void> _ensurePermissions() async {
    // Android 13+ notifications
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      await Permission.notification.request();
    }
    if (!await Permission.manageExternalStorage.request().isGranted) {
      await Permission.manageExternalStorage.request();
    }
    if (!await Permission.storage.request().isGranted) {
      await Permission.storage.request();
    }
  }

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
              FocusScope.of(context).unfocus();
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
                      childAspectRatio: 16 / 11,
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
                          // Resolve a robust downloads directory
                          var downloadsDir = Directory('/storage/emulated/0/Download');
                          final video = ref.watch(youtubeInfoProvider).value;
                          final title = video?.title ?? "video";
                          final quality = item.quality;
                          final container = item.fileExtension;

                          final safeFileName = "${title}_$quality.$container".replaceAll(RegExp(r'[^\w\s.-]'), '_');

                          // Show overlay and toast on start
                          ref.read(overlayControllerProvider.notifier).show('Starting download...');
                          Fluttertoast.showToast(msg: 'Download started');
                          await FlutterDownloader.enqueue(
                            url: item.url,
                            headers: {},
                            savedDir: downloadsDir.path,
                            fileName: safeFileName,
                            showNotification: true,
                            openFileFromNotification: true,
                          );
                          ref.read(overlayControllerProvider.notifier).hide();
                        },
                        child: _buildFormatItem(item),
                      );
                    },
                  );
                },
                loading: () => GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 16 / 11,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  itemBuilder: (context, index) => Skeletonizer(enabled: true, child: _buildFormatItem(null)),
                ),
                error: (err, st) => Center(child: Text("$err")),
              ),
        ],
      ),
    );
  }

  Widget _buildFormatItem(StreamItem? item) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineDivider),
      ),
      child: Stack(
        children: [
          if (item?.format != null)
            Center(
              child: Text(
                (item!.fileExtension.toUpperCase()),
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
                Text(item?.quality ?? "1234p", style: textTheme.h6),
                SizedBox(height: 4),
                Text(
                  item == null
                      ? 'Unknown'
                      : item.isAudioOnly
                      ? 'Audio Only'
                      : item.isVideoOnly
                      ? 'Video Only'
                      : 'Audio + Video',
                  style: textTheme.small,
                ),
                if (item?.sizeBytes != null) ...[
                  SizedBox(height: 2),
                  Text(_fmtSize(item!.sizeBytes!), style: textTheme.small),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(2)} KB';
    return '$bytes B';
  }

  Widget _buildVideoInfo(VideoInfo? video) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    DateTime? uploaded;
    if (video?.uploadDate.isNotEmpty == true) {
      uploaded = DateTime.tryParse(video!.uploadDate);
    }
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
                text: uploaded != null
                    ? DateFormat("d MMMM y 'at' hh:mm a").format(uploaded.toLocal())
                    : DateFormat("d MMMM y 'at' hh:mm a").format(DateTime.now()),
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
              Container(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    "https://i3.ytimg.com/vi/${video?.id ?? 'pbIv3Wupgmw'}/maxresdefault.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
