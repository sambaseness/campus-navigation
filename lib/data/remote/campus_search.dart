import '../../domain/campus/campus_feature.dart';

class CampusSearch {
  const CampusSearch();

  List<CampusFeature> search(
    Iterable<CampusFeature> features,
    String query, {
    int limit = 12,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final scored = <_ScoredFeature>[];

    for (final feature in features) {
      if (!feature.selectable) continue;

      final text = feature.searchableText;
      final name = feature.name?.toLowerCase() ?? '';

      var score = 0;
      if (name == normalized) {
        score = 100;
      } else if (name.startsWith(normalized)) {
        score = 80;
      } else if (name.contains(normalized)) {
        score = 60;
      } else if (text.contains(normalized)) {
        score = 30;
      }

      if (score > 0) {
        scored.add(_ScoredFeature(feature, score));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;

      return (a.feature.name ?? '').compareTo(b.feature.name ?? '');
    });

    return scored
        .take(limit)
        .map((item) => item.feature)
        .toList(growable: false);
  }
}

class _ScoredFeature {
  const _ScoredFeature(this.feature, this.score);

  final CampusFeature feature;
  final int score;
}
