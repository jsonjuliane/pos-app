import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/ui_helpers.dart';
import '../../../auth/data/models/app_user.dart';
import '../../data/providers/branch_provider.dart';

class AssignBranchDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const AssignBranchDialog({super.key, required this.user});

  @override
  ConsumerState<AssignBranchDialog> createState() => _AssignBranchDialogState();
}

class _AssignBranchDialogState extends ConsumerState<AssignBranchDialog> {
  String? selectedBranchId;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    selectedBranchId = widget.user.branchId;
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(allBranchesProvider);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.swap_horiz),
          const SizedBox(width: 12),
          Text('Assign Branch', style: theme.textTheme.titleLarge),
        ],
      ),
      content: branchesAsync.when(
        loading:
            () => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
        error: (e, _) => Text('Error loading branches: $e'),
        data: (branches) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.name,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                widget.user.email,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              Text(
                widget.user.role,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: selectedBranchId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Select a Branch',
                  border: OutlineInputBorder(),
                ),
                items:
                    branches.map((branch) {
                      return DropdownMenuItem(
                        value: branch.id,
                        child: Text(branch.name),
                      );
                    }).toList(),
                onChanged:
                    isSaving
                        ? null
                        : (value) {
                          setState(() => selectedBranchId = value);
                        },
              ),
            ],
          );
        },
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon:
              isSaving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.check),
          label: Text(isSaving ? 'Saving...' : 'Save'),
          onPressed:
              isSaving
                  ? null
                  : () async {
                    if (selectedBranchId == null) {
                      showErrorSnackBar(context, 'Please select a branch');
                      return;
                    }

                    setState(() => isSaving = true);
                    try {
                      final userDoc = FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.user.uid);

                      await userDoc.update({'branchId': selectedBranchId});
                      if (context.mounted) Navigator.of(context).pop();
                      showSuccessSnackBar(
                        context,
                        'Branch assigned successfully',
                      );
                    } catch (e) {
                      showErrorSnackBar(context, 'Failed to assign branch: $e');
                    } finally {
                      if (mounted) setState(() => isSaving = false);
                    }
                  },
        ),
      ],
    );
  }
}
