import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/ui_helpers.dart';
import '../../data/providers/branch_provider.dart';
import '../../data/providers/user_provider.dart';
import '../widgets/assign_branch_dialog.dart';
import '../widgets/delete_user_dialog.dart';
import '../widgets/reset_password_dialog.dart';
import '../widgets/toggle_user_dialog.dart';

class UserDetailPanel extends ConsumerWidget {
  final String uid;

  const UserDetailPanel({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: Theme.of(context).colorScheme.onSurface,
      ),
    );

    final userAsync = ref.watch(userByIdProvider(uid));
    final branchNames = ref.watch(branchNamesProvider).maybeWhen(
      data: (map) => map,
      orElse: () => {},
    );

    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error loading user: $e'),
      ),
      data: (user) {
        if (user == null) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('User not found'),
          );
        }

        final branchName = branchNames[user.branchId] ?? '-';

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: theme.textTheme.titleLarge),
              Text(user.email, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text('Role: ${user.role}'),
              Text('Branch: $branchName'),
              Text('Status: ${user.disabled ? "Disabled" : "Active"}'),
              const SizedBox(height: 16),
              if (user.createdAt != null)
                Text(
                  'Created: ${formatTimestamp(user.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              if (user.lastLogin != null)
                Text(
                  'Last Login: ${formatTimestamp(user.lastLogin)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              const Divider(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Assign Branch'),
                    onPressed: user.role == 'owner'
                        ? null
                        : () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => AssignBranchDialog(user: user),
                      );
                      if (result == true) {
                        showSuccessSnackBar(context, 'Branch updated');
                      } else if (result == false) {
                        showErrorSnackBar(context, 'Failed to assign branch');
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.lock_reset),
                    label: const Text('Reset Password'),
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => ResetPasswordDialog(user: user),
                      );
                      if (result == true) {
                        showSuccessSnackBar(context, 'Reset email sent');
                      } else if (result == false) {
                        showErrorSnackBar(context, 'Failed to send reset email');
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(user.disabled ? Icons.toggle_off : Icons.toggle_on),
                    label: Text(user.disabled ? 'Enable' : 'Disable'),
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => ToggleUserStatusDialog(
                          userName: user.name,
                          currentStatus: user.disabled,
                          onToggle: () =>
                              ref.read(toggleUserStatusProvider(user.uid).future),
                        ),
                      );
                      if (result == true) {
                        showSuccessSnackBar(context, 'User status updated');
                      }
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => DeleteUserDialog(user: user),
                      );
                      if (result == true) {
                        showSuccessSnackBar(context, 'User deleted');
                        Navigator.of(context).pop(); // Close the panel
                      } else if (result == false) {
                        showErrorSnackBar(context, 'Failed to delete user');
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

String formatTimestamp(DateTime? timestamp) {
  if (timestamp == null) return '-';
  return DateFormat('MMM d, y • h:mm a').format(timestamp);
}