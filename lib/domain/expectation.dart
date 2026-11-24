/// What the user hoped the habit would get them, in their own one-tap words.
enum ExpectationKind { relief, escapeBoredom, checking, habit, other }

/// Chip label plus the phrase that fits "you expected ___".
class ExpectationOption {
  const ExpectationOption({
    required this.kind,
    required this.label,
    required this.expectedPhrase,
  });

  final ExpectationKind kind;
  final String label;
  final String expectedPhrase;
}

const expectationOptions = <ExpectationOption>[
  ExpectationOption(
    kind: ExpectationKind.relief,
    label: 'Relief',
    expectedPhrase: 'relief',
  ),
  ExpectationOption(
    kind: ExpectationKind.escapeBoredom,
    label: 'Escape boredom',
    expectedPhrase: 'to escape boredom',
  ),
  ExpectationOption(
    kind: ExpectationKind.checking,
    label: 'Checking something',
    expectedPhrase: 'to check something',
  ),
  ExpectationOption(
    kind: ExpectationKind.habit,
    label: 'Habit, no reason',
    expectedPhrase: 'a habit, no reason',
  ),
  ExpectationOption(
    kind: ExpectationKind.other,
    label: 'Other',
    expectedPhrase: 'something else',
  ),
];

const expectationPromptQuestion = 'What were you hoping this would get you?';

const expectationFraming = 'See if it was worth it';

const expectationScaleCaption = '1 did not deliver · 5 did';

/// Mirror appears once this many ratings exist for the chosen expectation.
const expectationMirrorMinimum = 3;

/// Mirror averages at most this many of the most recent ratings.
const expectationMirrorWindow = 6;

/// Optional local reminder. Off unless Settings turns it on.
const expectationNudgeDelay = Duration(hours: 2);

const expectationNudgeTitle = expectationFraming;

/// Closing-screen rating is only for the pull just finished.
const closingRatingWindow = Duration(minutes: 15);

String expectedPhrase(ExpectationKind kind) {
  for (final option in expectationOptions) {
    if (option.kind == kind) return option.expectedPhrase;
  }
  return expectationOptions.last.expectedPhrase;
}

String expectationLabel(ExpectationKind kind) {
  for (final option in expectationOptions) {
    if (option.kind == kind) return option.label;
  }
  return expectationOptions.last.label;
}

String outcomeRatingQuestion(ExpectationKind kind) {
  return 'Last time you expected ${expectedPhrase(kind)}. '
      'When you\'ve given in to that before, did it deliver?';
}

String expectationNudgeBody(ExpectationKind kind) {
  return 'You expected ${expectedPhrase(kind)}. '
      'Recall the urge, and rate whether giving in delivered.';
}

/// One recorded hope, and an optional later rating of whether giving in
/// delivered it. Stored only on the device.
class ExpectationCheck {
  ExpectationCheck({
    required this.id,
    required this.recordedAt,
    required this.expectation,
    this.activationEventId,
    this.rating,
    this.ratedAt,
    this.ratingAsked = false,
    this.nudgeScheduled = false,
  });

  final String id;
  final DateTime recordedAt;
  final ExpectationKind expectation;
  final String? activationEventId;

  /// 1–5. Null until the user rates.
  final int? rating;
  final DateTime? ratedAt;

  /// The one later ask was shown (or the user already rated).
  final bool ratingAsked;

  /// A single local reminder was handed to the OS for this check.
  final bool nudgeScheduled;

  bool get needsRatingAsk => rating == null && !ratingAsked;

  ExpectationCheck copyWith({
    String? activationEventId,
    bool clearActivationEventId = false,
    int? rating,
    DateTime? ratedAt,
    bool? ratingAsked,
    bool? nudgeScheduled,
  }) {
    return ExpectationCheck(
      id: id,
      recordedAt: recordedAt,
      expectation: expectation,
      activationEventId: clearActivationEventId
          ? null
          : (activationEventId ?? this.activationEventId),
      rating: rating ?? this.rating,
      ratedAt: ratedAt ?? this.ratedAt,
      ratingAsked: ratingAsked ?? this.ratingAsked,
      nudgeScheduled: nudgeScheduled ?? this.nudgeScheduled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordedAt': recordedAt.toIso8601String(),
    'expectation': expectation.name,
    'activationEventId': activationEventId,
    'rating': rating,
    'ratedAt': ratedAt?.toIso8601String(),
    'ratingAsked': ratingAsked,
    'nudgeScheduled': nudgeScheduled,
  };

  static ExpectationCheck? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final recordedRaw = json['recordedAt'];
    final kindName = json['expectation'];
    if (id is! String || id.isEmpty) return null;
    if (recordedRaw is! String) return null;
    final recordedAt = DateTime.tryParse(recordedRaw);
    if (recordedAt == null) return null;
    if (kindName is! String) return null;
    final kind = ExpectationKind.values.asNameMap()[kindName];
    if (kind == null) return null;

    final rating = _ratingOrNull(json['rating']);
    final ratedRaw = json['ratedAt'];
    final ratedAt = ratedRaw is String ? DateTime.tryParse(ratedRaw) : null;
    final eventId = json['activationEventId'];

    return ExpectationCheck(
      id: id,
      recordedAt: recordedAt,
      expectation: kind,
      activationEventId: eventId is String && eventId.trim().isNotEmpty
          ? eventId
          : null,
      rating: rating,
      ratedAt: rating == null ? null : ratedAt,
      ratingAsked: json['ratingAsked'] == true || rating != null,
      nudgeScheduled: json['nudgeScheduled'] == true,
    );
  }
}

int? _ratingOrNull(Object? value) {
  int? rating;
  if (value is int) {
    rating = value;
  } else if (value is num) {
    rating = value.round();
  }
  if (rating == null || rating < 1 || rating > 5) return null;
  return rating;
}

/// Newest hope that has not been rated and has not been asked about yet.
ExpectationCheck? pendingRatingAsk(List<ExpectationCheck> checks) {
  ExpectationCheck? newest;
  for (final check in checks) {
    if (!check.needsRatingAsk) continue;
    if (newest == null || check.recordedAt.isAfter(newest.recordedAt)) {
      newest = check;
    }
  }
  return newest;
}

/// Unrated hope from the pull that just finished, for the closing screen.
ExpectationCheck? closingScreenCheck(
  List<ExpectationCheck> checks, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  ExpectationCheck? newest;
  for (final check in checks) {
    if (!check.needsRatingAsk) continue;
    final age = clock.difference(check.recordedAt);
    if (age.isNegative || age > closingRatingWindow) continue;
    if (newest == null || check.recordedAt.isAfter(newest.recordedAt)) {
      newest = check;
    }
  }
  return newest;
}

/// Factual line from the user's own ratings, or null when there are fewer
/// than [expectationMirrorMinimum] for [kind].
String? expectationMirrorLine(
  ExpectationKind kind,
  List<ExpectationCheck> checks,
) {
  final rated =
      checks
          .where((check) => check.expectation == kind && check.rating != null)
          .toList()
        ..sort((a, b) {
          final byRated = (b.ratedAt ?? b.recordedAt).compareTo(
            a.ratedAt ?? a.recordedAt,
          );
          if (byRated != 0) return byRated;
          return b.recordedAt.compareTo(a.recordedAt);
        });
  if (rated.length < expectationMirrorMinimum) return null;
  final window = rated.take(expectationMirrorWindow).toList();
  final sum = window.fold<int>(0, (total, check) => total + check.rating!);
  final average = sum / window.length;
  final count = window.length;
  final times = count == 1 ? 'time' : 'times';
  return 'The last $count $times you expected ${expectedPhrase(kind)}, '
      'you rated it ${average.toStringAsFixed(1)} out of 5.';
}

/// Settings keys added with the expectation check. Older installs omit them
/// and load the defaults (check on, reminder off).
const List<String> expectationSettingsKeys = [
  'expectationCheckEnabled',
  'expectationNudgeEnabled',
];
