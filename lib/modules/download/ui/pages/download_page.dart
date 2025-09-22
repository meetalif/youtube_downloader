import 'dart:developer';

import 'package:flutter/material.dart' show IconButton, ListTile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/download/providers/download_providers.dart';

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
        IconButton(onPressed: () {}, icon: const Icon(WaveIcons.navigation_28_filled)),
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
            onTap: () => ref.read(youtubeFormatsProvider.notifier).loadFormats(urlTextController.text),
          ),
          SizedBox(height: 16),
          ref
              .watch(youtubeFormatsProvider)
              .when(
                data: (formats) {
                  if (formats.isEmpty) return const Center(child: Text("No formats"));
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: formats.length,
                    itemBuilder: (context, index) {
                      final item = formats[index];
                      final format = "${item.qualityLabel} | ${item.container.name}";
                      return ListTile(
                        title: Text(format),
                        onTap: () async {
                          final url = item.url.toString();
                          log(url);
                        },
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
}
