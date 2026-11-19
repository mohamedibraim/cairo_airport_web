import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/session.dart';
import '../features/auth/login_screen.dart';
import '../features/baggage/baggage_screen.dart';
import '../features/events/events_screen.dart';
import '../features/flights/flights_screen.dart';
import '../features/flow/flow_screen.dart';
import '../features/health/health_screen.dart';
import '../features/incidents/incidents_screen.dart';
import '../features/maintenance/maintenance_screen.dart';
import '../features/overview/overview_screen.dart';
import '../features/predictions/predictions_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/simulation/simulation_screen.dart';
import '../features/staff/staff_screen.dart';
import '../features/twin/twin_screen.dart';
import 'navigation.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(sessionProvider.select((s) => s.authenticated));

  return GoRouter(
    initialLocation: Routes.login,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == Routes.login;
      if (!auth && !atLogin) return Routes.login;
      if (auth && atLogin) return Routes.overview;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(currentPath: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/', redirect: (_, _) => Routes.overview),
          GoRoute(
            path: Routes.overview,
            builder: (_, _) => const OverviewScreen(),
          ),
          GoRoute(
            path: Routes.flights,
            builder: (_, _) => const FlightsScreen(),
          ),
          GoRoute(path: Routes.flow, builder: (_, _) => const FlowScreen()),
          GoRoute(
            path: Routes.baggage,
            builder: (_, _) => const BaggageScreen(),
          ),
          GoRoute(
            path: Routes.maintenance,
            builder: (_, _) => const MaintenanceScreen(),
          ),
          GoRoute(path: Routes.twin, builder: (_, _) => const TwinScreen()),
          GoRoute(
            path: Routes.incidents,
            builder: (_, _) => const IncidentsScreen(),
          ),
          GoRoute(path: Routes.events, builder: (_, _) => const EventsScreen()),
          GoRoute(
            path: Routes.predictions,
            builder: (_, _) => const PredictionsScreen(),
          ),
          GoRoute(
            path: Routes.simulation,
            builder: (_, _) => const SimulationScreen(),
          ),
          GoRoute(
            path: Routes.reports,
            builder: (_, _) => const ReportsScreen(),
          ),
          GoRoute(path: Routes.staff, builder: (_, _) => const StaffScreen()),
          GoRoute(path: Routes.health, builder: (_, _) => const HealthScreen()),
          GoRoute(
            path: Routes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Center(child: Text('Not found: ${state.matchedLocation}')),
      ),
    ),
  );
});
