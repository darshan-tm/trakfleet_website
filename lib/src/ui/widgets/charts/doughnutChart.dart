import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/appColors.dart';

class SingleDoughnutChart extends StatelessWidget {
  final double currentValue;
  final double avgValue;
  final String title;
  final String unit; // e.g. km/h, %, rpm, °C, V
  final Color primaryColor;
  final bool isDark;

  const SingleDoughnutChart({
    super.key,
    required this.currentValue,
    required this.avgValue,
    required this.title,
    required this.unit,
    required this.primaryColor,
    required this.isDark,
  });

  // 🔹 Define value ranges per metric
  double _getMaxRange(String title) {
    switch (title.toLowerCase()) {
      case 'speed':
        return 150; // km/h
      case 'rpm':
        return 10000; // rpm
      case 'fuel':
        return 100; // %
      case 'voltage':
        return 100; // volts
      case 'temperature':
        return 200; // degrees
      case 'torque':
        return 500; //Nm
      default:
        return 100; // fallback
    }
  }

  double _getMinRange(String title) {
    switch (title.toLowerCase()) {
      case 'temperature':
        return -40; // min temp
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🔹 Normalize to 0–100% range for chart visuals
    final double min = _getMinRange(title);
    final double max = _getMaxRange(title);
    final double normalizedCurrent =
        ((currentValue - min) / (max - min)).clamp(0, 1) * 100;
    final double normalizedAvg =
        ((avgValue - min) / (max - min)).clamp(0, 1) * 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔹 Top Label
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 8),

        // 🔹 Doughnut chart
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 35,
                  startDegreeOffset: 270,
                  sections: [
                    PieChartSectionData(
                      value: normalizedCurrent,
                      color: primaryColor,
                      radius: 20,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - normalizedCurrent,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      radius: 20,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
            ),

            // 🔹 Center Value (real value)
            Text(
              currentValue.toStringAsFixed(0),
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: primaryColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 🔹 Average Value
        Text(
          "Avg: ${avgValue.toStringAsFixed(0)} $unit",
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }
}
