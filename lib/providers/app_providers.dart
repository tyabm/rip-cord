import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_repository.dart';
import '../domain/models.dart';

final repositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository();
});

final appBootstrapProvider = FutureProvider<AppRepository>((ref) async {
  final repo = ref.watch(repositoryProvider);
  await repo.load();
  return repo;
});

/// Bump to force rebuilds after mutations.
final dataVersionProvider = StateProvider<int>((ref) => 0);

final settingsProvider = Provider<AppSettings>((ref) {
  ref.watch(dataVersionProvider);
  ref.watch(appBootstrapProvider);
  return ref.watch(repositoryProvider).settings;
});

final responsesProvider = Provider<List<CompetingResponse>>((ref) {
  ref.watch(dataVersionProvider);
  ref.watch(appBootstrapProvider);
  return ref.watch(repositoryProvider).responses;
});

final eventsProvider = Provider<List<ActivationEvent>>((ref) {
  ref.watch(dataVersionProvider);
  ref.watch(appBootstrapProvider);
  return ref.watch(repositoryProvider).events;
});

final summaryProvider = Provider<LogSummary>((ref) {
  ref.watch(dataVersionProvider);
  ref.watch(appBootstrapProvider);
  return ref.watch(repositoryProvider).buildSummary();
});

void notifyDataChanged(WidgetRef ref) {
  ref.read(dataVersionProvider.notifier).state++;
}

class ActiveSequence {
  ActiveSequence({
    required this.eventId,
    required this.response,
    required this.source,
    required this.startedAt,
    required this.targetDurationSec,
  });

  final String eventId;
  final CompetingResponse response;
  final ActivationSource source;
  final DateTime startedAt;
  final int targetDurationSec;
}

final activeSequenceProvider = StateProvider<ActiveSequence?>((ref) => null);
