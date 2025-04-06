import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/ui_helpers.dart';
import '../../../auth/data/models/app_user.dart';
import '../../data/providers/user_provider.dart';

class DeleteUserDialog extends ConsumerStatefulWidget {
  /// The user to be deleted
  final AppUser user;

  const DeleteUserDialog({super.key, required this.user});

  @override
  ConsumerState<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends ConsumerState<DeleteUserDialog> {
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.delete_forever),
          const SizedBox(width: 12),
          Text('Delete User', style: theme.textTheme.titleLarge),
        ],
      ),
      content: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Are you sure you want to delete '),
            TextSpan(
              text: widget.user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '? This action cannot be undone.'),
          ],
        ),
        style: theme.textTheme.bodyMedium,
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: isDeleting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.delete),
          label: Text(isDeleting ? 'Deleting...' : 'Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: isDeleting
              ? null
              : () async {
            setState(() => isDeleting = true);
            try {
              final repository = ref.read(userRepositoryProvider);
              await repository.deleteUser(widget.user.uid);

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                showSuccessSnackBar(context, 'User deleted successfully');
              }
            } catch (e) {
              showErrorSnackBar(context, 'Failed to delete user: $e');
            } finally {
              if (mounted) setState(() => isDeleting = false);
            }
          },
        ),
      ],
    );
  }
}