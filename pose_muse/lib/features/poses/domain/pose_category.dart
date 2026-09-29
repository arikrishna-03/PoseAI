enum PoseCategory {
  all('All'),
  soloPortrait('Solo Portrait'),
  standing('Standing'),
  sitting('Sitting'),
  candid('Candid'),
  couple('Couple'),
  group('Group (3+)');

  final String label;
  const PoseCategory(this.label);

  static PoseCategory fromString(String val) {
    for (final cat in PoseCategory.values) {
      if (cat.label.toLowerCase() == val.toLowerCase()) return cat;
    }
    return PoseCategory.soloPortrait;
  }
}
