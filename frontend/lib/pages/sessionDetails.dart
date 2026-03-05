import 'package:flutter/material.dart';
import 'package:frontend/Api/sessionsApi.dart';
import 'package:frontend/pages/profDash.dart'
    show humanReadableDate, formatTime;

// ─────────────────────────────────────────────
//  THEME  (mirrors profDash)
// ─────────────────────────────────────────────

class _C {
  static const primary = Color(0xFF1A73E8);
  static const primaryLight = Color(0xFFE8F0FE);
  static const surface = Color(0xFFF9FAFB);
  static const cardBg = Colors.white;
  static const divider = Color(0xFFE8EAED);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);

  static const activeGreen = Color(0xFF1E8B4C);
  static const activeBg = Color(0xFFE6F4EA);
  static const upcomingBlue = Color(0xFF1565C0);
  static const upcomingBg = Color(0xFFE3EDFD);
  static const completedGrey = Color(0xFF5F6368);
  static const completedBg = Color(0xFFF1F3F4);

  static const attendanceHigh = Color(0xFF34A853);
  static const attendanceMedium = Color(0xFFFBBC04);
  static const attendanceLow = Color(0xFFEA4335);
}

// ─────────────────────────────────────────────
//  MODELS  (detail-specific)
// ─────────────────────────────────────────────

enum _Status { active, upcoming, completed }

_Status _parseStatus(String s) {
  switch (s.toUpperCase()) {
    case 'ACTIVE':
      return _Status.active;
    case 'UPCOMING':
      return _Status.upcoming;
    default:
      return _Status.completed;
  }
}

class _CourseInfo {
  final int id;
  final String title;
  final String code;
  _CourseInfo({required this.id, required this.title, required this.code});
  factory _CourseInfo.fromJson(Map<String, dynamic> j) => _CourseInfo(
    id: j['id'] as int,
    title: j['title'] as String,
    code: j['code'] as String,
  );
}

class _GroupInfo {
  final int id;
  final String level;
  final String section;
  final String filiere;
  final int totalStudents;
  _GroupInfo({
    required this.id,
    required this.level,
    required this.section,
    required this.filiere,
    required this.totalStudents,
  });
  factory _GroupInfo.fromJson(Map<String, dynamic> j) => _GroupInfo(
    id: j['id'] as int,
    level: j['level'] as String? ?? '',
    section: j['section'] as String? ?? '',
    filiere: j['filiere'] as String? ?? '',
    totalStudents: j['totalStudents'] as int? ?? 0,
  );
  String get label =>
      [filiere, level, section].where((s) => s.isNotEmpty).join(' · ');
}

class _AttendanceItem {
  final int id;
  final DateTime scanTime;
  final String studentEmail;
  final String status;
  _AttendanceItem({
    required this.id,
    required this.scanTime,
    required this.studentEmail,
    required this.status,
  });
  factory _AttendanceItem.fromJson(Map<String, dynamic> j) => _AttendanceItem(
    id: j['id'] as int,
    scanTime: DateTime.parse(j['scanTime'] as String),
    studentEmail: j['studentEmail'] as String? ?? '—',
    status: j['status'] as String? ?? 'UNKNOWN',
  );
}

class _SessionDetail {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final String qrCodeToken;
  final String salle;
  final String? description;
  final _Status status;
  final _CourseInfo course;
  final _GroupInfo group;
  final List<_AttendanceItem> attendances;

  _SessionDetail({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.qrCodeToken,
    required this.salle,
    this.description,
    required this.status,
    required this.course,
    required this.group,
    required this.attendances,
  });

  factory _SessionDetail.fromJson(Map<String, dynamic> j) => _SessionDetail(
    id: j['id'] as int,
    startTime: DateTime.parse(j['startTime'] as String),
    endTime: DateTime.parse(j['endTime'] as String),
    qrCodeToken: j['qrCodeToken'] as String? ?? '',
    salle: j['salle'] as String? ?? '',
    description: j['description'] as String?,
    status: _parseStatus(j['sessionStatus'] as String),
    course: _CourseInfo.fromJson(j['course'] as Map<String, dynamic>),
    group: _GroupInfo.fromJson(j['group'] as Map<String, dynamic>),
    attendances: (j['attendances'] as List? ?? [])
        .map((e) => _AttendanceItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  int get presentCount =>
      attendances.where((a) => a.status == 'PRESENT').length;
  int get lateCount => attendances.where((a) => a.status == 'LATE').length;
  int get absentCount => group.totalStudents - attendances.length;
  double get attendanceRatio =>
      group.totalStudents > 0 ? attendances.length / group.totalStudents : 0;
}

// ─────────────────────────────────────────────
//  PAGE WIDGET
// ─────────────────────────────────────────────

class SessionDetailsPage extends StatefulWidget {
  final int sessionId;
  const SessionDetailsPage({super.key, required this.sessionId});

  @override
  State<SessionDetailsPage> createState() => _SessionDetailsPageState();
}

class _SessionDetailsPageState extends State<SessionDetailsPage> {
  _SessionDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _showAllAttendances = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await fetchSessionDetails(widget.sessionId);
      setState(() {
        _detail = _SessionDetail.fromJson(json);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── helpers ──────────────────────────────────

  Color _statusBg(_Status s) {
    switch (s) {
      case _Status.active:
        return _C.activeBg;
      case _Status.upcoming:
        return _C.upcomingBg;
      case _Status.completed:
        return _C.completedBg;
    }
  }

  Color _statusFg(_Status s) {
    switch (s) {
      case _Status.active:
        return _C.activeGreen;
      case _Status.upcoming:
        return _C.upcomingBlue;
      case _Status.completed:
        return _C.completedGrey;
    }
  }

  IconData _statusIcon(_Status s) {
    switch (s) {
      case _Status.active:
        return Icons.radio_button_checked_rounded;
      case _Status.upcoming:
        return Icons.schedule_rounded;
      case _Status.completed:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _statusLabel(_Status s) {
    switch (s) {
      case _Status.active:
        return 'Active';
      case _Status.upcoming:
        return 'Upcoming';
      case _Status.completed:
        return 'Completed';
    }
  }

  Color _attendanceBarColor(double ratio) {
    if (ratio >= 0.75) return _C.attendanceHigh;
    if (ratio >= 0.50) return _C.attendanceMedium;
    return _C.attendanceLow;
  }

  Color _attendanceStatusColor(String s) {
    switch (s.toUpperCase()) {
      case 'PRESENT':
        return _C.activeGreen;
      case 'LATE':
        return _C.attendanceMedium;
      case 'ABSENT':
        return _C.attendanceLow;
      default:
        return _C.textSecondary;
    }
  }

  IconData _attendanceStatusIcon(String s) {
    switch (s.toUpperCase()) {
      case 'PRESENT':
        return Icons.check_circle_rounded;
      case 'LATE':
        return Icons.watch_later_rounded;
      case 'ABSENT':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ── build ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Session Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _C.textPrimary,
          ),
        ),
        actions: [
          if (_detail != null && _detail!.status != _Status.completed)
            IconButton(
              tooltip: 'Show QR Code',
              onPressed: () {
                // TODO: show QR code bottom sheet
              },
              icon: const Icon(Icons.qr_code_rounded, color: _C.primary),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _fetch,
              color: _C.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 14),
                  _buildInfoCard(),
                  const SizedBox(height: 14),
                  _buildAttendanceSummaryCard(),
                  const SizedBox(height: 14),
                  _buildAttendanceListCard(),
                ],
              ),
            ),
    );
  }

  // ── error state ──────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: _C.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _C.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _fetch,
              style: FilledButton.styleFrom(backgroundColor: _C.primary),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  1. HEADER CARD – Course + Status + Group
  // ─────────────────────────────────────────────

  Widget _buildHeaderCard() {
    final d = _detail!;
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _C.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course title + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: _C.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.course.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _C.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.course.code,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _C.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  label: _statusLabel(d.status),
                  icon: _statusIcon(d.status),
                  bg: _statusBg(d.status),
                  fg: _statusFg(d.status),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: _C.divider),
            const SizedBox(height: 14),

            // Group info
            Row(
              children: [
                const Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: _C.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  d.group.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _C.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${d.group.totalStudents} students',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.primary,
                    ),
                  ),
                ),
              ],
            ),

            // Description (if any)
            if (d.description != null && d.description!.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: _C.divider),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_rounded,
                    size: 16,
                    color: _C.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _C.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  2. INFO CARD – Date, Time, Room, QR Token
  // ─────────────────────────────────────────────

  Widget _buildInfoCard() {
    final d = _detail!;
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _C.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Session Info',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Date',
              value: humanReadableDate(d.startTime),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Time',
              value: '${formatTime(d.startTime)} – ${formatTime(d.endTime)}',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Room',
              value: d.salle.isNotEmpty ? d.salle : '—',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.qr_code_rounded,
              label: 'QR Token',
              value: d.qrCodeToken,
              valueStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.primary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  3. ATTENDANCE SUMMARY CARD
  // ─────────────────────────────────────────────

  Widget _buildAttendanceSummaryCard() {
    final d = _detail!;
    final ratio = d.attendanceRatio;
    final barColor = _attendanceBarColor(ratio);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _C.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + percentage
            Row(
              children: [
                const Text(
                  'Attendance Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _C.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: _C.divider,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 16),

            // Stat chips
            Row(
              children: [
                _StatChip(
                  icon: Icons.check_circle_rounded,
                  label: 'Present',
                  count: d.presentCount,
                  color: _C.activeGreen,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.watch_later_rounded,
                  label: 'Late',
                  count: d.lateCount,
                  color: _C.attendanceMedium,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.cancel_rounded,
                  label: 'Absent',
                  count: d.absentCount,
                  color: _C.attendanceLow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  4. ATTENDANCE LIST CARD (first 3 + expand)
  // ─────────────────────────────────────────────

  Widget _buildAttendanceListCard() {
    final d = _detail!;
    final list = d.attendances;

    if (list.isEmpty) {
      return Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _C.cardBg,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 36,
                  color: _C.textSecondary,
                ),
                SizedBox(height: 10),
                Text(
                  'No attendance records yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: _C.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final visible = _showAllAttendances ? list : list.take(3).toList();
    final hasMore = list.length > 3;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _C.cardBg,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.list_alt_rounded, size: 18, color: _C.primary),
                const SizedBox(width: 8),
                const Text(
                  'Attendance List',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: _C.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _C.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${list.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Items
            ...visible.map(
              (a) => _AttendanceTile(
                email: a.studentEmail,
                status: a.status,
                scanTime: a.scanTime,
                statusColor: _attendanceStatusColor(a.status),
                statusIcon: _attendanceStatusIcon(a.status),
              ),
            ),

            // Show more / less
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => setState(
                      () => _showAllAttendances = !_showAllAttendances,
                    ),
                    icon: Icon(
                      _showAllAttendances
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _showAllAttendances
                          ? 'Show less'
                          : 'View all ${list.length} records',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(foregroundColor: _C.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _C.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: _C.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style:
                valueStyle ??
                const TextStyle(
                  fontSize: 14,
                  color: _C.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final String email;
  final String status;
  final DateTime scanTime;
  final Color statusColor;
  final IconData statusIcon;

  const _AttendanceTile({
    required this.email,
    required this.status,
    required this.scanTime,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 16, color: statusColor),
          ),
          const SizedBox(width: 12),
          // Email + scan time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _C.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatTime(scanTime),
                  style: const TextStyle(fontSize: 11, color: _C.textSecondary),
                ),
              ],
            ),
          ),
          // Status label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
