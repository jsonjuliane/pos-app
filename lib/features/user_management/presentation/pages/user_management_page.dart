import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/features/user_management/data/providers/branch_provider.dart';

import '../../../../shared/utils/ui_helpers.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_user_providers.dart';
import '../../data/providers/user_provider.dart';
import '../providers/user_filter_provider.dart';
import '../utils/user_detail_view_helper.dart';
import '../widgets/assign_branch_dialog.dart';
import '../widgets/delete_user_dialog.dart';
import '../widgets/reset_password_dialog.dart';
import '../widgets/toggle_user_dialog.dart';
import '../widgets/user_status_chip.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authUserProvider).value;

    if (authUser == null ||
        !(authUser.role == 'admin' || authUser.role == 'owner')) {
      return const Center(child: Text('Access denied'));
    }

    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (users) {
        final searchQuery = ref.watch(userSearchQueryProvider).toLowerCase();
        final selectedRole = ref.watch(userRoleFilterProvider);
        final selectedBranch = ref.watch(userBranchFilterProvider);

        final filteredUsers =
            users.where((user) {
              final matchesSearch = user.email.toLowerCase().contains(
                searchQuery,
              );
              final matchesRole =
                  selectedRole == 'all' || user.role == selectedRole;
              final matchesBranch =
                  selectedBranch == 'all' || user.branchId == selectedBranch;
              return matchesSearch && matchesRole && matchesBranch;
            }).toList();

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
                      ? _UserDataTable(users: filteredUsers)
                      : _UserListView(users: filteredUsers),
            ),
          ],
        );
      },
    );
  }
}

class _SearchAndFilterBar extends ConsumerWidget {
  const _SearchAndFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(userRoleFilterProvider);
    final selectedBranch = ref.watch(userBranchFilterProvider);
    final branchesAsync = ref.watch(allBranchesProvider);

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
            onChanged:
                (value) =>
                    ref.read(userSearchQueryProvider.notifier).state = value,
          ),
        ),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Role',
            border: OutlineInputBorder(),
          ),
          value: selectedRole,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Roles')),
            DropdownMenuItem(value: 'admin', child: Text('Admin')),
            DropdownMenuItem(value: 'staff', child: Text('Staff')),
          ],
          onChanged:
              (value) =>
                  ref.read(userRoleFilterProvider.notifier).state =
                      value ?? 'all',
        ),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Branch',
            border: OutlineInputBorder(),
          ),
          value: selectedBranch,
          items: branchesAsync.when(
            loading:
                () => [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Loading...'),
                  ),
                ],
            error:
                (e, _) => [
                  DropdownMenuItem(value: 'all', child: Text('Error: $e')),
                ],
            data:
                (branches) => [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All Branches'),
                  ),
                  ...branches.map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ),
                ],
          ),
          onChanged:
              (value) =>
                  ref.read(userBranchFilterProvider.notifier).state =
                      value ?? 'all',
        ),
      ],
    );
  }
}

class _UserListView extends ConsumerWidget {
  final List<AppUser> users;

  const _UserListView({required this.users});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchNames = ref
        .watch(branchNamesProvider)
        .maybeWhen(data: (map) => map, orElse: () => {});

    return ListView.separated(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final user = users[index];
        final branchName = branchNames[user.branchId] ?? '-';

        return ListTile(
          leading: CircleAvatar(
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              UserStatusChip(isDisabled: user.disabled),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                '${user.role} • $branchName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => UserDetailViewHelper.show(context, user),
        );
      },
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
  int? _sortColumnIndex = 0; // 👈 Default to "Name" column
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();

    // Sort initially by name in ascending order
    widget.users.sort((a, b) => a.name.compareTo(b.name));
  }

  void _sortUsers(
    Comparable Function(AppUser user) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        // If same column is clicked again, toggle sort direction
        _isAscending = !_isAscending;
      } else {
        // New column sort, reset to ascending
        _sortColumnIndex = columnIndex;
        _isAscending = true;
      }

      widget.users.sort((a, b) {
        final aField = getField(a);
        final bField = getField(b);
        return _isAscending
            ? aField.compareTo(bField)
            : bField.compareTo(aField);
      });
    });
  }

  Widget _buildSortableLabel(String label, int columnIndex) {
    final isActive = _sortColumnIndex == columnIndex;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (isActive)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: AnimatedRotation(
              turns: _isAscending ? 0.0 : 0.5, // 0.5 = 180 degrees
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: const Icon(Icons.arrow_upward, size: 16),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchNames = ref
        .watch(branchNamesProvider)
        .maybeWhen(data: (map) => map, orElse: () => {});

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columnSpacing: 24,
        columns: [
          DataColumn(
            onSort: (index, _) => _sortUsers((u) => u.name, index, true),
            label: _buildSortableLabel('Name', 0),
          ),
          DataColumn(
            onSort: (index, _) => _sortUsers((u) => u.email, index, true),
            label: _buildSortableLabel('Email', 1),
          ),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('Status')),
          DataColumn(label: SizedBox.shrink()),
        ],
        rows: widget.users.map((user) {
          final branchName = branchNames[user.branchId] ?? '-';

          return DataRow(
            onSelectChanged: (_) => UserDetailViewHelper.show(context, user),
            cells: [
              DataCell(Text(user.name)),
              DataCell(Text(user.email)),
              DataCell(Text(user.role)),
              DataCell(Text(branchName)),
              DataCell(UserStatusChip(isDisabled: user.disabled)),
              DataCell(
                IconButton(
                  icon: Icon(
                    user.disabled ? Icons.toggle_off : Icons.toggle_on,
                  ),
                  tooltip: user.disabled ? 'Enable' : 'Disable',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (_) => ToggleUserStatusDialog(
                        userName: user.name,
                        currentStatus: user.disabled,
                        onToggle:
                            () => ref.read(
                          toggleUserStatusProvider(
                            user.uid,
                          ).future,
                        ),
                      ),
                    );
                    if (confirmed == true) {
                      showSuccessSnackBar(
                        context,
                        user.disabled
                            ? 'User enabled successfully'
                            : 'User disabled successfully',
                      );
                    }
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}