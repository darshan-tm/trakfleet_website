// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:svg_flutter/svg.dart';
// import 'package:tm_fleet_management/src/utils/appLogger.dart';

// import '../../models/tripsModel.dart';
// import '../../services/apiServices.dart';
// import '../../utils/appColors.dart';
// import '../../utils/appResponsive.dart';
// import '../widgets/components/customTitleBar.dart';

// class TripsScreen extends StatefulWidget {
//   const TripsScreen({super.key});

//   @override
//   State<TripsScreen> createState() => _TripsScreenState();
// }

// class _TripsScreenState extends State<TripsScreen> {
//   String selectedFilter = "All Trips";
//   Map<String, dynamic>? selectedTrip;
//   // flutter_map controller
//   final MapController _mapController = MapController();

//   // Dummy route coordinates (replace with real route coords per trip)
//   late final List<LatLng> _routePoints;
//   double _currentZoom = 17.0; // default zoom

//   // Playback state
//   Timer? _playTimer;
//   bool _isPlaying = false;
//   int _playIndex = 0;
//   LatLng? _movingMarker; // position of the animated marker

//   // Playback speed (milliseconds)
//   final int _tickMs = 1000;

//   final List<Map<String, dynamic>> allTrips = List.generate(50, (index) {
//     bool isOngoing = index.isEven;

//     final bengaluruAreas = [
//       'Koramangala',
//       'Indiranagar',
//       'Whitefield',
//       'Electronic City',
//       'HSR Layout',
//       'Jayanagar',
//       'BTM Layout',
//       'MG Road',
//       'Rajajinagar',
//       'Malleshwaram',
//       'Hebbal',
//       'Yelahanka',
//       'Ulsoor',
//       'Marathahalli',
//       'Banashankari',
//       'KR Puram',
//       'Basavanagudi',
//       'Vijayanagar',
//       'Bellandur',
//       'RT Nagar',
//     ];

//     final randomSource = bengaluruAreas[index % bengaluruAreas.length];
//     final randomDestination =
//         bengaluruAreas[(index + 5) %
//             bengaluruAreas.length]; // ensure not same as source

//     return {
//       'tripNumber': '00${index + 1}',
//       'truckNumber': 'TRK${1000 + index}',
//       'status': isOngoing ? 'Ongoing' : 'Completed',
//       'startTime': isOngoing ? '10:${index % 6}0 AM' : '08:${index % 6}0 AM',
//       'endTime': isOngoing ? '—' : '09:${index % 6}0 AM',
//       'durationMins': '${20 + index * 3}',
//       'distanceKm': '${10 + index * 2}',
//       'maxSpeed': '${60 + index * 2}',
//       'avgSpeed': '${45 + (index % 20)}',
//       'source': '$randomSource, Bengaluru',
//       'destination': '$randomDestination, Bengaluru',
//     };
//   });

//   List<Map<String, dynamic>> get filteredTrips {
//     if (selectedFilter == "Ongoing") {
//       return allTrips.where((t) => t['status'] == 'Ongoing').toList();
//     } else if (selectedFilter == "Completed") {
//       return allTrips.where((t) => t['status'] == 'Completed').toList();
//     } else {
//       return allTrips;
//     }
//   }

//   // Add these state variables at the top of your State class:
//   int currentPage = 1;
//   int itemsPerPage = 12; // you can tweak this
//   int get totalPages => (filteredTrips.length / itemsPerPage).ceil();

//   List<Map<String, dynamic>> get paginatedTrips {
//     final start = (currentPage - 1) * itemsPerPage;
//     final end = start + itemsPerPage;
//     return filteredTrips.sublist(
//       start,
//       end > filteredTrips.length ? filteredTrips.length : end,
//     );
//   }

//   void _nextPage() {
//     if (currentPage < totalPages) setState(() => currentPage++);
//   }

//   void _previousPage() {
//     if (currentPage > 1) setState(() => currentPage--);
//   }

//   List<LatLng> completedPath = [];
//   List<LatLng> remainingPath = [];

//   @override
//   void initState() {
//     super.initState();

//     fetchTrips();
//     // Example dummy route between two points (replace coordinates as needed)
//     _routePoints = [
//       LatLng(12.9716, 77.5946), // Start - MG Road
//       LatLng(12.9719, 77.5952),
//       LatLng(12.9723, 77.5958),
//       LatLng(12.9728, 77.5963),
//       LatLng(12.9733, 77.5968),
//       LatLng(12.9738, 77.5973),
//       LatLng(12.9742, 77.5978),
//       LatLng(12.9747, 77.5983),
//       LatLng(12.9751, 77.5989),
//       LatLng(12.9756, 77.5994),
//       LatLng(12.9760, 77.5999),
//       LatLng(12.9764, 77.6005),
//       LatLng(12.9769, 77.6010),
//       LatLng(12.9773, 77.6016),
//       LatLng(12.9777, 77.6021),
//       LatLng(12.9781, 77.6027),
//       LatLng(12.9785, 77.6033),
//       LatLng(12.9790, 77.6038),
//       LatLng(12.9794, 77.6044),
//       LatLng(12.9798, 77.6050),
//       LatLng(12.9803, 77.6056),
//       LatLng(12.9807, 77.6061),
//       LatLng(12.9811, 77.6067),
//       LatLng(12.9815, 77.6072),
//       LatLng(12.9820, 77.6078), // End - Near Ulsoor
//     ];

//     // Start marker at first point
//     _movingMarker = _routePoints.isNotEmpty ? _routePoints[0] : null;

//     // Move map to initial center
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_routePoints.isNotEmpty) {
//         _mapController.move(_routePoints[0], 13);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _playTimer?.cancel();
//     super.dispose();
//   }

//   void _togglePlayback() {
//     if (_isPlaying) {
//       _stopPlayback();
//     } else {
//       _startPlayback();
//     }
//   }

//   void _startPlayback() {
//     if (_routePoints.isEmpty) return;

//     // Reset index if at end
//     if (_playIndex >= _routePoints.length - 1) {
//       _playIndex = 0;
//       _movingMarker = _routePoints[0];

//       // reset paths
//       completedPath = [_routePoints[0]];
//       remainingPath = List.from(_routePoints);

//       _mapController.move(_movingMarker!, _currentZoom);
//     }

//     _playTimer?.cancel();
//     setState(() => _isPlaying = true);

//     _playTimer = Timer.periodic(Duration(milliseconds: _tickMs), (timer) {
//       if (_playIndex < _routePoints.length - 1) {
//         _playIndex++;
//         _movingMarker = _routePoints[_playIndex];

//         // 🔵 UPDATE PATHS (THIS IS THE IMPORTANT PART)
//         completedPath = _routePoints.sublist(0, _playIndex + 1);
//         remainingPath = _routePoints.sublist(_playIndex);

//         // Follow marker
//         _mapController.move(_movingMarker!, _currentZoom);

//         // Rebuild UI
//         setState(() {});
//       } else {
//         _stopPlayback();
//       }
//     });
//   }

//   void _stopPlayback() {
//     _playTimer?.cancel();
//     setState(() {
//       _isPlaying = false;
//     });
//   }

//   double _calculateBearing(LatLng from, LatLng to) {
//     final lat1 = from.latitude * pi / 180;
//     final lon1 = from.longitude * pi / 180;
//     final lat2 = to.latitude * pi / 180;
//     final lon2 = to.longitude * pi / 180;

//     final dLon = lon2 - lon1;

//     final y = sin(dLon) * cos(lat2);
//     final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

//     double brng = atan2(y, x);
//     brng = brng * 180 / pi;
//     return (brng + 360) % 360;
//   }

//   Future<TripsModel?> fetchTrips() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("accessToken") ?? "";

//     final url = Uri.parse(
//       "${BaseURLConfig.tripsApiUrl}?currentIndex=0&sizePerPage=10",
//     );

//     final response = await http.get(
//       url,
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//     );

//     if (response.statusCode == 200) {
//       LoggerUtil.getInstance.print(response.body);

//       return TripsModel.fromJson(json.decode(response.body));
//     } else {
//       print("Error: ${response.statusCode}");
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ResponsiveLayout(
//       mobile: _buildMobileLayout(),
//       tablet: _buildTabletLayout(),
//       desktop: _buildDesktopLayout(),
//     );
//   }

//   Widget _buildMobileLayout() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // _buildTitle(isDark),
//           FleetTitleBar(isDark: isDark, title: "Trips"),

//           const SizedBox(height: 10),
//           _buildFilterBySearch(isDark),
//           const SizedBox(height: 10),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//             decoration: BoxDecoration(
//               color: isDark ? tWhite.withOpacity(0.1) : tGrey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildSwapButton("All Trips", isDark),
//                 _buildSwapButton("Ongoing", isDark),
//                 _buildSwapButton("Completed", isDark),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 children:
//                     filteredTrips
//                         .map(
//                           (trip) => Padding(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 5.0,
//                               vertical: 5,
//                             ),
//                             child: GestureDetector(
//                               onTap: () {
//                                 if (trip['status'] == 'Completed') {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder:
//                                           (_) => TripDetailScreen(trip: trip),
//                                     ),
//                                   );
//                                 }
//                               },
//                               child: buildTripCard(
//                                 isDark: isDark,
//                                 tripNumber: trip['tripNumber'],
//                                 truckNumber: trip['truckNumber'],
//                                 status: trip['status'],
//                                 startTime: trip['startTime'],
//                                 endTime: trip['endTime'],
//                                 durationMins: trip['durationMins'],
//                                 distanceKm: trip['distanceKm'],
//                                 maxSpeed: trip['maxSpeed'],
//                                 avgSpeed: trip['avgSpeed'],
//                                 source: trip['source'],
//                                 destination: trip['destination'],
//                               ),
//                             ),
//                           ),
//                         )
//                         .toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabletLayout() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Padding(
//       padding: const EdgeInsets.all(10.0),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [_buildTitle(isDark), _buildFilterBySearch(isDark)],
//           ),
//           const SizedBox(height: 10),

//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
//             decoration: BoxDecoration(
//               color: isDark ? tWhite.withOpacity(0.1) : tGrey.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildSwapButton("All Trips", isDark),
//                 _buildSwapButton("Ongoing", isDark),
//                 _buildSwapButton("Completed", isDark),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           // Trips Grid
//           Expanded(
//             child: GridView.builder(
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2, // 4 → no selection, 2 → detail open
//                 mainAxisSpacing: 12,
//                 crossAxisSpacing: 12,
//                 childAspectRatio: 2,
//               ),
//               itemCount: paginatedTrips.length,
//               itemBuilder: (context, index) {
//                 final trip = paginatedTrips[index];
//                 return GestureDetector(
//                   onTap: () {
//                     if (trip['status'] == 'Completed') {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => TripDetailScreen(trip: trip),
//                         ),
//                       );
//                     }
//                   },
//                   child: buildTripCard(
//                     isDark: isDark,
//                     tripNumber: trip['tripNumber'],
//                     truckNumber: trip['truckNumber'],
//                     status: trip['status'],
//                     startTime: trip['startTime'],
//                     endTime: trip['endTime'],
//                     durationMins: trip['durationMins'],
//                     distanceKm: trip['distanceKm'],
//                     maxSpeed: trip['maxSpeed'],
//                     avgSpeed: trip['avgSpeed'],
//                     source: trip['source'],
//                     destination: trip['destination'],
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Pagination controls
//           if (totalPages > 1)
//             Padding(
//               padding: const EdgeInsets.only(top: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios_new, size: 18),
//                     onPressed: _previousPage,
//                   ),
//                   Text(
//                     "Page $currentPage of $totalPages",
//                     style: GoogleFonts.urbanist(
//                       fontSize: 14,
//                       color: isDark ? tWhite : tBlack,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.arrow_forward_ios, size: 18),
//                     onPressed: _nextPage,
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDesktopLayout() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             FleetTitleBar(isDark: isDark, title: "Trips"),
//             _buildFilterBySearch(isDark),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Expanded(
//           child: Row(
//             children: [
//               // LEFT PANEL (Trips Grid)
//               Expanded(
//                 flex:
//                     selectedTrip == null
//                         ? 10
//                         : 5, // shrink grid when trip selected
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Filter buttons
//                       Container(
//                         width: 600,
//                         height: 40,
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: isDark ? tWhite : tBlack,
//                             width: 0.6,
//                           ),
//                         ),
//                         padding: const EdgeInsets.all(5),

//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             _buildSwapButton("All Trips", isDark),
//                             _buildSwapButton("Ongoing", isDark),
//                             _buildSwapButton("Completed", isDark),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 10),

//                       // Trips Grid
//                       Expanded(
//                         child: GridView.builder(
//                           gridDelegate:
//                               SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount:
//                                     selectedTrip == null
//                                         ? 4
//                                         : 2, // 4 → no selection, 2 → detail open
//                                 mainAxisSpacing: 12,
//                                 crossAxisSpacing: 12,
//                                 childAspectRatio: 1.5,
//                               ),
//                           itemCount: paginatedTrips.length,
//                           itemBuilder: (context, index) {
//                             final trip = paginatedTrips[index];
//                             return GestureDetector(
//                               onTap: () {
//                                 // if (trip['status'] == 'Completed') {
//                                 //   setState(() {
//                                 //     selectedTrip = trip;
//                                 //   });
//                                 // }
//                                 setState(() {
//                                   selectedTrip = trip;
//                                 });
//                               },
//                               child: buildTripCard(
//                                 isDark: isDark,
//                                 tripNumber: trip['tripNumber'],
//                                 truckNumber: trip['truckNumber'],
//                                 status: trip['status'],
//                                 startTime: trip['startTime'],
//                                 endTime: trip['endTime'],
//                                 durationMins: trip['durationMins'],
//                                 distanceKm: trip['distanceKm'],
//                                 maxSpeed: trip['maxSpeed'],
//                                 avgSpeed: trip['avgSpeed'],
//                                 source: trip['source'],
//                                 destination: trip['destination'],
//                               ),
//                             );
//                           },
//                         ),
//                       ),

//                       // Pagination controls
//                       if (totalPages > 1) _buildPaginationControls(isDark),
//                     ],
//                   ),
//                 ),
//               ),

//               // RIGHT PANEL (Trip Details)
//               if (selectedTrip != null)
//                 Expanded(
//                   flex: 5,
//                   child: Container(
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color:
//                           isDark
//                               ? tWhite.withOpacity(0.05)
//                               : tGrey.withOpacity(0.05),
//                     ),
//                     child: _buildTripDetailsView(selectedTrip!, isDark),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPaginationControls(bool isDark) {
//     const int visiblePageCount = 5;

//     // Determine start and end of visible window
//     int startPage =
//         ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
//     int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

//     final pageButtons = <Widget>[];

//     for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
//       final isSelected = pageNum == currentPage;

//       pageButtons.add(
//         GestureDetector(
//           onTap: () {
//             if (!mounted) return;
//             setState(() => currentPage = pageNum);
//           },
//           child: Container(
//             margin: const EdgeInsets.symmetric(horizontal: 4),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             decoration: BoxDecoration(
//               color: isSelected ? tBlue : Colors.transparent,
//               borderRadius: BorderRadius.circular(6),
//               border: Border.all(
//                 color:
//                     isSelected
//                         ? tBlue
//                         : (isDark ? Colors.white54 : Colors.black54),
//               ),
//             ),
//             child: Text(
//               '$pageNum',
//               style: GoogleFonts.urbanist(
//                 color:
//                     isSelected
//                         ? tWhite
//                         : (isDark
//                             ? tWhite.withOpacity(0.8)
//                             : tBlack.withOpacity(0.8)),
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final controller = TextEditingController();

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           /// Previous Button
//           IconButton(
//             icon: Icon(
//               Icons.chevron_left,
//               color: isDark ? tWhite : tBlack,
//               size: 22,
//             ),
//             onPressed: () {
//               if (currentPage > 1) {
//                 setState(() => currentPage--);
//               }
//             },
//           ),

//           /// Page Buttons (windowed 5)
//           Row(children: pageButtons),

//           /// Next Button
//           IconButton(
//             icon: Icon(
//               Icons.chevron_right,
//               color: isDark ? tWhite : tBlack,
//               size: 22,
//             ),
//             onPressed: () {
//               if (currentPage < totalPages) {
//                 setState(() => currentPage++);
//               }
//             },
//           ),

//           const SizedBox(width: 16),

//           /// Page Input Box
//           SizedBox(
//             width: 70,
//             height: 32,
//             child: TextField(
//               controller: controller,
//               style: GoogleFonts.urbanist(
//                 fontSize: 13,
//                 color: isDark ? tWhite : tBlack,
//               ),
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 hintText: 'Page',
//                 hintStyle: GoogleFonts.urbanist(
//                   fontSize: 12,
//                   color: isDark ? Colors.white54 : Colors.black54,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 4,
//                 ),
//                 border: OutlineInputBorder(
//                   borderSide: BorderSide(
//                     color: isDark ? tWhite : tBlack,
//                     width: 0.8,
//                   ),
//                 ),
//               ),
//               onSubmitted: (value) {
//                 final page = int.tryParse(value);
//                 if (page != null &&
//                     page >= 1 &&
//                     page <= totalPages &&
//                     mounted) {
//                   setState(() => currentPage = page);
//                 }
//               },
//             ),
//           ),

//           const SizedBox(width: 10),

//           /// Show visible range (e.g., "1–5 of 20")
//           Text(
//             '$startPage–$endPage of $totalPages',
//             style: GoogleFonts.urbanist(
//               fontSize: 13,
//               color: isDark ? tWhite : tBlack,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTitle(bool isDark) => Text(
//     'Trips',
//     style: GoogleFonts.urbanist(
//       fontSize: 20,
//       color: isDark ? tWhite : tBlack,
//       fontWeight: FontWeight.bold,
//     ),
//   );

//   Widget _buildFilterBySearch(bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 250,
//           height: 40,
//           decoration: BoxDecoration(
//             color: tTransparent,
//             border: Border.all(color: isDark ? tWhite : tBlack, width: 1),
//           ),
//           child: TextField(
//             style: GoogleFonts.urbanist(
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//               color: isDark ? tWhite : tBlack,
//             ),
//             decoration: InputDecoration(
//               hintText: 'Search',
//               hintStyle: GoogleFonts.urbanist(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//                 color: isDark ? tWhite : tBlack,
//               ),
//               border: InputBorder.none,
//               prefixIcon: Icon(
//                 CupertinoIcons.search,
//                 color: isDark ? tWhite : tBlack,
//                 size: 18,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(
//           '(Note: Filter by Search)',
//           style: GoogleFonts.urbanist(
//             fontSize: 10,
//             color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSwapButton(String label, bool isDark) {
//     final bool isSelected = selectedFilter == label;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             selectedFilter = label;
//           });
//         },
//         child: Container(
//           decoration: BoxDecoration(color: isSelected ? tBlue : tTransparent),
//           alignment: Alignment.center,
//           child: Text(
//             label,
//             style: GoogleFonts.urbanist(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//               color: isSelected ? tWhite : (isDark ? tWhite : tBlack),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget buildTripCard({
//     required bool isDark,
//     required String tripNumber,
//     required String truckNumber,
//     required String status,
//     required String startTime,
//     required String endTime,
//     required String durationMins,
//     required String distanceKm,
//     required String maxSpeed,
//     required String avgSpeed,
//     required String source,
//     required String destination,
//   }) {
//     Color statusColor;
//     switch (status.toLowerCase()) {
//       case 'ongoing':
//         statusColor = tGreen;
//         break;
//       case 'completed':
//         statusColor = tBlue;
//         break;
//       default:
//         statusColor = tGrey;
//     }

//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: isDark ? tBlack : tWhite,
//         // borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             spreadRadius: 2,
//             blurRadius: 10,
//             color: isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(10),
//       child: Column(
//         children: [
//           // Header row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: statusColor, width: 1),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Column(
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(vertical: 4),
//                         decoration: BoxDecoration(
//                           // color: statusColor,
//                           gradient: SweepGradient(
//                             colors: [statusColor, statusColor.withOpacity(0.6)],
//                           ),
//                           borderRadius: const BorderRadius.only(
//                             topLeft: Radius.circular(5),
//                             topRight: Radius.circular(5),
//                           ),
//                         ),
//                         child: Text(
//                           tripNumber,
//                           style: GoogleFonts.urbanist(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w700,
//                             color: isDark ? tBlack : tWhite,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(4.0),
//                         child: Text(
//                           'TRUCK - $truckNumber',
//                           style: GoogleFonts.urbanist(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w600,
//                             color: isDark ? tWhite : tBlack,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(width: 15),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       // color: statusColor,
//                       gradient: SweepGradient(
//                         colors: [statusColor, statusColor.withOpacity(0.6)],
//                       ),
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     child: Text(
//                       status,
//                       style: GoogleFonts.urbanist(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         color: isDark ? tBlack : tWhite,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     'Time: $startTime / $endTime',
//                     style: GoogleFonts.urbanist(
//                       fontSize: 11,
//                       color: isDark ? tWhite : tBlack,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildStatColumn(
//                 isDark,
//                 title: 'Trip Duration (min)',
//                 value: durationMins,
//               ),
//               _buildStatColumn(
//                 isDark,
//                 title: 'Trip Distance (km)',
//                 value: distanceKm,
//                 alignEnd: true,
//               ),
//             ],
//           ),
//           const SizedBox(height: 5),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildStatColumn(
//                 isDark,
//                 title: 'Trip MAX Speed (km/h)',
//                 value: maxSpeed,
//               ),
//               _buildStatColumn(
//                 isDark,
//                 title: 'Trip AVG Speed (km/h)',
//                 value: avgSpeed,
//                 alignEnd: true,
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Divider(
//             color: isDark ? tWhite.withOpacity(0.4) : tBlack.withOpacity(0.4),
//             thickness: 0.3,
//           ),
//           const SizedBox(height: 6),
//           Row(
//             children: [
//               SvgPicture.asset(
//                 'icons/geofence.svg',
//                 width: 16,
//                 height: 16,
//                 color: tGreen,
//               ),
//               const SizedBox(width: 5),
//               Expanded(
//                 child: Text(
//                   'Source: $source',
//                   style: GoogleFonts.urbanist(
//                     fontSize: 13,
//                     color: isDark ? tWhite : tBlack,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 5),
//           Row(
//             children: [
//               SvgPicture.asset(
//                 'icons/geofence.svg',
//                 width: 16,
//                 height: 16,
//                 color: tRedDark,
//               ),
//               const SizedBox(width: 5),
//               Expanded(
//                 child: Text(
//                   'Destination: $destination',
//                   style: GoogleFonts.urbanist(
//                     fontSize: 13,
//                     color: isDark ? tWhite : tBlack,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatColumn(
//     bool isDark, {
//     required String title,
//     required String value,
//     bool alignEnd = false,
//   }) {
//     return Column(
//       crossAxisAlignment:
//           alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: GoogleFonts.urbanist(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//             color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
//           ),
//         ),
//         Text(
//           value,
//           style: GoogleFonts.urbanist(
//             fontSize: 13,
//             fontWeight: FontWeight.bold,
//             color: isDark ? tWhite : tBlack,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTripDetailsView(Map<String, dynamic> trip, bool isDark) {
//     return Container(
//       height: double.infinity,
//       margin: const EdgeInsets.all(3),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: isDark ? tWhite.withOpacity(0.05) : tWhite,
//         boxShadow: [
//           BoxShadow(
//             color:
//                 isDark
//                     ? Colors.black.withOpacity(0.4)
//                     : Colors.grey.withOpacity(0.2),
//             blurRadius: 10,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header Row (Title + Close)
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "#${trip['tripNumber']}",
//                 style: GoogleFonts.urbanist(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? tWhite : tBlack,
//                 ),
//               ),
//               IconButton(
//                 onPressed: () {
//                   setState(() {
//                     selectedTrip = null;
//                   });
//                 },
//                 icon: Icon(
//                   CupertinoIcons.xmark_circle_fill,
//                   color: isDark ? tRed : Colors.redAccent,
//                   size: 22,
//                 ),
//                 tooltip: "Close",
//               ),
//             ],
//           ),

//           Divider(
//             color: isDark ? tWhite.withOpacity(0.2) : tBlack.withOpacity(0.1),
//             thickness: 0.5,
//           ),

//           // const SizedBox(height: 8),

//           // Buttons Row
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               _buildStyledDetailButton(
//                 () {},
//                 "Download Trip",
//                 CupertinoIcons.cloud_download,
//                 isDark,
//               ),
//               const SizedBox(width: 10),
//               _buildStyledDetailButton(
//                 () => _togglePlayback(),
//                 _isPlaying ? "Stop Playback" : "Route Playback",
//                 CupertinoIcons.play_arrow_solid,
//                 isDark,
//               ),
//             ],
//           ),

//           const SizedBox(height: 5),

//           // Map placeholder
//           Expanded(
//             flex: 5,
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color:
//                     isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
//               ),
//               padding: const EdgeInsets.all(2),
//               child: FlutterMap(
//                 mapController: _mapController,
//                 options: MapOptions(
//                   initialCenter:
//                       _routePoints.isNotEmpty
//                           ? _routePoints[0]
//                           : LatLng(12.9716, 77.5946),
//                   initialZoom: _currentZoom,
//                   onPositionChanged: (position, _) {
//                     _currentZoom = position.zoom ?? _currentZoom;
//                   },
//                 ),

//                 children: [
//                   TileLayer(
//                     urlTemplate:
//                         isDark
//                             ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
//                             : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
//                     subdomains: const ['a', 'b', 'c'],
//                     userAgentPackageName: 'com.example.app',
//                   ),

//                   // Route polyline
//                   PolylineLayer(
//                     polylines: [
//                       if (completedPath.length > 1)
//                         Polyline(
//                           points: completedPath,
//                           strokeWidth: 6,
//                           color: Colors.lightBlueAccent.withOpacity(0.6),
//                         ),

//                       if (remainingPath.length > 1)
//                         Polyline(
//                           points: remainingPath,
//                           strokeWidth: 6,
//                           color: tBlue,
//                         ),
//                     ],
//                   ),

//                   // Marker layer: start, end, and moving marker
//                   MarkerLayer(
//                     markers: [
//                       if (_routePoints.isNotEmpty)
//                         Marker(
//                           point: _routePoints.first,
//                           width: 32,
//                           height: 32,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: tWhite, // inner dot
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: tGreen.withOpacity(0.7),
//                                   blurRadius: 12,
//                                   spreadRadius: 3,
//                                 ),
//                               ],
//                               border: Border.all(color: tGreen, width: 4),
//                             ),
//                             child: Center(
//                               child: Icon(
//                                 Icons.circle,
//                                 size: 16,
//                                 color: tGreen,
//                               ),
//                             ),
//                           ),
//                         ),

//                       if (_routePoints.length > 1)
//                         Marker(
//                           point: _routePoints.last,
//                           width: 32,
//                           height: 32,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: tWhite,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: tRedDark.withOpacity(0.7),
//                                   blurRadius: 12,
//                                   spreadRadius: 3,
//                                 ),
//                               ],
//                               border: Border.all(color: tRedDark, width: 4),
//                             ),
//                             child: Center(
//                               child: Icon(
//                                 Icons.circle,
//                                 size: 14,
//                                 color: tRedDark,
//                               ),
//                             ),
//                           ),
//                         ),

//                       // moving marker (only when there is a position)
//                       if (_movingMarker != null)
//                         Marker(
//                           point: _movingMarker!,
//                           width: 40,
//                           height: 40,
//                           child: Transform.rotate(
//                             angle:
//                                 (_playIndex < _routePoints.length - 1)
//                                     ? _calculateBearing(
//                                           _routePoints[_playIndex],
//                                           _routePoints[_playIndex + 1],
//                                         ) *
//                                         pi /
//                                         180
//                                     : 0,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: tBlue.withOpacity(0.8),
//                               ),
//                               padding: const EdgeInsets.all(6),
//                               child: Icon(
//                                 Icons.navigation_rounded,
//                                 size: 25,
//                                 color: tWhite,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),

//           // Playback progress / info
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Playback: ${_playIndex + 1}/${_routePoints.length}',
//                 style: GoogleFonts.urbanist(fontSize: 13),
//               ),
//               Text(
//                 trip['source'] ?? '',
//                 style: GoogleFonts.urbanist(
//                   fontSize: 13,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // Modern elevated action buttons
//   Widget _buildStyledDetailButton(
//     VoidCallback onPressed,
//     String text,
//     IconData icon,
//     bool isDark,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, size: 16, color: tBlue),
//       label: Text(
//         text,
//         style: GoogleFonts.urbanist(
//           fontSize: 13,
//           fontWeight: FontWeight.w600,
//           color: tBlue,
//         ),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isDark ? tBlack : tWhite,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//           side: BorderSide(color: tBlue, width: 1),
//         ),
//         elevation: 0,
//       ),
//     );
//   }
// }

// // ---------------- INLINE DETAIL SCREEN (MOBILE/TABLET) ----------------
// class TripDetailScreen extends StatelessWidget {
//   final Map<String, dynamic> trip;
//   const TripDetailScreen({super.key, required this.trip});

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return Scaffold(
//       appBar: AppBar(title: Text('Trip ${trip['tripNumber']} Details')),
//       body: Padding(
//         padding: const EdgeInsets.all(15),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(CupertinoIcons.cloud_download, size: 16),
//                   label: const Text("Download Trip"),
//                 ),
//                 const SizedBox(width: 10),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(CupertinoIcons.play_arrow_solid, size: 16),
//                   label: const Text("Route Playback"),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 color:
//                     isDark ? tWhite.withOpacity(0.08) : tGrey.withOpacity(0.08),
//                 alignment: Alignment.center,
//                 child: Text(
//                   "Map View Here",
//                   style: GoogleFonts.urbanist(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: isDark ? tWhite : tBlack,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svg_flutter/svg.dart';
import 'package:tm_fleet_management/src/provider/fleetModeProvider.dart';
import 'package:tm_fleet_management/src/services/apiServices.dart';
import 'package:tm_fleet_management/src/ui/widgets/components/customTitleBar.dart';
import '../../ui/screens/loginScreen.dart';

import '../../utils/appColors.dart';
import '../../utils/appResponsive.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String selectedFilter = "All Trips";
  Map<String, dynamic>? selectedTrip;
  // flutter_map controller
  final MapController _mapController = MapController();

  // Dummy route coordinates (replace with real route coords per trip)
  late final List<LatLng> _routePoints;
  double _currentZoom = 16.0; // default zoom

  // Playback state
  Timer? _playTimer;
  bool _isPlaying = false;
  int _playIndex = 0;
  LatLng? _movingMarker; // position of the animated marker

  // Playback speed (milliseconds)
  final int _tickMs = 1000;

  // final List<Map<String, dynamic>> allTrips = List.generate(50, (index) {
  //   bool isOngoing = index.isEven;

  //   final bengaluruAreas = [
  //     'Koramangala',
  //     'Indiranagar',
  //     'Whitefield',
  //     'Electronic City',
  //     'HSR Layout',
  //     'Jayanagar',
  //     'BTM Layout',
  //     'MG Road',
  //     'Rajajinagar',
  //     'Malleshwaram',
  //     'Hebbal',
  //     'Yelahanka',
  //     'Ulsoor',
  //     'Marathahalli',
  //     'Banashankari',
  //     'KR Puram',
  //     'Basavanagudi',
  //     'Vijayanagar',
  //     'Bellandur',
  //     'RT Nagar',
  //   ];

  //   final randomSource = bengaluruAreas[index % bengaluruAreas.length];
  //   final randomDestination =
  //       bengaluruAreas[(index + 5) %
  //           bengaluruAreas.length]; // ensure not same as source

  //   final startSOC = 70 + (index % 10); // example values
  //   final endSOC = startSOC - (5 + (index % 3));

  //   final startSOH = 95 - (index % 5);
  //   final endSOH = startSOH - (index % 2);

  //   return {
  //     'tripNumber': '00${index + 1}',
  //     'truckNumber': 'TRK${1000 + index}',
  //     'status': isOngoing ? 'Ongoing' : 'Completed',
  //     'startTime': isOngoing ? '10:${index % 6}0 AM' : '08:${index % 6}0 AM',
  //     'endTime': isOngoing ? '—' : '09:${index % 6}0 AM',
  //     'durationMins': '${20 + index * 3}',
  //     'distanceKm': '${10 + index * 2}',
  //     'maxSpeed': '${60 + index * 2}',
  //     'avgSpeed': '${45 + (index % 20)}',
  //     'startSOC': '$startSOC%',
  //     'endSOC': '$endSOC%',
  //     'startSOH': '$startSOH%',
  //     'endSOH': '$endSOH%',
  //     'source': '$randomSource, Bengaluru',
  //     'destination': '$randomDestination, Bengaluru',
  //   };
  // });

  List<Map<String, dynamic>> allTrips = [];
  int currentIndex = 0;
  int sizePerPage = 12;
  int totalCount = 0;

  bool isLoading = false;
  String formatDate(String? utc) {
    if (utc == null || utc.isEmpty) return '';
    final date = DateTime.parse(utc);
    return DateFormat('dd MMM yyyy HH:mm').format(date);
  }

  Future<void> fetchTrips() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? '';

    final response = await http.get(
      Uri.parse(
        "${BaseURLConfig.tripsApiUrl}?currentIndex=$currentIndex&sizePerPage=$sizePerPage",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        totalCount = data["totalCount"] ?? 0;

        final List entities = data["entities"] ?? [];

        allTrips =
            entities.map<Map<String, dynamic>>((t) {
              return {
                "tripNumber": (t["id"] ?? '').toString(),
                "truckNumber": (t["imei"] ?? '').toString(),
                "status": t["tripStatus"],
                "startTime": formatDate(t["tripStartTime"]),
                "endTime": formatDate(t["tripEndTime"]),
                "durationMins": (t["totalTime"] ?? 0).toString(),
                "distanceKm": (t["totalDistance"] ?? 0).toString(),
                "maxSpeed": (t["maxSpeed"] ?? 0).toString(),
                "avgSpeed": (t["averageSpeed"] ?? 0).toString(),
                "startSOC": "${t["startSOCReading"] ?? 0}%",
                "endSOC": "${t["endSOCReading"] ?? 0}%",
                "startSOH": "${t["startSOHReading"] ?? 0}%",
                "source": (t["startAddress"] ?? 'Unknown').toString(),
                "destination": (t["endAddress"] ?? 'Unknown').toString(),
              };
            }).toList();
      });
    } else {
      print("API ERROR: ${response.statusCode}  ${response.body}");
    }

    setState(() => isLoading = false);
  }

  List<Map<String, dynamic>> get filteredTrips {
    if (selectedFilter == "Ongoing") {
      return allTrips.where((t) => t['status'] == 0).toList();
    } else if (selectedFilter == "Completed") {
      return allTrips.where((t) => t['status'] == 1).toList();
    }
    return allTrips;
  }

  int currentPage = 1;
  int get totalPages => (totalCount / sizePerPage).ceil();

  // List<Map<String, dynamic>> get paginatedTrips {
  //   final start = (currentPage - 1) * itemsPerPage;
  //   final end = start + itemsPerPage;
  //   return filteredTrips.sublist(
  //     start,
  //     end > filteredTrips.length ? filteredTrips.length : end,
  //   );
  // }

  void _nextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      currentIndex = (currentPage - 1) * sizePerPage;
      fetchTrips();
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      currentPage--;
      currentIndex = (currentPage - 1) * sizePerPage;
      fetchTrips();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTrips();

    // Example dummy route between two points (replace coordinates as needed)
    _routePoints = [
      LatLng(12.9716, 77.5946), // Start - MG Road
      LatLng(12.9719, 77.5952),
      LatLng(12.9723, 77.5958),
      LatLng(12.9728, 77.5963),
      LatLng(12.9733, 77.5968),
      LatLng(12.9738, 77.5973),
      LatLng(12.9742, 77.5978),
      LatLng(12.9747, 77.5983),
      LatLng(12.9751, 77.5989),
      LatLng(12.9756, 77.5994),
      LatLng(12.9760, 77.5999),
      LatLng(12.9764, 77.6005),
      LatLng(12.9769, 77.6010),
      LatLng(12.9773, 77.6016),
      LatLng(12.9777, 77.6021),
      LatLng(12.9781, 77.6027),
      LatLng(12.9785, 77.6033),
      LatLng(12.9790, 77.6038),
      LatLng(12.9794, 77.6044),
      LatLng(12.9798, 77.6050),
      LatLng(12.9803, 77.6056),
      LatLng(12.9807, 77.6061),
      LatLng(12.9811, 77.6067),
      LatLng(12.9815, 77.6072),
      LatLng(12.9820, 77.6078), // End - Near Ulsoor
    ];

    // Start marker at first point
    _movingMarker = _routePoints.isNotEmpty ? _routePoints[0] : null;

    // Move map to initial center
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_routePoints.isNotEmpty) {
        _mapController.move(_routePoints[0], 13);
      }
    });
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_routePoints.isEmpty) return;

    // Reset index if at end
    if (_playIndex >= _routePoints.length - 1) {
      _playIndex = 0;
      _movingMarker = _routePoints[0];
      _mapController.move(_movingMarker!, _currentZoom);
    }

    _playTimer?.cancel();
    setState(() => _isPlaying = true);

    _playTimer = Timer.periodic(Duration(milliseconds: _tickMs), (timer) {
      // Move index forward
      if (_playIndex < _routePoints.length - 1) {
        _playIndex++;
        _movingMarker = _routePoints[_playIndex];

        // Move map center to follow the moving marker (optional)
        _mapController.move(_movingMarker!, _currentZoom);

        // Trigger rebuild to update marker layer
        setState(() {});
      } else {
        // reached the end — stop playback
        _stopPlayback();
      }
    });
  }

  void _stopPlayback() {
    _playTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<FleetModeProvider>().mode;
    final isEVMode = mode == "EV Fleet";

    return ResponsiveLayout(
      mobile: _buildMobileLayout(isEVMode),
      tablet: _buildTabletLayout(isEVMode),
      desktop: _buildDesktopLayout(isEVMode),
    );
  }

  Widget _buildMobileLayout(isEVMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(isDark),
          const SizedBox(height: 10),
          _buildFilterBySearch(isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? tWhite.withOpacity(0.1) : tGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSwapButton("All Trips", isDark),
                _buildSwapButton("Ongoing", isDark),
                _buildSwapButton("Completed", isDark),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      child: Column(
                        children:
                            filteredTrips
                                .map(
                                  (trip) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5.0,
                                      vertical: 5,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        if (trip['status'] == 'Completed') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => TripDetailScreen(
                                                    trip: trip,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      child: buildTripCard(
                                        isDark: isDark,
                                        isEVMode: isEVMode,
                                        tripNumber: trip['tripNumber'] ?? '',
                                        truckNumber: trip['truckNumber'] ?? '',
                                        status:
                                            trip['status'] == 0
                                                ? 'Ongoing'
                                                : 'Completed',
                                        startTime: trip['startTime'] ?? '',
                                        endTime: trip['endTime'] ?? '',
                                        durationMins:
                                            trip['durationMins'] ?? '0',
                                        distanceKm: trip['distanceKm'] ?? '0',
                                        maxSpeed: trip['maxSpeed'] ?? '0',
                                        avgSpeed: trip['avgSpeed'] ?? '0',
                                        startSOC: trip['startSOC'] ?? '0%',
                                        endSOC: trip['endSOC'] ?? '0%',
                                        startSOH: trip['startSOH'] ?? '0%',
                                        source: trip['source'] ?? 'Unknown',
                                        destination:
                                            trip['destination'] ?? 'Unknown',
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(isEVMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildTitle(isDark), _buildFilterBySearch(isDark)],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? tWhite.withOpacity(0.1) : tGrey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSwapButton("All Trips", isDark),
                _buildSwapButton("Ongoing", isDark),
                _buildSwapButton("Completed", isDark),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Trips Grid
          Expanded(
            child:
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 4 → no selection, 2 → detail open
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2,
                      ),
                      itemCount: filteredTrips.length,

                      itemBuilder: (context, index) {
                        final trip = filteredTrips[index];
                        return GestureDetector(
                          onTap: () {
                            if (trip['status'] == 'Completed') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripDetailScreen(trip: trip),
                                ),
                              );
                            }
                          },
                          child: buildTripCard(
                            isDark: isDark,
                            isEVMode: isEVMode,
                            tripNumber: trip['tripNumber'] ?? '',
                            truckNumber: trip['truckNumber'] ?? '',
                            status:
                                trip['status'] == 0 ? 'Ongoing' : 'Completed',
                            startTime: trip['startTime'] ?? '',
                            endTime: trip['endTime'] ?? '',
                            durationMins: trip['durationMins'] ?? '0',
                            distanceKm: trip['distanceKm'] ?? '0',
                            maxSpeed: trip['maxSpeed'] ?? '0',
                            avgSpeed: trip['avgSpeed'] ?? '0',
                            startSOC: trip['startSOC'] ?? '0%',
                            endSOC: trip['endSOC'] ?? '0%',
                            startSOH: trip['startSOH'] ?? '0%',
                            source: trip['source'] ?? 'Unknown',
                            destination: trip['destination'] ?? 'Unknown',
                          ),
                        );
                      },
                    ),
          ),

          // Pagination controls
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: _previousPage,
                  ),
                  Text(
                    "Page $currentPage of $totalPages",
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: isDark ? tWhite : tBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(isEVMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildTitle(isDark), _buildFilterBySearch(isDark)],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              // LEFT PANEL (Trips Grid)
              Expanded(
                flex:
                    selectedTrip == null
                        ? 10
                        : 5, // shrink grid when trip selected
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter buttons
                      Container(
                        width: 600,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? tWhite : tBlack,
                            width: 0.6,
                          ),
                        ),
                        padding: const EdgeInsets.all(5),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSwapButton("All Trips", isDark),
                            _buildSwapButton("Ongoing", isDark),
                            _buildSwapButton("Completed", isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Trips Grid
                      Expanded(
                        child:
                            isLoading
                                ? Center(child: CircularProgressIndicator())
                                : GridView.builder(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount:
                                            selectedTrip == null
                                                ? 4
                                                : 2, // 4 → no selection, 2 → detail open
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 1.5,
                                      ),
                                  itemCount: filteredTrips.length,
                                  itemBuilder: (context, index) {
                                    final trip = filteredTrips[index];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedTrip = trip;
                                        });
                                      },
                                      child: buildTripCard(
                                        isDark: isDark,
                                        isEVMode: isEVMode,
                                        tripNumber: trip['tripNumber'] ?? '',
                                        truckNumber: trip['truckNumber'] ?? '',
                                        status:
                                            trip['status'] == 0
                                                ? 'Ongoing'
                                                : 'Completed',
                                        startTime: trip['startTime'] ?? '',
                                        endTime: trip['endTime'] ?? '',
                                        durationMins:
                                            trip['durationMins'] ?? '0',
                                        distanceKm: trip['distanceKm'] ?? '0',
                                        maxSpeed: trip['maxSpeed'] ?? '0',
                                        avgSpeed: trip['avgSpeed'] ?? '0',
                                        startSOC: trip['startSOC'] ?? '0%',
                                        endSOC: trip['endSOC'] ?? '0%',
                                        startSOH: trip['startSOH'] ?? '0%',
                                        source: trip['source'] ?? 'Unknown',
                                        destination:
                                            trip['destination'] ?? 'Unknown',
                                      ),
                                    );
                                  },
                                ),
                      ),

                      // Pagination controls
                      if (totalPages > 1) _buildPaginationControls(isDark),
                    ],
                  ),
                ),
              ),

              // RIGHT PANEL (Trip Details)
              if (selectedTrip != null)
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? tWhite.withOpacity(0.05)
                              : tGrey.withOpacity(0.05),
                    ),
                    child: _buildTripDetailsView(selectedTrip!, isDark),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    const int visiblePageCount = 5;

    // Determine start and end of visible window
    int startPage =
        ((currentPage - 1) ~/ visiblePageCount) * visiblePageCount + 1;
    int endPage = (startPage + visiblePageCount - 1).clamp(1, totalPages);

    final pageButtons = <Widget>[];

    for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
      final isSelected = pageNum == currentPage;

      pageButtons.add(
        GestureDetector(
          onTap: () {
            if (!mounted) return;
            setState(() {
              currentPage = pageNum;
              currentIndex = (currentPage - 1) * sizePerPage;
            });
            fetchTrips();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? tBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isSelected
                        ? tBlue
                        : (isDark ? Colors.white54 : Colors.black54),
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
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Previous Button
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: isDark ? tWhite : tBlack,
              size: 22,
            ),
            onPressed: () {
              if (currentPage > 1) {
                currentPage--;
                currentIndex = (currentPage - 1) * sizePerPage;
                fetchTrips();
              }
            },
          ),

          /// Page Buttons (windowed 5)
          Row(children: pageButtons),

          /// Next Button
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isDark ? tWhite : tBlack,
              size: 22,
            ),
            onPressed: () {
              if (currentPage < totalPages) {
                currentPage++;
                currentIndex = (currentPage - 1) * sizePerPage;
                fetchTrips();
              }
            },
          ),

          const SizedBox(width: 16),

          /// Page Input Box
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
              decoration: InputDecoration(
                hintText: 'Page',
                hintStyle: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? tWhite : tBlack,
                    width: 0.8,
                  ),
                ),
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null &&
                    page >= 1 &&
                    page <= totalPages &&
                    mounted) {
                  setState(() {
                    currentPage = page;
                    currentIndex = (currentPage - 1) * sizePerPage;
                  });
                  fetchTrips();
                }
              },
            ),
          ),

          const SizedBox(width: 10),

          /// Show visible range (e.g., "1–5 of 20")
          Text(
            '$startPage–$endPage of $totalPages',
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isDark ? tWhite : tBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) =>
      FleetTitleBar(isDark: isDark, title: "Trips");

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

  Widget _buildSwapButton(String label, bool isDark) {
    final bool isSelected = selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = label;
          });
        },
        child: Container(
          decoration: BoxDecoration(color: isSelected ? tBlue : tTransparent),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? tWhite : (isDark ? tWhite : tBlack),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTripCard({
    required bool isDark,
    required bool isEVMode,
    required String tripNumber,
    required String truckNumber,
    required String status,
    required String startTime,
    required String endTime,
    required String durationMins,
    required String distanceKm,
    required String maxSpeed,
    required String startSOC,
    required String endSOC,
    required String startSOH,
    required String avgSpeed,
    required String source,
    required String destination,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'ongoing':
        statusColor = tGreen;
        break;
      case 'completed':
        statusColor = tBlue;
        break;
      default:
        statusColor = tGrey;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? tBlack : tWhite,
        // borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            spreadRadius: 2,
            blurRadius: 10,
            color: isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
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
                          tripNumber,
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? tBlack : tWhite,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          truckNumber,
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
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  const SizedBox(height: 5),
                  Text(
                    'Time: $startTime \n $endTime',
                    style: GoogleFonts.urbanist(
                      fontSize: 10,
                      color: isDark ? tWhite : tBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                isDark,
                title: 'Trip Duration (min)',
                value: durationMins,
              ),
              _buildStatColumn(
                isDark,
                title: 'Trip Distance (km)',
                value: distanceKm,
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                isDark,
                title: isEVMode ? 'Start - End SOC' : 'Trip MAX Speed (km/h)',
                value: isEVMode ? '$startSOC - $endSOC' : maxSpeed,
              ),
              _buildStatColumn(
                isDark,
                title: isEVMode ? 'SOH' : 'Trip AVG Speed (km/h)',
                value: isEVMode ? startSOH : avgSpeed,
                alignEnd: true,
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
                'assets/icons/geofence.svg',
                width: 16,
                height: 16,
                color: tGreen,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Source: $source',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/geofence.svg',
                width: 16,
                height: 16,
                color: tRedDark,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Destination: $destination',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
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

  Widget _buildStatColumn(
    bool isDark, {
    required String title,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? tWhite.withOpacity(0.6) : tBlack.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetailsView(Map<String, dynamic> trip, bool isDark) {
    return Container(
      height: double.infinity,
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? tWhite.withOpacity(0.05) : tWhite,
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Title + Close)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#${trip['tripNumber']} Details",
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? tWhite : tBlack,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedTrip = null;
                  });
                },
                icon: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: isDark ? tRed : Colors.redAccent,
                  size: 22,
                ),
                tooltip: "Close",
              ),
            ],
          ),

          Divider(
            color: isDark ? tWhite.withOpacity(0.2) : tBlack.withOpacity(0.1),
            thickness: 0.5,
          ),
          // Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildStyledDetailButton(
                () {},
                "Download Trip",
                CupertinoIcons.cloud_download,
                isDark,
              ),
              const SizedBox(width: 10),
              _buildStyledDetailButton(
                () => _togglePlayback(),
                _isPlaying ? "Stop Playback" : "Route Playback",
                CupertinoIcons.play_arrow_solid,
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Map placeholder
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    isDark ? tWhite.withOpacity(0.1) : tBlack.withOpacity(0.1),
              ),
              padding: const EdgeInsets.all(2),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _routePoints.isNotEmpty
                          ? _routePoints[0]
                          : LatLng(12.9716, 77.5946),
                  initialZoom: _currentZoom,
                  onPositionChanged: (position, _) {
                    _currentZoom = position.zoom ?? _currentZoom;
                  },
                ),

                children: [
                  TileLayer(
                    urlTemplate:
                        isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app',
                  ),

                  // Route polyline
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 2,
                        color: tBlue,
                      ),
                    ],
                  ),

                  // Marker layer: start, end, and moving marker
                  MarkerLayer(
                    markers: [
                      if (_routePoints.isNotEmpty)
                        Marker(
                          point: _routePoints.first,
                          width: 6,
                          height: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: tGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (_routePoints.length > 1)
                        Marker(
                          point: _routePoints.last,
                          width: 6,
                          height: 6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: tRedDark,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                      // moving marker (only when there is a position)
                      if (_movingMarker != null)
                        Marker(
                          point: _movingMarker!,
                          width: 35,
                          height: 35,
                          child: Transform.translate(
                            offset: const Offset(-12, -12),
                            child: SvgPicture.asset(
                              'assets/icons/truck1.svg',
                              width: 25,
                              height: 25,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Playback progress / info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Playback: ${_playIndex + 1}/${_routePoints.length}',
                style: GoogleFonts.urbanist(fontSize: 13),
              ),
              Text(
                trip['source'] ?? '',
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Improved info tile for grid layout
  Widget _buildDetailTile(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? tWhite.withOpacity(0.7) : tBlack.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? tWhite : tBlack,
          ),
        ),
      ],
    );
  }

  // Modern elevated action buttons
  Widget _buildStyledDetailButton(
    VoidCallback onPressed,
    String text,
    IconData icon,
    bool isDark,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: tBlue),
      label: Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: tBlue,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? tBlack : tWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tBlue, width: 1),
        ),
        elevation: 0,
      ),
    );
  }
}

// ---------------- INLINE DETAIL SCREEN (MOBILE/TABLET) ----------------
class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;
  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('Trip ${trip['tripNumber']} Details')),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(CupertinoIcons.cloud_download, size: 16),
                  label: const Text("Download Trip"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(CupertinoIcons.play_arrow_solid, size: 16),
                  label: const Text("Route Playback"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                color:
                    isDark ? tWhite.withOpacity(0.08) : tGrey.withOpacity(0.08),
                alignment: Alignment.center,
                child: Text(
                  "Map View Here",
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? tWhite : tBlack,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
