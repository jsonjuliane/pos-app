import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/user_management/data/providers/branch_provider.dart';
import '../../features/dashboard/products/presentation/providers/selected_branch_provider.dart';

/// Displays a dialog for selecting a branch. Only used by owner accounts.
class SelectBranchDialog extends ConsumerWidget {
  const SelectBranchDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(allBranchesProvider);

    return AlertDialog(
      title: const Text('Select a Branch'),
      content: branchesAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text('Error loading branches: $e'),
        data: (branches) {
          if (branches.isEmpty) {
            return const Text('No branches available.');
          }

          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];
                return ListTile(
                  title: Text(branch.name),
                  onTap: () {
                    ref.read(selectedBranchIdProvider.notifier).set(branch.id);
                    Navigator.of(context).pop(); // close the dialog
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
