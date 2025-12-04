import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';

class AlertsDonutChart extends StatelessWidget {
  final int critical;
  final int nonCritical;
  final double avgCritical;
  final double avgNonCritical;
  final String title;

  const AlertsDonutChart({
    super.key,
    required this.critical,
    required this.nonCritical,
    required this.avgCritical,
    required this.avgNonCritical,
    this.title = "Critical vs Non-Critical Alerts",
  });

  @override
  Widget build(BuildContext context) {
    final total = critical + nonCritical;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Top Title
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),

        const SizedBox(height: 10),

        /// Donut Chart + Center Text
        SizedBox(
          height: 175,
          width: 175,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: critical.toDouble(),
                      color: tOrange,
                      radius: 40,
                      title: '',
                    ),
                    PieChartSectionData(
                      value: nonCritical.toDouble(),
                      color: tBlueSky,
                      radius: 40,
                      title: '',
                    ),
                  ],
                ),
              ),

              /// Center Text
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Critical",
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "$critical",
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: isDark ? tWhite : tBlack,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Non-Critical",
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "$nonCritical",
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: isDark ? tWhite : tBlack,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        /// Bottom Averages
        Text(
          "Avg Critical: $avgCritical   |   Avg Non-Critical: $avgNonCritical",
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }
}
