import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete this user?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 6),
              Text(
                widget.user.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This action cannot be undone. The user’s data may be permanently lost.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: isDeleting ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon:
              isDeleting
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
          onPressed:
              isDeleting
                  ? null
                  : () async {
                    setState(() => isDeleting = true);
                    try {
                      final repository = ref.read(userRepositoryProvider);
                      await repository.deleteUser(widget.user.uid);

                      if (context.mounted) {
                        Navigator.of(context).pop(true); // Notify success
                      }
                    } catch (_) {
                      if (context.mounted) {
                        Navigator.of(context).pop(false); // Notify failure
                      }
                    } finally {
                      if (mounted) setState(() => isDeleting = false);
                    }
                  },
        ),
      ],
    );
  }
}
