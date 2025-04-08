import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/app_user.dart';

/// A dialog that allows sending a password reset email to a user.
///
/// On success, returns `true`. On failure or cancel, returns `false`.
class ResetPasswordDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const ResetPasswordDialog({super.key, required this.user});

  @override
  ConsumerState<ResetPasswordDialog> createState() =>
      _SetTempPasswordDialogState();
}

class _SetTempPasswordDialogState extends ConsumerState<ResetPasswordDialog> {
  bool isSending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.email),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Reset Password Email',
              style: theme.textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(user.email, style: theme.textTheme.bodyMedium, softWrap: true),
          const SizedBox(height: 12),
          Text(
            'This will send a password reset link to the user’s email address.\n'
            'They will use it to create a new password securely.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: isSending ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon:
              isSending
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.send),
          label: Text(isSending ? 'Sending...' : 'Send Email'),
          onPressed:
              isSending
                  ? null
                  : () async {
                    setState(() => isSending = true);
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: user.email,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(true); // return success
                      }
                    } catch (_) {
                      if (context.mounted) {
                        Navigator.of(context).pop(false); // return failure
                      }
                    } finally {
                      if (mounted) setState(() => isSending = false);
                    }
                  },
        ),
      ],
    );
  }
}
