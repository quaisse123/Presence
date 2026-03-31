import 'package:flutter/material.dart';
import 'package:frontend/Api/sessionsApi.dart';
import 'package:frontend/components/QrModal.dart';
import 'package:frontend/pages/sessionDetails.dart';

enum SessionStatus { active, upcoming, completed }

extension SessionStatusParsing on SessionStatus {
  static SessionStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return SessionStatus.active;
      case 'UPCOMING':
        return SessionStatus.upcoming;
      case 'COMPLETED':
      default:
        return SessionStatus.completed;
    }
  }
}

class Session {
  final int id;
  final int courseId;
  final String courseTitle;
  final String courseCode;
  final DateTime startTime;
  final DateTime endTime;
  final String salle;
  final int attendance;
  final int totalStudents;
  final SessionStatus status;
  final String? description;

  const Session({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.startTime,
    required this.endTime,
    required this.salle,
    required this.attendance,
    required this.totalStudents,
    required this.status,
    this.description,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int,
      courseId: json['courseId'] as int,
      courseTitle: json['courseTitle'] as String,
      courseCode: json['courseCode'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      salle: json['salle'] as String,
      attendance: json['attendance'] as int,
      totalStudents: json['totalStudents'] as int,
      status: SessionStatusParsing.fromString(json['sessionStatus'] as String),
      description: json['description'] as String?,
    );
  }
}

String humanReadableDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);

  if (target == today) return 'Today';
  if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (target == today.add(const Duration(days: 1))) return 'Tomorrow';
  return '${date.day}/${date.month}/${date.year}';
}

String formatTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final p = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $p';
}

class _DashTheme {
  static const pageBg = Color(0xFFF1F3F6);
  static const card = Colors.white;
  static const primary = Color(0xFF1C4FBF);
  static const primaryDeep = Color(0xFF163B9A);
  static const primarySoft = Color(0xFFEAF0FE);
  static const textPrimary = Color(0xFF1D293D);
  static const textSecondary = Color(0xFF7B8798);
  static const border = Color(0xFFE4E9F1);
  static const success = Color(0xFF1C9B63);
  static const successSoft = Color(0xFFE6F7EF);
  static const warning = Color(0xFFCC8A2E);
  static const warningSoft = Color(0xFFFFF3E3);
  static const danger = Color(0xFFD94B4B);
  static const dangerSoft = Color(0xFFFDECEC);
  static const neutral = Color(0xFF6E7E92);
  static const neutralSoft = Color(0xFFF0F3F8);
  static const surfaceSoft = Color(0xFFF6F8FC);
}

class ProfDashPage extends StatefulWidget {
  const ProfDashPage({super.key});

  @override
  State<ProfDashPage> createState() => _ProfDashPageState();
}

class _ProfDashPageState extends State<ProfDashPage> {
  List<Session> _sessions = [];
  bool _isLoading = true;
  String? _error;

  int _currentPage = 0;
  int _totalPages = 1;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await fetchSessions(page: _currentPage, size: 6);
      setState(() {
        _sessions = (data['content'] as List)
            .map((e) => Session.fromJson(e as Map<String, dynamic>))
            .toList();
        _totalPages = data['totalPages'] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      debugPrint('Error fetching sessions: $e');
    }
  }

  List<Session> get _filteredSessions {
    return _sessions.where((session) {
      final statusOk = switch (_filterStatus) {
        'Active' => session.status == SessionStatus.active,
        'Upcoming' => session.status == SessionStatus.upcoming,
        'Completed' => session.status == SessionStatus.completed,
        _ => true,
      };

      final queryOk =
          _searchQuery.isEmpty ||
          session.courseTitle.toLowerCase().contains(_searchQuery) ||
          session.courseCode.toLowerCase().contains(_searchQuery) ||
          session.salle.toLowerCase().contains(_searchQuery);

      return statusOk && queryOk;
    }).toList();
  }

  int get _activeCount =>
      _sessions.where((s) => s.status == SessionStatus.active).length;

  int get _upcomingCount =>
      _sessions.where((s) => s.status == SessionStatus.upcoming).length;

  int get _completedCount =>
      _sessions.where((s) => s.status == SessionStatus.completed).length;

  double get _attendanceRate {
    final present = _sessions.fold<int>(0, (sum, s) => sum + s.attendance);
    final total = _sessions.fold<int>(0, (sum, s) => sum + s.totalStudents);
    if (total == 0) {
      return 0;
    }
    return (present / total) * 100;
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage == 0) {
      return;
    }
    setState(() => _currentPage--);
    await _loadSessions();
  }

  Future<void> _goToNextPage() async {
    if (_currentPage >= _totalPages - 1) {
      return;
    }
    setState(() => _currentPage++);
    await _loadSessions();
  }

  void _showQrCode(Session session) async {
    await showQrModal(context, sessionId: session.id);
    _loadSessions();
  }

  void _viewAttendance(Session session) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Attendance details for ${session.courseTitle} - coming soon',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _createSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create session form - coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete(Session session) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete session'),
        content: Text(
          'Delete "${session.courseTitle}" (${session.courseCode})?',
          style: const TextStyle(color: _DashTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _DashTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() => _sessions.removeWhere((s) => s.id == session.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${session.courseTitle} deleted.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSummary = !_isLoading && _error == null;
    final hasFilters = _filterStatus != 'All' || _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        backgroundColor: _DashTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Create Session',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _loadSessions,
        color: _DashTheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 104),
          children: [
            _OverviewCard(
              total: showSummary ? _sessions.length : 0,
              active: showSummary ? _activeCount : 0,
              upcoming: showSummary ? _upcomingCount : 0,
              completed: showSummary ? _completedCount : 0,
              attendanceRate: showSummary ? _attendanceRate : 0,
            ),
            const SizedBox(height: 12),
            _SearchBar(
              controller: _searchController,
              showFilters: _showFilters,
              onToggleFilters: () =>
                  setState(() => _showFilters = !_showFilters),
            ),
            if (!_showFilters && _filterStatus != 'All') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _DashTheme.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Current filter: $_filterStatus',
                    style: const TextStyle(
                      color: _DashTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            if (_showFilters) ...[
              const SizedBox(height: 8),
              _StatusFilters(
                selectedStatus: _filterStatus,
                onStatusChanged: (value) =>
                    setState(() => _filterStatus = value),
              ),
            ],
            const SizedBox(height: 14),
            if (_isLoading)
              const _LoadingState()
            else if (_error != null)
              _ErrorState(error: _error!, onRetry: _loadSessions)
            else if (_filteredSessions.isEmpty)
              _EmptyState(
                hasFilters: hasFilters,
                onCreateTap: _createSession,
                onResetFilters: () {
                  setState(() {
                    _filterStatus = 'All';
                    _searchController.clear();
                  });
                },
              )
            else ...[
              ..._filteredSessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _SessionCard(
                    session: session,
                    onQrTap: () => _showQrCode(session),
                    onAttendanceTap: () => _viewAttendance(session),
                    onDeleteTap: () => _confirmDelete(session),
                  ),
                ),
              ),
              if (_totalPages > 1) ...[
                const SizedBox(height: 2),
                _PaginationBar(
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPrevious: _goToPreviousPage,
                  onNext: _goToNextPage,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final int total;
  final int active;
  final int upcoming;
  final int completed;
  final double attendanceRate;

  const _OverviewCard({
    required this.total,
    required this.active,
    required this.upcoming,
    required this.completed,
    required this.attendanceRate,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedAttendance = (attendanceRate / 100)
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DashTheme.primaryDeep, _DashTheme.primary],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0A2F7A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$total sessions',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.people_alt_rounded,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                '${attendanceRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: normalizedAttendance,
              minHeight: 4,
              backgroundColor: const Color(0x3FFFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _OverviewStat(
                icon: Icons.radio_button_checked_rounded,
                label: 'Active',
                value: '$active',
              ),
              const SizedBox(width: 8),
              _OverviewStat(
                icon: Icons.schedule_rounded,
                label: 'Upcoming',
                value: '$upcoming',
              ),
              const SizedBox(width: 8),
              _OverviewStat(
                icon: Icons.task_alt_rounded,
                label: 'Done',
                value: '$completed',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$label $value',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xEEFFFFFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool showFilters;
  final VoidCallback onToggleFilters;

  const _SearchBar({
    required this.controller,
    required this.showFilters,
    required this.onToggleFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _DashTheme.border),
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search by title, code or room',
                hintStyle: const TextStyle(
                  color: _DashTheme.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _DashTheme.textSecondary,
                  size: 20,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: controller.clear,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _DashTheme.textSecondary,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggleFilters,
            child: Ink(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: showFilters ? _DashTheme.primarySoft : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: showFilters ? _DashTheme.primary : _DashTheme.border,
                  width: showFilters ? 1.4 : 1,
                ),
              ),
              child: Icon(
                showFilters ? Icons.tune_rounded : Icons.tune_outlined,
                size: 20,
                color: _DashTheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  const _StatusFilters({
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = ['All', 'Active', 'Upcoming', 'Completed'];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final option = options[index];
          final isSelected = option == selectedStatus;

          return InkWell(
            onTap: () => onStatusChanged(option),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _DashTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _DashTheme.primary : _DashTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    option,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : _DashTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final Session session;
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
  bool _expanded = false;

  Color get _statusBg {
    switch (widget.session.status) {
      case SessionStatus.active:
        return _DashTheme.successSoft;
      case SessionStatus.upcoming:
        return _DashTheme.warningSoft;
      case SessionStatus.completed:
        return _DashTheme.neutralSoft;
    }
  }

  Color get _statusColor {
    switch (widget.session.status) {
      case SessionStatus.active:
        return _DashTheme.success;
      case SessionStatus.upcoming:
        return _DashTheme.warning;
      case SessionStatus.completed:
        return _DashTheme.neutral;
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
        return Icons.check_circle_rounded;
    }
  }

  double get _attendanceRatio {
    final total = widget.session.totalStudents;
    if (total == 0) {
      return 0;
    }
    return widget.session.attendance / total;
  }

  Color get _attendanceColor {
    if (_attendanceRatio >= 0.75) {
      return _DashTheme.success;
    }
    if (_attendanceRatio >= 0.5) {
      return _DashTheme.warning;
    }
    return _DashTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final hasDescription =
        session.description != null && session.description!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailsPage(sessionId: session.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _DashTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _DashTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D122849),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _DashTheme.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: _DashTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.courseTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _DashTheme.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          session.courseCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _DashTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _statusColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 12, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    icon: Icons.calendar_today_rounded,
                    text: humanReadableDate(session.startTime),
                    color: _DashTheme.primary,
                    bg: _DashTheme.primarySoft,
                  ),
                  _MetricChip(
                    icon: Icons.schedule_rounded,
                    text:
                        '${formatTime(session.startTime)} - ${formatTime(session.endTime)}',
                    color: _DashTheme.textSecondary,
                    bg: _DashTheme.surfaceSoft,
                  ),
                  _MetricChip(
                    icon: Icons.meeting_room_outlined,
                    text: session.salle,
                    color: _DashTheme.textSecondary,
                    bg: _DashTheme.surfaceSoft,
                  ),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _DashTheme.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _DashTheme.border),
                  ),
                  child: Text(
                    session.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _DashTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                decoration: BoxDecoration(
                  color: _DashTheme.surfaceSoft,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _DashTheme.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          size: 16,
                          color: _DashTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${session.attendance}/${session.totalStudents} present',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _DashTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(_attendanceRatio * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _attendanceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _attendanceRatio,
                        minHeight: 7,
                        backgroundColor: _DashTheme.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _attendanceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: _DashTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expanded ? 'Hide details' : 'Show details',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _DashTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: _expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _DashTheme.surfaceSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _DashTheme.border),
                          ),
                          child: Column(
                            children: [
                              _DetailRow(
                                label: 'Session ID',
                                value: '#${session.id}',
                              ),
                              const SizedBox(height: 6),
                              _DetailRow(
                                label: 'Date',
                                value: humanReadableDate(session.startTime),
                              ),
                              const SizedBox(height: 6),
                              _DetailRow(label: 'Status', value: _statusLabel),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (session.status != SessionStatus.completed)
                    _ActionButton(
                      icon: Icons.qr_code_2_rounded,
                      label: 'QR Code',
                      color: _DashTheme.primary,
                      bg: _DashTheme.primarySoft,
                      onTap: widget.onQrTap,
                    ),
                  _ActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Attendance',
                    color: _DashTheme.success,
                    bg: _DashTheme.successSoft,
                    onTap: widget.onAttendanceTap,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: _DashTheme.danger,
                    bg: _DashTheme.dangerSoft,
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

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;

  const _MetricChip({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _DashTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: _DashTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DashTheme.border),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: _DashTheme.primary),
          SizedBox(height: 12),
          Text(
            'Loading sessions...',
            style: TextStyle(
              color: _DashTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onCreateTap;
  final VoidCallback onResetFilters;

  const _EmptyState({
    required this.hasFilters,
    required this.onCreateTap,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DashTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: _DashTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_note_rounded,
              size: 42,
              color: _DashTheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasFilters ? 'No sessions match filters' : 'No sessions found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _DashTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try changing the status or search query.'
                : 'Create your first session to start tracking attendance.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DashTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (hasFilters)
            FilledButton.icon(
              onPressed: onResetFilters,
              style: FilledButton.styleFrom(
                backgroundColor: _DashTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text(
                'Reset Filters',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          else
            FilledButton.icon(
              onPressed: onCreateTap,
              style: FilledButton.styleFrom(
                backgroundColor: _DashTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Create Session',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _DashTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 50,
            color: _DashTheme.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load sessions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _DashTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DashTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: _DashTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Future<void> Function() onPrevious;
  final Future<void> Function() onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = currentPage == 0;
    final isLast = currentPage >= totalPages - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DashTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: !isFirst,
            onTap: isFirst ? null : onPrevious,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _DashTheme.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentPage + 1} of $totalPages',
              style: const TextStyle(
                color: _DashTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _PaginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: !isLast,
            onTap: isLast ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final Future<void> Function()? onTap;
  final bool enabled;

  const _PaginationButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? _DashTheme.primary : _DashTheme.border,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : _DashTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
