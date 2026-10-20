
import 'package:flutter/material.dart';
import 'package:evently_mobile/core/auth/oidc_service.dart';
import 'package:evently_mobile/core/theme/app_theme.dart';
import 'package:evently_mobile/core/widgets/shared_widgets.dart';
import 'package:evently_mobile/features/organizer/data/organizer_event_repository.dart';
import 'package:evently_mobile/features/organizer/presentation/event_form_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState
    extends State<OrganizerDashboardScreen> {
  final _repository = OrganizerEventRepository();
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    _eventsFuture = _repository.listEvents();
  }

  Future<void> _openForm({String? eventId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(
          repository: _repository,
          eventId: eventId,
        ),
      ),
    );

    if (changed == true && mounted) {
      setState(_loadEvents);
    }
  }

  Future<void> _deleteEvent(Map<String, dynamic> event) async {
    final id = event['id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text(
          'Are you sure you want to delete "${event['name']}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteEvent(id);
      if (!mounted) return;

      setState(_loadEvents);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = EventlyAuth.instance;
    final name = auth.userName ?? auth.userEmail ?? 'Organizer';
    final picture = auth.userPicture;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppTheme.purple, size: 28),
            SizedBox(width: 8),
            Text(
              'My Events',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh events',
            onPressed: () => setState(_loadEvents),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
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
                    const SizedBox(height: 4),
                    const StatusBadge(label: 'ORGANIZER', color: AppTheme.purple),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
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
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Event'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_loadEvents),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ErrorStateWidget(
                message: 'Could not load your events.\nCheck your connection and try again.',
                icon: Icons.cloud_off_rounded,
                onRetry: () => setState(_loadEvents),
              );
            }

            final events = snapshot.data ?? [];

            if (events.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.event_note_rounded,
                title: 'No events yet',
                subtitle: 'Create your first event to get started.\nTap the button below.',
                action: FilledButton.icon(
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create Event'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return _OrganizerEventCard(
                  event: event,
                  onEdit: () => _openForm(eventId: event['id']?.toString()),
                  onDelete: () => _deleteEvent(event),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ── Organizer Event Card ─────────────────────────────────────────────
class _OrganizerEventCard extends StatelessWidget {
  const _OrganizerEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = event['name']?.toString() ?? 'Untitled event';
    final venue = event['venue']?.toString() ?? 'Venue not set';
    final status = event['status']?.toString() ?? 'UNKNOWN';
    final start = event['start']?.toString();

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Event icon ──
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D45D9), Color(0xFF3D1F8A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: AppTheme.purpleLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                                venue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (start != null && start.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Starts: $start',
                                style: const TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Edit event'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18,
                                color: AppTheme.error),
                            SizedBox(width: 10),
                            Text('Delete event',
                                style: TextStyle(color: AppTheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatusBadge(label: status),
            ],
          ),
        ),
      ),
    );
  }
}
