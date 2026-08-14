enum ActivationOutcome { completed, aborted, incomplete }

enum ActivationSource { fab, tile, widget, deepLink }

enum AppThemeMode { system, light, dark, highContrast, moreColors }

/// Default accent (calm green) when no custom color is stored.
const int defaultSeedColorArgb = 0xFF1B6B4A;

class CompetingResponse {
  CompetingResponse({
    required this.id,
    required this.phrase,
    this.actionPrompt,
    this.category,
    this.enabled = true,
    this.sortOrder = 0,
    this.weight = 1,
    this.requiresBonusUnlock = false,
  });

  final String id;
  final String phrase;
  final String? actionPrompt;
  /// Optional group label (e.g. "Breathing", "Grounding"). Custom entries may omit it.
  final String? category;
  final bool enabled;
  final int sortOrder;
  final int weight;
  /// Only enters rotation while a bonus unlock window is active.
  final bool requiresBonusUnlock;

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
    bool? requiresBonusUnlock,
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
      requiresBonusUnlock: requiresBonusUnlock ?? this.requiresBonusUnlock,
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
        'requiresBonusUnlock': requiresBonusUnlock,
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
      requiresBonusUnlock: json['requiresBonusUnlock'] as bool? ??
          (json['id'] as String?)?.startsWith('seed_bonus_') == true,
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
    return ActivationEvent(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      outcome: ActivationOutcome.values.byName(json['outcome'] as String),
      durationSec: json['durationSec'] as int?,
      responseId: json['responseId'] as String?,
      responsePhrase: json['responsePhrase'] as String?,
      pointsAwarded: json['pointsAwarded'] as int? ?? 0,
      bonusAwarded: json['bonusAwarded'] as int? ?? 0,
      source: ActivationSource.values.byName(
        (json['source'] as String?) ?? ActivationSource.fab.name,
      ),
    );
  }
}

class AppSettings {
  AppSettings({
    this.sequenceDurationSec = 25,
    this.basePoints = 10,
    this.variableRatioEnabled = true,
    this.variableRatioChance = 0.2,
    this.variableRatioBonus = 15,
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
    this.bonusUnlockThreshold = 150,
    this.bonusUnlockExpiresAt,
    this.customSeedColor = defaultSeedColorArgb,
  });

  final int sequenceDurationSec;
  final int basePoints;
  final bool variableRatioEnabled;
  final double variableRatioChance;
  final int variableRatioBonus;
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
  /// Points earned in rolling 24h needed to unlock bonus categories.
  final int bonusUnlockThreshold;
  /// When set and in the future, bonus prompts are in rotation.
  final DateTime? bonusUnlockExpiresAt;
  /// ARGB seed for **MC (More Colors)** theme mode.
  final int customSeedColor;

  bool isBonusUnlockActive([DateTime? now]) {
    final n = now ?? DateTime.now();
    final exp = bonusUnlockExpiresAt;
    return exp != null && exp.isAfter(n);
  }

  AppSettings copyWith({
    int? sequenceDurationSec,
    int? basePoints,
    bool? variableRatioEnabled,
    double? variableRatioChance,
    int? variableRatioBonus,
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
    int? bonusUnlockThreshold,
    DateTime? bonusUnlockExpiresAt,
    bool clearBonusUnlockExpiresAt = false,
    int? customSeedColor,
  }) {
    return AppSettings(
      sequenceDurationSec: sequenceDurationSec ?? this.sequenceDurationSec,
      basePoints: basePoints ?? this.basePoints,
      variableRatioEnabled: variableRatioEnabled ?? this.variableRatioEnabled,
      variableRatioChance: variableRatioChance ?? this.variableRatioChance,
      variableRatioBonus: variableRatioBonus ?? this.variableRatioBonus,
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
      bonusUnlockThreshold: bonusUnlockThreshold ?? this.bonusUnlockThreshold,
      bonusUnlockExpiresAt: clearBonusUnlockExpiresAt
          ? null
          : (bonusUnlockExpiresAt ?? this.bonusUnlockExpiresAt),
      customSeedColor: customSeedColor ?? this.customSeedColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'sequenceDurationSec': sequenceDurationSec,
        'basePoints': basePoints,
        'variableRatioEnabled': variableRatioEnabled,
        'variableRatioChance': variableRatioChance,
        'variableRatioBonus': variableRatioBonus,
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
        'bonusUnlockThreshold': bonusUnlockThreshold,
        'bonusUnlockExpiresAt': bonusUnlockExpiresAt?.toIso8601String(),
        'customSeedColor': customSeedColor,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      sequenceDurationSec: json['sequenceDurationSec'] as int? ?? 25,
      basePoints: json['basePoints'] as int? ?? 10,
      variableRatioEnabled: json['variableRatioEnabled'] as bool? ?? true,
      variableRatioChance:
          (json['variableRatioChance'] as num?)?.toDouble() ?? 0.2,
      variableRatioBonus: json['variableRatioBonus'] as int? ?? 15,
      streakWindowHours: json['streakWindowHours'] as int? ?? 24,
      themeMode: AppThemeMode.values.byName(
        (json['themeMode'] as String?) ?? AppThemeMode.system.name,
      ),
      grayscaleDuringSequence:
          json['grayscaleDuringSequence'] as bool? ?? false,
      ttsEnabled: json['ttsEnabled'] as bool? ?? false,
      currentPoints: json['currentPoints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastSuccessAt: json['lastSuccessAt'] != null
          ? DateTime.parse(json['lastSuccessAt'] as String)
          : null,
      pendingSequenceId: json['pendingSequenceId'] as String?,
      responseLibraryVersion: json['responseLibraryVersion'] as int? ?? 0,
      lastResponseId: json['lastResponseId'] as String?,
      bonusUnlockThreshold: json['bonusUnlockThreshold'] as int? ?? 150,
      bonusUnlockExpiresAt: json['bonusUnlockExpiresAt'] != null
          ? DateTime.parse(json['bonusUnlockExpiresAt'] as String)
          : null,
      customSeedColor: json['customSeedColor'] as int? ?? defaultSeedColorArgb,
    );
  }
}

class ReinforcementResult {
  const ReinforcementResult({
    required this.basePoints,
    required this.bonusPoints,
    required this.newStreak,
    required this.bestStreak,
    required this.totalPoints,
    this.justUnlockedBonus = false,
  });

  final int basePoints;
  final int bonusPoints;
  final int newStreak;
  final int bestStreak;
  final int totalPoints;
  /// True when this completion newly opened the 24h bonus-prompt window.
  final bool justUnlockedBonus;

  int get pointsAwarded => basePoints + bonusPoints;
  bool get hadBonus => bonusPoints > 0;

  ReinforcementResult copyWith({bool? justUnlockedBonus}) {
    return ReinforcementResult(
      basePoints: basePoints,
      bonusPoints: bonusPoints,
      newStreak: newStreak,
      bestStreak: bestStreak,
      totalPoints: totalPoints,
      justUnlockedBonus: justUnlockedBonus ?? this.justUnlockedBonus,
    );
  }
}

/// Snapshot for Home / Settings bonus unlock UI.
class BonusUnlockStatus {
  const BonusUnlockStatus({
    required this.pointsLast24h,
    required this.threshold,
    required this.active,
    this.expiresAt,
  });

  final int pointsLast24h;
  final int threshold;
  final bool active;
  final DateTime? expiresAt;

  int get pointsTowardUnlock =>
      pointsLast24h > threshold ? threshold : pointsLast24h;
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
