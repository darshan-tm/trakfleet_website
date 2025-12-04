import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';
import 'package:tm_fleet_management/src/utils/appColors.dart';

import '../../services/apiServices.dart';
import '../../utils/appResponsive.dart';
import '../widgets/components/customTitleBar.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  DateTime selectedDate = DateTime.now();

  int hoveredAlertIndex = -1; // add this above build()

  int alertCurrentPage = 1;
  int alertRowsPerPage = 25;
  int alertTotalPages = 1;
  // 🔔 Recent alerts state
  List<Map<String, dynamic>> recentAlerts = [];
  int alertsTotalCount = 0;
  bool isAlertsLoading = false;

  String formatAlertDate(String? utc) {
    if (utc == null || utc.isEmpty) return '';
    final dateTime = DateTime.parse(utc).toLocal();
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(dateTime);
  }

  Future<void> fetchRecentAlerts() async {
    setState(() => isAlertsLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      // Build date string from your selectedDate (or use DateTime.now())
      final nowUtc = selectedDate.toUtc();
      final dateParam = nowUtc.toIso8601String();

      final uri = Uri.parse(BaseURLConfig.alertsApiUrl).replace(
        queryParameters: {
          "date": dateParam,
          "groups": "", // you can pass selectedGroup if backend supports
          "seriesName": "Vehicle Alerts",
          "title": "Vehicle Alerts",
          "page": "$alertCurrentPage",
          "sizePerPage": "$alertRowsPerPage",
          "currentIndex": "${(alertCurrentPage - 1) * alertRowsPerPage}",
        },
      );

      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          alertsTotalCount = data["totalCount"] ?? 0;

          recentAlerts =
              (data["entities"] as List)
                  .map<Map<String, dynamic>>(
                    (a) => {
                      "vehicleId": "${a["vehicleNumber"]}",
                      "imei": "${a["imei"]}",
                      "alertType": "${a["alertType"]}",
                      "data": "${a["data"]}",
                      "dateTime": formatAlertDate(a["time"]),
                    },
                  )
                  .toList();

          alertTotalPages =
              (alertsTotalCount / alertRowsPerPage).ceil(); //<-- here
        });
      } else {
        print("ALERTS API ERROR: ${response.statusCode}  ${response.body}");
      }
    } catch (e) {
      print("ALERTS API EXCEPTION: $e");
    }

    if (mounted) {
      setState(() => isAlertsLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    alertCurrentPage = 1;
    fetchRecentAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildMobileLayout() {
    return Container();
  }

  Widget _buildTabletLayout() {
    return Container();
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // _buildTitle(isDark),
            FleetTitleBar(isDark: isDark, title: "Alerts"),

            Row(
              children: [
                _buildFilterBySearch(isDark),
                SizedBox(width: 10),
                _buildDynamicDatePicker(isDark),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(flex: 4, child: _buildAlertsOverview(isDark)),
              const SizedBox(width: 10),
              Expanded(flex: 6, child: _buildAlertsTable(isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(bool isDark) => Text(
    'Alerts',
    style: GoogleFonts.urbanist(
      fontSize: 20,
      color: isDark ? tWhite : tBlack,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _buildFilterBySearch(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 250,
          height: 40,
          decoration: BoxDecoration(
            color: tTransparent,
            border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
          ),
          child: TextField(
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? tWhite : tBlack,
            ),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: GoogleFonts.urbanist(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? tWhite : tBlack,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: isDark ? tWhite : tBlack,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '(Note: Filter by Search)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicDatePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: tTransparent,
              border: Border.all(width: 0.6, color: isDark ? tWhite : tBlack),
            ),
            child: Center(
              child: Text(
                DateFormat('dd MMM yyyy').format(selectedDate).toUpperCase(),
                style: GoogleFonts.urbanist(
                  fontSize: 12.5,
                  color: isDark ? tWhite : tBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '(Note: Filter by Date)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.blueAccent,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  // Widget _buildAlertsTable(bool isDark) {
  //   final alertTypes = [
  //     'Power Disconnect',
  //     'GPRS Lost',
  //     'Over Speed',
  //     'Ignition On',
  //     'Ignition Off',
  //     'Geo Fence Alert',
  //     'Battery Low',
  //     'Tilt Alert',
  //     'Fall Detected',
  //     'SOS Triggered',
  //   ];

  //   // Define color mapping for each alert type
  //   final Map<String, Color> alertColors = {
  //     'Power Disconnect': Colors.redAccent,
  //     'GPRS Lost': Colors.orangeAccent,
  //     'Over Speed': Colors.deepOrange,
  //     'Ignition On': Colors.green,
  //     'Ignition Off': Colors.grey,
  //     'Geo Fence Alert': Colors.purpleAccent,
  //     'Battery Low': Colors.amber,
  //     'Tilt Alert': Colors.blueAccent,
  //     'Fall Detected': Colors.pinkAccent,
  //     'SOS Triggered': Colors.red,
  //   };

  //   // Generate dummy alerts
  //   final List<Map<String, dynamic>> alerts = List.generate(100, (index) {
  //     final type = alertTypes[index % alertTypes.length];
  //     final isCritical = [
  //       'Over Speed',
  //       'Power Disconnect',
  //       'Battery Low',
  //       'SOS Triggered',
  //       'Fall Detected',
  //     ].contains(type);

  //     return {
  //       'imei': '3568790400${(index + 100).toString().padLeft(3, '0')}',
  //       'vehicleId': 'VH-${index % 15 + 1}',
  //       'alertTime': DateFormat(
  //         'dd MMM yyyy, hh:mm a',
  //       ).format(DateTime.now().subtract(Duration(minutes: index * 3))),
  //       'type': type,
  //       'alertData':
  //           isCritical
  //               ? 'Immediate attention required'
  //               : 'Monitor status normally',
  //     };
  //   });

  //   // Pagination logic
  //   final startIndex = (currentPage - 1) * rowsPerPage;
  //   final endIndex = (startIndex + rowsPerPage).clamp(0, alerts.length);
  //   final currentPageAlerts = alerts.sublist(startIndex, endIndex);

  //   return LayoutBuilder(
  //     builder: (context, constraints) {
  //       final maxHeight = constraints.maxHeight;
  //       final maxWidth = constraints.maxWidth;

  //       return Container(
  //         width: maxWidth,
  //         height: maxHeight,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Scrollable Table Area
  //             Expanded(
  //               child: Scrollbar(
  //                 thumbVisibility: true,
  //                 child: SingleChildScrollView(
  //                   scrollDirection: Axis.horizontal,
  //                   child: ConstrainedBox(
  //                     constraints: BoxConstraints(minWidth: maxWidth),
  //                     child: SingleChildScrollView(
  //                       scrollDirection: Axis.vertical,
  //                       child: DataTable(
  //                         headingRowColor: WidgetStateProperty.all(
  //                           isDark
  //                               ? tBlue.withOpacity(0.15)
  //                               : tBlue.withOpacity(0.05),
  //                         ),
  //                         headingTextStyle: GoogleFonts.urbanist(
  //                           fontWeight: FontWeight.w700,
  //                           color: isDark ? tWhite : tBlack,
  //                           fontSize: 13,
  //                         ),
  //                         dataTextStyle: GoogleFonts.urbanist(
  //                           color: isDark ? tWhite : tBlack,
  //                           fontWeight: FontWeight.w400,
  //                           fontSize: 12,
  //                         ),
  //                         columnSpacing: 30,
  //                         border: TableBorder.all(
  //                           color:
  //                               isDark
  //                                   ? tWhite.withOpacity(0.1)
  //                                   : tBlack.withOpacity(0.1),
  //                           width: 0.4,
  //                         ),
  //                         dividerThickness: 0.01,
  //                         columns: const [
  //                           DataColumn(label: Text('IMEI Number')),
  //                           DataColumn(label: Text('Vehicle ID')),
  //                           DataColumn(label: Text('Alert Time')),
  //                           DataColumn(label: Text('Alert Type')),
  //                           DataColumn(label: Text('Alert Data')),
  //                         ],
  //                         rows:
  //                             currentPageAlerts.map((alert) {
  //                               final color =
  //                                   alertColors[alert['type']] ??
  //                                   (isDark ? tBlue : Colors.blueGrey);

  //                               return DataRow(
  //                                 cells: [
  //                                   DataCell(Text(alert['imei'])),
  //                                   DataCell(Text(alert['vehicleId'])),
  //                                   DataCell(Text(alert['alertTime'])),
  //                                   DataCell(
  //                                     Row(
  //                                       mainAxisSize: MainAxisSize.min,
  //                                       children: [
  //                                         // Small circular critical/non-critical indicator
  //                                         Container(
  //                                           width: 10,
  //                                           height: 10,
  //                                           margin: const EdgeInsets.only(
  //                                             right: 8,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color:
  //                                                 [
  //                                                       'Over Speed',
  //                                                       'Power Disconnect',
  //                                                       'Battery Low',
  //                                                       'SOS Triggered',
  //                                                       'Fall Detected',
  //                                                     ].contains(alert['type'])
  //                                                     ? tOrange1 // Critical
  //                                                     : tBlueSky, // Non-critical
  //                                             shape: BoxShape.circle,
  //                                             boxShadow: [
  //                                               BoxShadow(
  //                                                 color:
  //                                                     [
  //                                                           'Over Speed',
  //                                                           'Power Disconnect',
  //                                                           'Battery Low',
  //                                                           'SOS Triggered',
  //                                                           'Fall Detected',
  //                                                         ].contains(
  //                                                           alert['type'],
  //                                                         )
  //                                                         ? tOrange1
  //                                                             .withOpacity(0.4)
  //                                                         : tBlueSky
  //                                                             .withOpacity(0.4),
  //                                                 blurRadius: 4,
  //                                                 spreadRadius: 1,
  //                                               ),
  //                                             ],
  //                                           ),
  //                                         ),

  //                                         // Alert type colored container
  //                                         Container(
  //                                           padding: const EdgeInsets.symmetric(
  //                                             vertical: 4,
  //                                             horizontal: 10,
  //                                           ),
  //                                           decoration: BoxDecoration(
  //                                             color: color.withOpacity(0.1),
  //                                             borderRadius:
  //                                                 BorderRadius.circular(5),
  //                                             border: Border.all(
  //                                               color: color.withOpacity(0.6),
  //                                               width: 0.8,
  //                                             ),
  //                                           ),
  //                                           child: Text(
  //                                             alert['type'],
  //                                             style: GoogleFonts.urbanist(
  //                                               color: color,
  //                                               fontWeight: FontWeight.w600,
  //                                               fontSize: 12,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ],
  //                                     ),
  //                                   ),
  //                                   DataCell(Text(alert['alertData'])),
  //                                 ],
  //                               );
  //                             }).toList(),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),

  //             // Pagination Controls
  //             if (totalPages > 1) _buildPaginationControls(isDark),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildAlertsTable(bool isDark) {
    final alerts = recentAlerts; // Backend alerts
    final currentPageAlerts = recentAlerts;

    final totalPages =
        alertsTotalCount == 0
            ? 1
            : (alertsTotalCount / alertRowsPerPage).ceil();

    alertTotalPages = totalPages;

    Color getAlertColor(String type) {
      type = type.toLowerCase();
      if (type.contains('disconnect')) return tRed;
      if (type.contains('battery')) return tRed;
      if (type.contains('lowfuel') || type.contains('low_fuel'))
        return tOrange1;
      if (type.contains('hightemperature') || type.contains('temp'))
        return Colors.amber;
      if (type.contains('ignition')) return tBlue;
      return tGrey;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        return Container(
          width: maxWidth,
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: maxWidth),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            isDark
                                ? tBlue.withOpacity(0.15)
                                : tBlue.withOpacity(0.05),
                          ),
                          headingTextStyle: GoogleFonts.urbanist(
                            fontWeight: FontWeight.w700,
                            color: isDark ? tWhite : tBlack,
                            fontSize: 13,
                          ),
                          dataTextStyle: GoogleFonts.urbanist(
                            color: isDark ? tWhite : tBlack,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          ),
                          columnSpacing: 30,
                          border: TableBorder.all(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.1)
                                    : tBlack.withOpacity(0.1),
                            width: 0.4,
                          ),
                          dividerThickness: 0.01,
                          columns: const [
                            DataColumn(label: Text('S.No')),
                            DataColumn(label: Text('IMEI Number')),
                            DataColumn(label: Text('Vehicle ID')),
                            DataColumn(label: Text('Alert Time')),
                            DataColumn(label: Text('Alert Type')),
                            DataColumn(label: Text('Alert Data')),
                          ],
                          rows:
                              currentPageAlerts.asMap().entries.map((entry) {
                                final idx = entry.key + 1; // index
                                final alert = entry.value;
                                final type =
                                    (alert['alertType'] ?? '').toString();
                                final color = getAlertColor(type);

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        '${(alertCurrentPage - 1) * alertRowsPerPage + idx}',
                                      ),
                                    ),
                                    DataCell(Text('${alert['imei']}')),
                                    DataCell(Text('${alert['vehicleId']}')),
                                    DataCell(Text('${alert['dateTime']}')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                              horizontal: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color: color.withOpacity(0.6),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              type,
                                              style: GoogleFonts.urbanist(
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text('${alert['data']}')),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (totalPages > 0) _buildPaginationControls(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsOverview(bool isDark) {
    final Map<String, double> criticalAlerts = {
      'Power Disconnect': 30,
      'Battery Low': 25,
      'Tilt Alert': 20,
      'Fall Detected': 15,
      'SOS Triggered': 10,
    };

    final Map<String, double> nonCriticalAlerts = {
      'GPRS Lost': 20,
      'Over Speed': 30,
      'Ignition On': 25,
      'Ignition Off': 15,
      'Geo Fence Alert': 10,
    };

    final Map<String, Color> alertColors = {
      'Power Disconnect': Colors.redAccent,
      'Battery Low': Colors.orange,
      'Tilt Alert': Colors.pinkAccent,
      'Fall Detected': Colors.deepOrange,
      'SOS Triggered': Colors.red,
      'GPRS Lost': Colors.lightBlue,
      'Over Speed': Colors.green,
      'Ignition On': Colors.teal,
      'Ignition Off': Colors.cyan,
      'Geo Fence Alert': Colors.purple,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAlertInfoCard(
              index: 0,
              title: 'Total Alerts',
              count: '$alertsTotalCount',
              iconPath: 'icons/alert.svg',
              iconColor: tBlue,
              bgColor: tBlue.withOpacity(0.1),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildAlertInfoCard(
              index: 1,
              title: 'Faults',
              count: '--',
              iconPath: 'icons/flagged.svg',
              iconColor: tRed,
              bgColor: tRed.withOpacity(0.1),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildAlertInfoCard(
              index: 2,
              title: 'Critical Alerts',
              count: '--',
              iconPath: 'icons/alert.svg',
              iconColor: tOrange1,
              bgColor: tOrange1.withOpacity(0.1),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildAlertInfoCard(
              index: 3,
              title: 'Non-Critical Alerts',
              count: '--',
              iconPath: 'icons/alert.svg',
              iconColor: tBlueSky,
              bgColor: tBlueSky.withOpacity(0.1),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 15),
        // AlertsPieChart(),
        Text(
          'Critical Alerts',
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 10),
        _buildAnimatedAlertsBar(criticalAlerts, alertColors, isDark),
        const SizedBox(height: 10),
        _buildLegends(criticalAlerts, alertColors, isDark),

        const SizedBox(height: 20),

        // ===== Non-Critical Alerts =====
        Text(
          'Non-Critical Alerts',
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 10),
        _buildAnimatedAlertsBar(nonCriticalAlerts, alertColors, isDark),
        const SizedBox(height: 10),
        _buildLegends(nonCriticalAlerts, alertColors, isDark),
      ],
    );
  }

  Widget _buildAnimatedAlertsBar(
    Map<String, double> data,
    Map<String, Color> colors,
    bool isDark,
  ) {
    double total = data.values.fold(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      height: 35,
      decoration: BoxDecoration(
        color: tTransparent,
        // border: Border.all(width: 0.3, color: isDark ? tWhite : tBlack),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            data.entries.map((entry) {
              double percentage = entry.value / total;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percentage),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Expanded(
                    flex: (value * 1000).toInt().clamp(1, 1000),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? tGrey,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (colors[entry.key]?.withOpacity(0.4)) ??
                                tGrey.withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Tooltip(
                        message:
                            "${entry.key}: ${(entry.value).toStringAsFixed(1)}%",
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
      ),
    );
  }

  // Legends Row
  Widget _buildLegends(
    Map<String, double> data,
    Map<String, Color> colors,
    bool isDark,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children:
          data.keys.map((key) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[key] ?? Colors.grey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  key,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildAlertInfoCard({
    required int index,
    required String title,
    required String count,
    required String iconPath,
    required Color iconColor,
    required Color bgColor,
    required bool isDark,
  }) {
    final isHovered = hoveredAlertIndex == index;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => hoveredAlertIndex = index),
        onExit: (_) => setState(() => hoveredAlertIndex = -1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            border: Border.all(
              width: isHovered ? 1.3 : 0.6,
              color:
                  isHovered
                      ? iconColor.withOpacity(0.7)
                      : iconColor.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                spreadRadius: 2,
                blurRadius: isHovered ? 14 : 10,
                color:
                    isDark
                        ? tWhite.withOpacity(0.12)
                        : tBlack.withOpacity(0.08),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    color: iconColor,
                  ),
                ),
              ),

              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    count,
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            setState(() => alertCurrentPage--);
            fetchRecentAlerts();
          },

          icon: Icon(Icons.chevron_left),
        ),

        Text(
          "$alertCurrentPage / $alertTotalPages",
          style: TextStyle(fontSize: 14),
        ),

        IconButton(
          onPressed: () {
            setState(() => alertCurrentPage++);
            fetchRecentAlerts();
          },

          icon: Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  // Widget _buildPaginationControls(bool isDark) {
  //   const int visiblePageCount = 5;

  //   // Determine start and end of visible window
  //   int startPage =
  //       ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
  //   int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

  //   final pageButtons = <Widget>[];

  //   for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
  //     final isSelected = pageNum == currentPage;

  //     pageButtons.add(
  //       GestureDetector(
  //         onTap: () {
  //           if (!mounted) return;
  //           setState(() => currentPage = pageNum);
  //         },
  //         child: Container(
  //           margin: const EdgeInsets.symmetric(horizontal: 4),
  //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //           decoration: BoxDecoration(
  //             color: isSelected ? tBlue : Colors.transparent,
  //             borderRadius: BorderRadius.circular(6),
  //             border: Border.all(
  //               color:
  //                   isSelected
  //                       ? tBlue
  //                       : (isDark ? Colors.white54 : Colors.black54),
  //             ),
  //           ),
  //           child: Text(
  //             '$pageNum',
  //             style: GoogleFonts.urbanist(
  //               color:
  //                   isSelected
  //                       ? tWhite
  //                       : (isDark
  //                           ? tWhite.withOpacity(0.8)
  //                           : tBlack.withOpacity(0.8)),
  //               fontWeight: FontWeight.w600,
  //               fontSize: 13,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   final controller = TextEditingController();

  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         /// Previous Button
  //         IconButton(
  //           icon: Icon(
  //             Icons.chevron_left,
  //             color: isDark ? tWhite : tBlack,
  //             size: 22,
  //           ),
  //           onPressed: () {
  //             if (currentPage > 1) {
  //               setState(() => currentPage--);
  //             }
  //           },
  //         ),

  //         /// Page Buttons (windowed 5)
  //         Row(children: pageButtons),

  //         /// Next Button
  //         IconButton(
  //           icon: Icon(
  //             Icons.chevron_right,
  //             color: isDark ? tWhite : tBlack,
  //             size: 22,
  //           ),
  //           onPressed: () {
  //             if (currentPage < totalPages) {
  //               setState(() => currentPage++);
  //             }
  //           },
  //         ),

  //         const SizedBox(width: 16),

  //         /// Page Input Box
  //         SizedBox(
  //           width: 70,
  //           height: 32,
  //           child: TextField(
  //             controller: controller,
  //             style: GoogleFonts.urbanist(
  //               fontSize: 13,
  //               color: isDark ? tWhite : tBlack,
  //             ),
  //             keyboardType: TextInputType.number,
  //             decoration: InputDecoration(
  //               hintText: 'Page',
  //               hintStyle: GoogleFonts.urbanist(
  //                 fontSize: 12,
  //                 color: isDark ? Colors.white54 : Colors.black54,
  //               ),
  //               contentPadding: const EdgeInsets.symmetric(
  //                 horizontal: 8,
  //                 vertical: 4,
  //               ),
  //               border: OutlineInputBorder(
  //                 borderSide: BorderSide(
  //                   color: isDark ? tWhite : tBlack,
  //                   width: 0.8,
  //                 ),
  //               ),
  //             ),
  //             onSubmitted: (value) {
  //               final page = int.tryParse(value);
  //               if (page != null &&
  //                   page >= 1 &&
  //                   page <= totalPages &&
  //                   mounted) {
  //                 setState(() => currentPage = page);
  //               }
  //             },
  //           ),
  //         ),

  //         const SizedBox(width: 10),

  //         /// Show visible range (e.g., "1–5 of 20")
  //         Text(
  //           '$startPage–$endPage of $totalPages',
  //           style: GoogleFonts.urbanist(
  //             fontSize: 13,
  //             color: isDark ? tWhite : tBlack,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
