/// The legacy API sends the same timeline for every catalogue service.
/// Only explicit catalogue aliases can narrow that timeline. Unknown services
/// retain the server's phases; IDs are never used to guess a service.
class LaundryWorkflow {
  const LaundryWorkflow({
    required this.washing,
    required this.ironing,
    required this.known,
  });
  final bool washing, ironing, known;
  factory LaundryWorkflow.fromNames(Iterable<String> names) {
    if (names.isEmpty) {
      return const LaundryWorkflow(washing: true, ironing: true, known: false);
    }
    var washing = false;
    var ironing = false;
    for (final raw in names) {
      final name = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (const {
        'cuci reguler',
        'cuci regular',
        'cuci kering',
        'cuci kilat',
        'cuci tanpa setrika',
      }.contains(name)) {
        washing = true;
      } else if (RegExp(r'\bsetrika\b').hasMatch(name) &&
          !RegExp(r'\b(tanpa|tidak|no)\b').hasMatch(name)) {
        ironing = true;
        washing = washing || RegExp(r'\bcuci\b').hasMatch(name);
      } else {
        return const LaundryWorkflow(
          washing: true,
          ironing: true,
          known: false,
        );
      }
    }
    return LaundryWorkflow(washing: washing, ironing: ironing, known: true);
  }
  List<String> get stages => [
    'menunggu',
    if (washing) 'proses',
    if (ironing) 'setrika',
    'selesai',
    'diambil',
  ];
  String customerStage(String raw) {
    if (!known) return raw;
    if (raw == 'setrika' && !ironing) return 'proses';
    if (raw == 'proses' && !washing) return 'setrika';
    return raw;
  }

  /// Summary endpoints on older servers don't carry service names. Keep those
  /// summaries generic rather than promising an ironing/washing step.
  List<String> get summaryStages => known
      ? stages.where((s) => s != 'diambil').toList()
      : const ['menunggu', 'proses', 'selesai'];
}
