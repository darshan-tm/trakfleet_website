import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../provider/fleetModeProvider.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';
import '../widgets/charts/doughnutChart.dart';
import '../widgets/charts/evCellTemperaturesChart.dart';
import '../widgets/charts/evCellVoltagesChart.dart';
import '../widgets/charts/fuelChart.dart';
import '../widgets/charts/odometerChart.dart';
import '../widgets/charts/rpmChart.dart';
import '../widgets/charts/speedChart.dart';
import '../widgets/charts/temperatureChart.dart';
import '../widgets/charts/vehicleVoltageChart.dart';
import '../widgets/components/customBatteryCellTemperature.dart';
import '../widgets/components/customBatteryCellVoltage.dart';

class CellStats {
  final double max;
  final double min;
  final double last;
  final double mean;

  CellStats(this.max, this.min, this.last, this.mean);

  static CellStats compute(List<double> values) {
    double maxV = values.reduce((a, b) => a > b ? a : b);
    double minV = values.reduce((a, b) => a < b ? a : b);
    double lastV = values.last;
    double meanV = values.reduce((a, b) => a + b) / values.length;

    return CellStats(
      double.parse(maxV.toStringAsFixed(3)),
      double.parse(minV.toStringAsFixed(3)),
      double.parse(lastV.toStringAsFixed(3)),
      double.parse(meanV.toStringAsFixed(3)),
    );
  }
}

class DeviceDiagnosticsInfoScreen extends StatefulWidget {
  final Map<String, dynamic> device;
  const DeviceDiagnosticsInfoScreen({super.key, required this.device});

  @override
  State<DeviceDiagnosticsInfoScreen> createState() =>
      _DeviceDiagnosticsInfoScreenState();
}

class _DeviceDiagnosticsInfoScreenState
    extends State<DeviceDiagnosticsInfoScreen> {
  String selectedTab = "Statistics";

  List<List<double>> generateCellVoltages(int cells) {
    final random = Random();
    const int points = 24; // last 24 hours

    List<List<double>> data = [];

    for (int c = 0; c < cells; c++) {
      double base = 3.15 + random.nextDouble() * 0.10;
      List<double> values = [];

      for (int i = 0; i < points; i++) {
        double variation = (random.nextDouble() - 0.5) * 0.01;
        base = (base + variation).clamp(3.25, 3.80);
        values.add(double.parse(base.toStringAsFixed(4)));
      }

      data.add(values);
    }

    return data;
  }

  List<String> generateLast24HourLabels() {
    List<String> labels = [];
    DateTime now = DateTime.now();
    DateTime currentHour = DateTime(now.year, now.month, now.day, now.hour);

    for (int i = 23; i >= 0; i--) {
      DateTime t = currentHour.subtract(Duration(hours: i));
      labels.add("${t.hour.toString().padLeft(2, '0')}:00");
    }

    return labels;
  }

  final List<Color> cellColors24 = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.lightGreen,
    Colors.teal,
    Colors.cyan,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.lime,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.blueGrey,
    Colors.amber,
    Colors.lightBlue,
    Colors.deepOrangeAccent,
    Colors.greenAccent,
    Colors.redAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
  ];

  List<List<double>> generateTemperatureListOf10Sensors({
    int sensors = 10,
    int points = 50,
    double minTemp = 20.0,
    double maxTemp = 45.0,
  }) {
    final random = Random();
    List<List<double>> sensorData = [];

    for (int i = 0; i < sensors; i++) {
      List<double> readings = List.generate(points, (_) {
        double v = minTemp + random.nextDouble() * (maxTemp - minTemp);
        return double.parse(v.toStringAsFixed(2));
      });

      sensorData.add(readings);
    }

    return sensorData;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ResponsiveLayout(
      mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      desktop: _buildDesktopLayout(context, isDark),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    final device = widget.device;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: buildDeviceCard(
            isDark: isDark,
            imei: device['imei'] ?? '12265679827872127',
            vehicleNumber: device['vehicleNumber'] ?? 'VGFDG4251271677',
            status: device['status'] ?? 'Moving',
            fuel: device['fuel'] ?? '',
            odo: device['odo'] ?? '',
            trips: device['trips'] ?? '',
            alerts: device['alerts'] ?? '',
            location: device['location'] ?? '',
            onTabChanged: (tab) {
              setState(() => selectedTab = tab);
            },
            selectedTab: selectedTab,
          ),
        ),

        // ===== Dynamic Body Section =====
        if (selectedTab == "Statistics")
          _buildDiagnosticsCards(isDark)
        else
          _buildCanDataTables(isDark),
      ],
    );
  }

  Widget _buildDiagnosticsCards(bool isDark) {
    final device = widget.device;
    final mode = context.watch<FleetModeProvider>().mode;

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 5,
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SingleDoughnutChart(
                            currentValue: 12.8,
                            avgValue: 12,
                            title: "Voltage",
                            unit: "V",
                            primaryColor: tBlue,
                            isDark: isDark,
                          ),
                          mode == 'EV Fleet'
                              ? SingleDoughnutChart(
                                currentValue: 35,
                                avgValue: 24,
                                title: "Current",
                                unit: "A",
                                primaryColor: tPink,
                                isDark: isDark,
                              )
                              : SingleDoughnutChart(
                                currentValue: 72,
                                avgValue: 55,
                                title: "Fuel",
                                unit: "%",
                                primaryColor: tGreen,
                                isDark: isDark,
                              ),
                          mode == 'EV Fleet'
                              ? SingleDoughnutChart(
                                currentValue: 72,
                                avgValue: 55,
                                title: "SOH",
                                unit: "%",
                                primaryColor: tBlueSky,
                                isDark: isDark,
                              )
                              : SingleDoughnutChart(
                                currentValue: 3500,
                                avgValue: 2500,
                                title: "RPM",
                                unit: "rpm",
                                primaryColor: tBlueSky,
                                isDark: isDark,
                              ),
                          mode == 'EV Fleet'
                              ? SingleDoughnutChart(
                                currentValue: 72,
                                avgValue: 55,
                                title: "SOC",
                                unit: "%",
                                primaryColor: tGreen,
                                isDark: isDark,
                              )
                              : SingleDoughnutChart(
                                currentValue: 320,
                                avgValue: 280,
                                title: 'Torque',
                                unit: 'Nm',
                                primaryColor: tPink2,
                                isDark: true,
                              ),
                          SingleDoughnutChart(
                            currentValue: 64,
                            avgValue: 50,
                            title: "Temperature",
                            unit: "°C",
                            primaryColor: tOrange1,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 20),

                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildInfoCard(
                                isDark,
                                "Speed (km/h)",
                                "85",
                                tGreenGradient,
                              ),
                              const SizedBox(height: 20),

                              _buildInfoCard(
                                isDark,
                                "Odometer (km)",
                                "45272",
                                tBlueGradient1,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "SOS",
                                      device['sos'] == "1" ? "ON" : "OFF",
                                      device['sos'] == "1"
                                          ? tGreenGradient1
                                          : tRedGradient3,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "PTO",
                                      device['pto'] == "1" ? "ON" : "OFF",
                                      device['pto'] == "1"
                                          ? tGreenGradient1
                                          : tRedGradient3,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "AdBlue (L)",
                                      '45',
                                      tBlueGradient2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "Ignition",
                                      'ON',
                                      tGreenGradient2,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "4 Wheel Drive",
                                      device['4 Wheel Drive'] == "1"
                                          ? "ON"
                                          : "OFF",
                                      device['4 Wheel Drive'] == "1"
                                          ? tGreenGradient1
                                          : tRedGradient3,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildInfoCard(
                                      isDark,
                                      "Immobilize",
                                      device['Immobilize'] == "1"
                                          ? "ON"
                                          : "OFF",
                                      device['Immobilize'] == "1"
                                          ? tGreenGradient1
                                          : tRedGradient3,
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
                ],
              ),
              SizedBox(height: 20),
              _buildStatsGraphsAndBars(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    bool isDark,
    String title,
    String value,
    Gradient cardGradient,
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
            padding: const EdgeInsets.symmetric(vertical: 5),
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
            height: 75,
            width: double.infinity,
            decoration: BoxDecoration(gradient: cardGradient),
            alignment: Alignment.center,
            child: Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 35,
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
    required Function(String) onTabChanged,
    required String selectedTab,
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
        color: isDark ? tBlack : tWhite,
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.25) : tBlack.withOpacity(0.15),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // SvgPicture.asset('icons/struck1.svg', width: 80, height: 80),
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
                          Container(
                            width: 350,
                            // constraints: const BoxConstraints(
                            //   minWidth: 200,
                            //   maxWidth: 400,
                            // ),
                            decoration: BoxDecoration(
                              border: Border.all(color: statusColor, width: 1),
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

                    // ==== Right Side (Tabs) ====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildTabButton("Statistics", selectedTab, isDark, () {
                          onTabChanged("Statistics");
                        }),
                        const SizedBox(width: 5),
                        _buildTabButton("CAN Data", selectedTab, isDark, () {
                          onTabChanged("CAN Data");
                        }),
                      ],
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

  Widget _buildStatsGraphsAndBars(bool isDark) {
    final int totalCells = 10;

    // --- USE IT HERE ---
    final List<List<double>> cellVoltageListOf24Cells = generateCellVoltages(
      24,
    );
    final temperatureListOf10Sensors = generateTemperatureListOf10Sensors(
      points: 100, // number of values per sensor
    );

    final List<String> timeStampsList = generateLast24HourLabels();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                height: 250,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Vehicle Voltage (V)",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                        _buildLegendItem(tBlue, "Vehicle Voltage", isDark),
                      ],
                    ),

                    const SizedBox(height: 10),
                    VehicleVoltageChart(
                      isDark: isDark,
                      voltageData: [12.5, 12.7, 13.2, 13.8, 14.0, 13.5, 13.1],
                      timeLabels: [
                        '10:00',
                        '10:05',
                        '10:10',
                        '10:15',
                        '10:20',
                        '10:25',
                        '10:30',
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Container(
                height: 250,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Speed (Km/h)",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                        _buildLegendItem(tGreen, "Speed", isDark),
                      ],
                    ),

                    const SizedBox(height: 10),
                    VehicleSpeedChart(
                      isDark: isDark,
                      speedData: [40, 45, 60, 72, 68, 70, 65],
                      timeLabels: [
                        '10:00',
                        '10:05',
                        '10:10',
                        '10:15',
                        '10:20',
                        '10:25',
                        '10:30',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Container(
                height: 250,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Odometer (km)",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                        _buildLegendItem(tBlueSky, "Odometer", isDark),
                      ],
                    ),

                    const SizedBox(height: 10),
                    OdometerChart(
                      odometerData: [10200, 10205, 10215, 10225, 10240, 10255],
                      timeLabels: [
                        '10:00',
                        '10:10',
                        '10:20',
                        '10:30',
                        '10:40',
                        '10:50',
                      ],
                      isDark: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                height: 250,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "RPM",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                        _buildLegendItem(tOrange1, "RPM", isDark),
                      ],
                    ),

                    const SizedBox(height: 10),
                    RpmChart(
                      rpmData: [800, 1500, 2500, 3000, 2800, 3200, 4000, 3500],
                      timeLabels: [
                        '10:00',
                        '10:01',
                        '10:02',
                        '10:03',
                        '10:04',
                        '10:05',
                        '10:06',
                        '10:07',
                      ],
                      isDark: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Container(
                height: 250,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Fuel (%)",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                        _buildLegendItem(tGreenDark, "Fuel", isDark),
                      ],
                    ),

                    const SizedBox(height: 10),
                    FuelChart(
                      fuelData: [100, 95, 90, 85, 80, 75, 70, 65],
                      timeLabels: [
                        '10:00',
                        '10:01',
                        '10:02',
                        '10:03',
                        '10:04',
                        '10:05',
                        '10:06',
                        '10:07',
                      ],
                      isDark: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Container(
                height: 250,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Temperature (°C)",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? tWhite : tBlack,
                          ),
                        ),
                        _buildLegendItem(tRed, "Temperature", isDark),
                      ],
                    ),

                    const SizedBox(height: 10),
                    VehicleTemperatureChart(
                      temperatureData: [72, 75, 78, 82, 85, 88, 90, 93],
                      timeLabels: [
                        '10:00',
                        '10:01',
                        '10:02',
                        '10:03',
                        '10:04',
                        '10:05',
                        '10:06',
                        '10:07',
                      ],
                      isDark: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        buildStatusBars(isDark),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 7,
              child: Container(
                height: 400,
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
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      'Live Cell Voltages (V)',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    SizedBox(height: 20),

                    // First row: 12 cells
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(12, (index) {
                        double randomVoltage =
                            3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
                        return Real3DBatteryVertical(
                          voltage: randomVoltage,
                          height: 150,
                          width: 75,
                          isDark: isDark,
                          label:
                              "Cell ${index + 1}", // optional label for each cell
                        );
                      }),
                    ),

                    SizedBox(height: 20),

                    // Second row: remaining 12 cells
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(12, (index) {
                        double randomVoltage =
                            3.0 + Random().nextDouble() * 1.5; // 3.0 - 4.5V
                        return Real3DBatteryVertical(
                          voltage: randomVoltage,
                          height: 150,
                          width: 75,
                          isDark: isDark,
                          label:
                              "Cell ${index + 13}", // optional label for each cell
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Container(
                height: 400,
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
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      'Live Cell Temperatures (°C)',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Split the cells into rows (5 per row)
                    for (int row = 0; row < (totalCells / 5).ceil(); row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (index) {
                            int cellNumber = row * 5 + index + 1;
                            if (cellNumber > totalCells)
                              return SizedBox(width: 75); // empty space

                            double randomTemp =
                                25 + Random().nextDouble() * 10; // 25°C to 35°C

                            return Thermometer3D(
                              temperature: randomTemp,
                              height: 150,
                              width: 75,
                              label: 'Cell Temp. $cellNumber',
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Container(
          height: 450,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            children: [
              /// LEFT — CHART
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Text(
                      "Cell Voltages (Last 24 Hours)",
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? tWhite : tBlack,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: MultiCellVoltageChart(
                        cellVoltages: cellVoltageListOf24Cells,
                        timeLabels: timeStampsList,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              /// RIGHT — LEGEND TABLE
              Expanded(
                flex: 1,
                child: buildCellLegendTable(
                  cellVoltages: cellVoltageListOf24Cells,
                  colors: cellColors24,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Container(
          height: 400,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Cell Temperatures",
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  _buildLegendItem(tOrange1, "RPM", isDark),
                ],
              ),

              const SizedBox(height: 10),
              MultiSensorTemperatureChart(
                tempValues: temperatureListOf10Sensors, // List<List<double>>
                timeLabels: timeStampsList, // List<String>
                isDark: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanDataTables(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? tWhite.withOpacity(0.3) : tBlack.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "CAN Data Tables",
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? tWhite : tBlack,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "This section will show detailed CAN Bus data (RPM, Fuel Level, Engine Temp, etc.)",
            style: GoogleFonts.urbanist(
              fontSize: 11,
              color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    String selectedTab,
    bool isDark,
    VoidCallback onTap,
  ) {
    final bool isSelected = selectedTab == label;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // color: isSelected ? tBlue.withOpacity(0.15) : Colors.transparent,
          gradient:
              isSelected
                  ? SweepGradient(colors: [tBlue, tBlue.withOpacity(0.6)])
                  : SweepGradient(colors: [tTransparent, tTransparent]),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color:
                isSelected
                    ? tTransparent
                    : (isDark
                        ? tWhite.withOpacity(0.3)
                        : tBlack.withOpacity(0.3)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color:
                isDark
                    ? (isSelected ? tWhite : tWhite.withOpacity(0.7))
                    : (isSelected ? tWhite : tBlack.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }

  Widget buildStatusBars(bool isDark) {
    final mode = context.watch<FleetModeProvider>().mode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusBar(
          title: "Ignition Status (Last 24 Hours)",
          history: [
            1,
            1,
            0,
            0,
            1,
            1,
            1,
            0,
            0,
            1,
            1,
            1,
            0,
            0,
            0,
            1,
            1,
            1,
            0,
            0,
            1,
            0,
            0,
            1,
          ],
          onColor: tGreen,
          offColor: tRed,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _buildStatusBar(
          title: "SOS Status (Last 24 Hours)",
          history: [
            0, 0, 1, 1, 0, 0, 1, 0, 0, 1, // last 10
            1, 0, 0, 0, 1, 0, 0, 1, 1, 0, // 10 older
            1, 0, 0, 1, // oldest 4
          ],
          onColor: tGreen,
          offColor: tRed,
          isDark: isDark,
        ),
        if (mode == 'ICE Fleet') ...[
          const SizedBox(height: 20),
          _buildStatusBar(
            title: "PTO Status (Last 24 Hours)",
            history: [
              1,
              1,
              1,
              0,
              0,
              0,
              1,
              0,
              1,
              1,
              0,
              0,
              1,
              1,
              1,
              0,
              0,
              1,
              0,
              0,
              1,
              1,
              0,
              0,
            ],
            onColor: tGreen,
            offColor: tRed,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildStatusBar(
            title: "4 Wheel Drive (Last 24 Hours)",
            history: [
              0,
              0,
              0,
              0,
              1,
              1,
              1,
              1,
              0,
              0,
              0,
              0,
              1,
              1,
              1,
              0,
              0,
              0,
              1,
              1,
              0,
              0,
              0,
              0,
            ],
            onColor: tGreen,
            offColor: tRed,
            isDark: isDark,
          ),
        ],

        if (mode == 'EV Fleet') ...[
          const SizedBox(height: 20),

          _buildChargingStatusBar(
            title: "Charging Status (Last 24 Hours)",
            history: [
              0,
              0,
              1,
              1,
              0,
              0,
              2,
              0,
              0,
              1,
              2,
              0,
              0,
              0,
              1,
              0,
              2,
              1,
              1,
              0,
              1,
              0,
              2,
              1,
            ],
            chargingColor: tGreen,
            dischargingColor: tBlue, // <-- pick your discharging color
            idleColor: tOrange1, // <-- idle color
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBar({
    required String title,
    required List<int> history,
    required Color onColor,
    required Color offColor,
    required bool isDark,
  }) {
    // Count totals
    final Map<String, double> data = {
      "ON": history.where((v) => v == 1).length.toDouble(),
      "OFF": history.where((v) => v == 0).length.toDouble(),
    };

    final Map<String, Color> borderColors = {"ON": onColor, "OFF": offColor};

    final Map<String, Color> fillColors = {
      "ON": onColor.withOpacity(0.2),
      "OFF": offColor.withOpacity(0.2),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
        const SizedBox(height: 6),

        _buildAnimatedAlertsBar(data, borderColors, fillColors, isDark),

        const SizedBox(height: 6),

        // Hour labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(24, (i) {
            final now = DateTime.now();
            final hour = now.subtract(Duration(hours: 23 - i));
            return Text(
              "${hour.hour.toString().padLeft(2, '0')}:00",
              style: GoogleFonts.urbanist(
                fontSize: 8,
                color:
                    isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildChargingStatusBar({
    required String title,
    required List<int> history, // 0=idle, 1=charging, 2=discharging
    required Color chargingColor,
    required Color dischargingColor,
    required Color idleColor,
    required bool isDark,
  }) {
    // Count totals
    final Map<String, double> data = {
      "CHARGING": history.where((v) => v == 1).length.toDouble(),
      "DISCHARGING": history.where((v) => v == 2).length.toDouble(),
      "IDLE": history.where((v) => v == 0).length.toDouble(),
    };

    final Map<String, Color> borderColors = {
      "CHARGING": chargingColor,
      "DISCHARGING": dischargingColor,
      "IDLE": idleColor,
    };

    final Map<String, Color> fillColors = {
      "CHARGING": chargingColor.withOpacity(0.20),
      "DISCHARGING": dischargingColor.withOpacity(0.20),
      "IDLE": idleColor.withOpacity(0.20),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),

        const SizedBox(height: 6),

        _buildAnimatedAlertsBar(data, borderColors, fillColors, isDark),

        const SizedBox(height: 6),

        // Hour labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(24, (i) {
            final now = DateTime.now();
            final hour = now.subtract(Duration(hours: 23 - i));
            return Text(
              "${hour.hour.toString().padLeft(2, '0')}:00",
              style: GoogleFonts.urbanist(
                fontSize: 8,
                color:
                    isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAnimatedAlertsBar(
    Map<String, double> data,
    Map<String, Color> borderColors,
    Map<String, Color> fillColors,
    bool isDark,
  ) {
    double total = data.values.fold(0, (a, b) => a + b);

    return Container(
      width: double.infinity,
      height: 40,
      decoration: const BoxDecoration(color: Colors.transparent),
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
                        color: fillColors[entry.key] ?? tGrey.withOpacity(0.2),
                        border: Border.all(
                          color: borderColors[entry.key] ?? tGrey,
                          width: 1.5,
                        ),
                      ),
                      child: Tooltip(
                        message:
                            "${entry.key}: ${(entry.value).toStringAsFixed(1)} hrs",
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

  Widget buildCellLegendTable({
    required List<List<double>> cellVoltages,
    required List<Color> colors,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(
          width: 0.5,
          color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
        ),
        // borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER ROW
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text("Cell", style: _legendHeader(isDark)),
              ),
              sizedW(8),
              SizedBox(
                width: 40,
                child: Text("Last", style: _legendHeader(isDark)),
              ),
              SizedBox(
                width: 40,
                child: Text("Max", style: _legendHeader(isDark)),
              ),
              SizedBox(
                width: 40,
                child: Text("Min", style: _legendHeader(isDark)),
              ),
              SizedBox(
                width: 45,
                child: Text("Mean", style: _legendHeader(isDark)),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// TABLE BODY SCROLL
          Expanded(
            child: ListView.builder(
              itemCount: cellVoltages.length,
              itemBuilder: (context, i) {
                final stats = CellStats.compute(cellVoltages[i]);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      /// Cell color + number
                      SizedBox(
                        width: 30,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors[i],
                                // shape: BoxShape.circle,
                              ),
                            ),
                            sizedW(4),
                            Text("${i + 1}", style: _legendText(isDark)),
                          ],
                        ),
                      ),
                      sizedW(8),

                      SizedBox(
                        width: 40,
                        child: Text(
                          "${stats.last}",
                          style: _legendText(isDark),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text("${stats.max}", style: _legendText(isDark)),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text("${stats.min}", style: _legendText(isDark)),
                      ),
                      SizedBox(
                        width: 45,
                        child: Text(
                          "${stats.mean}",
                          style: _legendText(isDark),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Text styles
  TextStyle _legendHeader(bool isDark) => GoogleFonts.urbanist(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: isDark ? Colors.white : Colors.black,
  );

  TextStyle _legendText(bool isDark) => GoogleFonts.urbanist(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: isDark ? Colors.white70 : Colors.black87,
  );

  Widget sizedW(double w) => SizedBox(width: w);
}
