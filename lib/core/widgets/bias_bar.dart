import 'package:flutter/material.dart';

import '../../data/models/source.dart';

/// Boje i piktogrami po odnosu izvora prema vlasti. Boje nisu "dobro/loše":
/// samo razlikuju grupe.
Color leaningColor(Leaning l) => switch (l) {
  Leaning.critical => const Color(0xFF2F6F8F),
  Leaning.mixed => const Color(0xFFA7A3A5),
  Leaning.proGovernment => const Color(0xFFB83B52),
  Leaning.unknown => const Color(0xFFE2DEDF),
};

IconData leaningIcon(Leaning l) => switch (l) {
  Leaning.critical => Icons.visibility_outlined,
  Leaning.mixed => Icons.compare_arrows,
  Leaning.proGovernment => Icons.account_balance_outlined,
  Leaning.unknown => Icons.help_outline,
};

/// Traka sa udelima izvora po orijentaciji (kao "bias bar" na Ground News).
class BiasBar extends StatelessWidget {
  const BiasBar({
    super.key,
    required this.sources,
    this.height = 8,
    this.showLegend = false,
  });

  final List<Source> sources;
  final double height;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final counts = <Leaning, int>{};
    for (final s in sources) {
      counts[s.leaning] = (counts[s.leaning] ?? 0) + 1;
    }
    final order = [
      Leaning.critical,
      Leaning.mixed,
      Leaning.unknown,
      Leaning.proGovernment,
    ].where(counts.containsKey).toList();
    if (order.isEmpty) return const SizedBox.shrink();

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (final l in order)
              Expanded(
                flex: counts[l]!,
                child: Container(
                  margin: const EdgeInsets.only(right: 1.5),
                  color: leaningColor(l),
                ),
              ),
          ],
        ),
      ),
    );
    if (!showLegend) return bar;

    final total = sources.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar,
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            for (final l in order)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    leaningIcon(l),
                    size: 14,
                    color: leaningColor(l) == const Color(0xFFE2DEDF)
                        ? Colors.grey
                        : leaningColor(l),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l.label} ${(counts[l]! * 100 / total).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
