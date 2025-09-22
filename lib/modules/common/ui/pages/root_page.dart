import 'package:flutter/widgets.dart';
import 'package:waveui/waveui.dart';

class RootPage extends StatelessWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WaveScaffold(
      bottomNavigationBar: WaveNavigationBar(
        items: [
          WaveNavigationBarItem(label: 'Downloads', icon: WaveIcons.arrow_download_24_filled),
          WaveNavigationBarItem(label: 'History', icon: WaveIcons.history_24_filled),
        ],
        onSelected: (index) {},
        selectedIndex: 0,
      ),
    );
  }
}
