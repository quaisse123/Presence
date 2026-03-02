import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  DATA MODELS  (will be replaced by real API calls)
// ─────────────────────────────────────────────

enum SessionStatus { active, upcoming, completed }

class MockSession {
  final String id;
  final String courseTitle;
  final String courseCode;
  final String startTime; // human-readable for now
  final String endTime;
  final String location;
  final int attendeeCount;
  final int totalStudents;
  final SessionStatus status;
  final String rawDate; // for the date chip

  const MockSession({
    required this.id,
    required this.courseTitle,
    required this.courseCode,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.attendeeCount,
    required this.totalStudents,
    required this.status,
    required this.rawDate,
  });
}

// ─────────────────────────────────────────────
//  SIMULATED DATA
// ─────────────────────────────────────────────

final List<MockSession> _mockSessions = [
  MockSession(
    id: '1',
    courseTitle: 'Software Engineering',
    courseCode: 'SE101',
    startTime: '10:00 AM',
    endTime: '11:30 AM',
    location: 'Room 204',
    attendeeCount: 45,
    totalStudents: 60,
    status: SessionStatus.active,
    rawDate: 'Today',
  ),
  MockSession(
    id: '2',
    courseTitle: 'Database Systems',
    courseCode: 'DB202',
    startTime: '2:00 PM',
    endTime: '3:30 PM',
    location: 'Room 301',
    attendeeCount: 0,
    totalStudents: 55,
    status: SessionStatus.upcoming,
    rawDate: 'Today',
  ),
  MockSession(
    id: '3',
    courseTitle: 'Algorithms',
    courseCode: 'ALG303',
    startTime: '9:00 AM',
    endTime: '10:30 AM',
    location: 'Room 105',
    attendeeCount: 58,
    totalStudents: 60,
    status: SessionStatus.completed,
    rawDate: 'Yesterday',
  ),
  MockSession(
    id: '4',
    courseTitle: 'Mobile Development',
    courseCode: 'MOB401',
    startTime: '4:00 PM',
    endTime: '5:30 PM',
    location: 'Room 210',
    attendeeCount: 42,
    totalStudents: 50,
    status: SessionStatus.completed,
    rawDate: 'Feb 26',
  ),
];

// ─────────────────────────────────────────────
//  THEME CONSTANTS
// ─────────────────────────────────────────────

class _AppColors {
  // Brand
  static const primary = Color(0xFF1A73E8); // Google-blue feel
  static const primaryLight = Color(0xFFE8F0FE);

  // Status badges
  static const activeGreen = Color(0xFF1E8B4C);
  static const activeBg = Color(0xFFE6F4EA);
  static const upcomingBlue = Color(0xFF1565C0);
  static const upcomingBg = Color(0xFFE3EDFD);
  static const completedGrey = Color(0xFF5F6368);
  static const completedBg = Color(0xFFF1F3F4);

  // Neutral
  static const surface = Color(0xFFF9FAFB);
  static const cardBg = Colors.white;
  static const divider = Color(0xFFE8EAED);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);

  // Attendance bar
  static const attendanceHigh = Color(0xFF34A853);
  static const attendanceMedium = Color(0xFFFBBC04);
  static const attendanceLow = Color(0xFFEA4335);
}

// ─────────────────────────────────────────────
//  PAGE WIDGET
// ─────────────────────────────────────────────

class ProfDashPage extends StatefulWidget {
  const ProfDashPage({super.key});

  @override
  State<ProfDashPage> createState() => _ProfDashPageState();
}

class _ProfDashPageState extends State<ProfDashPage> {
  // Local copy so we can delete items without touching the const list
  late List<MockSession> _sessions;

  // For the future search/filter bar (collapsed by default)
  bool _showFilterBar = false;
  String _filterStatus = 'All'; // 'All' | 'Active' | 'Upcoming' | 'Completed'

  // Pull-to-refresh state
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _sessions = List.from(_mockSessions);
  }

  // ── Helpers ──────────────────────────────────

  List<MockSession> get _filteredSessions {
    if (_filterStatus == 'All') return _sessions;
    return _sessions.where((s) {
      switch (_filterStatus) {
        case 'Active':
          return s.status == SessionStatus.active;
        case 'Upcoming':
          return s.status == SessionStatus.upcoming;
        case 'Completed':
          return s.status == SessionStatus.completed;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    // TODO: replace with real API call
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _sessions = List.from(_mockSessions); // reset simulated data
      _isRefreshing = false;
    });
  }

  void _deleteSession(MockSession session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete the "${session.courseTitle}" session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _sessions.remove(session));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${session.courseTitle} session deleted.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              // TODO: call DELETE /sessions/{id}
              debugPrint('DELETE session id=${session.id}');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showQrCode(MockSession session) {
    // TODO: fetch real QR token and render qr_flutter widget
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${session.courseTitle} – QR Code',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${session.rawDate} · ${session.startTime} – ${session.endTime}',
              style: const TextStyle(color: _AppColors.textSecondary),
            ),
            const SizedBox(height: 28),
            // Placeholder QR square – replace with qr_flutter's QrImageView
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _AppColors.primary, width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 120,
                  color: _AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Token: mock-token-${session.id}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    debugPrint('SHOW QR for session id=${session.id}');
  }

  void _viewAttendance(MockSession session) {
    // TODO: navigate to AttendancePage with sessionId
    debugPrint('VIEW attendance for session id=${session.id}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance details for ${session.courseTitle} – coming soon',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createSession() {
    // TODO: push CreateSessionPage
    debugPrint('CREATE new session');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create session form – coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openProfile() {
    // TODO: show dropdown with Settings / Logout
    debugPrint('OPEN profile menu');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile menu – coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openNotifications() {
    // TODO: push NotificationsPage
    debugPrint('OPEN notifications');
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.surface,
      // ── App Bar ────────────────────────────────
      appBar: _buildAppBar(context),
      // ── Body ───────────────────────────────────
      body: Column(
        children: [
          // Filter / search bar (collapsible – space reserved for future)
          _FilterBar(
            visible: _showFilterBar,
            selectedStatus: _filterStatus,
            onStatusChanged: (v) => setState(() => _filterStatus = v),
          ),
          // Session list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: _AppColors.primary,
              child: _filteredSessions.isEmpty
                  ? _EmptyState(onCreateTap: _createSession)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: _filteredSessions.length,
                      itemBuilder: (_, i) => _SessionCard(
                        session: _filteredSessions[i],
                        onQrTap: () => _showQrCode(_filteredSessions[i]),
                        onAttendanceTap: () =>
                            _viewAttendance(_filteredSessions[i]),
                        onDeleteTap: () => _deleteSession(_filteredSessions[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
      // ── FAB ────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        backgroundColor: _AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Session',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // TODO: add BottomNavigationBar here when Student/History tabs are added
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 20,
      title: Row(
        children: [
          // Logo mark
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'PresenceApp',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: _AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        // Filter toggle
        IconButton(
          tooltip: 'Filter sessions',
          onPressed: () => setState(() => _showFilterBar = !_showFilterBar),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _showFilterBar
                  ? Icons.filter_list_off_rounded
                  : Icons.filter_list_rounded,
              key: ValueKey(_showFilterBar),
              color: _showFilterBar
                  ? _AppColors.primary
                  : _AppColors.textSecondary,
            ),
          ),
        ),
        // Notification bell – badge-ready via Stack
        Stack(
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: _openNotifications,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _AppColors.textSecondary,
              ),
            ),
            // TODO: replace Positioned container with real badge count
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        // Profile avatar – dropdown-ready
        GestureDetector(
          onTap: _openProfile,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _AppColors.primaryLight,
              // TODO: replace with NetworkImage(profileUrl) when auth is ready
              child: const Text(
                'P',
                style: TextStyle(
                  color: _AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  FILTER BAR WIDGET
// ─────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final bool visible;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const _FilterBar({
    required this.visible,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  static const _options = ['All', 'Active', 'Upcoming', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: visible
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TODO: add a TextField search bar here later
                  const Text(
                    'Filter by status',
                    style: TextStyle(
                      fontSize: 12,
                      color: _AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _options.map((opt) {
                        final selected = opt == selectedStatus;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(opt),
                            selected: selected,
                            onSelected: (_) => onStatusChanged(opt),
                            selectedColor: _AppColors.primary,
                            labelStyle: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : _AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                            backgroundColor: _AppColors.surface,
                            side: const BorderSide(color: _AppColors.divider),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 1, color: _AppColors.divider),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─────────────────────────────────────────────
//  SESSION CARD WIDGET
// ─────────────────────────────────────────────

class _SessionCard extends StatefulWidget {
  final MockSession session;
  final VoidCallback onQrTap;
  final VoidCallback onAttendanceTap;
  final VoidCallback onDeleteTap;

  const _SessionCard({
    required this.session,
    required this.onQrTap,
    required this.onAttendanceTap,
    required this.onDeleteTap,
  });

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  // Expand/collapse – space reserved for future detail rows
  bool _expanded = false;

  // ── Status styling helpers ────────────────────

  Color get _statusBg {
    switch (widget.session.status) {
      case SessionStatus.active:
        return _AppColors.activeBg;
      case SessionStatus.upcoming:
        return _AppColors.upcomingBg;
      case SessionStatus.completed:
        return _AppColors.completedBg;
    }
  }

  Color get _statusFg {
    switch (widget.session.status) {
      case SessionStatus.active:
        return _AppColors.activeGreen;
      case SessionStatus.upcoming:
        return _AppColors.upcomingBlue;
      case SessionStatus.completed:
        return _AppColors.completedGrey;
    }
  }

  String get _statusLabel {
    switch (widget.session.status) {
      case SessionStatus.active:
        return 'Active';
      case SessionStatus.upcoming:
        return 'Upcoming';
      case SessionStatus.completed:
        return 'Completed';
    }
  }

  IconData get _statusIcon {
    switch (widget.session.status) {
      case SessionStatus.active:
        return Icons.radio_button_checked_rounded;
      case SessionStatus.upcoming:
        return Icons.schedule_rounded;
      case SessionStatus.completed:
        return Icons.check_circle_outline_rounded;
    }
  }

  // ── Attendance bar color ──────────────────────

  Color _attendanceColor(double ratio) {
    if (ratio >= 0.75) return _AppColors.attendanceHigh;
    if (ratio >= 0.50) return _AppColors.attendanceMedium;
    return _AppColors.attendanceLow;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final attendanceRatio = session.totalStudents > 0
        ? session.attendeeCount / session.totalStudents
        : 0.0;

    return GestureDetector(
      // Long-press hint for future edit action
      onLongPress: () {
        // TODO: show edit option
        debugPrint('LONG-PRESS edit session id=${session.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edit session – coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 14),
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _AppColors.cardBg,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: course + status badge ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Course title + code
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.courseTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.courseCode,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 11, color: _statusFg),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusFg,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: _AppColors.divider),
              const SizedBox(height: 12),

              // ── Info row: date, time, location ──────
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: session.rawDate,
                  ),
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    label: '${session.startTime} – ${session.endTime}',
                  ),
                  _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: session.location,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Attendance section ───────────────────
              Row(
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 15,
                    color: _AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${session.attendeeCount}/${session.totalStudents} present',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(attendanceRatio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: _attendanceColor(attendanceRatio),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Attendance progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: attendanceRatio,
                  minHeight: 6,
                  backgroundColor: _AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _attendanceColor(attendanceRatio),
                  ),
                ),
              ),

              // ── Expandable detail area (future use) ─
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            // TODO: populate with GPS coords, session ID, QR token
                            'Additional details will appear here.\n'
                            'GPS coordinates · Session ID · QR token validity',
                            style: TextStyle(
                              fontSize: 12,
                              color: _AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: _AppColors.divider),
              const SizedBox(height: 4),

              // ── Action buttons row ───────────────────
              Row(
                children: [
                  // Expand/collapse toggle
                  _ActionButton(
                    icon: _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    label: _expanded ? 'Less' : 'More',
                    color: _AppColors.textSecondary,
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                  const Spacer(),
                  // QR Code button (only visible when not completed)
                  if (widget.session.status != SessionStatus.completed)
                    _ActionButton(
                      icon: Icons.qr_code_rounded,
                      label: 'QR Code',
                      color: _AppColors.primary,
                      onTap: widget.onQrTap,
                    ),
                  if (widget.session.status != SessionStatus.completed)
                    const SizedBox(width: 8),
                  // View Attendance button
                  _ActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Attendance',
                    color: _AppColors.activeGreen,
                    onTap: widget.onAttendanceTap,
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: Colors.red,
                    onTap: widget.onDeleteTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────

/// A small labelled icon used for date / time / location
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// A compact text+icon action button used in the card footer
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  EMPTY STATE WIDGET
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                size: 52,
                color: _AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No sessions yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first session to start\ntracking attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onCreateTap,
              style: FilledButton.styleFrom(
                backgroundColor: _AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create First Session',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
