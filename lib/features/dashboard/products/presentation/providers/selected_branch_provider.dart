import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs/selected_branch_prefs.dart';

final selectedBranchIdProvider =
StateNotifierProvider<SelectedBranchNotifier, String?>(
      (ref) => SelectedBranchNotifier(),
);

class SelectedBranchNotifier extends StateNotifier<String?> {
  SelectedBranchNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final loaded = await SelectedBranchPrefs.load();
    state = loaded;
  }

  Future<void> set(String branchId) async {
    state = branchId;
    await SelectedBranchPrefs.save(branchId);
  }

  Future<void> clear() async {
    state = null;
    await SelectedBranchPrefs.clear();
  }
}
