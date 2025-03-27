import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/providers/auth_providers.dart';
import 'ui_helpers.dart';

Future<void> showLogoutDialog(BuildContext context, WidgetRef ref) async {
  final theme = Theme.of(context);

  final shouldLogout = await showDialog<bool>(
    context: context,
    builder:
        (dialogContext) => Dialog(
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
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
  );

  if (shouldLogout != true) return;

  // Show loader
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
  );

  try {
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loader
    context.goNamed('login');
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loader
    showErrorSnackBar(context, 'Logout failed: $e');
  }
}
