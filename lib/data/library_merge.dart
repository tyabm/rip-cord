import '../domain/models.dart';

/// Adds default prompts whose ids are not already stored.
///
/// Existing rows are returned unchanged, so edits to former bonus prompts
/// (`seed_bonus_*`) and to any other saved prompt are kept. Disabled prompts
/// stay disabled. Deleted ids are re-added only when they are missing, which
/// is how an older library gains the prompts that used to be locked.
List<CompetingResponse> mergeMissingResponses(
  List<CompetingResponse> existing,
  List<CompetingResponse> defaults,
) {
  if (defaults.isEmpty) return List<CompetingResponse>.from(existing);
  final existingIds = existing.map((r) => r.id).toSet();
  final missing = defaults.where((d) => !existingIds.contains(d.id)).toList();
  if (missing.isEmpty) return List<CompetingResponse>.from(existing);

  var order = 0;
  if (existing.isNotEmpty) {
    order = existing.map((r) => r.sortOrder).reduce((a, b) => a > b ? a : b) +
        1;
  }
  return [
    ...existing,
    for (final item in missing) item.copyWith(sortOrder: order++),
  ];
}
