import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/presentation/login_screen.dart';
import 'core/auth/oidc_service.dart';
import 'core/theme/app_theme.dart';
import 'features/events/presentation/event_details_screen.dart';
import 'features/events/presentation/event_discovery_screen.dart';
import 'features/staff/presentation/staff_dashboard_screen.dart';
import 'features/organizer/presentation/organizer_dashboard_screen.dart';

final auth = EventlyAuth.instance;

final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: _AuthRouterNotifier(auth),
  redirect: (context, state) async {
    await auth.initialize();

    final path = state.uri.path;
    final loggedIn = auth.isLoggedIn;

    if (!loggedIn) {
      if (path == '/staff' || path == '/organizer') {
        return '/login';
      }
      return null;
    }

    final roles = await auth.getRoles();

    final isStaff = roles.contains('ROLE_STAFF');
    final isOrganizer = roles.contains('ROLE_ORGANIZER');
    final isAttendee = roles.contains('ROLE_ATTENDEE');

    if (path == '/login') {
      if (isStaff) return '/staff';
      if (isOrganizer) return '/organizer';
      if (isAttendee) return '/';
      return '/';
    }

    if (path == '/staff' && !isStaff) {
      return isOrganizer ? '/organizer' : '/';
    }

    if (path == '/organizer' && !isOrganizer) {
      return isStaff ? '/staff' : '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const EventDiscoveryScreen(),
    ),
    GoRoute(
      path: '/events/:eventId',
      builder: (context, state) => EventDetailsScreen(
        eventId: state.pathParameters['eventId']!,
      ),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffDashboardScreen(),
    ),
    GoRoute(
      path: '/organizer',
      builder: (context, state) => const OrganizerDashboardScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(EventlyAuth auth) {
    auth.authChanges.listen((_) => notifyListeners());
  }
}

class EventlyApp extends StatelessWidget {
  const EventlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Evently',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
    );
  }
}
