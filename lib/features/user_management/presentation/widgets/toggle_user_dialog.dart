import 'package:flutter/material.dart';

/// A confirmation dialog for enabling/disabling a user.
///
/// This widget shows a confirmation message, executes the provided [onToggle]
/// callback, and returns `true` on success or `false` on failure.
/// Snackbars should be handled by the calling widget.
class ToggleUserStatusDialog extends StatefulWidget {
  final String userName;
  final bool currentStatus;
  final Future<void> Function() onToggle;

  const ToggleUserStatusDialog({
    super.key,
    required this.userName,
    required this.currentStatus,
    required this.onToggle,
  });

  @override
  State<ToggleUserStatusDialog> createState() => _ToggleUserStatusDialogState();
}

class _ToggleUserStatusDialogState extends State<ToggleUserStatusDialog> {
  bool isProcessing = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = widget.currentStatus ? 'Enable' : 'Disable';

    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.currentStatus ? Icons.toggle_on : Icons.toggle_off),
          const SizedBox(width: 12),
          Text('$action User', style: theme.textTheme.titleLarge),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to $action this user?',
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
                widget.userName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This action will restrict this user from logging in or performing any actions in the system.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              isProcessing ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              isProcessing
                  ? null
                  : () async {
                    setState(() {
                      isProcessing = true;
                      errorMessage = null;
                    });

                    try {
                      await widget.onToggle();
                      if (context.mounted)
                        Navigator.of(context).pop(true); // success
                    } catch (e) {
                      setState(
                        () => errorMessage = 'Failed to update status: $e',
                      );
                    } finally {
                      setState(() => isProcessing = false);
                    }
                  },
          style: ElevatedButton.styleFrom(
            foregroundColor: theme.colorScheme.onPrimary,
            backgroundColor: theme.colorScheme.primary,
          ),
          child:
              isProcessing
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(action),
        ),
      ],
    );
  }
}
