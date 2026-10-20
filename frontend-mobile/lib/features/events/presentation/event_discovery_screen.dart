import 'package:dio/dio.dart';
import 'package:evently_mobile/core/auth/oidc_service.dart';
import 'package:evently_mobile/features/auth/presentation/auth_provider.dart';
import 'package:evently_mobile/features/tickets/presentation/my_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evently_mobile/features/auth/presentation/login_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/event_models.dart';
import '../data/events_repository.dart';
import 'package:evently_mobile/features/tickets/data/tickets_repository.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

// ── Attendee Shell with Bottom Navigation ────────────────────────────
class EventDiscoveryScreen extends ConsumerStatefulWidget {
  const EventDiscoveryScreen({
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  @override
  ConsumerState<EventDiscoveryScreen> createState() =>
      _EventDiscoveryScreenState();
}

class _EventDiscoveryScreenState extends ConsumerState<EventDiscoveryScreen> {
  @override
  void initState() {
    super.initState();

    // Set the initial tab after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(selectedTabProvider.notifier).state =
          widget.initialTab.clamp(0, 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    final auth = EventlyAuth.instance;
    final loggedIn = auth.isLoggedIn;
    final tabIndex = ref.watch(selectedTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: [
          const _HomeTab(),
          loggedIn
              ? const MyTicketsScreen(embedded: true)
              : const _LoginPromptTab(),
          loggedIn ? const _AccountTab() : const _LoginPromptTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: tabIndex,
          onTap: (index) {
            ref.read(selectedTabProvider.notifier).state = index;

            // Fetch fresh tickets whenever My Tickets is selected.
            if (index == 1 && loggedIn) {
              ref.invalidate(myTicketsProvider);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_outlined),
              activeIcon: Icon(Icons.confirmation_number),
              label: 'My Tickets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login prompt for unauthenticated tabs ────────────────────────────
class _LoginPromptTab extends StatelessWidget {
  const _LoginPromptTab();

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.lock_outline_rounded,
      title: 'Sign in required',
      subtitle: 'Log in to access your tickets and account.',
      action: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        icon: const Icon(Icons.login_rounded, size: 18),
        label: const Text('Sign in'),
      ),
    );
  }
}

// ── Home Tab ─────────────────────────────────────────────────────────
class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  final _searchController = TextEditingController();
  String _query = '';
  int _page = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result =
        ref.watch(publishedEventsProvider((query: _query, page: _page)));

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.purple, size: 28),
            SizedBox(width: 8),
            Text(
              'evently',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh events',
            onPressed: () => ref.invalidate(
                publishedEventsProvider((query: _query, page: _page))),
            icon: const Icon(Icons.refresh_rounded),
          ),
          Consumer(
            builder: (context, ref, child) {
              ref.watch(authProvider);

              final auth = EventlyAuth.instance;
              final loggedIn = auth.isLoggedIn;

              if (!loggedIn) {
                return TextButton.icon(
                  onPressed: () {
                    context.push('/login');
                  },
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Login'),
                );
              }

              final name = auth.userName ?? auth.userEmail ?? 'User';
              final picture = auth.userPicture;

              return PopupMenuButton<String>(
                tooltip: name,
                onSelected: (value) async {
                  if (value == 'logout') {
                    await auth.logout();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (auth.userEmail != null)
                          Text(
                            auth.userEmail!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: UserAvatar(name: name, imageUrl: picture),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref
            .invalidate(publishedEventsProvider((query: _query, page: _page))),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ── Header ──
            const Text(
              'MAKE IT A MOMENT',
              style: TextStyle(
                color: AppTheme.purple,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find your next\nunforgettable event.',
              style: TextStyle(
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 22),

            // ── Search bar ──
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {
                _query = value;
                _page = 0;
              }),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search concerts, meetups, shows...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textTertiary,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _page = 0;
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 28),

            // ── Section header ──
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Upcoming events',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                result.maybeWhen(
                  data: (data) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${data.events.length} shown',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Content ──
            result.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => ErrorStateWidget(
                message: _friendlyError(error),
                onRetry: () => ref.invalidate(
                    publishedEventsProvider((query: _query, page: _page))),
              ),
              data: (page) {
                if (page.events.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.event_busy_rounded,
                    title: 'No events found',
                    subtitle:
                        'No published events match your search.\nTry a different query.',
                  );
                }
                return Column(
                  children: [
                    for (final event in page.events) ...[
                      _EventCard(
                        event: event,
                        onTap: () => context.push('/events/${event.id}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (page.totalPages > 1)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _page > 0
                                  ? () => setState(() => _page--)
                                  : null,
                              icon: const Icon(Icons.chevron_left, size: 22),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'Page ${_page + 1} of ${page.totalPages}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _page + 1 < page.totalPages
                                  ? () => setState(() => _page++)
                                  : null,
                              icon: const Icon(Icons.chevron_right, size: 22),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Account Tab ──────────────────────────────────────────────────────
class _AccountTab extends ConsumerWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = EventlyAuth.instance;
    final name = auth.userName ?? 'User';
    final email = auth.userEmail;
    final picture = auth.userPicture;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Profile card ──
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                UserAvatar(name: name, imageUrl: picture, size: 72),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                const StatusBadge(
                  label: 'ATTENDEE',
                  color: AppTheme.purple,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Account actions ──
          _AccountActionTile(
            icon: Icons.confirmation_number_outlined,
            title: 'My Tickets',
            subtitle: 'View your purchased tickets',
            onTap: () {
              // Switch to the existing bottom-navigation tab.
              ref.read(selectedTabProvider.notifier).state = 1;

              // Refresh the ticket API data.
              ref.invalidate(myTicketsProvider);
            },
          ),
          const SizedBox(height: 8),
          _AccountActionTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Log out of your account',
            isDestructive: true,
            onTap: () async {
              await auth.logout();
            },
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDestructive ? AppTheme.error : AppTheme.purple)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? AppTheme.error : AppTheme.purpleLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isDestructive
                            ? AppTheme.error
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive
                    ? AppTheme.error.withOpacity(0.5)
                    : AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Event Card ───────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});
  final PublishedEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = event.start;
    final dateLabel = date == null
        ? 'DATE TBA'
        : '${_month(date.month).toUpperCase()} ${date.day} · ${date.year}';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Date/image box ──
              Container(
                width: 66,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6D45D9), Color(0xFF2A1652)],
                  ),
                ),
                child: date != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _month(date.month).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.purpleLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${date.day}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      )
                    : const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.purpleLight,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppTheme.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.purpleLight,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _friendlyError(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401 ||
        error.response?.statusCode == 403) {
      return 'The API rejected this request. Check your Spring Security rules for published events.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Cannot reach the backend. Check that Spring Boot is running and API_BASE_URL is correct.';
    }
    return 'Could not load events (HTTP ${error.response?.statusCode ?? 'network error'}).';
  }
  return 'Could not load events. Check the API response and try again.';
}

String _month(int month) => const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][month];
