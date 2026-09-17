class GlideTestCandidate {
  GlideTestCandidate({required this.title, required this.skiIds, this.notes})
    : assert(skiIds.isNotEmpty);

  final String title;
  final String? notes;
  final List<int> skiIds;
}
