import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/utils/ui_helpers.dart';
import '../../../auth/data/models/app_user.dart';

class SetTempPasswordDialog extends ConsumerStatefulWidget {
  final AppUser user;

  const SetTempPasswordDialog({super.key, required this.user});

  @override
  ConsumerState<SetTempPasswordDialog> createState() => _SetTempPasswordDialogState();
}

class _SetTempPasswordDialogState extends ConsumerState<SetTempPasswordDialog> {
  bool isSending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.email),
          const SizedBox(width: 12),
          Text('Send Reset Password Email', style: theme.textTheme.titleLarge),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${user.name} (${user.email})', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(
            'This will send a password reset link to the user’s email address. '
                'They will use it to create a new password securely.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: isSending
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.send),
          label: Text(isSending ? 'Sending...' : 'Send Email'),
          onPressed: isSending
              ? null
              : () async {
            setState(() => isSending = true);
            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email);
              if (context.mounted) {
                Navigator.of(context).pop();
                showSuccessSnackBar(context, 'Reset email sent to ${user.email}');
              }
            } catch (e) {
              showErrorSnackBar(context, 'Failed to send reset email: $e');
            } finally {
              if (mounted) setState(() => isSending = false);
            }
          },
        ),
      ],
    );
  }
}