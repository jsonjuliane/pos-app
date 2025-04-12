import 'package:flutter/material.dart';

/// A reusable confirmation dialog for deleting items.
/// Returns `true` on successful delete, `false` on failure, `null` on cancel.
class ConfirmDeleteDialog extends StatefulWidget {
  final String title; // e.g., "Delete Product"
  final String message; // e.g., "Are you sure you want to delete this product?"
  final Future<void> Function() onConfirm;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  bool isDeleting = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.delete, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(widget.title, style: theme.textTheme.titleLarge),
          ),
        ],
      ),
      content: Text(widget.message),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: isDeleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          icon: isDeleting
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.delete),
          label: Text(isDeleting ? 'Deleting...' : 'Delete'),
          onPressed: isDeleting
              ? null
              : () async {
            setState(() {
              isDeleting = true;
              errorMessage = null;
            });

            try {
              await widget.onConfirm();
              if (context.mounted) Navigator.of(context).pop(true);
            } catch (e) {
              setState(() {
                errorMessage = 'Failed to delete: $e';
              });
            } finally {
              if (mounted) setState(() => isDeleting = false);
            }
          },
        ),
      ],
    );
  }
}