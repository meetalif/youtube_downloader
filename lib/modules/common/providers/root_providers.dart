import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'root_providers.g.dart';

@riverpod
class RootNavIndex extends _$RootNavIndex {
  @override
  int build() => 0;

  void changeIndex(int index) => state = index;
}
