import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg_flutter.dart';
import '../../services/apiServices.dart';
import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';

class CommandModel {
  final String? id;
  final String? type;
  final String? commandSent;
  final String? dataReceived;
  final String? date;
  final String? userId;

  CommandModel({
    this.id,
    this.type,
    this.commandSent,
    this.dataReceived,
    this.date,
    this.userId,
  });

  factory CommandModel.fromJson(Map<String, dynamic> json) {
    return CommandModel(
      id: json['id'] ?? "",
      type: json['type'] ?? "",
      commandSent: json['commandSent'],
      dataReceived: json['dataReceived'],
      date: json['date'],
      userId: json['userId'],
    );
  }
}

class DeviceConfigInfoScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const DeviceConfigInfoScreen({super.key, required this.device});

  @override
  State<DeviceConfigInfoScreen> createState() => _DeviceConfigInfoScreenState();
}

class _DeviceConfigInfoScreenState extends State<DeviceConfigInfoScreen> {
  final TextEditingController _customCommandController =
      TextEditingController();

  //   final List<Map<String, String>> _commandLogs = [
  //     {
  //       'type': 'Sent',
  //       'sent': 'AT+GTRTO',
  //       'receive': 'OK',
  //       'date': '2025-11-10 12:30',
  //       'user': 'Admin',
  //     },
  //     {
  //       'type': 'Received',
  //       'sent': '-',
  //       'receive': '+GTRTO:SUCCESS',
  //       'date': '2025-11-10 12:31',
  //       'user': 'Device',
  //     },
  //   ];

  String? _selectedCommand;
  String get imei => widget.device['imei'];

  List<CommandModel> commands = [];
  bool isLoading = false;

  int currentPage = 1;
  int sizePerPage = 10;
  int totalCount = 0;
  int totalPages = 1;

  final List<Map<String, String>> _defaultcommands = [
    {'label': 'SHOW CONFIG', 'cmd': 'SHOW CONFIG'},
    {'label': 'SHOW IOSTATUS', 'cmd': 'SHOW IOSTATUS'},
    {'label': 'START OTA', 'cmd': 'START OTA'},
    {'label': 'MOBILIZE', 'cmd': 'MOBILIZE'},
    {'label': 'IMMOBILIZE', 'cmd': 'IMMOBILIZE'},
  ];

  Future<void> fetchCommands(int page) async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final url = Uri.parse(
      "${BaseURLConfig.vehicleCommand}/$imei"
      "?page=$page"
      "&sizePerPage=$sizePerPage"
      "&currentIndex=${(page - 1) * sizePerPage}",
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);

    setState(() {
      totalCount = data['totalCount'];
      commands =
          (data['entities'] as List)
              .map((e) => CommandModel.fromJson(e))
              .toList();

      totalPages = (totalCount / sizePerPage).ceil();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCommands(currentPage);
  }

  void _sendCommand(String command) {
    if (command.isEmpty) return;

    final newCmd = CommandModel(
      id: "local",
      type: "SENT",
      commandSent: command,
      dataReceived: "Pending...",
      date: DateTime.now().toString().substring(0, 16),
      userId: "Admin",
    );

    setState(() {
      commands.insert(0, newCmd);
      _customCommandController.clear();
      _selectedCommand = null;
    });

    // Simulate response
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        commands[0] = CommandModel(
          id: commands[0].id,
          type: "RECEIVED",
          commandSent: commands[0].commandSent,
          dataReceived: "OK",
          date: commands[0].date,
          userId: commands[0].userId,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveLayout(
      mobile: const Center(child: Text("Mobile / Tablet layout coming soon")),
      tablet: const Center(child: Text("Mobile / Tablet layout coming soon")),
      desktop: _buildDesktopLayout(isDark),
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    final device = widget.device;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT PANEL
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Device Info",
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
              SizedBox(height: 5),
              buildDeviceCard(
                isDark: isDark,
                imei: device['imei'],
                vehicleNumber: device['vehicleNumber'],
                status: device['status'],
                fuel: device['fuel'],
                odo: device['odo'],
                trips: device['trips'],
                alerts: device['alerts'],
                location: device['location'],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Default Commands",
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      "Send",
                      style: GoogleFonts.urbanist(
                        color: tWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      final command =
                          _customCommandController.text.isNotEmpty
                              ? _customCommandController.text
                              : (_selectedCommand ?? '');
                      _sendCommand(command);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _defaultcommands.map((cmd) {
                      final isSelected = _selectedCommand == cmd['cmd'];

                      // Assign individual colors for each command
                      Color baseColor;
                      switch (cmd['label']) {
                        case 'SHOW CONFIG':
                          baseColor = tBlue;
                          break;
                        case 'SHOW IOSTATUS':
                          baseColor = tPink2;
                          break;
                        case 'START OTA':
                          baseColor = tBlueSky;
                          break;
                        case 'MOBILIZE':
                          baseColor = tGreen;
                          break;
                        case 'IMMOBILIZE':
                          baseColor = tRedDark;
                          break;
                        default:
                          baseColor = tGrey;
                      }

                      return TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor:
                              isSelected
                                  ? baseColor
                                  : baseColor.withOpacity(0.15),
                          foregroundColor: isSelected ? tWhite : baseColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: () {
                          setState(() => _selectedCommand = cmd['cmd']);
                        },
                        child: Text(
                          cmd['label'] ?? '',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 20),

              Text(
                "Custom Commands",
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
              const SizedBox(height: 10),

              // Custom command input
              Row(
                children: [
                  //  Command Input Field
                  Expanded(
                    child: SizedBox(
                      height: 35, //  fixed height for alignment
                      child: TextField(
                        controller: _customCommandController,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: isDark ? tWhite : tBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter command...",
                          hintStyle: GoogleFonts.urbanist(
                            color:
                                isDark
                                    ? tWhite.withOpacity(0.5)
                                    : tBlack.withOpacity(0.5),
                            fontSize: 13,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),

                          // ✅ Normal border
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(
                              color:
                                  isDark
                                      ? tWhite.withOpacity(0.4)
                                      : tBlack.withOpacity(0.4),
                              width: 1,
                            ),
                          ),

                          // ✅ Focused border
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: BorderSide(color: tBlue, width: 1.2),
                          ),

                          // ✅ Error border (optional)
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(color: tRed, width: 1),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  // 🟦 Send Button
                  SizedBox(
                    height: 35, // ✅ same height as TextField
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tBlue,
                        shape: RoundedRectangleBorder(
                          // borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final command =
                            _customCommandController.text.isNotEmpty
                                ? _customCommandController.text
                                : (_selectedCommand ?? '');
                        _sendCommand(command);
                      },
                      child: Text(
                        "Send",
                        style: GoogleFonts.urbanist(
                          color: tWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 15),
        // RIGHT PANEL
        Expanded(flex: 6, child: _buildCommandLogTable(isDark)),
      ],
    );
  }

  Widget _buildCommandLogTable(bool isDark) {
    int totalPages = this.totalPages;

    // Safety: prevent invalid current page
    if (currentPage > totalPages) {
      currentPage = totalPages;
    } else if (currentPage < 1) {
      currentPage = 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;

        Color getTypeColor(String type) {
          switch ((type ?? '').toUpperCase()) {
            case 'Sent':
              return tBlue;
            case 'Received':
              return tGreen;
            default:
              return tGrey;
          }
        }

        return Container(
          width: maxWidth,
          height: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scrollable Table Area
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  thickness: 6,
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
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Sent Data')),
                            DataColumn(label: Text('Received Data')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('User')),
                          ],
                          rows:
                              commands.map((cmd) {
                                return DataRow(
                                  cells: [
                                    // Type cell with colored badge
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getTypeColor(
                                            cmd.type ?? '',
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          cmd.type ?? '',
                                          style: GoogleFonts.urbanist(
                                            color: getTypeColor(cmd.type ?? ''),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(cmd.commandSent ?? '-')),
                                    DataCell(Text(cmd.dataReceived ?? '-')),
                                    DataCell(Text(cmd.date ?? '-')),
                                    DataCell(Text(cmd.userId ?? '-')),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildPaginationControls(isDark, totalPages),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(bool isDark, int totalPages) {
    const int visiblePageCount = 5;

    // Calculate visible window
    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// ◀ PREVIOUS
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: currentPage > 1 ? (isDark ? tWhite : tBlack) : Colors.grey,
            ),
            onPressed:
                currentPage > 1
                    ? () {
                      setState(() => currentPage--);
                      fetchCommands(currentPage);
                    }
                    : null,
            tooltip: "Previous page",
          ),

          /// 🔢 Page Number Links
          Wrap(
            spacing: 6,
            children: List.generate((endPage - startPage + 1), (i) {
              final pageNum = startPage + i;
              final isSelected = pageNum == currentPage;
              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => setState(() => currentPage = pageNum),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? tBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isSelected
                              ? tBlue
                              : (isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                  child: Text(
                    '$pageNum',
                    style: GoogleFonts.urbanist(
                      color:
                          isSelected
                              ? tWhite
                              : (isDark
                                  ? tWhite.withOpacity(0.8)
                                  : tBlack.withOpacity(0.8)),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),

          /// ▶ NEXT
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color:
                  currentPage < totalPages
                      ? (isDark ? tWhite : tBlack)
                      : Colors.grey,
            ),
            onPressed:
                currentPage < totalPages
                    ? () {
                      setState(() => currentPage++);
                      fetchCommands(currentPage);
                    }
                    : null,
            tooltip: "Next page",
          ),

          const SizedBox(width: 16),

          /// ⌨ Go To Page Box
          SizedBox(
            width: 70,
            height: 32,
            child: TextField(
              controller: controller,
              style: GoogleFonts.urbanist(
                fontSize: 13,
                color: isDark ? tWhite : tBlack,
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Go to',
                hintStyle: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color:
                        isDark
                            ? tWhite.withOpacity(0.5)
                            : tBlack.withOpacity(0.5),
                    width: 0.8,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: tBlue, width: 1),
                ),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null &&
                    page >= 1 &&
                    page <= totalPages &&
                    mounted) {
                  setState(() => currentPage = page);
                  fetchCommands(currentPage);
                }
              },
            ),
          ),

          const SizedBox(width: 14),

          /// 📘 Page Info
          Text(
            'Page $currentPage of $totalPages',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tWhite.withOpacity(0.8) : tBlack.withOpacity(0.8),
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
      decoration: BoxDecoration(
        color: tTransparent,
        border: Border.all(
          color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
          width: 0.4,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMEI + Vehicle + Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligns status on top
            children: [
              /// IMEI + Vehicle box (fixed width)
              Container(
                width: 250, // fixed width (adjust as you like)
                decoration: BoxDecoration(
                  border: Border.all(color: statusColor, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        // color: statusColor,
                        gradient: SweepGradient(
                          colors: [statusColor, statusColor.withOpacity(0.6)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
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
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        vehicleNumber,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? tWhite : tBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),

              /// 🔹 Status container (top-aligned)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  // color: statusColor,
                  gradient: SweepGradient(
                    colors: [statusColor, statusColor.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? tBlack : tWhite,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(
            color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
            thickness: 0.3,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SvgPicture.asset(
                'icons/geofence.svg',
                width: 16,
                height: 16,
                color: tGreen,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Live Location : $location',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
