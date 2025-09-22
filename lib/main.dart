import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/common/ui/pages/root_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => WaveApp(theme: Theme(), child: child!),
      home: RootPage(),
    );
  }
}
