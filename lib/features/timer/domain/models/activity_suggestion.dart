/// A reusable activity name derived from the user's completed history.
class ActivitySuggestion {
  const ActivitySuggestion({
    required this.name,
    required this.usesCount,
    required this.lastUsedAt,
  });

  final String name;
  final int usesCount;
  final int lastUsedAt;
}
