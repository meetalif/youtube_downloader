import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/common/providers/root_providers.dart';

class RootPage extends ConsumerWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(rootNavIndexProvider);
    return WaveScaffold(
      bottomNavigationBar: WaveNavigationBar(
        items: [
          WaveNavigationBarItem(label: 'Downloads', icon: WaveIcons.arrow_download_24_filled),
          WaveNavigationBarItem(label: 'History', icon: WaveIcons.history_24_filled),
        ],
        onSelected: (index) {
          ref.read(rootNavIndexProvider.notifier).changeIndex(index);
        },
        selectedIndex: index,
      ),
      body: index == 0 ? const Text('Downloads') : const Text('History'),
    );
  }
}
