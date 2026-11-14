enum ActivationOutcome { completed, aborted, incomplete }

enum ActivationSource { fab, tile, widget, deepLink }

enum AppThemeMode { system, light, dark, highContrast, moreColors }

/// What opens after a successful pull, before Rip-Cord leaves.
/// [HandoffKind.none] just closes the app.
enum HandoffKind { none, walkTimer, music, call }

/// Default accent (calm green) when no custom color is stored.
const int defaultSeedColorArgb = 0xFF1B6B4A;

/// Keys written by builds that had a variable-ratio bonus and a 24h
/// bonus-prompt unlock. [AppSettings.fromJson] ignores them so an existing
/// `app_settings_v1` blob cannot crash on upgrade, and [AppSettings.toJson]
/// does not write them back.
const List<String> legacyAppSettingsKeys = [
  'variableRatioEnabled',
  'variableRatioChance',
  'variableRatioBonus',
  'bonusUnlockThreshold',
  'bonusUnlockExpiresAt',
];

class CompetingResponse {
  CompetingResponse({
    required this.id,
    required this.phrase,
    this.actionPrompt,
    this.category,
    this.enabled = true,
    this.sortOrder = 0,
    this.weight = 1,
  });

  final String id;
  final String phrase;
  final String? actionPrompt;
  /// Optional group label (e.g. "Breathing", "Grounding"). Custom entries may omit it.
  final String? category;
  final bool enabled;
  final int sortOrder;
  final int weight;

  CompetingResponse copyWith({
    String? id,
    String? phrase,
    String? actionPrompt,
    bool clearActionPrompt = false,
    String? category,
    bool clearCategory = false,
    bool? enabled,
    int? sortOrder,
    int? weight,
  }) {
    return CompetingResponse(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      actionPrompt:
          clearActionPrompt ? null : (actionPrompt ?? this.actionPrompt),
      category: clearCategory ? null : (category ?? this.category),
      enabled: enabled ?? this.enabled,
      sortOrder: sortOrder ?? this.sortOrder,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phrase': phrase,
        'actionPrompt': actionPrompt,
        'category': category,
        'enabled': enabled,
        'sortOrder': sortOrder,
        'weight': weight,
      };

  factory CompetingResponse.fromJson(Map<String, dynamic> json) {
    return CompetingResponse(
      id: json['id'] as String,
      phrase: json['phrase'] as String,
      actionPrompt: json['actionPrompt'] as String?,
      category: json['category'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      weight: json['weight'] as int? ?? 1,
    );
  }
}

class ActivationEvent {
  ActivationEvent({
    required this.id,
    required this.startedAt,
    this.completedAt,
    required this.outcome,
    this.durationSec,
    this.responseId,
    this.responsePhrase,
    this.pointsAwarded = 0,
    this.bonusAwarded = 0,
    required this.source,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final ActivationOutcome outcome;
  final int? durationSec;
  final String? responseId;
  final String? responsePhrase;
  final int pointsAwarded;
  /// Kept so older logs still load. New completions store 0.
  final int bonusAwarded;
  final ActivationSource source;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'outcome': outcome.name,
        'durationSec': durationSec,
        'responseId': responseId,
        'responsePhrase': responsePhrase,
        'pointsAwarded': pointsAwarded,
        'bonusAwarded': bonusAwarded,
        'source': source.name,
      };

  factory ActivationEvent.fromJson(Map<String, dynamic> json) {
    final outcomeName = json['outcome'];
    final sourceName = json['source'];
    return ActivationEvent(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      outcome: outcomeName is String
          ? (ActivationOutcome.values.asNameMap()[outcomeName] ??
              ActivationOutcome.incomplete)
          : ActivationOutcome.incomplete,
      durationSec: json['durationSec'] as int?,
      responseId: json['responseId'] as String?,
      responsePhrase: json['responsePhrase'] as String?,
      pointsAwarded: json['pointsAwarded'] as int? ?? 0,
      bonusAwarded: json['bonusAwarded'] as int? ?? 0,
      source: sourceName is String
          ? (ActivationSource.values.asNameMap()[sourceName] ??
              ActivationSource.fab)
          : ActivationSource.fab,
    );
  }
}

class AppSettings {
  AppSettings({
    this.sequenceDurationSec = 25,
    this.basePoints = 10,
    this.streakWindowHours = 24,
    this.themeMode = AppThemeMode.system,
    this.grayscaleDuringSequence = false,
    this.ttsEnabled = false,
    this.currentPoints = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastSuccessAt,
    this.pendingSequenceId,
    this.responseLibraryVersion = 0,
    this.lastResponseId,
    this.customSeedColor = defaultSeedColorArgb,
    this.handoffKind = HandoffKind.none,
    this.walkTimerMinutes = 10,
    this.musicUri,
    this.trustedPersonName,
    this.trustedPersonPhone,
    this.drillIsDefaultPull = false,
  });

  final int sequenceDurationSec;
  final int basePoints;
  final int streakWindowHours;
  final AppThemeMode themeMode;
  final bool grayscaleDuringSequence;
  final bool ttsEnabled;
  final int currentPoints;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastSuccessAt;
  /// If set, a sequence was interrupted by process death.
  final String? pendingSequenceId;
  /// Bumped when built-in prompt library is upgraded on device.
  final int responseLibraryVersion;
  /// Last selected response id — used to reduce immediate repeats.
  final String? lastResponseId;
  /// ARGB seed for **MC (More Colors)** theme mode.
  final int customSeedColor;
  /// Optional real-world step launched when a pull finishes.
  final HandoffKind handoffKind;
  /// Length handed to the system Clock app when [handoffKind] is a walk.
  final int walkTimerMinutes;
  /// Playlist or music link opened when [handoffKind] is music.
  final String? musicUri;
  /// Typed by the user. Never read from the contacts database.
  final String? trustedPersonName;
  /// Typed by the user. Stays on this device.
  final String? trustedPersonPhone;
  /// When true, the Rip-Cord button and external entry points open the urge drill.
  final bool drillIsDefaultPull;

  AppSettings copyWith({
    int? sequenceDurationSec,
    int? basePoints,
    int? streakWindowHours,
    AppThemeMode? themeMode,
    bool? grayscaleDuringSequence,
    bool? ttsEnabled,
    int? currentPoints,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastSuccessAt,
    bool clearLastSuccessAt = false,
    String? pendingSequenceId,
    bool clearPendingSequenceId = false,
    int? responseLibraryVersion,
    String? lastResponseId,
    bool clearLastResponseId = false,
    int? customSeedColor,
    HandoffKind? handoffKind,
    int? walkTimerMinutes,
    String? musicUri,
    bool clearMusicUri = false,
    String? trustedPersonName,
    bool clearTrustedPersonName = false,
    String? trustedPersonPhone,
    bool clearTrustedPersonPhone = false,
    bool? drillIsDefaultPull,
  }) {
    return AppSettings(
      sequenceDurationSec: sequenceDurationSec ?? this.sequenceDurationSec,
      basePoints: basePoints ?? this.basePoints,
      streakWindowHours: streakWindowHours ?? this.streakWindowHours,
      themeMode: themeMode ?? this.themeMode,
      grayscaleDuringSequence:
          grayscaleDuringSequence ?? this.grayscaleDuringSequence,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      currentPoints: currentPoints ?? this.currentPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastSuccessAt:
          clearLastSuccessAt ? null : (lastSuccessAt ?? this.lastSuccessAt),
      pendingSequenceId: clearPendingSequenceId
          ? null
          : (pendingSequenceId ?? this.pendingSequenceId),
      responseLibraryVersion:
          responseLibraryVersion ?? this.responseLibraryVersion,
      lastResponseId: clearLastResponseId
          ? null
          : (lastResponseId ?? this.lastResponseId),
      customSeedColor: customSeedColor ?? this.customSeedColor,
      handoffKind: handoffKind ?? this.handoffKind,
      walkTimerMinutes: walkTimerMinutes ?? this.walkTimerMinutes,
      musicUri: clearMusicUri ? null : (musicUri ?? this.musicUri),
      trustedPersonName: clearTrustedPersonName
          ? null
          : (trustedPersonName ?? this.trustedPersonName),
      trustedPersonPhone: clearTrustedPersonPhone
          ? null
          : (trustedPersonPhone ?? this.trustedPersonPhone),
      drillIsDefaultPull: drillIsDefaultPull ?? this.drillIsDefaultPull,
    );
  }

  Map<String, dynamic> toJson() => {
        'sequenceDurationSec': sequenceDurationSec,
        'basePoints': basePoints,
        'streakWindowHours': streakWindowHours,
        'themeMode': themeMode.name,
        'grayscaleDuringSequence': grayscaleDuringSequence,
        'ttsEnabled': ttsEnabled,
        'currentPoints': currentPoints,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastSuccessAt': lastSuccessAt?.toIso8601String(),
        'pendingSequenceId': pendingSequenceId,
        'responseLibraryVersion': responseLibraryVersion,
        'lastResponseId': lastResponseId,
        'customSeedColor': customSeedColor,
        'handoffKind': handoffKind.name,
        'walkTimerMinutes': walkTimerMinutes,
        'musicUri': musicUri,
        'trustedPersonName': trustedPersonName,
        'trustedPersonPhone': trustedPersonPhone,
        'drillIsDefaultPull': drillIsDefaultPull,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // Legacy bonus / variable-ratio keys are intentionally unread.
    return AppSettings(
      sequenceDurationSec:
          _optInt(json['sequenceDurationSec'], 25).clamp(10, 45),
      basePoints: _optInt(json['basePoints'], 10).clamp(1, 999),
      streakWindowHours: _optInt(json['streakWindowHours'], 24).clamp(1, 168),
      themeMode: _optTheme(json['themeMode']),
      grayscaleDuringSequence:
          _optBool(json['grayscaleDuringSequence'], fallback: false),
      ttsEnabled: _optBool(json['ttsEnabled'], fallback: false),
      currentPoints: _optInt(json['currentPoints'], 0),
      currentStreak: _optInt(json['currentStreak'], 0),
      bestStreak: _optInt(json['bestStreak'], 0),
      lastSuccessAt: _optDate(json['lastSuccessAt']),
      pendingSequenceId: _optString(json['pendingSequenceId']),
      responseLibraryVersion: _optInt(json['responseLibraryVersion'], 0),
      lastResponseId: _optString(json['lastResponseId']),
      customSeedColor: _optInt(json['customSeedColor'], defaultSeedColorArgb),
      handoffKind: _optHandoff(json['handoffKind']),
      walkTimerMinutes: _optInt(json['walkTimerMinutes'], 10).clamp(1, 180),
      musicUri: _optString(json['musicUri']),
      trustedPersonName: _optString(json['trustedPersonName']),
      trustedPersonPhone: _optString(json['trustedPersonPhone']),
      drillIsDefaultPull:
          _optBool(json['drillIsDefaultPull'], fallback: false),
    );
  }
}

class ReinforcementResult {
  const ReinforcementResult({
    required this.basePoints,
    required this.newStreak,
    required this.bestStreak,
    required this.totalPoints,
  });

  final int basePoints;
  final int newStreak;
  final int bestStreak;
  final int totalPoints;

  int get pointsAwarded => basePoints;
}

class LogSummary {
  const LogSummary({
    required this.todayUses,
    required this.todaySuccesses,
    required this.weekUses,
    required this.weekSuccesses,
    required this.totalPoints,
    required this.currentStreak,
    required this.bestStreak,
    required this.longestFreePeriod,
  });

  final int todayUses;
  final int todaySuccesses;
  final int weekUses;
  final int weekSuccesses;
  final int totalPoints;
  final int currentStreak;
  final int bestStreak;
  final Duration? longestFreePeriod;

  double get todaySuccessRate =>
      todayUses == 0 ? 0 : todaySuccesses / todayUses;

  double get weekSuccessRate => weekUses == 0 ? 0 : weekSuccesses / weekUses;
}

int _optInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();
  return fallback;
}

bool _optBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  return fallback;
}

String? _optString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _optDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

AppThemeMode _optTheme(Object? value) {
  if (value is! String) return AppThemeMode.system;
  return AppThemeMode.values.asNameMap()[value] ?? AppThemeMode.system;
}

HandoffKind _optHandoff(Object? value) {
  if (value is! String) return HandoffKind.none;
  return HandoffKind.values.asNameMap()[value] ?? HandoffKind.none;
}
