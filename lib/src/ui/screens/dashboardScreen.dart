import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../provider/fleetModeProvider.dart';
import '../../services/apiServices.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../components/largeHoverCard.dart';
import '../components/smallHoverCard.dart';
import '../components/vehicleStatusLabelHover.dart';
import '../widgets/charts/alertDoughnutChart.dart';
import '../widgets/charts/alertsChart.dart';
import '../widgets/charts/evBatteriesDistributionProgressBar.dart';
import '../widgets/charts/tripsChart.dart';
import '../widgets/charts/vehicleUtilizationChart.dart';
import '../widgets/components/customTitleBar.dart';

class Group {
  final String id;
  final String name;

  Group({required this.id, required this.name});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(id: json['id'], name: json['name']);
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime selectedDate = DateTime.now();
  List<Group> groupsList = [];
  String? selectedGroup;
  String get dateParam => selectedDate.toUtc().toIso8601String();
  bool isLoadingGroups = false;

  Future<void> fetchGroups() async {
    setState(() => isLoadingGroups = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final uri = Uri.parse(BaseURLConfig.Groups);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        final List entities = body['entities'] ?? [];

        groupsList =
            entities.map((item) => Group.fromJson(item)).toList().cast<Group>();

        setState(() {});
      } else {
        debugPrint('Groups API failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Groups API error: $e');
    } finally {
      setState(() => isLoadingGroups = false);
    }
  }

  Map<String, dynamic>? dashboardData;
  bool isDashboardLoading = false;
  int totalVehicles = 0;
  int etotalvehicles = 0;

  int moving = 0;
  int idle = 0;
  int stopped = 0;
  int nonCoverage = 0;
  int disconnected = 0;
  int charging = 0;
  int discharging = 0;
  int batteryIdle = 0;
  int batteryDisconnected = 0;

  int activeVehicles = 0;
  int inactiveVehicles = 0;
  int evActive = 0;

  Future<void> fetchDashboardData() async {
    setState(() => isDashboardLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final res = await http.get(
      Uri.parse(
        "${BaseURLConfig.dashboardApiUrl}?groups=${selectedGroup ?? ""}&date=$dateParam",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final batteryLabels = List<String>.from(data["battery_status"]["labels"]);
      final batteryData = List<int>.from(data["battery_status"]["data"]);
      final labels = List<String>.from(data["vehicle_status"]["labels"]);
      final values = List<int>.from(data["vehicle_status"]["data"]);

      moving = values[labels.indexOf("Moving")];
      idle = values[labels.indexOf("Idle")];
      stopped = values[labels.indexOf("Stopped")];
      nonCoverage = values[labels.indexOf("Non Coverage")];
      disconnected = values[labels.indexOf("Disconnected")];

      charging = batteryData[batteryLabels.indexOf("Charging")];
      discharging = batteryData[batteryLabels.indexOf("DisCharging")];
      batteryIdle = batteryData[batteryLabels.indexOf("Battery Idle")];
      batteryDisconnected = batteryData[batteryLabels.indexOf("Disconnected")];
      activeVehicles = moving + idle + stopped + disconnected;
      inactiveVehicles = nonCoverage;
      evActive = charging + discharging + batteryIdle + batteryDisconnected;
      totalVehicles = activeVehicles + inactiveVehicles;
      etotalvehicles = evActive + inactiveVehicles;
      setState(() {
        dashboardData = data;
      });
    }

    setState(() => isDashboardLoading = false);
  }

  List<Map<String, dynamic>> getBackendStatus() {
    if (activeVehicles == 0) return [];

    return [
      {
        'label': 'Moving',
        'color': tGreen,
        'count': moving,
        'percent': (moving / activeVehicles) * 100,
      },
      {
        'label': 'stopped',
        'color': tRed,
        'count': stopped,
        'percent': (stopped / activeVehicles) * 100,
      },
      {
        'label': 'Idle',
        'color': tOrange1,
        'count': idle,
        'percent': (idle / activeVehicles) * 100,
      },
      {
        'label': 'Disconnected',
        'color': tGrey,
        'count': disconnected,
        'percent': (disconnected / activeVehicles) * 100,
      },
    ];
  }

  List<Map<String, dynamic>> getEVBackendStatus() {
    if (evActive == 0) return [];

    return [
      {
        'label': 'Charging',
        'color': tGreen,
        'count': charging,
        'percent': (charging / evActive) * 100,
      },
      {
        'label': 'Discharging',
        'color': tBlue,
        'count': discharging,
        'percent': (discharging / evActive) * 100,
      },
      {
        'label': 'Idle',
        'color': tOrange1,
        'count': batteryIdle,
        'percent': (batteryIdle / evActive) * 100,
      },
      {
        'label': 'Disconnected',
        'color': tGrey,
        'count': batteryDisconnected,
        'percent': (batteryDisconnected / evActive) * 100,
      },
    ];
  }

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
          "groups":
              selectedGroup ??
              "", // you can pass selectedGroup if backend supports
          "seriesName": "Vehicle Alerts",
          "title": "Vehicle Alerts",
          "page": "1",
          "sizePerPage": "10",
          "currentIndex": "0",
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

          final List entities = data["entities"] ?? [];

          recentAlerts =
              entities.map<Map<String, dynamic>>((a) {
                return {
                  "vehicleId": (a["vehicleNumber"] ?? '').toString(),
                  "imei": (a["imei"] ?? '').toString(),
                  "alertType": (a["alertType"] ?? '').toString(),
                  "data": (a["data"] ?? '').toString(),
                  "dateTime": formatAlertDate(a["time"]),
                };
              }).toList();
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

  int tripsTotalCount = 0;
  List<Map<String, dynamic>> trips = [];

  Future<void> fetchTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';
    final uri = Uri.parse(
      "${BaseURLConfig.tripApiUrl}"
      "&groups=${selectedGroup ?? ""}",
    );

    final response = await http.get(
      uri,
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        tripsTotalCount = data["totalCount"] ?? 0; // 👈 THIS IS TOTAL TRIPS
        trips = data["entities"] ?? [];
      });
    } else {
      print("Trips API Error: ${response.body}");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGroups().then((_) {
      fetchDashboardData();
      fetchRecentAlerts();
      fetchTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(isDark),
          const SizedBox(height: 15),
          _buildGroupSelector(isDark),
          const SizedBox(height: 6),
          _buildDateSelector(isDark),
          const SizedBox(height: 15),

          // Scrollable content (no Expanded inside)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Left Vehicle Summary
                  Container(
                    width: double.infinity,
                    height: 210,
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
                    child: Column(
                      children: [
                        _buildVehicleHeaderSection(isDark),
                        const SizedBox(height: 5),
                        Divider(
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.6)
                                  : tBlack.withOpacity(0.6),
                          thickness: 0.6,
                        ),
                        const SizedBox(height: 5),
                        _buildVehicleBottomSection(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Right Vehicle Status Progress
                  Container(
                    width: double.infinity,
                    height: 210,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle Status',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            color: isDark ? tWhite : tBlack,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 15),
                        mode == "EV Fleet"
                            ? _buildMobileDynamicStatusBar(getEVBackendStatus())
                            : _buildMobileDynamicStatusBar(getBackendStatus()),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  // Alerts Summary
                  Container(
                    width: double.infinity,
                    height: 210,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAlertsHeaderSection(isDark),
                        const SizedBox(height: 5),
                        Divider(
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.6)
                                  : tBlack.withOpacity(0.6),
                          thickness: 0.6,
                        ),
                        const SizedBox(height: 5),
                        _buildAlertsBottomSection(),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    height: 250,
                    width: double.infinity,
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
                    child: SingleChildScrollView(
                      child: buildAlertsWidget(isDark: isDark),
                    ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    height: 325,
                    width: double.infinity,
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
                    child: buildVehicleMap(isDark: isDark, zoom: 14),
                  ),
                  SizedBox(height: 15),
                  Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTripsHeaderSection(isDark),
                        const SizedBox(height: 5),
                        Divider(
                          color:
                              isDark
                                  ? tWhite.withOpacity(0.6)
                                  : tBlack.withOpacity(0.6),
                          thickness: 0.6,
                        ),
                        const SizedBox(height: 5),
                        _buildTripsBottomSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTitle(isDark),
              Row(
                children: [
                  _buildGroupSelector(isDark),
                  const SizedBox(width: 10),
                  _buildDateSelector(isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Left Vehicle Summary
              Container(
                width: MediaQuery.of(context).size.width * 0.35,
                height: 210,
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
                child: Column(
                  children: [
                    _buildVehicleHeaderSection(isDark),
                    const SizedBox(height: 5),
                    Divider(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.6)
                              : tBlack.withOpacity(0.6),
                      thickness: 0.6,
                    ),
                    const SizedBox(height: 5),
                    _buildVehicleBottomSection(),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right Vehicle Status Progress
              Expanded(
                child: Container(
                  width: double.infinity,
                  height: 210,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Status',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          color: isDark ? tWhite : tBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: _buildMobileDynamicStatusBar(getBackendStatus()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            height: 325,
            width: double.infinity,
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
            padding: const EdgeInsets.all(5),
            child: buildVehicleMap(isDark: isDark, zoom: 14),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.35,
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
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAlertsHeaderSection(isDark),
                    const SizedBox(height: 5),
                    Divider(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.6)
                              : tBlack.withOpacity(0.6),
                      thickness: 0.6,
                    ),
                    const SizedBox(height: 5),
                    _buildAlertsBottomSection(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 225,
                  width: double.infinity,
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
                  child: SingleChildScrollView(
                    child: buildAlertsWidget(isDark: isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // _buildTitle(isDark),
            FleetTitleBar(isDark: isDark, title: "Dashboard"),

            Row(
              children: [
                _buildGroupSelector(isDark),
                const SizedBox(width: 10),
                _buildDateSelector(isDark),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      /// 🔹 Total Vehicles Main Card
                      GestureDetector(
                        onTap: () {
                          context.go('/home/devices');
                        },
                        child: LargeHoverCard(
                          value:
                              mode == 'EV Fleet'
                                  ? '$etotalvehicles'
                                  : "$totalVehicles",
                          label: "Vehicles",
                          labelColor: tBlue,
                          icon: "icons/car.svg",
                          iconColor: tBlue,
                          bgColor: tBlue.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            SmallHoverCard(
                              width: double.infinity,
                              height: 87,
                              value:
                                  mode == 'EV Fleet'
                                      ? "$evActive"
                                      : "$activeVehicles",
                              label: "Active Vehicles",
                              labelColor: tGreen,
                              icon: "icons/car.svg",
                              iconColor: tGreen,
                              bgColor: tGreen.withOpacity(0.1),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 11),
                            SmallHoverCard(
                              width: double.infinity,
                              height: 87,
                              value: "$inactiveVehicles",
                              label: "Inactive Vehicles",
                              labelColor: tRed,
                              icon: "icons/car.svg",
                              iconColor: tRed,
                              bgColor: tRed.withOpacity(0.1),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),

                      /// 🔹 Middle: Vehicle Status Bars
                      Expanded(
                        flex: 8,
                        child: Container(
                          height: 185,
                          decoration: BoxDecoration(
                            color: isDark ? tBlack : tWhite,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 12,
                                spreadRadius: 2,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.12)
                                        : tBlack.withOpacity(0.1),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.only(
                            left: 15,
                            right: 15,
                            top: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode == 'EV Fleet'
                                    ? 'EV Vehicle Status'
                                    : 'Vehicle Status',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  color: isDark ? tWhite : tBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),
                              mode == "EV Fleet"
                                  ? _buildMobileDynamicStatusBar(
                                    getEVBackendStatus(),
                                  )
                                  : _buildMobileDynamicStatusBar(
                                    getBackendStatus(),
                                  ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      GestureDetector(
                        onTap: () {
                          context.go('/home/trips');
                        },
                        child: LargeHoverCard(
                          value: tripsTotalCount.toString(),
                          label: "Trips",
                          labelColor: tGreen,
                          icon: "icons/distance.svg",
                          iconColor: tGreen,
                          bgColor: tGreen.withOpacity(0.1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  if (mode == "EV Fleet") ...[
                    const SizedBox(height: 10),
                    Text(
                      'Batteries Status',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: isDark ? tWhite : tBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
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
                      child: BatteryProgressBar(
                        counts: [12, 25, 40, 8],
                        showLabels: true,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // LEFT SIDE (Flex 8)
                      Expanded(
                        flex: 8,
                        child: Column(
                          children: [
                            // --------------------- ALERTS OVERVIEW ---------------------
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: tTransparent,
                                // boxShadow: [
                                //   BoxShadow(
                                //     blurRadius: 12,
                                //     spreadRadius: 2,
                                //     color:
                                //         isDark
                                //             ? tWhite.withOpacity(0.12)
                                //             : tBlack.withOpacity(0.1),
                                //   ),
                                // ],
                              ),
                              // padding: EdgeInsets.all(10),
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
                                      Expanded(
                                        child: Column(
                                          children: [
                                            // ---------------- FIRST ROW (Large Cards) ----------------
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      context.go(
                                                        '/home/alerts',
                                                      );
                                                    },
                                                    child: LargeHoverCard(
                                                      value:
                                                          alertsTotalCount
                                                              .toString(),
                                                      label: "Alerts",
                                                      labelColor: tRed,
                                                      icon: "icons/alert.svg",
                                                      iconColor: tRed,
                                                      bgColor: tRed.withOpacity(
                                                        0.1,
                                                      ),
                                                      isDark: isDark,
                                                      height: 185,
                                                    ),
                                                  ),
                                                ),

                                                SizedBox(width: 10),

                                                Expanded(
                                                  child: LargeHoverCard(
                                                    value: "--",
                                                    label: "Faults",
                                                    labelColor: tPink,
                                                    icon: "icons/flagged.svg",
                                                    iconColor: tPink,
                                                    bgColor: tPink.withOpacity(
                                                      0.1,
                                                    ),
                                                    isDark: isDark,
                                                    height: 185,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            SizedBox(height: 10),

                                            // ---------------- SECOND ROW (Small Cards) ----------------
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: SmallHoverCard(
                                                    height: 74,
                                                    value: "--",
                                                    label:
                                                        "Non-Critical Alerts",
                                                    labelColor: tBlueSky,
                                                    icon: "icons/alert.svg",
                                                    iconColor: tBlueSky,
                                                    bgColor: tBlueSky
                                                        .withOpacity(0.1),
                                                    isDark: isDark,
                                                  ),
                                                ),

                                                SizedBox(width: 10),

                                                Expanded(
                                                  child: SmallHoverCard(
                                                    height: 74,
                                                    value: "--",
                                                    label: "Critical Alerts",
                                                    labelColor: tOrange1,
                                                    icon: "icons/alert.svg",
                                                    iconColor: tOrange1,
                                                    bgColor: tOrange1
                                                        .withOpacity(0.1),
                                                    isDark: isDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(width: 10),

                                      // ---------------- DONUT CHART CONTAINER ----------------
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          height: 270,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isDark ? tBlack : tWhite,
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                                color:
                                                    isDark
                                                        ? tWhite.withOpacity(
                                                          0.12,
                                                        )
                                                        : tBlack.withOpacity(
                                                          0.08,
                                                        ),
                                              ),
                                            ],
                                          ),
                                          child: AlertsDonutChart(
                                            critical: 40,
                                            nonCritical: 60,
                                            avgCritical: 35,
                                            avgNonCritical: 55,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 10),

                            // --------------------- TRIPS OVERVIEW ---------------------
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: tTransparent,
                                // color: isDark ? tBlack : tWhite,
                                // boxShadow: [
                                //   BoxShadow(
                                //     blurRadius: 12,
                                //     spreadRadius: 2,
                                //     color:
                                //         isDark
                                //             ? tWhite.withOpacity(0.12)
                                //             : tBlack.withOpacity(0.1),
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
                                  SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          children: [
                                            SmallHoverCard(
                                              width: double.infinity,
                                              height: 75,
                                              value: "--",
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
                                              height: 75,
                                              value: "--",
                                              label: "Ongoing Trips",
                                              labelColor: tOrange1,
                                              icon: "icons/ongoing.svg",
                                              iconColor: tOrange1,
                                              bgColor: tOrange1.withOpacity(
                                                0.1,
                                              ),
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
                                              height: 75,
                                              value: "--",
                                              label: "Avg. Trips",
                                              labelColor: tBlueSky,
                                              icon: "icons/distance.svg",
                                              iconColor: tBlueSky,
                                              bgColor: tBlueSky.withOpacity(
                                                0.1,
                                              ),
                                              isDark: isDark,
                                            ),
                                            const SizedBox(height: 10),

                                            mode == 'EV Fleet'
                                                ? SmallHoverCard(
                                                  width: double.infinity,
                                                  height: 75,
                                                  value: "--",
                                                  label: "Consumed Energy",
                                                  labelColor: tBlue1,
                                                  icon: "icons/battery.svg",
                                                  iconColor: tBlue1,
                                                  bgColor: tBlue1.withOpacity(
                                                    0.1,
                                                  ),
                                                  isDark: isDark,
                                                )
                                                : SmallHoverCard(
                                                  width: double.infinity,
                                                  height: 75,
                                                  value: "--",
                                                  label: "Consumed Fuel(L)",
                                                  labelColor: tRed,
                                                  icon: "icons/fuel.svg",
                                                  iconColor: tRed,
                                                  bgColor: tRed.withOpacity(
                                                    0.1,
                                                  ),
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
                                              height: 75,
                                              value: "--",
                                              label: "Total Distance(km)",
                                              labelColor: tGreenDark,
                                              icon: "icons/distance.svg",
                                              iconColor: tGreenDark,
                                              bgColor: tGreenDark.withOpacity(
                                                0.1,
                                              ),
                                              isDark: isDark,
                                            ),
                                            const SizedBox(height: 10),
                                            SmallHoverCard(
                                              width: double.infinity,
                                              height: 75,
                                              value: "--",
                                              label: "Total Oper. Hours(hrs)",
                                              labelColor: tPink,
                                              icon: "icons/consumedhours.svg",
                                              iconColor: tPink,
                                              bgColor: tPink.withOpacity(0.1),
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
                                              height: 75,
                                              value: "--",
                                              label: "Today's Distance(km)",
                                              labelColor: tGreen,
                                              icon: "icons/distance.svg",
                                              iconColor: tGreen,
                                              bgColor: tGreen.withOpacity(0.1),
                                              isDark: isDark,
                                            ),
                                            const SizedBox(height: 10),
                                            SmallHoverCard(
                                              width: double.infinity,
                                              height: 75,
                                              value: "--",
                                              label: "Today's Oper. Hours(hrs)",
                                              labelColor: Colors.purpleAccent,
                                              icon: "icons/consumedhours.svg",
                                              iconColor: Colors.purpleAccent,
                                              bgColor: Colors.purpleAccent
                                                  .withOpacity(0.1),
                                              isDark: isDark,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 10),

                      // RIGHT SIDE (Flex 4) → MERGED MAP CONTAINER
                      // Expanded(
                      //   flex: 4,
                      //   child: Container(
                      //     height:
                      //         530, // 300 + 10 + 220 merged height (you can adjust)
                      //     decoration: BoxDecoration(
                      //       color: isDark ? tBlack : tWhite,
                      //       boxShadow: [
                      //         BoxShadow(
                      //           blurRadius: 12,
                      //           spreadRadius: 2,
                      //           color:
                      //               isDark
                      //                   ? tWhite.withOpacity(0.12)
                      //                   : tBlack.withOpacity(0.1),
                      //         ),
                      //       ],
                      //     ),
                      //     padding: EdgeInsets.all(2),
                      //     child: buildVehicleMap(isDark: isDark, zoom: 5),
                      //   ),
                      // ),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 510,
                          decoration: BoxDecoration(
                            color: tTransparent,
                            // color: isDark ? tBlack : tWhite,
                            // boxShadow: [
                            //   BoxShadow(
                            //     blurRadius: 12,
                            //     spreadRadius: 2,
                            //     color:
                            //         isDark
                            //             ? tWhite.withOpacity(0.12)
                            //             : tBlack.withOpacity(0.1),
                            //   ),
                            // ],
                          ),
                          // padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Alerts',
                                style: GoogleFonts.urbanist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? tWhite : tBlack,
                                ),
                              ),

                              const SizedBox(height: 10),

                              /// Scrollable content must be wrapped in Expanded
                              Expanded(child: buildAlertsTable(isDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 325,
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
                        flex: 4,
                        child: Container(
                          height: 325,
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
                          child: VehicleUtilizationChart(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Container(
                          height: 325,
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

  Widget _buildTitle(bool isDark) => Text(
    'Dashboard',
    style: GoogleFonts.urbanist(
      fontSize: 20,
      color: isDark ? tWhite : tBlack,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _buildGroupSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabelBox("Group Name", tBlue, isDark),
            const SizedBox(width: 5),
            _buildDynamicDropdown(isDark),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '(Note: Filter by Group Name)',
          style: GoogleFonts.urbanist(
            fontSize: 10,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabelBox("Date", tBlue, isDark),
            const SizedBox(width: 5),
            _buildDynamicDatePicker(isDark),
          ],
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

  Widget _buildLabelBox(String text, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(width: 0.5, color: isDark ? tWhite : tBlack),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDynamicDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(width: 0.6, color: isDark ? tWhite : tBlack),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: false,
          hint: Text(
            'Select Group',
            style: GoogleFonts.urbanist(fontSize: 12.5, color: tGrey),
          ),

          items:
              groupsList
                  .map(
                    (group) => DropdownMenuItem<String>(
                      value: group.id, // storing id as value
                      child: Text(
                        group.name, // showing name
                        style: GoogleFonts.urbanist(
                          fontSize: 12.5,
                          color: isDark ? tWhite : tBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),

          value: selectedGroup, // must be id or null

          onChanged: (value) {
            setState(() {
              selectedGroup = value; // value is id here
            });
            fetchDashboardData(); // Refresh dashboard data on group change
            fetchRecentAlerts();
            fetchTrips();
          },

          iconStyleData: IconStyleData(
            icon: Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: isDark ? tWhite : tBlack,
            ),
          ),

          dropdownStyleData: DropdownStyleData(
            padding: EdgeInsets.zero,
            maxHeight: 200,
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
          ),

          buttonStyleData: const ButtonStyleData(
            padding: EdgeInsets.zero,
            height: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicDatePicker(bool isDark) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tTransparent,
          border: Border.all(width: 0.6, color: isDark ? tWhite : tBlack),
        ),
        child: Text(
          DateFormat('dd MMM yyyy').format(selectedDate).toUpperCase(),
          style: GoogleFonts.urbanist(
            fontSize: 12.5,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

  Widget _buildVehicleHeaderSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTotalVehiclesInfo(isDark),
        _buildIconCircle('icons/vehicle1.svg', tBlue),
      ],
    );
  }

  Widget _buildAlertsHeaderSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTotalAlertsInfo(isDark),
        _buildIconCircle('icons/alerts.svg', tRedDark),
      ],
    );
  }

  Widget _buildTripsHeaderSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTotalTripsInfo(isDark),
        _buildIconCircle('icons/trip.svg', tPink2),
      ],
    );
  }

  Widget _buildTotalVehiclesInfo(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicles',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              mode == 'EV Fleet' ? '$etotalvehicles' : '$totalVehicles',
              style: GoogleFonts.urbanist(
                fontSize: 35,
                color: isDark ? tWhite : tBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
            Positioned(
              right: -60,
              bottom: 8,
              child: Row(
                children: [
                  Text(
                    '3.48%',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: tGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    decoration: BoxDecoration(
                      color: tGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    child: Icon(
                      Icons.arrow_upward_outlined,
                      size: 14,
                      color: tGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalAlertsInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          alertsTotalCount.toString(),
          style: GoogleFonts.urbanist(
            fontSize: 35,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalTripsInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trips',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          tripsTotalCount.toString(),
          style: GoogleFonts.urbanist(
            fontSize: 35,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIconCircle(String iconPath, Color color) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      // color: color.withOpacity(0.25),
      gradient: SweepGradient(
        colors: [color.withOpacity(0.6), color.withOpacity(0.2)],
        // startAngle: 3.14 * 1.25,
        // endAngle: 3.14 * 2.25,
      ),
      shape: BoxShape.circle,
    ),
    padding: const EdgeInsets.all(15),
    child: SvgPicture.asset(iconPath, width: 30, height: 30, color: color),
  );

  Widget _buildVehicleBottomSection() {
    final mode = context.watch<FleetModeProvider>().mode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildVehicleValuesColumn(
          iconPath: 'icons/vehicle1.svg',
          iconColor: tGreen,
          title: 'Active Vehicles',
          value: mode == 'EV Fleet' ? '$evActive' : '$activeVehicles',
          percentage:
              mode == 'EV Fleet'
                  ? '${((evActive / totalVehicles) * 100).toStringAsFixed(1)}%'
                  : '${((activeVehicles / totalVehicles) * 100).toStringAsFixed(1)}%',
        ),
        _buildVehicleValuesColumn(
          iconPath: 'icons/vehicle1.svg',
          iconColor: tRedDark,
          title: 'Inactive Vehicles',
          value: '$inactiveVehicles',
          percentage:
              '${((inactiveVehicles / totalVehicles) * 100).toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildAlertsBottomSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildAnyValuesColumn(
          iconPath: 'icons/alerts.svg',
          iconColor: tRedDark,
          title: 'Crtitical',
          value: '--',
        ),
        _buildAnyValuesColumn(
          iconPath: 'icons/alerts.svg',
          iconColor: tBlue1,
          title: 'Non-Critical',
          value: '--',
        ),
        _buildAnyValuesColumn(
          iconPath: 'icons/flagged.svg',
          iconColor: tRedDark,
          title: 'Faults',
          value: '--',
        ),
      ],
    );
  }

  Widget _buildTripsBottomSection() {
    final List<Map<String, dynamic>> tripStats = [
      {
        'iconPath': 'icons/completed.svg',
        'iconColor': tBlue,
        'title': 'Completed Trips',
        'value': '--',
      },
      {
        'iconPath': 'icons/ongoing.svg',
        'iconColor': tOrange1,
        'title': 'Ongoing Trips',
        'value': '--',
      },
      {
        'iconPath': 'icons/distance.svg',
        'iconColor': tGreen,
        'title': 'Distance Covered (km)',
        'value': '--',
      },
      {
        'iconPath': 'icons/consumedhours.svg',
        'iconColor': tPink,
        'title': 'Consumed Hours',
        'value': '--',
      },
    ];

    List<Widget> rows = [];
    for (int i = 0; i < tripStats.length; i += 2) {
      final first = tripStats[i];
      final second = (i + 1 < tripStats.length) ? tripStats[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              // First item
              Expanded(
                child: _buildAnyValuesColumn(
                  iconPath: first['iconPath'],
                  iconColor: first['iconColor'],
                  title: first['title'],
                  value: first['value'],
                ),
              ),

              const SizedBox(width: 25),

              // Second item (if exists)
              Expanded(
                child:
                    second != null
                        ? _buildAnyValuesColumn(
                          iconPath: second['iconPath'],
                          iconColor: second['iconColor'],
                          title: second['title'],
                          value: second['value'],
                        )
                        : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildVehicleValuesColumn({
    required String iconPath,
    required Color iconColor,
    required String title,
    required String value,
    required String percentage,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(iconPath, width: 25, height: 25, color: iconColor),
            const SizedBox(width: 5),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$value ',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: '($percentage)',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: iconColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAnyValuesColumn({
    required String iconPath,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(iconPath, width: 25, height: 25, color: iconColor),
            const SizedBox(width: 5),
            Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: isDark ? tWhite : tBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: isDark ? tWhite : tBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicStatusBar(List<Map<String, dynamic>> statuses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;
    final total = mode == 'EV Fleet' ? evActive : activeVehicles;
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        double currentStart = 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======= LABELS ALIGNED TO BAR SEGMENTS =======
            SizedBox(
              height: 100, // enough vertical room for 2 label lines
              width: totalWidth,
              child: Stack(
                children:
                    statuses.asMap().entries.map((entry) {
                      final status = entry.value;

                      final count = status['count'] as int;
                      final color = status['color'] as Color;
                      final label = status['label'] as String;
                      final percent = status['percent'] as double;
                      final fraction = total > 0 ? count / total : 0.0;
                      final startX = currentStart;
                      currentStart += fraction;

                      // --- Calculate label width & overflow guard ---
                      const estimatedLabelWidth =
                          100.0; // rough label width estimate
                      double leftPos = totalWidth * startX;
                      if (leftPos + estimatedLabelWidth > totalWidth) {
                        // shift inside container
                        leftPos = totalWidth - estimatedLabelWidth - 5;
                      }

                      return Positioned(
                        left: leftPos,
                        top: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusLabel(
                              label: label,
                              color: color,
                              isDark: isDark,
                              onTap: () {
                                context.go(
                                  '/home/devices?status=${label.toLowerCase()}',
                                );
                              },
                            ),

                            const SizedBox(height: 10),
                            Text(
                              '${percent.toStringAsFixed(1)}%',
                              style: GoogleFonts.urbanist(
                                fontSize: 20,
                                color: isDark ? tWhite : tBlack,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '$count',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                color: isDark ? tWhite : tBlack,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 10),

            // ======= PROGRESS BAR =======
            Stack(
              children: [
                // background
                Container(
                  width: totalWidth,
                  height: 25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color:
                        isDark
                            ? tWhite.withOpacity(0.1)
                            : tBlack.withOpacity(0.05),
                  ),
                ),

                // colored segments
                Row(
                  children:
                      statuses.map((status) {
                        final count = status['count'] as int;
                        final color = status['color'] as Color;
                        final fraction = total > 0 ? count / total : 0.0;
                        return Container(
                          width: totalWidth * fraction,
                          height: 25,
                          color: color,
                        );
                      }).toList(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileDynamicStatusBar(List<Map<String, dynamic>> statuses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = context.watch<FleetModeProvider>().mode;
    final total = mode == 'EV Fleet' ? evActive : activeVehicles;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        double currentStart = 0.0;

        return SizedBox(
          width: totalWidth,
          height: 120, // enough space for top/bottom labels + bar + connector
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ======= PROGRESS BAR BACKGROUND =======
              Positioned(
                top: 50,
                child: Container(
                  width: totalWidth,
                  height: 25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color:
                        isDark
                            ? tWhite.withOpacity(0.1)
                            : tBlack.withOpacity(0.05),
                  ),
                ),
              ),

              // ======= PROGRESS BAR SEGMENTS =======
              Positioned(
                top: 50,
                child: Row(
                  children:
                      statuses.map((status) {
                        final count = status['count'] as int;
                        final color = status['color'] as Color;
                        final fraction = total > 0 ? count / total : 0.0;
                        final segmentWidth = totalWidth * fraction;

                        return Container(
                          width: segmentWidth,
                          height: 25,
                          color: color,
                        );
                      }).toList(),
                ),
              ),

              // ======= LABELS AND CONNECTOR LINES =======
              ...statuses.map((status) {
                final index = statuses.indexOf(status);

                final count = status['count'] as int;
                final color = status['color'] as Color;
                final label = status['label'] as String;
                final percent = status['percent'] as double;
                final fraction = total > 0 ? count / total : 0.0;
                if (count == 0) return const SizedBox.shrink();

                final segmentStart = currentStart;
                final segmentEnd = currentStart + fraction;
                final segmentCenter =
                    segmentStart + fraction / 2; // center of segment
                currentStart = segmentEnd;

                // Determine if label is top or bottom
                final isTop = index % 2 == 0;

                // Horizontal position: label centered over segment
                const estimatedLabelWidth = 100.0;
                double leftPos =
                    totalWidth * segmentCenter - estimatedLabelWidth / 2;

                // Clamp to container edges
                if (leftPos < 0) leftPos = 0;
                if (leftPos + estimatedLabelWidth > totalWidth) {
                  leftPos = totalWidth - estimatedLabelWidth - 5;
                }

                // Vertical positions
                final barTop = 50.0;
                final barHeight = 25.0;
                final verticalOffset = isTop ? 0.0 : barTop + barHeight + 10;

                // Connector line: always from segment end
                final lineX = totalWidth * segmentEnd;
                final lineTop =
                    isTop ? verticalOffset + 30 : barTop + barHeight;
                final lineHeight =
                    isTop
                        ? barTop - (verticalOffset + 30)
                        : verticalOffset - (barTop + barHeight);

                return Stack(
                  children: [
                    // Vertical connector line
                    Positioned(
                      left: lineX - 1, // center 2px line
                      top: isTop ? lineTop : barTop + barHeight,
                      child: Container(
                        width: 2,
                        height: lineHeight.abs(),
                        color: color,
                      ),
                    ),

                    // Label + percentage
                    Positioned(
                      left: leftPos,
                      top: verticalOffset,
                      child: GestureDetector(
                        onTap: () {
                          context.go(
                            '/home/devices?status=${label.toLowerCase()}',
                          );
                        },
                        // onTap: () {
                        //   context.go('/home/devices');
                        // },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(height: 14, width: 3, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  label,
                                  style: GoogleFonts.urbanist(
                                    fontSize: 13,
                                    color: isDark ? tWhite : tBlack,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${percent.toStringAsFixed(1)}% ($count)',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                color:
                                    isDark
                                        ? tWhite.withOpacity(0.7)
                                        : tBlack.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget buildVehicleMap({bool isDark = false, double zoom = 12.0}) {
    final vehicles = [
      {'location': const LatLng(12.9716, 77.5946), 'status': 'moving'},
      {'location': const LatLng(12.9750, 77.6000), 'status': 'idle'},
      {'location': const LatLng(12.9680, 77.5800), 'status': 'stopped'},
      {'location': const LatLng(12.9650, 77.6200), 'status': 'disconnected'},
      {'location': const LatLng(12.9810, 77.6050), 'status': 'moving'},
      {'location': const LatLng(12.9890, 77.6100), 'status': 'idle'},
      {'location': const LatLng(12.9600, 77.5950), 'status': 'stopped'},
      {'location': const LatLng(12.9550, 77.5850), 'status': 'disconnected'},
      {'location': const LatLng(12.9760, 77.5900), 'status': 'moving'},
      {'location': const LatLng(12.9830, 77.6000), 'status': 'idle'},
    ];

    final tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    String getTruckIcon(String status) {
      switch (status) {
        case 'moving':
          return 'icons/truck1.svg';
        case 'idle':
          return 'icons/truck2.svg';
        case 'stopped':
          return 'icons/truck3.svg';
        case 'disconnected':
          return 'icons/truck4.svg';
        default:
          return 'icons/truck1.svg';
      }
    }

    return FlutterMap(
      key: const ValueKey('vehicle_map_widget'),
      options: MapOptions(
        initialCenter: const LatLng(12.9716, 77.5946),
        initialZoom: zoom,
        maxZoom: 18.0,
        minZoom: 3.0,
      ),
      children: [
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.example.app',
        ),
        MarkerLayer(
          markers:
              vehicles.map((vehicle) {
                final LatLng point = vehicle['location'] as LatLng;
                final String iconPath = getTruckIcon(
                  vehicle['status'] as String,
                );

                return Marker(
                  point: point,
                  width: 35,
                  height: 35,
                  child: SvgPicture.asset(iconPath, width: 25, height: 25),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget buildAlertsWidget({bool isDark = false}) {
    final alerts = recentAlerts;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Alerts ($alertsTotalCount)",
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 10),

        if (alerts.isEmpty && !isAlertsLoading)
          Center(
            child: Text(
              "No alerts available",
              style: GoogleFonts.urbanist(
                fontSize: 12,
                color: isDark ? tWhite : tBlack,
              ),
            ),
          ),

        if (isAlertsLoading) const Center(child: CircularProgressIndicator()),

        ...alerts.map((alert) {
          final alertType = alert["alertType"] ?? "";
          final color = getAlertColor(alertType);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
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
                  /// Vehicle + IMEI
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

                  /// Date + alert badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        alert['dateTime'] ?? '',
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
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          alertType,
                          style: GoogleFonts.urbanist(
                            color: color,
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

  // Widget buildAlertsWidget({bool isDark = false}) {
  //   // 10 dummy alert entries
  //   final List<Map<String, String>> alerts = List.generate(10, (index) {
  //     final alertTypes = [
  //       'Power Disconnect',
  //       'GPRS Lost',
  //       'Over Speed',
  //       'Ignition On',
  //       'Ignition Off',
  //       'Geo Fence Alert',
  //       'Battery Low',
  //       'Tilt Alert',
  //       'Fall Detected',
  //       'SOS Triggered',
  //     ];

  //     return {
  //       'vehicleId': 'VHC-${1000 + index}',
  //       'imei': 'IMEI-${8900000 + index}',
  //       'dateTime': '26 Oct 2025, ${10 + index}:15:30',
  //       'alertType': alertTypes[index % alertTypes.length],
  //     };
  //   });

  //   Color getAlertColor(String type) {
  //     if (type.contains('Disconnect') || type.contains('Lost')) return tRed;
  //     if (type.contains('Low') || type.contains('Fall')) return tOrange1;
  //     if (type.contains('Speed')) return Colors.amber;
  //     if (type.contains('Ignition')) return tBlue;
  //     if (type.contains('Geo') || type.contains('Tilt')) return Colors.purple;
  //     if (type.contains('SOS')) return Colors.redAccent;
  //     return tGrey;
  //   }

  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       ...alerts.map((alert) {
  //         return Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 6.0),
  //           child: Container(
  //             width: double.infinity,
  //             margin: const EdgeInsets.only(bottom: 8),
  //             padding: const EdgeInsets.all(10),
  //             decoration: BoxDecoration(
  //               color: isDark ? tBlack : tWhite,
  //               // borderRadius: BorderRadius.circular(15),
  //               boxShadow: [
  //                 BoxShadow(
  //                   spreadRadius: 1,
  //                   blurRadius: 6,
  //                   color:
  //                       isDark
  //                           ? tWhite.withOpacity(0.1)
  //                           : tBlack.withOpacity(0.1),
  //                 ),
  //               ],
  //             ),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 /// Vehicle ID + IMEI
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       'Vehicle: ${alert['vehicleId']}',
  //                       style: GoogleFonts.urbanist(
  //                         color: isDark ? tWhite : tBlack,
  //                         fontWeight: FontWeight.w600,
  //                         fontSize: 12,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 3),
  //                     Text(
  //                       'IMEI: ${alert['imei']}',
  //                       style: GoogleFonts.urbanist(
  //                         color: isDark ? Colors.grey[300] : Colors.grey[700],
  //                         fontSize: 11,
  //                       ),
  //                     ),
  //                   ],
  //                 ),

  //                 /// Date + Alert type
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.end,
  //                   children: [
  //                     Text(
  //                       alert['dateTime']!,
  //                       style: TextStyle(
  //                         color: isDark ? Colors.grey[300] : Colors.grey[800],
  //                         fontSize: 11,
  //                       ),
  //                     ),
  //                     const SizedBox(height: 3),
  //                     Container(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 8,
  //                         vertical: 4,
  //                       ),
  //                       decoration: BoxDecoration(
  //                         color: getAlertColor(
  //                           alert['alertType']!,
  //                         ).withOpacity(0.1),
  //                         borderRadius: BorderRadius.circular(4),
  //                       ),
  //                       child: Text(
  //                         alert['alertType']!,
  //                         style: GoogleFonts.urbanist(
  //                           color: getAlertColor(alert['alertType']!),
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.w600,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //     ],
  //   );
  // }

  //   Widget buildAlertsTable(bool isDark) {

  //     // Dummy alerts data
  //     final List<Map<String, String>> alerts = List.generate(10, (index) {
  //       final alertTypes = [
  //         'Power Disconnect',
  //         'GPRS Lost',
  //         'Over Speed',
  //         'Ignition On',
  //         'Ignition Off',
  //         'Geo Fence Alert',
  //         'Battery Low',
  //         'Tilt Alert',
  //         'Fall Detected',
  //         'SOS Triggered',
  //       ];

  //       return {
  //         'vehicleId': 'VHC-${1000 + index}',
  //         'imei': 'IMEI-${8900000 + index}',
  //         'dateTime': '26 Oct 2025, ${10 + index}:15:30',
  //         'alertType': alertTypes[index % alertTypes.length],
  //       };
  //     });

  //     Color getAlertColor(String type) {
  //       if (type.contains('Disconnect') || type.contains('Lost')) return tRed;
  //       if (type.contains('Low') || type.contains('Fall')) return tOrange1;
  //       if (type.contains('Speed')) return Colors.amber;
  //       if (type.contains('Ignition')) return tBlue;
  //       if (type.contains('Geo') || type.contains('Tilt')) return Colors.purple;
  //       if (type.contains('SOS')) return Colors.redAccent;
  //       return tGrey;
  //     }

  //     return LayoutBuilder(
  //       builder: (context, constraints) {
  //         final maxHeight = constraints.maxHeight;
  //         final maxWidth = constraints.maxWidth;

  //         return Container(
  //           width: maxWidth,
  //           height: maxHeight,
  //           padding: const EdgeInsets.all(10),
  //           decoration: BoxDecoration(
  //             color: isDark ? tBlack : tWhite,
  //             boxShadow: [
  //               BoxShadow(
  //                 blurRadius: 10,
  //                 color: isDark ? Colors.white24 : Colors.black12,
  //               ),
  //             ],
  //           ),
  //           child: Column(
  //             children: [
  //               Expanded(
  //                 child: Scrollbar(
  //                   thumbVisibility: true,
  //                   radius: const Radius.circular(6),
  //                   thickness: 4,
  //                   child: SingleChildScrollView(
  //                     scrollDirection: Axis.horizontal,
  //                     child: ConstrainedBox(
  //                       constraints: BoxConstraints(minWidth: maxWidth),
  //                       child: SingleChildScrollView(
  //                         scrollDirection: Axis.vertical,
  //                         child: DataTable(
  //                           headingRowColor: WidgetStateProperty.all(
  //                             isDark
  //                                 ? tBlue.withOpacity(0.15)
  //                                 : tBlue.withOpacity(0.05),
  //                           ),
  //                           headingTextStyle: GoogleFonts.urbanist(
  //                             fontWeight: FontWeight.w700,
  //                             color: isDark ? tWhite : tBlack,
  //                             fontSize: 13,
  //                           ),
  //                           dataTextStyle: GoogleFonts.urbanist(
  //                             color: isDark ? tWhite : tBlack,
  //                             fontWeight: FontWeight.w400,
  //                             fontSize: 12,
  //                           ),
  //                           columnSpacing: 35,
  //                           border: TableBorder.all(
  //                             color:
  //                                 isDark
  //                                     ? tWhite.withOpacity(0.1)
  //                                     : tBlack.withOpacity(0.1),
  //                             width: 0.4,
  //                           ),
  //                           dividerThickness: 0.01,
  //                           columns: const [
  //                             DataColumn(label: Text("Vehicle / IMEI")),
  //                             DataColumn(label: Text("Date & Time")),
  //                             DataColumn(label: Text("Alert Type")),
  //                           ],
  //                           rows:
  //                               alerts.map((alert) {
  //                                 final alertColor = getAlertColor(
  //                                   alert['alertType']!,
  //                                 );

  //                                 return DataRow(
  //                                   cells: [
  //                                     // Vehicle + IMEI column
  //                                     DataCell(
  //                                       Column(
  //                                         crossAxisAlignment:
  //                                             CrossAxisAlignment.start,
  //                                         mainAxisAlignment:
  //                                             MainAxisAlignment.center,
  //                                         children: [
  //                                           Text(
  //                                             alert['vehicleId']!,
  //                                             style: GoogleFonts.urbanist(
  //                                               fontWeight: FontWeight.bold,
  //                                             ),
  //                                           ),
  //                                           Text(
  //                                             alert['imei']!,
  //                                             style: GoogleFonts.urbanist(
  //                                               fontSize: 11,
  //                                               color:
  //                                                   isDark
  //                                                       ? Colors.grey[300]
  //                                                       : Colors.grey[700],
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),

  //                                     // DateTime
  //                                     DataCell(Text(alert['dateTime']!)),

  //                                     // Alert Type Badge
  //                                     DataCell(
  //                                       Container(
  //                                         padding: const EdgeInsets.symmetric(
  //                                           vertical: 4,
  //                                           horizontal: 10,
  //                                         ),
  //                                         decoration: BoxDecoration(
  //                                           color: alertColor.withOpacity(0.18),
  //                                           borderRadius: BorderRadius.circular(
  //                                             6,
  //                                           ),
  //                                         ),
  //                                         child: Text(
  //                                           alert['alertType']!,
  //                                           style: GoogleFonts.urbanist(
  //                                             color: alertColor,
  //                                             fontWeight: FontWeight.w700,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 );
  //                               }).toList(),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         );
  //       },
  //     );
  //   }
  // }

  Widget buildAlertsTable(bool isDark) {
    // Use the fetched alerts
    final alerts = recentAlerts;

    Color getAlertColor(String type) {
      type = type.toLowerCase();
      if (type.contains('disconnect')) return tRed;
      if (type.contains('battery')) return tRed;
      if (type.contains('lowfuel') || type.contains('low_fuel'))
        return tOrange1;
      if (type.contains('hightemperature') || type.contains('temp')) {
        return Colors.amber;
      }
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
          padding: const EdgeInsets.all(10),
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
              // Optional small loading / count info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Alerts (${alertsTotalCount})',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  if (isAlertsLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child:
                    alerts.isEmpty && !isAlertsLoading
                        ? Center(
                          child: Text(
                            'No alerts available',
                            style: GoogleFonts.urbanist(
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        )
                        : Scrollbar(
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
                                  columnSpacing: 35,
                                  border: TableBorder.all(
                                    color:
                                        isDark
                                            ? tWhite.withOpacity(0.1)
                                            : tBlack.withOpacity(0.1),
                                    width: 0.4,
                                  ),
                                  dividerThickness: 0.01,
                                  columns: const [
                                    DataColumn(label: Text("Vehicle / IMEI")),
                                    DataColumn(label: Text("Date & Time")),
                                    DataColumn(label: Text("Alert Type")),
                                  ],
                                  rows:
                                      alerts.map((alert) {
                                        final alertType =
                                            (alert['alertType'] ?? '')
                                                .toString();
                                        final alertColor = getAlertColor(
                                          alertType,
                                        );

                                        return DataRow(
                                          cells: [
                                            // Vehicle + IMEI column
                                            DataCell(
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    (alert['vehicleId'] ?? '')
                                                        .toString(),
                                                    style: GoogleFonts.urbanist(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    (alert['imei'] ?? '')
                                                        .toString(),
                                                    style: GoogleFonts.urbanist(
                                                      fontSize: 11,
                                                      color:
                                                          isDark
                                                              ? Colors.grey[300]
                                                              : Colors
                                                                  .grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // DateTime
                                            DataCell(
                                              Text(
                                                (alert['dateTime'] ?? '')
                                                    .toString(),
                                              ),
                                            ),

                                            // Alert Type Badge
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 10,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: alertColor.withOpacity(
                                                    0.18,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  alertType,
                                                  style: GoogleFonts.urbanist(
                                                    color: alertColor,
                                                    fontWeight: FontWeight.w700,
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
            ],
          ),
        );
      },
    );
  }
}
