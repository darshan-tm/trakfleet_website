import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';

/// Horizontal segmented progress bar with aligned top labels + legends below.
class BatteryProgressBar extends StatelessWidget {
  final List<int> counts; // [100–90, 90–60, 60–30, 30–0]
  final double height;
  final bool showLabels;

  const BatteryProgressBar({
    super.key,
    required this.counts,
    this.height = 26,
    this.showLabels = true,
  }) : assert(counts.length == 4);

  static const colors = [tGreen3, tBlue, tOrange, tRed];

  /// ***UPDATED RANGE LABELS USING < and > ***
  static const ranges = ["> 90%", "60% < 90%", "30% < 60%", "< 30%"];

  static const performanceLabels = [
    "Excellent", // > 90%
    "Good", // 60%–90%
    "Moderate", // 30%–60%
    "Poor", // < 30%
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final total = counts.fold(0, (a, b) => a + b);

    if (total == 0) {
      return Column(
        children: [
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(color: Colors.grey.shade200),
            alignment: Alignment.center,
            child: Text(
              "No data",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// --- Top Range Labels ---
        Row(
          children: List.generate(4, (i) {
            final count = counts[i];
            final pct = total == 0 ? 0 : (count / total);

            return Expanded(
              flex: maxFlex(pct.toDouble()),
              child: Center(
                child: Text(
                  ranges[i],
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: isDark ? tWhite : tBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 6),

        /// --- PROGRESS BAR ---
        Row(
          children: List.generate(4, (i) {
            final count = counts[i];
            if (count == 0) return const SizedBox.shrink();

            final pct = count / total;

            return Expanded(
              flex: maxFlex(pct),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: colors[i],
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      spreadRadius: 5,
                      color: colors[i].withOpacity(0.2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child:
                    showLabels
                        ? LayoutBuilder(
                          builder:
                              (_, constraints) =>
                                  constraints.maxWidth > 40
                                      ? Text(
                                        "${(pct * 100).toStringAsFixed(0)}%",
                                        style: GoogleFonts.urbanist(
                                          fontSize: 13,
                                          color: tWhite,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                      : const SizedBox.shrink(),
                        )
                        : null,
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        /// --- LEGENDS BELOW ---
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: List.generate(4, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 6,
                  decoration: BoxDecoration(color: colors[i]),
                ),
                const SizedBox(width: 6),
                Text(
                  performanceLabels[i],
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: isDark ? tWhite : tBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  /// Ensure minimum size for visibility
  int maxFlex(double pct) {
    final flex = (pct * 1000).round();
    return flex > 0 ? flex : 1;
  }
}
