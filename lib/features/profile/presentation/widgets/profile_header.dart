import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../community/application/community_provider.dart';
import '../../../community/community_theme.dart';
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

  Future<void> _editUsername(
    BuildContext context,
    WidgetRef ref,
    String currentUsername,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UsernameEditSheet(initialUsername: currentUsername),
    );
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
    final _ = context.locale;
    final profileAsync = ref.watch(userProfileProvider);
    final meAsync = ref.watch(meProvider);
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
            const SizedBox(height: 4),
            // Инстаграм-стиль: уникальный @username
            meAsync.when(
              loading: () => const SizedBox(height: 20),
              error: (e, s) => const SizedBox.shrink(),
              data: (me) => GestureDetector(
                onTap: () => _editUsername(context, ref, me.username),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CommunityTheme.accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '@${me.username}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CommunityTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.edit,
                        size: 12,
                        color: CommunityTheme.accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
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

/// Модальное окно редактирования @username с валидацией как в Instagram.
class _UsernameEditSheet extends ConsumerStatefulWidget {
  const _UsernameEditSheet({required this.initialUsername});

  final String initialUsername;

  @override
  ConsumerState<_UsernameEditSheet> createState() => _UsernameEditSheetState();
}

class _UsernameEditSheetState extends ConsumerState<_UsernameEditSheet> {
  late final TextEditingController _controller;
  Timer? _debounce;
  bool _isChecking = false;
  bool _isSaving = false;
  bool? _isAvailable;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUsername);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final clean = value.trim().replaceAll('@', '').toLowerCase();

    if (clean == widget.initialUsername.toLowerCase()) {
      setState(() {
        _isChecking = false;
        _isAvailable = true;
        _errorMessage = null;
      });
      return;
    }

    if (clean.length < 3) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = 'profile.username_min_length'.tr();
      });
      return;
    }

    if (clean.length > 30) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = 'profile.username_max_length'.tr();
      });
      return;
    }

    final regex = RegExp(
      r'^(?!.*\.\.)(?!.*\.$)[a-z0-9_][a-z0-9_\.]{1,28}[a-z0-9_]$',
    );
    if (!regex.hasMatch(clean)) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _errorMessage = 'profile.username_allowed_chars'.tr();
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final available = await ref
            .read(communityControllerProvider)
            .checkUsernameAvailable(clean);

        if (mounted) {
          setState(() {
            _isChecking = false;
            _isAvailable = available;
            _errorMessage = available ? null : 'profile.username_taken'.tr();
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isChecking = false;
            _isAvailable = false;
            _errorMessage = 'profile.username_check_error'.tr();
          });
        }
      }
    });
  }

  Future<void> _save() async {
    final clean = _controller.text.trim().replaceAll('@', '').toLowerCase();
    if (_isAvailable != true || clean.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(communityControllerProvider).updateUsername(clean);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.username_changed'.tr(args: ['@$clean'])),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'profile.username_title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'profile.username_desc'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixText: '@',
              prefixStyle: const TextStyle(
                color: CommunityTheme.accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              hintText: 'profile.username_hint'.tr(),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? Colors.redAccent
                      : _isAvailable == true
                      ? const Color(0xFF22C55E)
                      : Colors.white12,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? Colors.redAccent
                      : _isAvailable == true
                      ? const Color(0xFF22C55E)
                      : Colors.white12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _errorMessage != null
                      ? Colors.redAccent
                      : _isAvailable == true
                      ? const Color(0xFF22C55E)
                      : CommunityTheme.accentColor,
                  width: 1.5,
                ),
              ),
              suffixIcon: _isChecking
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : _isAvailable == true && _errorMessage == null
                  ? const Icon(
                      Icons.check_circle,
                      color: Color(0xFF22C55E),
                      size: 20,
                    )
                  : _errorMessage != null
                  ? const Icon(Icons.cancel, color: Colors.redAccent, size: 20)
                  : null,
            ),
            onChanged: _onChanged,
          ),
          const SizedBox(height: 10),
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            )
          else if (_isAvailable == true && _controller.text.trim().isNotEmpty)
            Text(
              'profile.username_available'.tr(),
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              'profile.username_requirements'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_isAvailable == true && !_isChecking && !_isSaving)
                ? _save
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: CommunityTheme.accentColor,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.black,
              disabledForegroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    'profile.save_username'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
