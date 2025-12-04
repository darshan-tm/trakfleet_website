import 'package:go_router/go_router.dart';

import '../../ui/screens/deviceControlWidget.dart';
import '../../ui/screens/fleetModeSelectionScreen.dart';
import '../../ui/screens/landingScreen.dart';
import '../../ui/screens/loadingScreen.dart';
import '../../ui/screens/loginScreen.dart';
import '../../ui/screens/homeScreen.dart';
import '../../ui/screens/dashboardScreen.dart';
import '../../ui/screens/devicesScreen.dart';
import '../../ui/screens/tripsScreen.dart';
import '../../ui/screens/reportsScreen.dart';
import '../../ui/screens/alertsScreen.dart';
import '../../ui/screens/settingsScreen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/loading',
    routes: [
      /// ------------------------------
      /// AUTH & LOADING ROUTES
      /// ------------------------------
      GoRoute(
        path: '/loading',
        name: 'loading',
        builder: (context, state) => const LoadingScreen(),
      ),

      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),

      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/fleetmodeselection',
        name: 'fleetmodeselection',
        builder: (context, state) => const FleetModeSelectionScreen(),
      ),

      /// ------------------------------
      /// MAIN SHELL LAYOUT
      /// ------------------------------
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          /// ------------------------------
          /// DEVICES LIST + NESTED ROUTES
          /// ------------------------------
          GoRoute(
            path: '/home/devices',
            builder: (context, state) {
              final status = state.uri.queryParameters['status'];
              return DevicesScreen(filterStatus: status);
            },
            routes: [
              /// DEVICE DETAIL ROOT
              GoRoute(
                path: ':imei',
                name: 'deviceDetail',
                builder: (context, state) {
                  final device = state.extra as Map<String, dynamic>?;

                  return DeviceControlWidget(
                    device:
                        device ??
                        {
                          'imei':
                              state.pathParameters['imei'] ?? 'Unknown IMEI',
                        },
                    initialTab: 0,
                  );
                },

                routes: [
                  /// SUB-TABS
                  GoRoute(
                    path: 'overview',
                    name: 'deviceOverview',
                    builder: (context, state) {
                      final device = state.extra as Map<String, dynamic>?;

                      return DeviceControlWidget(
                        device:
                            device ??
                            {
                              'imei':
                                  state.pathParameters['imei'] ??
                                  'Unknown IMEI',
                            },
                        initialTab: 0,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'diagnostics',
                    name: 'deviceDiagnostics',
                    builder: (context, state) {
                      final device = state.extra as Map<String, dynamic>?;

                      return DeviceControlWidget(
                        device:
                            device ??
                            {
                              'imei':
                                  state.pathParameters['imei'] ??
                                  'Unknown IMEI',
                            },
                        initialTab: 1,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'configuration',
                    name: 'deviceConfiguration',
                    builder: (context, state) {
                      final device = state.extra as Map<String, dynamic>?;

                      return DeviceControlWidget(
                        device:
                            device ??
                            {
                              'imei':
                                  state.pathParameters['imei'] ??
                                  'Unknown IMEI',
                            },
                        initialTab: 2,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          /// ------------------------------
          /// OTHER SCREENS
          /// ------------------------------
          GoRoute(
            path: '/home/trips',
            name: 'trips',
            builder: (context, state) => const TripsScreen(),
          ),
          GoRoute(
            path: '/home/reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/home/alerts',
            name: 'alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          // GoRoute(
          //   path: '/home/settings',
          //   name: 'settings',
          //   builder: (context, state) => const SettingsScreen(),
          // ),
          GoRoute(
            path: '/home/settings',
            builder: (context, state) {
              final subTab =
                  state.uri.pathSegments.length > 2
                      ? state.uri.pathSegments[2]
                      : 'profile';

              return SettingsScreen(initialTab: subTab);
            },
            routes: [
              GoRoute(
                path: 'profile',
                name: 'settingsProfile',
                builder:
                    (context, state) =>
                        const SettingsScreen(initialTab: 'profile'),
              ),
              GoRoute(
                path: 'users',
                name: 'settingsUsers',
                builder:
                    (context, state) =>
                        const SettingsScreen(initialTab: 'users'),
              ),
              GoRoute(
                path: 'groups',
                name: 'settingsGroups',
                builder:
                    (context, state) =>
                        const SettingsScreen(initialTab: 'groups'),
              ),
              GoRoute(
                path: 'apikey',
                name: 'settingsApiKey',
                builder:
                    (context, state) =>
                        const SettingsScreen(initialTab: 'apikey'),
              ),
              GoRoute(
                path: 'commands',
                name: 'settingsCommands',
                builder:
                    (context, state) =>
                        const SettingsScreen(initialTab: 'commands'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
