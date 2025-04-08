import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  Future<Map<String, String>> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return {
      'App Name': info.appName,
      'Package Name': info.packageName,
      'Version': info.version,
      'Build Number': info.buildNumber,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Information')),
      body: FutureBuilder<Map<String, String>>(
        future: _loadAppInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appInfo = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: appInfo.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                subtitle: Text(entry.value),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
