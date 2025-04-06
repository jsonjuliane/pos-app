import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/user_management/data/providers/branch_provider.dart';

import '../../../../shared/utils/ui_helpers.dart';
import '../../../auth/data/models/app_user.dart';
import '../../data/providers/user_provider.dart';
import '../widgets/assign_branch_dialog.dart';
import '../widgets/delete_user_dialog.dart';
import '../widgets/set_temporary_password_dialog.dart';
import '../widgets/toggle_user_dialog.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          final isWide = MediaQuery.of(context).size.width >= 700;
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: _SearchAndFilterBar(),
              ),
              Expanded(
                child:
                    isWide
                        ? _UserDataTable(users: users)
                        : _UserListView(users: users),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search by email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // TODO: Apply search filter logic
            },
          ),
        ),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Role',
            border: OutlineInputBorder(),
          ),
          value: 'all',
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Roles')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
            DropdownMenuItem(value: 'staff', child: Text('Staff')),
          ],
          onChanged: (value) {
            // TODO: Apply role filter logic
          },
        ),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Branch',
            border: OutlineInputBorder(),
          ),
          value: 'all',
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Branches')),
            // TODO: Add actual branches here
          ],
          onChanged: (value) {
            // TODO: Apply branch filter logic
          },
        ),
      ],
    );
  }
}

class _UserListView extends StatelessWidget {
  final List<AppUser> users;

  const _UserListView({required this.users});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final user = users[index];

        return ListTile(
          title: Text(user.email),
          subtitle: Text('${user.role} • ${user.branchId ?? 'Unassigned'}'),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showUserActions(context, user),
          ),
        );
      },
    );
  }

  void _showUserActions(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _UserActionSheet(user: user),
    );
  }
}

class _UserDataTable extends ConsumerStatefulWidget {
  final List<AppUser> users;
  const _UserDataTable({required this.users});

  @override
  _UserDataTableState createState() => _UserDataTableState();
}

class _UserDataTableState extends ConsumerState<_UserDataTable> {
  // A map to store the toggling state for each user (by UID)
  Map<String, bool> _isTogglingMap = {};

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final branchNames = ref.watch(branchNamesProvider).maybeWhen(
      data: (map) => map,
      orElse: () => {},
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: widget.users.map((user) {
          final branchName = branchNames[user.branchId] ?? '-';
          bool isToggling = _isTogglingMap[user.uid] ?? false;

          return DataRow(cells: [
            DataCell(Text(user.name)),
            DataCell(Text(user.email)),
            DataCell(Text(user.role)),
            DataCell(Text(branchName)),
            DataCell(Text(user.disabled ? 'Disabled' : 'Active')),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Assign Branch',
                  onPressed: user.role == 'owner'
                      ? null
                      : () async {
                    final success = await showDialog<bool>(
                      context: context,
                      builder: (_) => AssignBranchDialog(user: user),
                    );

                    if (success == true) {
                      showSuccessSnackBar(context, 'Branch assigned successfully');
                    } else if (success == false) {
                      showErrorSnackBar(context, 'Failed to assign branch');
                    }
                  },
                  color: user.role == 'owner' ? Colors.grey : null,
                ),
                IconButton(
                  icon: const Icon(Icons.lock_reset),
                  tooltip: 'Set Temp Password',
                  onPressed: () async {
                    final success = await showDialog<bool>(
                      context: context,
                      builder: (_) => SetTempPasswordDialog(user: user),
                    );

                    if (success == true) {
                      showSuccessSnackBar(context, 'Reset email sent to ${user.email}');
                    } else if (success == false) {
                      showErrorSnackBar(context, 'Failed to send reset email.');
                    }
                  }
                ),
                IconButton(
                  icon: Icon(
                    user.disabled ? Icons.toggle_off : Icons.toggle_on,
                  ),
                  tooltip: user.disabled ? 'Enable' : 'Disable',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => ToggleUserStatusDialog(
                        userName: user.name,
                        currentStatus: user.disabled,
                        onToggle: () => ref.read(toggleUserStatusProvider(user.uid).future),
                      ),
                    );
  
                    if (confirmed == true) {
                      showSuccessSnackBar(
                        context,
                        user.disabled ? 'User enabled successfully' : 'User disabled successfully',
                      );
                    }
                  }
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => DeleteUserDialog(user: user),
                    );

                    if (confirmed == true) {
                      showSuccessSnackBar(context, 'User deleted successfully');
                    } else if (confirmed == false) {
                      showErrorSnackBar(context, 'Failed to delete user');
                    }
                  }
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}

class _UserActionSheet extends StatelessWidget {
  final AppUser user;

  const _UserActionSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          Text(user.email, style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Assign Branch'),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Set Temp Password'),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Disable/Enable'),
            onTap: () {
              // TODO
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Delete'),
            onTap: () {
              // TODO
            },
          ),
        ],
      ),
    );
  }
}
