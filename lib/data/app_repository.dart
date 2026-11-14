import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/free_period.dart';
import '../domain/models.dart';
import '../domain/reinforcement.dart';
import '../domain/urge_drill.dart';
import 'library_merge.dart';
import 'seed.dart';

const _settingsKey = 'app_settings_v1';
const _responsesFile = 'competing_responses.json';
const _eventsFile = 'activation_events.json';

class AppRepository {
  AppRepository({
    SharedPreferences? prefs,
    ReinforcementEngine? engine,
    Uuid? uuid,
    this.documentsDirectory,
  })  : _engine = engine ?? const ReinforcementEngine(),
        _uuid = uuid ?? const Uuid() {
    _prefsFuture = prefs != null
        ? Future.value(prefs)
        : SharedPreferences.getInstance();
  }

  final ReinforcementEngine _engine;
  final Uuid _uuid;
  final Directory? documentsDirectory;
  late final Future<SharedPreferences> _prefsFuture;

  Future<Directory> _docs() async {
    final override = documentsDirectory;
    if (override != null) return override;
    return getApplicationDocumentsDirectory();
  }

  List<CompetingResponse> _responses = [];
  List<ActivationEvent> _events = [];
  AppSettings _settings = AppSettings();
  bool _loaded = false;

  AppSettings get settings => _settings;
  List<CompetingResponse> get responses => List.unmodifiable(_responses);
  List<ActivationEvent> get events => List.unmodifiable(_events);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await _prefsFuture;
    final raw = prefs.getString(_settingsKey);
    if (raw != null) {
      _settings = AppSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }

    final dir = await _docs();
    final responsesPath = File('${dir.path}/$_responsesFile');
    final eventsPath = File('${dir.path}/$_eventsFile');

    final isFreshLibrary = !await responsesPath.exists();
    if (!isFreshLibrary) {
      final list = jsonDecode(await responsesPath.readAsString()) as List;
      _responses = list
          .map((e) => CompetingResponse.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } else {
      _responses = defaultCompetingResponses();
      await _persistResponses();
    }

    // Fresh installs already have the full library, including the former
    // bonus prompts. Older installs:
    // - below v3 were stuck on a short built-in set: replace seed rows, keep customs
    // - v3 already has (and may have edited) those prompts: merge missing ids only
    if (isFreshLibrary) {
      _settings = _settings.copyWith(
        responseLibraryVersion: currentResponseLibraryVersion,
      );
      await _persistSettings();
    } else if (_settings.responseLibraryVersion < currentResponseLibraryVersion) {
      if (_settings.responseLibraryVersion < 3) {
        await refreshBuiltInResponses();
      } else {
        _responses = mergeMissingResponses(
          _responses,
          defaultCompetingResponses(),
        );
        await _persistResponses();
      }
      _settings = _settings.copyWith(
        responseLibraryVersion: currentResponseLibraryVersion,
      );
      await _persistSettings();
    } else {
      await mergeMissingDefaultResponses();
    }

    if (await eventsPath.exists()) {
      final list = jsonDecode(await eventsPath.readAsString()) as List;
      _events = list
          .map((e) => ActivationEvent.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    }

    // Mark any interrupted in-progress sequence as incomplete.
    if (_settings.pendingSequenceId != null) {
      final id = _settings.pendingSequenceId!;
      final idx = _events.indexWhere((e) => e.id == id);
      if (idx >= 0 &&
          _events[idx].outcome != ActivationOutcome.completed &&
          _events[idx].outcome != ActivationOutcome.aborted) {
        final old = _events[idx];
        _events[idx] = ActivationEvent(
          id: old.id,
          startedAt: old.startedAt,
          completedAt: DateTime.now(),
          outcome: ActivationOutcome.incomplete,
          durationSec: DateTime.now().difference(old.startedAt).inSeconds,
          responseId: old.responseId,
          responsePhrase: old.responsePhrase,
          pointsAwarded: 0,
          bonusAwarded: 0,
          source: old.source,
        );
        await _persistEvents();
      }
      _settings = _settings.copyWith(clearPendingSequenceId: true);
      await _persistSettings();
    }

    _loaded = true;
  }

  Future<void> _persistSettings() async {
    final prefs = await _prefsFuture;
    await prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
  }

  Future<void> _persistResponses() async {
    final dir = await _docs();
    final file = File('${dir.path}/$_responsesFile');
    await file.writeAsString(
      jsonEncode(_responses.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _persistEvents() async {
    final dir = await _docs();
    final file = File('${dir.path}/$_eventsFile');
    await file.writeAsString(
      jsonEncode(_events.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> updateSettings(AppSettings next) async {
    _settings = next;
    await _persistSettings();
  }

  Future<void> saveResponse(CompetingResponse response) async {
    final idx = _responses.indexWhere((r) => r.id == response.id);
    if (idx >= 0) {
      _responses[idx] = response;
    } else {
      _responses.add(response);
    }
    _responses.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await _persistResponses();
  }

  Future<void> deleteResponse(String id) async {
    _responses.removeWhere((r) => r.id == id);
    await _persistResponses();
  }

  CompetingResponse createBlankResponse() {
    return CompetingResponse(
      id: _uuid.v4(),
      phrase: '',
      actionPrompt: '',
      category: 'Custom',
      enabled: true,
      sortOrder: _responses.length,
      weight: 1,
    );
  }

  /// Appends built-in seed responses whose IDs are not already present.
  /// Returns how many were added. Preserves user edits and custom items.
  Future<int> mergeMissingDefaultResponses() async {
    final before = _responses.length;
    final merged = mergeMissingResponses(
      _responses,
      defaultCompetingResponses(),
    );
    if (merged.length == before) return 0;
    _responses = merged;
    _responses.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await _persistResponses();
    return merged.length - before;
  }

  /// Phrases from the original 8-item first-run seed (random UUIDs).
  static const _legacyDefaultPhrases = {
    'This urge is a wave. I can ride it without checking.',
    'I choose presence over the scroll.',
    'Boredom is information, not an emergency.',
    'I already have what I need right now.',
    'Checking can wait. My attention is valuable.',
    'I interrupt the chain and free the next hour.',
    'Urges pass. Patterns change with practice.',
    'I am practicing control, not fighting myself.',
  };

  /// Replaces built-in (`seed_*`) entries with the current default library.
  /// Keeps user customs; drops legacy first-run UUID defaults.
  Future<int> refreshBuiltInResponses() async {
    final defaults = defaultCompetingResponses();
    final defaultIds = defaults.map((d) => d.id).toSet();

    final customs = _responses.where((r) {
      if (r.id.startsWith('seed_') || defaultIds.contains(r.id)) return false;
      if (_legacyDefaultPhrases.contains(r.phrase)) return false;
      return true;
    }).toList();

    var order = defaults.length;
    _responses = [
      ...defaults,
      for (final c in customs) c.copyWith(sortOrder: order++),
    ];
    await _persistResponses();
    return defaults.length;
  }

  /// Starts a sequence: logs activation and returns event + selected response.
  Future<({ActivationEvent event, CompetingResponse response})> startActivation({
    required ActivationSource source,
  }) async {
    final response = pickWeightedResponse(
          _responses,
          excludeId: _settings.lastResponseId,
        ) ??
        CompetingResponse(
          id: 'fallback',
          phrase: 'Pause. Breathe. You do not need to check right now.',
          actionPrompt: 'Take three deep breaths.',
        );

    _settings = _settings.copyWith(lastResponseId: response.id);
    await _persistSettings();

    final event = ActivationEvent(
      id: _uuid.v4(),
      startedAt: DateTime.now(),
      outcome: ActivationOutcome.incomplete,
      responseId: response.id,
      responsePhrase: response.phrase,
      source: source,
    );

    _events.insert(0, event);
    _settings = _settings.copyWith(pendingSequenceId: event.id);
    await _persistEvents();
    await _persistSettings();
    return (event: event, response: response);
  }

  Future<ReinforcementResult> completeActivation({
    required String eventId,
    required int durationSec,
  }) async {
    final result = _engine.complete(settings: _settings);
    final now = DateTime.now();
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      final old = _events[idx];
      _events[idx] = ActivationEvent(
        id: old.id,
        startedAt: old.startedAt,
        completedAt: now,
        outcome: ActivationOutcome.completed,
        durationSec: durationSec,
        responseId: old.responseId,
        responsePhrase: old.responsePhrase,
        pointsAwarded: result.pointsAwarded,
        bonusAwarded: 0,
        source: old.source,
      );
    }

    _settings = _settings.copyWith(
      currentPoints: result.totalPoints,
      currentStreak: result.newStreak,
      bestStreak: result.bestStreak,
      lastSuccessAt: now,
      clearPendingSequenceId: true,
    );

    await _persistEvents();
    await _persistSettings();
    return result;
  }

  /// Logs an urge drill without points, streak, or a reward.
  Future<ActivationEvent> startDrill({
    required ActivationSource source,
    required String urge,
    required DrillAction action,
  }) async {
    final event = ActivationEvent(
      id: _uuid.v4(),
      startedAt: DateTime.now(),
      outcome: ActivationOutcome.incomplete,
      responseId: 'drill_${action.id}',
      responsePhrase: drillLogPhrase(urge, action.label),
      pointsAwarded: 0,
      bonusAwarded: 0,
      source: source,
    );
    _events.insert(0, event);
    _settings = _settings.copyWith(pendingSequenceId: event.id);
    await _persistEvents();
    await _persistSettings();
    return event;
  }

  Future<void> completeDrill({
    required String eventId,
    required int durationSec,
  }) async {
    final now = DateTime.now();
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      final old = _events[idx];
      _events[idx] = ActivationEvent(
        id: old.id,
        startedAt: old.startedAt,
        completedAt: now,
        outcome: ActivationOutcome.completed,
        durationSec: durationSec,
        responseId: old.responseId,
        responsePhrase: old.responsePhrase,
        pointsAwarded: 0,
        bonusAwarded: 0,
        source: old.source,
      );
    }
    _settings = _settings.copyWith(clearPendingSequenceId: true);
    await _persistEvents();
    await _persistSettings();
  }

  Future<void> abortActivation({
    required String eventId,
    required int durationSec,
  }) async {
    final now = DateTime.now();
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx >= 0) {
      final old = _events[idx];
      _events[idx] = ActivationEvent(
        id: old.id,
        startedAt: old.startedAt,
        completedAt: now,
        outcome: ActivationOutcome.aborted,
        durationSec: durationSec,
        responseId: old.responseId,
        responsePhrase: old.responsePhrase,
        pointsAwarded: 0,
        bonusAwarded: 0,
        source: old.source,
      );
    }
    _settings = _settings.copyWith(clearPendingSequenceId: true);
    await _persistEvents();
    await _persistSettings();
  }

  LogSummary buildSummary() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    bool isToday(ActivationEvent e) => !e.startedAt.isBefore(startOfToday);
    bool isWeek(ActivationEvent e) => !e.startedAt.isBefore(startOfWeek);
    bool success(ActivationEvent e) =>
        e.outcome == ActivationOutcome.completed;

    final today = _events.where(isToday).toList();
    final week = _events.where(isWeek).toList();

    return LogSummary(
      todayUses: today.length,
      todaySuccesses: today.where(success).length,
      weekUses: week.length,
      weekSuccesses: week.where(success).length,
      totalPoints: _settings.currentPoints,
      currentStreak: _settings.currentStreak,
      bestStreak: _settings.bestStreak,
      longestFreePeriod: longestFreePeriod(_events, now: now),
    );
  }

  String exportCsv() {
    final buf = StringBuffer();
    buf.writeln(
      'id,started_at,completed_at,outcome,duration_sec,response_phrase,points,bonus,source',
    );
    for (final e in _events) {
      final phrase = (e.responsePhrase ?? '').replaceAll('"', '""');
      buf.writeln(
        [
          e.id,
          e.startedAt.toIso8601String(),
          e.completedAt?.toIso8601String() ?? '',
          e.outcome.name,
          e.durationSec?.toString() ?? '',
          '"$phrase"',
          e.pointsAwarded,
          e.bonusAwarded,
          e.source.name,
        ].join(','),
      );
    }
    return buf.toString();
  }

  Future<void> clearAll() async {
    _settings = AppSettings(
      responseLibraryVersion: currentResponseLibraryVersion,
    );
    _responses = defaultCompetingResponses();
    _events = [];
    await _persistSettings();
    await _persistResponses();
    await _persistEvents();
  }
}
