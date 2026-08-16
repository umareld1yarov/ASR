import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_background.dart';
import '../screens/settings_screen.dart';
import '../widgets/goals_preview_section.dart';
import '../widgets/memory_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/teaser_tiles_row.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const ProfileHeader(),
                    const SizedBox(height: 24),
                    const GoalsPreviewSection(),
                    const SizedBox(height: 20),
                    const TeaserTilesRow(),
                    const SizedBox(height: 20),
                    const MemoryCard(),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
