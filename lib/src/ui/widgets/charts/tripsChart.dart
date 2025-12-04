import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/appColors.dart';

class TripsChart extends StatefulWidget {
  const TripsChart({super.key});

  @override
  State<TripsChart> createState() => _TripsChartState();
}

class _TripsChartState extends State<TripsChart> {
  String _viewMode = "weekly";
  late List<Map<String, dynamic>> chartData;
  int? touchedIndex;
  double? touchedY;

  @override
  void initState() {
    super.initState();
    _generateDummyData();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   setState(() => touchedIndex = 0); // auto show on first group
    // });
  }

  void _generateDummyData() {
    final now = DateTime.now();

    if (_viewMode == "weekly") {
      // Generate last 7 days (today + past 6 days)
      chartData = List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        final dayLabel =
            ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.weekday % 7];

        return {
          "label": dayLabel,
          "trips": 5 + i * 2 + (date.day % 3),
          "distance": 20 + i * 5 + (date.day % 10),
          "hours": 2.0 + (i * 0.5),
        };
      });
    } else if (_viewMode == "monthly") {
      // Generate last 4 weeks (current week + 3 previous)
      chartData =
          List.generate(4, (i) {
            final startOfWeek = now.subtract(Duration(days: i * 7));
            final weekNumber =
                ((startOfWeek.day - startOfWeek.weekday + 10) / 7).floor();
            return {
              "label": "W${weekNumber}",
              "trips": 40 + i * 8,
              "distance": 150 + i * 20,
              "hours": 18.0 + i * 1.5,
            };
          }).reversed.toList();
    }
  }

  void _updateView(String mode) {
    setState(() {
      _viewMode = mode;
      _generateDummyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trips',
              style: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? tWhite : tBlack,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: tGrey.withOpacity(0.1),
                // borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  _buildToggleButton("Weekly"),
                  _buildToggleButton("Monthly"),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Chart
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < chartData.length) {
                            return Text(
                              chartData[value.toInt()]["label"],
                              style: GoogleFonts.urbanist(
                                fontSize: 11,
                                color:
                                    isDark
                                        ? Colors.white70
                                        : Colors.black.withOpacity(0.7),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),

                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      tooltipPadding: const EdgeInsets.all(10),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (group) => isDark ? tWhite : tBlack,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final data = chartData[group.x.toInt()];
                        final legendColors = [tBlue, tGreen, tPink];
                        final legendLabels = ["Trips", "Distance", "Hours"];
                        final legendValues = [
                          "${data["trips"]}",
                          "${data["distance"]} km",
                          "${data["hours"]} h",
                        ];

                        final spans = <TextSpan>[
                          TextSpan(
                            text: "${data["label"]}\n",
                            style: GoogleFonts.urbanist(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? tBlack : tWhite,
                            ),
                          ),
                        ];

                        for (int i = 0; i < legendLabels.length; i++) {
                          spans.add(
                            TextSpan(
                              text: "● ",
                              style: TextStyle(
                                color: legendColors[i],
                                fontSize: 12,
                              ),
                            ),
                          );
                          spans.add(
                            TextSpan(
                              text: "${legendLabels[i]}: ${legendValues[i]}\n",
                              style: GoogleFonts.urbanist(
                                color: isDark ? tBlack : tWhite,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }

                        return BarTooltipItem(
                          '',
                          const TextStyle(),
                          children: spans,
                          textAlign: TextAlign.start,
                        );
                      },
                    ),

                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.spot == null) {
                        setState(() {
                          touchedIndex = null;
                          touchedY = null;
                        });
                        return;
                      }

                      setState(() {
                        touchedIndex = response.spot!.touchedBarGroupIndex;
                        touchedY = response.spot!.touchedRodData.toY;
                      });
                    },
                  ),

                  extraLinesData: ExtraLinesData(
                    verticalLines:
                        touchedIndex != null
                            ? [
                              VerticalLine(
                                x: touchedIndex!.toDouble(),
                                color: isDark ? Colors.white38 : Colors.black38,
                                strokeWidth: 1,
                                dashArray: [5, 4],
                              ),
                            ]
                            : [],
                  ),

                  barGroups:
                      chartData.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 5,
                          showingTooltipIndicators:
                              touchedIndex == i ? [0, 1, 2] : [],
                          barRods: [
                            BarChartRodData(
                              toY: item["trips"].toDouble(),
                              color: tBlue.withOpacity(0.9),
                              width: 8,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            BarChartRodData(
                              toY: item["distance"].toDouble() / 5,
                              color: tGreen.withOpacity(0.9),
                              width: 8,
                              borderRadius: BorderRadius.circular(0),
                            ),
                            BarChartRodData(
                              toY: item["hours"].toDouble() * 10,
                              color: tPink.withOpacity(0.9),
                              width: 8,
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),

              //Add the custom painter overlay
              if (touchedIndex != null && touchedY != null)
                IgnorePointer(
                  ignoring: true,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: CrosshairPainter(
                      xIndex: touchedIndex!,
                      yValue: touchedY!,
                      chartDataLength: chartData.length,
                      isDark: isDark,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 5),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: tBlue.withOpacity(0.9), label: "Trips"),
            SizedBox(width: 6),
            _LegendItem(
              color: tGreen.withOpacity(0.9),
              label: "Distance Travelled",
            ),
            SizedBox(width: 6),
            _LegendItem(color: tPink.withOpacity(0.9), label: "Opertion Hours"),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label) {
    final isSelected = _viewMode == label.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _updateView(label.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? tWhite : tBlack) : Colors.transparent,
          // borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                isSelected
                    ? (isDark ? tBlack : tWhite)
                    : (isDark ? tWhite : tBlack),
          ),
        ),
      ),
    );
  }
}

class CrosshairPainter extends CustomPainter {
  final int xIndex;
  final double yValue;
  final int chartDataLength;
  final bool isDark;

  CrosshairPainter({
    required this.xIndex,
    required this.yValue,
    required this.chartDataLength,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDark ? tWhite : tBlack
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    const dashArray = [5, 4];

    // Convert index to pixel position horizontally
    final double spacing = size.width / (chartDataLength + 1);
    final double xPos = spacing * (xIndex + 1);

    // Convert Y value (0–max) to pixel Y coordinate (bottom-up)
    // For simplicity, assume 0–100 max range; adjust if your data scale differs
    final double yPos = size.height * (1 - (yValue / 100).clamp(0, 1));

    // Draw dashed vertical line
    _drawDashedLine(
      canvas,
      Offset(xPos, 0),
      Offset(xPos, size.height),
      paint,
      dashArray,
    );

    // Draw dashed horizontal line
    _drawDashedLine(
      canvas,
      Offset(0, yPos),
      Offset(size.width, yPos),
      paint,
      dashArray,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
    List<int> dashArray,
  ) {
    const double dashWidth = 5;
    const double dashSpace = 4;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    final double angle = atan2(dy, dx);
    double start = 0;
    final path = Path();

    while (start < distance) {
      final x1 = p1.dx + cos(angle) * start;
      final y1 = p1.dy + sin(angle) * start;
      start += dashWidth;
      final x2 = p1.dx + cos(angle) * min(start, distance);
      final y2 = p1.dy + sin(angle) * min(start, distance);
      path.moveTo(x1, y1);
      path.lineTo(x2, y2);
      start += dashSpace;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? tWhite
                    : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
