import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';

import '../../provider/fleetModeProvider.dart';
import '../../services/apiServices.dart';
import '../../utils/appColors.dart';
import '../../utils/appLogger.dart';
import '../../utils/appResponsive.dart';
import '../components/largeHoverCard.dart';
import '../components/smallHoverCard.dart';
import '../widgets/charts/alertsChart.dart';
import '../widgets/charts/doughnutChart.dart';
import '../widgets/charts/speedDistanceChart.dart';
import '../widgets/charts/tripsChart.dart';

class DeviceGeneralInfoScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceGeneralInfoScreen({super.key, required this.device});

  @override
  State<DeviceGeneralInfoScreen> createState() =>
      _DeviceGeneralInfoScreenState();
}

class _DeviceGeneralInfoScreenState extends State<DeviceGeneralInfoScreen> {
  late Color statusColor;

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'moving':
        return tGreen;
      case 'idle':
        return tOrange1;
      case 'stopped':
        return tRed;
      case 'disconnected':
        return tGrey;
      default:
        return tBlack;
    }
  }

  final Map<String, Color> statusColors = {
    'moving': tGreen.withOpacity(0.9),
    'stopped': tRed.withOpacity(0.9),
    'idle': tOrange1.withOpacity(0.9),
    'halted': tBlue.withOpacity(0.9),
  };

  int alertCurrentPage = 1;
  int alertRowsPerPage = 25;
  int alertTotalPages = 1;
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> recentAlerts = [];
  int VehiclealertsCount = 0;
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
      final imei = widget.device['imei']?.toString() ?? "";

      final uri = Uri.parse(
        "${BaseURLConfig.alertsApiUrl}"
        "?date=$dateParam"
        "&groups="
        "&imei=$imei"
        "&seriesName=Vehicle+Alerts"
        "&title=Vehicle+Alerts"
        "&page=$alertCurrentPage"
        "&sizePerPage=$alertRowsPerPage"
        "&currentIndex=${(alertCurrentPage - 1) * alertRowsPerPage}",
      );

      print("FINAL URL => $uri");
      // Check final URL

      // final uri = Uri.parse(
      //   "https://ev-backend.trakmatesolutions.com/api/dashboard/evAllDatalistData?date=2025-12-03T11:59:23.825Z&groups=&imei=$imei&seriesName=Vehicle+Alerts&title=Vehicle+Alerts&page=1&sizePerPage=10&currentIndex=0",
      // );
      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          VehiclealertsCount = data["totalCount"] ?? 0;

          recentAlerts =
              (data["entities"] as List)
                  .map<Map<String, dynamic>>(
                    (a) => {
                      "vehicleId": "${a["vehicleNumber"]}",
                      "imei": "${a["imei"]}",
                      "alertType": "${a["alertType"]}",
                      // "data": "${a["data"]}",
                      "dateTime": formatAlertDate(a["time"]),
                    },
                  )
                  .toList();

          alertTotalPages =
              (VehiclealertsCount / alertRowsPerPage).ceil(); //<-- here
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
    // Initialize statusColor based on the device's current status
    final status = widget.device['status'] ?? '';
    LoggerUtil.getInstance.print(status);
    fetchRecentAlerts();
    statusColor = getStatusColor(status);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final mode = context.watch<FleetModeProvider>().mode;

    final device = widget.device;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: buildDeviceCard(
            isDark: isDark,
            imei: widget.device['imei'] ?? '356938035643809',
            vehicleNumber: widget.device['vehicleNumber'] ?? 'TRK-1001',
            status: widget.device['status'] ?? 'Disconnected',
            fuel: widget.device['fuel'] ?? '',
            odo: widget.device['odo'] ?? '',
            trips: widget.device['trips'] ?? '',
            alerts: widget.device['alerts'] ?? '',
            location: widget.device['location'] ?? '',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              // padding: const EdgeInsets.all(10),
              padding: EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Left panel
                      Expanded(
                        flex: 5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔹 Left section (Title + Doughnut Charts)
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 225,
                                decoration: BoxDecoration(
                                  color: isDark ? tBlack : tWhite,
                                  boxShadow: [
                                    BoxShadow(
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      color:
                                          isDark
                                              ? tWhite.withOpacity(0.25)
                                              : tBlack.withOpacity(0.15),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    SingleDoughnutChart(
                                      currentValue: 12.8,
                                      avgValue: 12,
                                      title: "Voltage",
                                      unit: "V",
                                      primaryColor: tBlue,
                                      isDark: isDark,
                                    ),
                                    SingleDoughnutChart(
                                      currentValue: 72,
                                      avgValue: 55,
                                      title: "Speed",
                                      unit: "km/h",
                                      primaryColor: tGreen,
                                      isDark: isDark,
                                    ),

                                    mode == 'EV Fleet'
                                        ? SingleDoughnutChart(
                                          currentValue: 85,
                                          avgValue: 48,
                                          title: "SOC",
                                          unit: "%",
                                          primaryColor: tBlueSky,
                                          isDark: isDark,
                                        )
                                        : SingleDoughnutChart(
                                          currentValue: 64,
                                          avgValue: 50,
                                          title: "Fuel",
                                          unit: "%",
                                          primaryColor: tBlueSky,
                                          isDark: isDark,
                                        ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            // 🔹 Right section (Info cards)
                            Expanded(
                              flex: 2,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildInfoCard(
                                    isDark,
                                    "Odometer (km)",
                                    "5,412",
                                    tBlueGradient2,
                                  ),
                                  const SizedBox(height: 10),

                                  _buildInfoCard(
                                    isDark,
                                    "Operation Hours (hrs)",
                                    "1,289",
                                    tRedGradient2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Right panel (placeholder for map, chart, etc.)
                      Expanded(flex: 5, child: _buildDeviceStatus(isDark)),
                    ],
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 600,
                          decoration: BoxDecoration(
                            color: tTransparent,
                            // color: isDark ? tBlack : tWhite,
                            // boxShadow: [
                            //   BoxShadow(
                            //     spreadRadius: 2,
                            //     blurRadius: 10,
                            //     color:
                            //         isDark
                            //             ? tWhite.withOpacity(0.25)
                            //             : tBlack.withOpacity(0.15),
                            //   ),
                            // ],
                          ),
                          // padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alerts Overview',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  LargeHoverCard(
                                    value: VehiclealertsCount.toString(),
                                    label: "Alerts",
                                    labelColor: tRed,
                                    icon: "icons/alert.svg",
                                    iconColor: tRed,
                                    bgColor: tRed.withOpacity(0.1),
                                    isDark: isDark,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value: "53",
                                          label: "Non-Critical Alerts",
                                          labelColor: tBlueSky,
                                          icon: "icons/alert.svg",
                                          iconColor: tBlueSky,
                                          bgColor: tBlueSky.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 10),
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value: "53",
                                          label: "Critical Alerts",
                                          labelColor: tOrange1,
                                          icon: "icons/alert.svg",
                                          iconColor: tOrange1,
                                          bgColor: tOrange1.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Recent Alerts',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: tTransparent,
                                  ),
                                  child: buildAlertsTable(isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 600,
                          decoration: BoxDecoration(
                            color: tTransparent,
                            // color: isDark ? tBlack : tWhite,
                            // boxShadow: [
                            //   BoxShadow(
                            //     spreadRadius: 2,
                            //     blurRadius: 10,
                            //     color:
                            //         isDark
                            //             ? tWhite.withOpacity(0.25)
                            //             : tBlack.withOpacity(0.15),
                            //   ),
                            // ],
                          ),
                          // padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trips Overview',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  LargeHoverCard(
                                    value: "50,678",
                                    label: "Trips",
                                    labelColor: tGreen,
                                    icon: "icons/distance.svg",
                                    iconColor: tGreen,
                                    bgColor: tGreen.withOpacity(0.1),
                                    isDark: isDark,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value: "45,256",
                                          label: "Completed Trips",
                                          labelColor: tBlue,
                                          icon: "icons/completed.svg",
                                          iconColor: tBlue,
                                          bgColor: tBlue.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 10),
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value: "5,345",
                                          label: "Avg. Trips",
                                          labelColor: tOrange1,
                                          icon: "icons/distance.svg",
                                          iconColor: tOrange1,
                                          bgColor: tOrange1.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value: "2,456",
                                          label: "Avg.Dist. Travelled(km)",
                                          labelColor: tBlueSky,
                                          icon: "icons/distance.svg",
                                          iconColor: tBlueSky,
                                          bgColor: tBlueSky.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                        const SizedBox(height: 10),
                                        SmallHoverCard(
                                          width: double.infinity,
                                          height: 85,
                                          value: "456",
                                          label: "Avg.Oper. Hours(hrs)",
                                          labelColor: tRed,
                                          icon: "icons/consumedhours.svg",
                                          iconColor: tRed,
                                          bgColor: tRed.withOpacity(0.1),
                                          isDark: isDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Recent Trips',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),
                              SizedBox(height: 10),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: tTransparent,
                                  ),
                                  child: _buildTripsTable(
                                    isDark,
                                  ), // <-- NO SingleChildScrollView here
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 600,
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            boxShadow: [
                              BoxShadow(
                                spreadRadius: 2,
                                blurRadius: 10,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.25)
                                        : tBlack.withOpacity(0.15),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: buildVehicleMap(isDark: isDark, zoom: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 330,
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            boxShadow: [
                              BoxShadow(
                                spreadRadius: 2,
                                blurRadius: 10,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.25)
                                        : tBlack.withOpacity(0.15),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(15),
                          child: TripsChart(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 330,
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            boxShadow: [
                              BoxShadow(
                                spreadRadius: 2,
                                blurRadius: 10,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.25)
                                        : tBlack.withOpacity(0.15),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle Status',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: isDark ? tWhite : tBlack,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildStatusBarChart(isDark),
                              const SizedBox(height: 10),
                              // Legend
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegendItem(
                                    color: tGreen.withOpacity(0.9),
                                    label: "Moving",
                                  ),
                                  SizedBox(width: 6),
                                  _LegendItem(
                                    color: tOrange1.withOpacity(0.9),
                                    label: "Idle",
                                  ),
                                  SizedBox(width: 6),
                                  _LegendItem(
                                    color: tRed.withOpacity(0.9),
                                    label: "Stopped",
                                  ),
                                  SizedBox(width: 6),
                                  _LegendItem(
                                    color: tBlue.withOpacity(0.9),
                                    label: "Halted",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 330,
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            boxShadow: [
                              BoxShadow(
                                spreadRadius: 2,
                                blurRadius: 10,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.25)
                                        : tBlack.withOpacity(0.15),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(15),
                          child: AlertsChart(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    bool isDark,
    String title,
    String value,
    Gradient cardColor,
  ) {
    return Container(
      width: double.infinity, // fits 2 per row
      decoration: BoxDecoration(
        color: tTransparent,
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? tBlack : tWhite,
              // border: Border.all(width: 0.5, color: isDark ? tWhite : tBlack),
            ),
            child: Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 12,
                color: isDark ? tWhite : tBlack,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          /// Gradient Value Box
          Container(
            height: 78,
            width: double.infinity,
            decoration: BoxDecoration(gradient: cardColor),
            alignment: Alignment.center,
            child: Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 33,
                color: tWhite,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDeviceCard({
    required bool isDark,
    required String vehicleNumber,
    required String status,
    required String imei,
    required String fuel,
    required String odo,
    required String trips,
    required String alerts,
    required String location,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'moving':
        statusColor = tGreen;
        break;
      case 'idle':
        statusColor = tOrange1;
        break;
      case 'stopped':
        statusColor = tRed;
        break;
      case 'disconnected':
        statusColor = tGrey;
        break;
      default:
        statusColor = tBlack;
    }

    return Container(
      width: double.infinity,
      height: 90,
      decoration: BoxDecoration(
        // color: tGrey.withOpacity(0.1),
        color: isDark ? tBlack : tWhite,
        // borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SvgPicture.asset('icons/truck1.svg', width: 80, height: 80),
          Image.asset(
            'images/truck1.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ===== Top Row =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==== Left Side (IMEI + Vehicle + Status) ====
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // IMEI + Vehicle ID Container
                          Flexible(
                            child: Container(
                              width: 350,
                              // constraints: const BoxConstraints(
                              //   minWidth: 200,
                              //   maxWidth: 400,
                              // ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: statusColor,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // IMEI Box
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: SweepGradient(
                                        colors: [
                                          statusColor,
                                          statusColor.withOpacity(0.6),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        bottomLeft: Radius.circular(5),
                                      ),
                                    ),
                                    child: Text(
                                      imei,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: tWhite,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                  // Vehicle ID Text
                                  Expanded(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          vehicleNumber,
                                          style: GoogleFonts.urbanist(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? tWhite : tBlack,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Moving Status Container
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  statusColor,
                                  statusColor.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? tWhite : tBlack,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==== Right Side ====
                    SvgPicture.asset(
                      'icons/immobilize_ON.svg',
                      width: 25,
                      height: 25,
                      color: isDark ? tRed : tGreen,
                    ),
                  ],
                ),

                const SizedBox(height: 2),
                Divider(
                  // color:
                  //     isDark
                  //         ? tWhite.withOpacity(0.4)
                  //         : tBlack.withOpacity(0.4),
                  color: statusColor,
                  thickness: 0.3,
                ),
                const SizedBox(height: 2),

                // ===== Bottom Row (Location) =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: SvgPicture.asset(
                              'icons/geofence.svg',
                              color: statusColor,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Live Location: $location',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: isDark ? tWhite : tBlack,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'DateTime :',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '15:52 PM 04 NOV 2025',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus(bool isDark) {
    return Container(
      height: 225,
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: SpeedDistanceChart(),
    );
  }

  Widget _buildStatusBarChart(bool isDark) {
    final Map<String, Color> statusColors = this.statusColors;

    final Map<String, Map<String, int>> hourlyStatusBreakdown = {
      '12:00 AM': {'moving': 50, 'stopped': 10},
      '01:00 AM': {'idle': 60},
      '02:00 AM': {'moving': 60},
      '03:00 AM': {'moving': 15, 'idle': 45},
      '04:00 AM': {'halted': 60},
      '05:00 AM': {'stopped': 30, 'moving': 30},
      '06:00 AM': {'stopped': 60},
      '07:00 AM': {'idle': 60},
      '08:00 AM': {'moving': 20, 'idle': 20, 'stopped': 20},
      '09:00 AM': {'moving': 45, 'idle': 15},
      '10:00 AM': {'halted': 60},
      '11:00 AM': {'moving': 60},
      '12:00 PM': {'idle': 20, 'halted': 40},
      '01:00 PM': {'moving': 30, 'stopped': 30},
      '02:00 PM': {'moving': 40, 'idle': 10, 'stopped': 10},
      '03:00 PM': {'moving': 25, 'idle': 20, 'stopped': 15},
      '04:00 PM': {'moving': 30, 'idle': 30},
      '05:00 PM': {'moving': 60},
      '06:00 PM': {'idle': 60},
      '07:00 PM': {'stopped': 60},
      '08:00 PM': {'moving': 60},
      '09:00 PM': {'moving': 30, 'idle': 30},
      '10:00 PM': {'stopped': 60},
      '11:00 PM': {'moving': 60},
    };

    // Ensure hours are sorted chronologically
    final hours = hourlyStatusBreakdown.keys.toList();

    // --- ✅ Combine every 2 consecutive hours in normal order ---
    final Map<String, Map<String, int>> mergedData = {};
    for (int i = 0; i < hours.length; i += 2) {
      final hour1 = hours[i];
      final hour2 = (i + 1 < hours.length) ? hours[i + 1] : null;

      // Label like "02:00 PM - 03:00 PM"
      String label = hour2 != null ? "$hour1\n$hour2" : hour1;

      final combined = <String, int>{};

      // Merge hour1 data
      hourlyStatusBreakdown[hour1]!.forEach((k, v) {
        combined[k] = (combined[k] ?? 0) + v;
      });

      // Merge hour2 data if present
      if (hour2 != null) {
        hourlyStatusBreakdown[hour2]!.forEach((k, v) {
          combined[k] = (combined[k] ?? 0) + v;
        });
      }

      mergedData[label] = combined;
    }

    final mergedHours = mergedData.keys.toList();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= mergedHours.length) {
                    return const SizedBox();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      mergedHours[index],
                      style: GoogleFonts.urbanist(
                        fontSize: 8,
                        color: isDark ? tWhite : tBlack,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),

          // Tooltip data (unchanged)
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(10),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (group) => isDark ? tWhite : tBlack,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = mergedHours[group.x.toInt()];
                final data = mergedData[label]!;

                final entries =
                    data.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                final spans = <TextSpan>[
                  TextSpan(
                    text: '$label\n',
                    style: GoogleFonts.urbanist(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? tBlack : tWhite,
                    ),
                  ),
                ];

                for (final e in entries) {
                  spans.add(
                    TextSpan(
                      text: "● ",
                      style: TextStyle(
                        color: statusColors[e.key] ?? Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  );
                  spans.add(
                    TextSpan(
                      text: "${e.key.capitalize()}: ${e.value} min\n",
                      style: GoogleFonts.urbanist(
                        fontSize: 10,
                        color: isDark ? tBlack : tWhite,
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
          ),

          // ✅ Generate merged stacked bars
          barGroups: List.generate(mergedHours.length, (index) {
            final label = mergedHours[index];
            final data = mergedData[label]!;

            double startY = 0.0;
            final totalMins = data.values.fold<int>(0, (sum, v) => sum + v);

            final rods =
                data.entries.map((e) {
                  final color = statusColors[e.key]!.withOpacity(
                    0.9,
                  ); //?? tBlack;
                  final endY = startY + (e.value / totalMins) * 60;
                  final item = BarChartRodStackItem(startY, endY, color);
                  startY = endY;
                  return item;
                }).toList();

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: 60,
                  rodStackItems: rods,
                  width: 15,
                  borderRadius: BorderRadius.circular(0),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget buildVehicleMap({bool isDark = false, double zoom = 14.0}) {
    //Step 1: Ensure valid map data
    if (widget.device == null || widget.device is! Map) {
      return const Center(child: Text("Invalid device data"));
    }

    final deviceLatLngRaw = widget.device['latlng'];
    LatLng? deviceLatLng;

    if (deviceLatLngRaw is LatLng) {
      deviceLatLng = deviceLatLngRaw;
    } else if (deviceLatLngRaw is Map) {
      final lat = deviceLatLngRaw['lat'] ?? deviceLatLngRaw['latitude'];
      final lng = deviceLatLngRaw['lng'] ?? deviceLatLngRaw['longitude'];
      if (lat != null && lng != null) {
        deviceLatLng = LatLng(lat.toDouble(), lng.toDouble());
      }
    }

    if (deviceLatLng == null) {
      return const Center(child: Text("No location data available"));
    }

    final deviceStatus = widget.device['status'] ?? 'unknown';
    final tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    String getTruckIcon(String status) {
      switch (status.toLowerCase()) {
        case 'moving':
          return 'icons/truck1.svg';
        case 'idle':
          return 'icons/truck3.svg';
        case 'stopped':
          return 'icons/truck4.svg';
        case 'disconnected':
          return 'icons/truck5.svg';
        default:
          return 'icons/truck1.svg';
      }
    }

    Color getCircleColor(String status) {
      switch (status.toLowerCase()) {
        case 'moving':
          return tGreen.withOpacity(0.3);
        case 'idle':
          return tOrange1.withOpacity(0.3);
        case 'stopped':
          return tRed.withOpacity(0.3);
        case 'disconnected':
          return tGrey.withOpacity(0.3);
        default:
          return tBlue.withOpacity(0.3);
      }
    }

    final iconPath = getTruckIcon(deviceStatus);
    final circleColor = getCircleColor(deviceStatus);

    // ✅ Step 2: Bounded size for FlutterMap
    return SizedBox(
      height: 300,
      child: FlutterMap(
        key: const ValueKey('vehicle_map_widget'),
        options: MapOptions(
          initialCenter: deviceLatLng,
          initialZoom: zoom,
          maxZoom: 18.0,
          minZoom: 3.0,
        ),
        children: [
          TileLayer(
            urlTemplate: tileUrl,
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          CircleLayer(
            circles: [
              CircleMarker(
                point: deviceLatLng,
                color: circleColor,
                borderStrokeWidth: 1,
                borderColor: circleColor.withOpacity(0.7),
                radius: 125,
                useRadiusInMeter: true,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: deviceLatLng,
                width: 35,
                height: 35,
                child: SvgPicture.asset(iconPath, width: 30, height: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsWidget({bool isDark = false}) {
    // 10 dummy alert entries
    final List<Map<String, String>> alerts = List.generate(10, (index) {
      final alertTypes = [
        'Power Disconnect',
        'GPRS Lost',
        'Over Speed',
        'Ignition On',
        'Ignition Off',
        'Geo Fence Alert',
        'Battery Low',
        'Tilt Alert',
        'Fall Detected',
        'SOS Triggered',
      ];

      return {
        'vehicleId': 'VHC-${1000 + index}',
        'imei': 'IMEI-${8900000 + index}',
        'dateTime': '26 Oct 2025, ${10 + index}:15:30',
        'alertType': alertTypes[index % alertTypes.length],
      };
    });

    Color getAlertColor(String type) {
      if (type.contains('Disconnect') || type.contains('Lost')) return tRed;
      if (type.contains('Low') || type.contains('Fall')) return tOrange1;
      if (type.contains('Speed')) return Colors.amber;
      if (type.contains('Ignition')) return tBlue;
      if (type.contains('Geo') || type.contains('Tilt')) return Colors.purple;
      if (type.contains('SOS')) return Colors.redAccent;
      return tGrey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...alerts.map((alert) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? tBlack : tWhite,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 1,
                    blurRadius: 6,
                    color:
                        isDark
                            ? tWhite.withOpacity(0.1)
                            : tBlack.withOpacity(0.1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Vehicle ID + IMEI
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle: ${alert['vehicleId']}',
                        style: GoogleFonts.urbanist(
                          color: isDark ? tWhite : tBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'IMEI: ${alert['imei']}',
                        style: GoogleFonts.urbanist(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  /// Date + Alert type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        alert['dateTime']!,
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getAlertColor(
                            alert['alertType']!,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alert['alertType']!,
                          style: GoogleFonts.urbanist(
                            color: getAlertColor(alert['alertType']!),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTripsTable(bool isDark) {
    const int rowsPerPage = 10;

    final List<Map<String, dynamic>> trips = [
      {
        "start": "2025-01-01 08:12",
        "end": "2025-01-01 08:55",
        "duration": "43 mins",
        "distance": "12.4 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-02 10:05",
        "end": "2025-01-02 10:37",
        "duration": "32 mins",
        "distance": "9.2 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-03 14:22",
        "end": "2025-01-03 14:58",
        "duration": "36 mins",
        "distance": "11.1 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-04 09:10",
        "end": "2025-01-04 09:50",
        "duration": "40 mins",
        "distance": "13.6 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-05 16:00",
        "end": "2025-01-05 16:45",
        "duration": "45 mins",
        "distance": "14.8 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-06 11:22",
        "end": "2025-01-06 11:55",
        "duration": "33 mins",
        "distance": "10.5 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-07 13:08",
        "end": "2025-01-07 13:48",
        "duration": "40 mins",
        "distance": "12.1 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-08 07:45",
        "end": "2025-01-08 08:20",
        "duration": "35 mins",
        "distance": "9.9 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-09 18:01",
        "end": "2025-01-09 18:40",
        "duration": "39 mins",
        "distance": "13.3 km",
        "status": "Completed",
      },
      {
        "start": "2025-01-10 12:26",
        "end": "2025-01-10 13:05",
        "duration": "39 mins",
        "distance": "12.0 km",
        "status": "Completed",
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        Color getStatusColor(String status) {
          return status == "Completed" ? tBlue : tGreen;
        }

        return Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ],
          ),
          child: Column(
            children: [
              // Scrollable Area
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 4,
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
                            DataColumn(label: Text("Start Date")),
                            DataColumn(label: Text("End Date")),
                            DataColumn(label: Text("Duration")),
                            DataColumn(label: Text("Distance")),
                            DataColumn(label: Text("Trip Status")),
                          ],
                          rows:
                              trips.map((trip) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(trip["start"])),
                                    DataCell(Text(trip["end"])),
                                    DataCell(Text(trip["duration"])),
                                    DataCell(Text(trip["distance"])),

                                    // Status badge
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(
                                            trip["status"],
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          trip["status"],
                                          style: GoogleFonts.urbanist(
                                            color: getStatusColor(
                                              trip["status"],
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // No pagination required unless you need it later
            ],
          ),
        );
      },
    );
  }

  Widget buildAlertsTable(bool isDark) {
    // Dummy alerts data
    // final List<Map<String, String>> alerts = List.generate(10, (index) {
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

    //   return {
    //     'dateTime': '26 Oct 2025, ${10 + index}:15:30',
    //     'alertType': alertTypes[index % alertTypes.length],
    //   };
    // });

    final List<Map<String, dynamic>> alerts = recentAlerts;

    Color getAlertColor(String type) {
      if (type.contains('Disconnect') || type.contains('Lost')) return tRed;
      if (type.contains('Low') || type.contains('Fall')) return tOrange1;
      if (type.contains('Speed')) return Colors.amber;
      if (type.contains('Ignition')) return tBlue;
      if (type.contains('Geo') || type.contains('Tilt')) return Colors.purple;
      if (type.contains('SOS')) return Colors.redAccent;
      return tGrey;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        return Container(
          width: maxWidth,
          height: maxHeight,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? tBlack : tWhite,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: isDark ? Colors.white24 : Colors.black12,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 4,
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
                          columnSpacing: 40,
                          border: TableBorder.all(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.1)
                                    : tBlack.withOpacity(0.1),
                            width: 0.4,
                          ),
                          dividerThickness: 0.01,

                          /// TWO COLUMNS ONLY
                          columns: const [
                            DataColumn(label: Text("Date & Time")),
                            DataColumn(label: Text("Alert Type")),
                          ],

                          rows:
                              alerts.map((alert) {
                                final color = getAlertColor(
                                  alert["alertType"] ?? "",
                                );

                                return DataRow(
                                  cells: [
                                    DataCell(Text(alert["dateTime"] ?? "--")),

                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          alert["alertType"] ?? "--",
                                          style: GoogleFonts.urbanist(
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                    DataCell(Text(alert["data"] ?? "--")),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension StringCasing on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
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
            fontSize: 11,
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
