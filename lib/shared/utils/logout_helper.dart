import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/providers/auth_providers.dart';
import '../../features/dashboard/products/presentation/providers/selected_branch_provider.dart';
import 'ui_helpers.dart';

Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
  final theme = Theme.of(context);

  bool isLoggingOut = false;

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  Text('Logout', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Are you sure you want to logout?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoggingOut
                            ? null
                            : () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: isLoggingOut
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.logout),
                        label: Text(isLoggingOut ? 'Logging out...' : 'Logout'),
                        onPressed: isLoggingOut
                            ? null
                            : () async {
                          setState(() => isLoggingOut = true);
                          try {
                            // 🔑 Clear selected branch from SharedPreferences
                            await ref.read(selectedBranchIdProvider.notifier).clear();

                            await ref.read(authRepositoryProvider).signOut();
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop(true); // dismiss dialog
                            }
                          } catch (e) {
                            setState(() => isLoggingOut = false);
                            showErrorSnackBar(
                              context,
                              'Logout failed: $e',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
