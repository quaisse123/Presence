import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/Api/AuthApi.dart';
import 'package:frontend/Api/QrCodeApi.dart';
import 'package:frontend/pages/studentScanTest.dart';

enum StudentAttendanceStatus { present, late, absent }

extension StudentAttendanceStatusX on StudentAttendanceStatus {
  String get label {
    switch (this) {
      case StudentAttendanceStatus.present:
        return 'Present';
      case StudentAttendanceStatus.late:
        return 'Late';
      case StudentAttendanceStatus.absent:
        return 'Absent';
    }
  }

  Color textColor() {
    switch (this) {
      case StudentAttendanceStatus.present:
        return const Color(0xFF1C9B63);
      case StudentAttendanceStatus.late:
        return const Color(0xFFCC8A2E);
      case StudentAttendanceStatus.absent:
        return const Color(0xFFD94B4B);
    }
  }

  Color bgColor() {
    switch (this) {
      case StudentAttendanceStatus.present:
        return const Color(0xFFE6F7EF);
      case StudentAttendanceStatus.late:
        return const Color(0xFFFFF3E3);
      case StudentAttendanceStatus.absent:
        return const Color(0xFFFDECEC);
    }
  }

  IconData get icon {
    switch (this) {
      case StudentAttendanceStatus.present:
        return Icons.check_circle_rounded;
      case StudentAttendanceStatus.late:
        return Icons.access_time_filled_rounded;
      case StudentAttendanceStatus.absent:
        return Icons.cancel_rounded;
    }
  }
}

enum StudentHistoryRange { week, month, all }

extension StudentHistoryRangeX on StudentHistoryRange {
  String get label {
    switch (this) {
      case StudentHistoryRange.week:
        return 'This Week';
      case StudentHistoryRange.month:
        return 'Last 30 Days';
      case StudentHistoryRange.all:
        return 'All';
    }
  }
}

class StudentAttendanceRecord {
  final int sessionId;
  final String courseTitle;
  final String courseCode;
  final String salle;
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final DateTime? scanTime;
  final StudentAttendanceStatus status;

  const StudentAttendanceRecord({
    required this.sessionId,
    required this.courseTitle,
    required this.courseCode,
    required this.salle,
    required this.sessionStart,
    required this.sessionEnd,
    required this.scanTime,
    required this.status,
  });

  bool get attended => status != StudentAttendanceStatus.absent;
}

class _StudentTheme {
  static const pageBg = Color(0xFFF1F3F6);
  static const card = Colors.white;
  static const primary = Color(0xFF1C4FBF);
  static const primaryDeep = Color(0xFF163B9A);
  static const primarySoft = Color(0xFFEAF0FE);
  static const textPrimary = Color(0xFF1D293D);
  static const textSecondary = Color(0xFF7B8798);
  static const border = Color(0xFFE4E9F1);
  static const neutral = Color(0xFF6E7E92);
  static const neutralSoft = Color(0xFFF0F3F8);
}

class StudentDashPage extends StatefulWidget {
  const StudentDashPage({super.key});

  @override
  State<StudentDashPage> createState() => _StudentDashPageState();
}

class _StudentDashPageState extends State<StudentDashPage> {
  List<StudentAttendanceRecord> _allRecords = [];
  int _totalSessions = 0;
  int _attendedSessions = 0;
  int _missedSessions = 0;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  StudentAttendanceStatus? _selectedStatus;
  StudentHistoryRange _selectedRange = StudentHistoryRange.week;

  int? _loggedUserId;
  bool _loadingUser = true;
  bool _loadingAttendances = true;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    _loadLoggedUser();

    // Recherche avec petit debounce pour eviter trop d'appels API.
    _searchController.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 350), () {
        _loadAttendances();
      });
    });

    _loadAttendances();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendances() async {
    setState(() {
      _loadingAttendances = true;
      _loadingError = null;
    });

    try {
      // Filtre periode envoye au backend.
      final period = switch (_selectedRange) {
        StudentHistoryRange.week => 'LAST_WEEK',
        StudentHistoryRange.month => 'LAST_MONTH',
        StudentHistoryRange.all => 'ALL',
      };

      // Filtre statut envoye au backend.
      final status = _selectedStatus?.name.toUpperCase();

      // Filtre recherche envoye au backend.
      final search = _searchController.text.trim();

      final data = await fetchMyAttendances(
        period: period,
        status: status,
        search: search.isEmpty ? null : search,
      );

      final items = (data['items'] as List<dynamic>? ?? <dynamic>[]);

      final records = items
          .map((item) => _fromApi(item as Map<String, dynamic>))
          .toList();

      final totalSessions = (data['totalSessions'] as num?)?.toInt() ?? 0;
      final attendedSessions = (data['attendedSessions'] as num?)?.toInt() ?? 0;
      final missedSessions = (data['missedSessions'] as num?)?.toInt() ?? 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _allRecords = records;
        _totalSessions = totalSessions;
        _attendedSessions = attendedSessions;
        _missedSessions = missedSessions;
        _loadingAttendances = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingAttendances = false;
        _loadingError = 'Impossible de charger les presences.';
        _allRecords = [];
        _totalSessions = 0;
        _attendedSessions = 0;
        _missedSessions = 0;
      });
    }
  }

  StudentAttendanceRecord _fromApi(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final status = switch (rawStatus) {
      'PRESENT' => StudentAttendanceStatus.present,
      'LATE' => StudentAttendanceStatus.late,
      _ => StudentAttendanceStatus.absent,
    };

    final start = DateTime.parse(json['sessionStartTime'] as String);
    final end = DateTime.parse(json['sessionEndTime'] as String);

    return StudentAttendanceRecord(
      sessionId: (json['sessionId'] as num).toInt(),
      courseTitle: (json['courseTitle'] ?? 'Session').toString(),
      courseCode: (json['courseCode'] ?? '-').toString(),
      salle: (json['salle'] ?? '-').toString(),
      sessionStart: start,
      sessionEnd: end,
      scanTime: json['scanTime'] == null
          ? null
          : DateTime.parse(json['scanTime'] as String),
      status: status,
    );
  }

  Future<void> _loadLoggedUser() async {
    try {
      final id = await getLoggedUserId();
      if (!mounted) {
        return;
      }
      setState(() {
        _loggedUserId = id;
        _loadingUser = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingUser = false;
      });
    }
  }

  Future<void> _openScanPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const StudentScanTestPage()));
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  DateTime _at(
    DateTime baseWeekStart,
    int dayOffset,
    int hour, [
    int minute = 0,
  ]) {
    final day = baseWeekStart.add(Duration(days: dayOffset));
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  bool _isInCurrentWeek(DateTime date) {
    final start = _startOfWeek(DateTime.now());
    final end = start.add(const Duration(days: 7));
    return !date.isBefore(start) && date.isBefore(end);
  }

  List<StudentAttendanceRecord> get _filteredRecords {
    final sorted = [..._allRecords];
    sorted.sort((a, b) => b.sessionStart.compareTo(a.sessionStart));
    return sorted;
  }

  List<StudentAttendanceRecord> get _currentWeekRecords => _allRecords
      .where((record) => _isInCurrentWeek(record.sessionStart))
      .toList();

  int get _weekAttended =>
      _currentWeekRecords.where((record) => record.attended).length;

  int get _weekTotal => _currentWeekRecords.length;

  int get _weekMissed => _currentWeekRecords
      .where((record) => record.status == StudentAttendanceStatus.absent)
      .length;

  double get _weekRatio {
    if (_totalSessions == 0) {
      return 0;
    }
    return _attendedSessions / _totalSessions;
  }

  int get _filteredMissed => _filteredRecords
      .where((record) => record.status == StudentAttendanceStatus.absent)
      .length;

  int get _filteredLate => _filteredRecords
      .where((record) => record.status == StudentAttendanceStatus.late)
      .length;

  String get _selectedRangeSubtitle {
    switch (_selectedRange) {
      case StudentHistoryRange.week:
        return 'This week';
      case StudentHistoryRange.month:
        return 'Last 30 days';
      case StudentHistoryRange.all:
        return 'All';
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime date) {
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  String _humanReadableDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today';
    }
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return _formatDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: _StudentTheme.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Student Dashboard',
          style: TextStyle(
            color: _StudentTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _selectedRange = StudentHistoryRange.week;
            _selectedStatus = null;
            _searchController.clear();
          });
          await _loadAttendances();
        },
        color: _StudentTheme.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 12),
            _buildFiltersCard(),
            const SizedBox(height: 12),
            Text(
              'Attendance history (${records.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _StudentTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            if (_loadingAttendances)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_loadingError != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _StudentTheme.border),
                ),
                child: const Text(
                  'Erreur de chargement des presences.',
                  style: TextStyle(
                    color: _StudentTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (records.isEmpty)
              _buildEmptyState()
            else
              ...records.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AttendanceHistoryCard(
                    record: record,
                    dateLabel: _humanReadableDate(record.sessionStart),
                    timeLabel:
                        '${_formatTime(record.sessionStart)} - ${_formatTime(record.sessionEnd)}',
                    scanLabel: record.scanTime == null
                        ? 'Not scanned'
                        : _formatTime(record.scanTime!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_StudentTheme.primaryDeep, _StudentTheme.primary],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My weekly presence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_loadingUser)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _loggedUserId == null ? 'Student' : 'ID #$_loggedUserId',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$_attendedSessions / $_totalSessions sessions attended ($_selectedRangeSubtitle)',
            style: const TextStyle(
              color: Color(0xE6FFFFFF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: _weekRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0x4DFFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openScanPage,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _StudentTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text(
                'Scan presence now',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniStatCard(
          title: 'Attended',
          value: '$_attendedSessions / $_totalSessions',
          subtitle: _selectedRangeSubtitle,
          icon: Icons.how_to_reg_rounded,
          color: const Color(0xFF1C9B63),
          bg: const Color(0xFFE6F7EF),
        ),
        _MiniStatCard(
          title: 'Missed sessions',
          value: '$_missedSessions',
          subtitle: 'In current filter',
          icon: Icons.event_busy_rounded,
          color: const Color(0xFFD94B4B),
          bg: const Color(0xFFFDECEC),
        ),
        _MiniStatCard(
          title: 'Late arrivals',
          value: '$_filteredLate',
          subtitle: 'In current filter',
          icon: Icons.schedule_send_rounded,
          color: const Color(0xFFCC8A2E),
          bg: const Color(0xFFFFF3E3),
        ),
        _MiniStatCard(
          title: 'Missed this week',
          value: '$_weekMissed',
          subtitle: 'Weekly risk indicator',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFF6E7E92),
          bg: const Color(0xFFF0F3F8),
        ),
      ],
    );
  }

  Widget _buildFiltersCard() {
    final statusOptions = <StudentAttendanceStatus?>[
      null,
      StudentAttendanceStatus.present,
      StudentAttendanceStatus.late,
      StudentAttendanceStatus.absent,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _StudentTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by course code, title or room...',
              hintStyle: const TextStyle(color: _StudentTheme.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => _searchController.clear(),
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: _StudentTheme.neutralSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Range',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _StudentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StudentHistoryRange.values.map((range) {
              final selected = _selectedRange == range;
              return ChoiceChip(
                selected: selected,
                label: Text(range.label),
                onSelected: (_) {
                  setState(() => _selectedRange = range);
                  _loadAttendances();
                },
                backgroundColor: Colors.white,
                selectedColor: _StudentTheme.primarySoft,
                side: BorderSide(
                  color: selected
                      ? _StudentTheme.primary
                      : _StudentTheme.border,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? _StudentTheme.primary
                      : _StudentTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Status',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _StudentTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusOptions.map((status) {
              final selected = _selectedStatus == status;
              final label = status == null ? 'All statuses' : status.label;
              return ChoiceChip(
                selected: selected,
                label: Text(label),
                onSelected: (_) {
                  setState(() => _selectedStatus = status);
                  _loadAttendances();
                },
                backgroundColor: Colors.white,
                selectedColor: status == null
                    ? _StudentTheme.primarySoft
                    : status.bgColor(),
                side: BorderSide(
                  color: selected
                      ? (status == null
                            ? _StudentTheme.primary
                            : status.textColor())
                      : _StudentTheme.border,
                ),
                labelStyle: TextStyle(
                  color: selected
                      ? (status == null
                            ? _StudentTheme.primary
                            : status.textColor())
                      : _StudentTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.find_in_page_rounded,
            size: 44,
            color: _StudentTheme.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No attendance found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _StudentTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try adjusting filters to display your history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _StudentTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = (MediaQuery.of(context).size.width - 42) / 2;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _StudentTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _StudentTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _StudentTheme.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: _StudentTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceHistoryCard extends StatelessWidget {
  final StudentAttendanceRecord record;
  final String dateLabel;
  final String timeLabel;
  final String scanLabel;

  const _AttendanceHistoryCard({
    required this.record,
    required this.dateLabel,
    required this.timeLabel,
    required this.scanLabel,
  });

  @override
  Widget build(BuildContext context) {
    final status = record.status;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _StudentTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.courseTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _StudentTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${record.courseCode} - Room ${record.salle}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _StudentTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: status.bgColor(),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 13, color: status.textColor()),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        color: status.textColor(),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _StudentTheme.neutralSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: _StudentTheme.neutral,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$dateLabel - $timeLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _StudentTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.qr_code_rounded,
                  size: 15,
                  color: _StudentTheme.neutral,
                ),
                const SizedBox(width: 4),
                Text(
                  scanLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _StudentTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Session #${record.sessionId}',
            style: const TextStyle(
              fontSize: 11,
              color: _StudentTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
