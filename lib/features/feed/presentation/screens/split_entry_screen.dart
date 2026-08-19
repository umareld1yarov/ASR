import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_pill_button.dart';
import '../../../timer/domain/models/activity_entry.dart';

class SplitEntryResult {
  const SplitEntryResult({
    required this.splitAt,
    required this.firstName,
    required this.firstCategory,
    required this.secondName,
    required this.secondCategory,
  });

  final int splitAt;
  final String firstName;
  final ActivityCategory firstCategory;
  final String secondName;
  final ActivityCategory secondCategory;
}

class SplitEntryScreen extends StatefulWidget {
  const SplitEntryScreen({super.key, required this.entry});

  final ActivityEntry entry;

  @override
  State<SplitEntryScreen> createState() => _SplitEntryScreenState();
}

class _SplitEntryScreenState extends State<SplitEntryScreen> {
  static const _splitHelpSeenKey = 'split_entry_help_seen';

  late final TextEditingController _firstName;
  late final TextEditingController _secondName;
  late ActivityCategory _firstCategory;
  late ActivityCategory _secondCategory;
  late final List<int> _splitPoints;
  late int _selectedIndex;
  bool _submitted = false;
  bool _helpSeen = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.entry.name);
    _secondName = TextEditingController();
    _firstCategory = ActivityCategory.fromStorageKey(widget.entry.categoryKey);
    _secondCategory = _firstCategory;

    final firstMinute = ((widget.entry.startedAt + 59999) ~/ 60000) * 60000;
    final lastMinute = (widget.entry.endedAt ~/ 60000) * 60000;
    _splitPoints = [
      for (var value = firstMinute; value <= lastMinute; value += 60000)
        if (value - widget.entry.startedAt >= 60000 &&
            widget.entry.endedAt - value >= 60000)
          value,
    ];
    _selectedIndex = _splitPoints.isEmpty ? 0 : (_splitPoints.length - 1) ~/ 2;
    _loadHelpState();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _secondName.dispose();
    super.dispose();
  }

  int get _splitAt => _splitPoints[_selectedIndex];

  String _time(int millis) =>
      DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(millis));

  String _duration(int start, int end) =>
      formatDuration(((end - start) / 1000).floor());

  Future<void> _loadHelpState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _helpSeen = prefs.getBool(_splitHelpSeenKey) ?? false);
  }

  Future<void> _showSplitHelp() async {
    if (!_helpSeen) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_splitHelpSeenKey, true);
      if (mounted) setState(() => _helpSeen = true);
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      builder: (context) => const _SplitHelpSheet(),
    );
  }

  void _moveSplit(int minutes) {
    setState(() {
      _selectedIndex = (_selectedIndex + minutes).clamp(
        0,
        _splitPoints.length - 1,
      );
    });
  }

  Future<void> _pickExactTime() async {
    final current = DateTime.fromMillisecondsSinceEpoch(_splitAt);
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'feed.switch_moment'.tr(),
    );
    if (selected == null || !mounted) return;
    final candidate = DateTime(
      current.year,
      current.month,
      current.day,
      selected.hour,
      selected.minute,
    ).millisecondsSinceEpoch;
    final index = _splitPoints.indexOf(candidate);
    if (index < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('feed.split_time_invalid'.tr())));
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _pickCategory({required bool first}) async {
    final selected = await showModalBottomSheet<ActivityCategory>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'feed.choose_category'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ActivityCategory.values.map((category) {
                  return ActionChip(
                    avatar: Text(category.emoji),
                    label: Text(category.label),
                    backgroundColor: category.color.withValues(alpha: 0.16),
                    side: BorderSide(
                      color: category.color.withValues(alpha: 0.4),
                    ),
                    onPressed: () => Navigator.of(context).pop(category),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    setState(() {
      if (first) {
        _firstCategory = selected;
      } else {
        _secondCategory = selected;
      }
    });
  }

  void _save() {
    setState(() => _submitted = true);
    final first = _firstName.text.trim();
    final second = _secondName.text.trim();
    if (first.isEmpty || second.isEmpty) return;
    Navigator.of(context).pop(
      SplitEntryResult(
        splitAt: _splitAt,
        firstName: first,
        firstCategory: _firstCategory,
        secondName: second,
        secondCategory: _secondCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSplit = _splitPoints.isNotEmpty;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text('feed.split_title_short'.tr()),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextButton.icon(
                onPressed: _showSplitHelp,
                icon: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFACC15),
                ),
                label: _helpSeen
                    ? const SizedBox.shrink()
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 118),
                        child: Text(
                          'feed.split_help_button'.tr(),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: canSplit ? _buildEditor() : _buildTooShort(),
        ),
      ),
    );
  }

  Widget _buildTooShort() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'feed.split_too_short'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildEditor() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'feed.split_explanation'.tr(),
                  style: const TextStyle(color: Colors.white60, height: 1.4),
                ),
                const SizedBox(height: 20),
                _buildOriginalCard(),
                const SizedBox(height: 24),
                _buildTimeEditor(),
                const SizedBox(height: 24),
                _buildPartCard(
                  before: true,
                  controller: _firstName,
                  category: _firstCategory,
                ),
                const SizedBox(height: 12),
                _buildPartCard(
                  before: false,
                  controller: _secondName,
                  category: _secondCategory,
                ),
                const SizedBox(height: 24),
                _buildResultPreview(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: GlassPillButton(
            onTap: _save,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.call_split_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'feed.create_two_entries'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalCard() {
    final category = ActivityCategory.fromStorageKey(widget.entry.categoryKey);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'feed.currently_recorded'.tr().toUpperCase(),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${category.emoji} ${category.label} · ${widget.entry.name}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${_time(widget.entry.startedAt)} — ${_time(widget.entry.endedAt)} · '
            '${_duration(widget.entry.startedAt, widget.entry.endedAt)}',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'feed.when_switched'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _lockedTime(
              _time(widget.entry.startedAt),
              'feed.start_locked'.tr(),
            ),
            Column(
              children: [
                const Icon(Icons.call_split, color: Color(0xFF06B6D4)),
                Text(
                  _time(_splitAt),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            _lockedTime(_time(widget.entry.endedAt), 'feed.end_locked'.tr()),
          ],
        ),
        Slider(
          value: _selectedIndex.toDouble(),
          min: 0,
          max: (_splitPoints.length - 1).toDouble(),
          divisions: _splitPoints.length > 1 ? _splitPoints.length - 1 : null,
          label: _time(_splitAt),
          onChanged: _splitPoints.length > 1
              ? (value) => setState(() => _selectedIndex = value.round())
              : null,
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedIndex == 0 ? null : () => _moveSplit(-5),
                child: Text('feed.minus_five'.tr()),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _pickExactTime,
              child: Text(_time(_splitAt)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedIndex == _splitPoints.length - 1
                    ? null
                    : () => _moveSplit(5),
                child: Text('feed.plus_five'.tr()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _lockedTime(String time, String label) {
    return Column(
      children: [
        const Icon(Icons.lock_outline, color: Colors.white30, size: 15),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white30, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildPartCard({
    required bool before,
    required TextEditingController controller,
    required ActivityCategory category,
  }) {
    final start = before ? widget.entry.startedAt : _splitAt;
    final end = before ? _splitAt : widget.entry.endedAt;
    final empty = controller.text.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: category.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (before ? 'feed.before_switch' : 'feed.after_switch')
                .tr()
                .toUpperCase(),
            style: TextStyle(
              color: category.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_time(start)} — ${_time(end)} · ${_duration(start, end)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _pickCategory(first: before),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'feed.category_label'.tr(),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          category.label,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: before
                  ? 'feed.name_label'.tr()
                  : 'feed.after_name_hint'.tr(),
              errorText: _submitted && empty ? 'feed.name_required'.tr() : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPreview() {
    final firstName = _firstName.text.trim();
    final secondName = _secondName.text.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'feed.result_in_timeline'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _previewRow(
            _firstCategory,
            '${_time(widget.entry.startedAt)}–${_time(_splitAt)}',
            firstName.isEmpty ? '—' : firstName,
          ),
          const SizedBox(height: 8),
          _previewRow(
            _secondCategory,
            '${_time(_splitAt)}–${_time(widget.entry.endedAt)}',
            secondName.isEmpty ? '—' : secondName,
          ),
          const SizedBox(height: 12),
          Text(
            'feed.total_unchanged'.tr(
              args: [_duration(widget.entry.startedAt, widget.entry.endedAt)],
            ),
            style: const TextStyle(
              color: Color(0xFF67E8F9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(ActivityCategory category, String time, String name) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: Text(time, style: const TextStyle(color: Colors.white54)),
        ),
        Expanded(
          child: Text(
            '${category.label} · $name',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _SplitHelpSheet extends StatelessWidget {
  const _SplitHelpSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          52,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFACC15).withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFFACC15),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'feed.split_help_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'feed.split_help_intro'.tr(),
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 18),
            _exampleCard(),
            const SizedBox(height: 20),
            _HelpSection(
              title: 'feed.split_help_when_title'.tr(),
              lines: [
                'feed.split_help_when_1'.tr(),
                'feed.split_help_when_2'.tr(),
                'feed.split_help_when_3'.tr(),
              ],
            ),
            const SizedBox(height: 18),
            _HelpSection(
              title: 'feed.split_help_unchanged_title'.tr(),
              lines: [
                'feed.split_help_unchanged_1'.tr(),
                'feed.split_help_unchanged_2'.tr(),
                'feed.split_help_unchanged_3'.tr(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'feed.split_help_only_distribution'.tr(),
              style: const TextStyle(
                color: Color(0xFF67E8F9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _HelpSection(
              title: 'feed.split_help_media_title'.tr(),
              lines: ['feed.split_help_media_body'.tr()],
            ),
            const SizedBox(height: 22),
            GlassPillButton(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'common.got_it'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exampleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'feed.split_help_before'.tr(),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            'feed.split_help_example_original'.tr(),
            style: const TextStyle(color: Colors.white),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Icon(Icons.arrow_downward, color: Colors.white30, size: 18),
          ),
          Text(
            'feed.split_help_after'.tr(),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'feed.split_help_example_first'.tr(),
            style: const TextStyle(color: Color(0xFFEC4899)),
          ),
          const SizedBox(height: 3),
          Text(
            'feed.split_help_example_second'.tr(),
            style: const TextStyle(color: Color(0xFF22C55E)),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: CircleAvatar(
                    radius: 2,
                    backgroundColor: Colors.white38,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(color: Colors.white60, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
