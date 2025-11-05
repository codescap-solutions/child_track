import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import '../../settings/view/settings_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppColors.surfaceColor,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsView()),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text('Home Page (UI Preview)', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
