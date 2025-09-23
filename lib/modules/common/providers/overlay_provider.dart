import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'overlay_provider.g.dart';

@riverpod
class OverlayController extends _$OverlayController {
  @override
  ({bool visible, String? message}) build() {
    return (visible: false, message: null);
  }

  void show([String? message]) {
    state = (visible: true, message: message);
  }

  void hide() {
    Future.delayed(const Duration(seconds: 2), () {
      state = (visible: false, message: null);
    });
  }
}
