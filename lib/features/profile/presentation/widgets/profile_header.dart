import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../feed/data/photo_service.dart';
import '../../application/profile_provider.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  Future<void> _pickAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final savedPath = await PhotoService.savePhoto(File(picked.path));
    await ref
        .read(profileControllerProvider)
        .updateProfile(avatarPath: savedPath);
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text('profile.name'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await ref.read(profileControllerProvider).updateProfile(name: newName);
    }
  }

  Future<void> _editMission(
    BuildContext context,
    WidgetRef ref,
    String currentMission,
  ) async {
    final controller = TextEditingController(text: currentMission);
    final newMission = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text('profile.mission_title'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'profile.mission_hint'.tr(),
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );

    if (newMission != null) {
      await ref
          .read(profileControllerProvider)
          .updateProfile(missionStatement: newMission);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final streakAsync = ref.watch(overallStreakProvider);
    final streak = streakAsync.valueOrNull ?? 0;

    return profileAsync.when(
      data: (profile) {
        return Column(
          children: [
            GestureDetector(
              onTap: () => _pickAvatar(context, ref),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFF1F1F1F),
                backgroundImage: profile.avatarPath != null
                    ? FileImage(File(profile.avatarPath!))
                    : null,
                child: profile.avatarPath == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white38)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _editName(context, ref, profile.name),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (streak > 0) ...[
                    const SizedBox(width: 8),
                    const Text('🔥', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 2),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, size: 14, color: Colors.white38),
                ],
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () =>
                  _editMission(context, ref, profile.missionStatement ?? ''),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  (profile.missionStatement ?? '').isEmpty
                      ? 'profile.add_mission'.tr()
                      : profile.missionStatement!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: (profile.missionStatement ?? '').isEmpty
                        ? Colors.white38
                        : Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (e, _) => Text('${"common.error".tr()}: $e'),
    );
  }
}
