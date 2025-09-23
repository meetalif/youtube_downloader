import 'dart:ui';

import 'package:flutter/material.dart' show MaterialApp, Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waveui/waveui.dart';
import 'package:youtube_downloader/modules/download/ui/pages/download_page.dart';
import 'package:youtube_downloader/modules/common/providers/overlay_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  runApp(ProviderScope(child: const MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => WaveApp(
        theme: Theme(),
        child: Consumer(
          builder: (context, ref, _) {
            final overlay = ref.watch(overlayControllerProvider);
            return Stack(
              children: [
                child!,
                if (overlay.visible)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Positioned.fill(
                      child: ColoredBox(
                        color: const Color.fromARGB(90, 0, 0, 0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              WaveCircularProgressIndicator(color: Colors.white, backgroundColor: Colors.white30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      home: DownloadPage(),
    );
  }
}
