import 'package:flutter/material.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')), // 👈 Add const here
      body: const Center(child: Text('👤 User Management Page')),
    );
  }
}
